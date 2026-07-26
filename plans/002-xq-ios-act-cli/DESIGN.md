# Design: xq-ios-act-cli

- **Plan**: [`PLAN.md`](PLAN.md)
- **Role**: `engineer-in-design`
- **Status**: draft for product-lead / user review
- **Repo**: `xq-versastack` → `modules/xq-ios-act-cli/`

## Summary

`xq-ios-act` is a **macOS-hosted Swift CLI** that speaks **DeviceKit JSON-RPC over WebSocket**. It gives coding agents stable verbs, structured `--json` output, and predictable exit codes — without MobileCLI as the control plane.

**v1 interaction model:** subcommands only (no REPL). Each invocation is a short-lived process that opens a WS connection, performs one or more RPC round-trips defined by that subcommand, then exits. A persistent session/daemon is **v2**.

---

## Problem & constraints

| Constraint | Implication |
| --- | --- |
| DeviceKit runs on sim/device as XCUITest server | CLI is a **host-side client**; we do not vendor or embed DeviceKit |
| Agents need headless, composable tools | Non-interactive flags, `--json`, examples on `--help` |
| Versastack module independence | `Package.swift` + module-local verify + path-scoped CI only |
| macOS case-insensitive FS | Shell verify scripts live in `scripts/`, Swift tests in `Tests/` |
| FSL-1.1 DeviceKit license | Document runtime dependency; no source bundling |

---

## Tech stack

| Layer | Choice | Alternatives considered | Why this choice |
| --- | --- | --- | --- |
| Language | **Swift 5.9+** | Go, Rust, Node | Aligns with DeviceKit/iOS toolchain; native on macOS CI; matches research |
| Package manager | **Swift Package Manager** | Xcode project only | Agent-friendly CLI build (`swift build`); no checked-in `.xcodeproj` required for v1 |
| CLI framework | **[swift-argument-parser](https://github.com/apple/swift-argument-parser)** | Commander, raw `CommandLine` | Layered `--help`, subcommands, examples; Apple-maintained |
| WebSocket transport | **`URLSessionWebSocketTask`** | Starscream, FlyingFox client | Zero extra deps; sufficient for JSON-RPC request/response |
| HTTP (health only) | **`URLSession`** | curl subprocess | Same stack; no shell-out |
| JSON | **`Codable` structs + `JSONValue` enum** for dynamic params | SwiftyJSON, hand-rolled only | Typed RPC envelope; flexible `params`/`result` |
| Concurrency | **Swift `async/await`** | callbacks, Combine | Natural fit for URLSession |
| Test runner | **`swift test` + xunit output** | XCTest via Xcode only | CI-friendly; integrates with `tsr/` |
| Verify wrappers | **bash in `scripts/`** | Makefile only | Matches `xq-scout-kit` module pattern |

**Explicitly not in v1 stack:** MobileCLI, vendored DeviceKit, MJPEG/H264 clients, REPL framework, root versastack workspace.

---

## Architecture

### Layer diagram

```text
┌─────────────────────────────────────────────────────────────┐
│  xq-ios-act (executable)                                     │
│  ArgumentParser · global flags · subcommand routing          │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  XqIosAct (library)                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐ │
│  │ CLIOutput   │  │ Command      │  │ DeviceKitClient     │ │
│  │ human/json  │  │ handlers     │  │ (facade)            │ │
│  └─────────────┘  └──────────────┘  └──────────┬──────────┘ │
│  ┌─────────────┐  ┌──────────────┐             │            │
│  │ JSONRPC     │  │ DeviceKitURL │             │            │
│  │ codec       │  │ builders     │             │            │
│  └─────────────┘  └──────────────┘             │            │
└────────────────────────────────────────────────┼────────────┘
                                                 │
                    ┌────────────────────────────▼────────────┐
                    │  Transport (protocol seam)                 │
                    │  · WebSocketTransport (production)         │
                    │  · MockTransport (unit tests)              │
                    └────────────────────────────┬────────────┘
                                                 │
                    ┌────────────────────────────▼────────────┐
                    │  DeviceKit (external runtime)              │
                    │  GET /health · WS /ws JSON-RPC 2.0         │
                    └───────────────────────────────────────────┘
```

### Package layout (target)

```text
modules/xq-ios-act-cli/
  Package.swift
  README.md
  Sources/
    XqIosAct/
      JSONRPC.swift           # Request/Response/JSONValue codec
      DeviceKitURL.swift      # http base → /health, /ws URLs
      CLIError.swift          # Typed errors + exit codes
      Transport.swift         # DeviceKitTransport protocol
      WebSocketTransport.swift
      DeviceKitClient.swift   # Facade: health + call(method:params:)
      Output.swift            # --json envelope + human formatting
    xq-ios-act/
      Commands/                 # one file per verb (Vibium pattern)
        Health.swift
        Map.swift
        Tap.swift
        ...
      KitCall.swift             # uniform dispatch → DeviceKitClient
      XqIosActCLI.swift         # ArgumentParser root + global flags
    XqIosAct/
      ...
      MapStore.swift            # last-map + @ref cache (file-backed)
  Tests/
    XqIosActTests/            # codec, URL, mock transport, client
  scripts/
    run-static.sh             # help/README contract
    run-all.sh                # static + swift test + tsr/
  tsr/                        # generated evidence (gitignored)
```

### Core seams (for dev / test parallel wave)

```swift
// Seam 1 — transport (mock in unit tests)
protocol DeviceKitTransport: Sendable {
    func fetchHealth() async throws -> HealthResult
    func call(method: String, params: JSONValue?, id: Int) async throws -> JSONRPCResponse
}

// Seam 2 — client facade (handlers depend on this, not URLSession directly)
struct DeviceKitClient {
    var transport: any DeviceKitTransport
    func health() async throws -> HealthResult
    func rpc(_ method: String, params: JSONValue?) async throws -> JSONValue
}

// Seam 3 — output (test JSON envelope shape without printing)
enum CLIOutput { ... }
```

---

## CLI design (v1)

### Global flags

| Flag | Default | Purpose |
| --- | --- | --- |
| `--base-url` | `http://127.0.0.1:12004` | DeviceKit HTTP base (WS derived as `/ws`) |
| `--timeout` | `30` | Per-request seconds |
| `--json` | off | Machine-readable stdout |

**Env overrides (optional v1):** `XQ_IOS_ACT_BASE_URL`, `XQ_IOS_ACT_TIMEOUT`

### Command tree

> **Updated after [Vibium benchmark](VIBIUM-BENCHMARK.md):** prefer **flat verbs** and a **map → @ref → act → diff** loop (Vibium-shaped), not deep nesting.

```text
xq-ios-act [--json] [--base-url URL] [--timeout SEC]

  health
  map [--out PATH]                # device.dump.ui + client @ref assignment
  diff map                        # compare to cached last map
  tap @eN | --x INT --y INT
  type TEXT | --ref @eN TEXT
  screenshot [-o PATH]
  launch --bundle-id ID
  foreground
  dump                            # raw device.dump.ui JSON
  rpc --method NAME [--params JSON]   # escape hatch
```

**v1 scope lock (recommended):** commands above + `rpc`. Swipe/gesture/orientation via `rpc` until v1.1.

**Local session (Vibium-inspired):** cache last map + ref table under `~/.xq-ios-act/` (or `$XQ_IOS_ACT_STATE_DIR`); invalidate refs after UI-changing acts — document in skill.

### Agent-native behaviors

Per [CLI for agents](https://github.com/chauhaidang/xq-context-hub) conventions:

1. **Non-interactive first** — every input is a flag; no prompts in v1
2. **Examples on every `--help`** — real copy-paste invocations
3. **Actionable errors** — stderr includes `hint` with a correct example command
4. **Idempotent where possible** — `health`, `device info` are read-only; `launch` may no-op if already foreground (document DeviceKit behavior)
5. **Success output** — human: concise summary; `--json`: structured envelope (below)

### JSON output envelope

**Success:**

```json
{
  "ok": true,
  "command": "device.info",
  "result": { "width": 390, "height": 844, "scale": 3 },
  "meta": {
    "baseUrl": "http://127.0.0.1:12004",
    "method": "device.info",
    "durationMs": 38,
    "rpcId": 1
  }
}
```

**Failure:**

```json
{
  "ok": false,
  "command": "device.info",
  "error": {
    "kind": "transport",
    "message": "Connection refused",
    "hint": "xq-ios-act health --base-url http://127.0.0.1:12004"
  },
  "exitCode": 3
}
```

`result` is the **raw DeviceKit JSON-RPC result** (no lossy re-shaping) so agents can rely on upstream semantics.

### Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 2 | Usage / validation (missing `--method`, bad JSON in `--params`) |
| 3 | Transport (connection refused, timeout, TLS) |
| 4 | JSON-RPC error returned by DeviceKit |
| 5 | Internal decode / unexpected response |

---

## Transport & session model

### v1: one process, one WS connection per command

```text
Agent runs: xq-ios-act device info --json

  CLI parse flags
    → open WS to ws://127.0.0.1:12004/ws
    → send {"jsonrpc":"2.0","method":"device.info","id":1}
    → receive response
    → close WS
    → print envelope / exit
```

**Why WS for one-shot:** keeps transport consistent with future multi-RPC session; avoids baking HTTP `/rpc` as the default path agents learn.

### v2 (out of v1 scope): session mode

```text
xq-ios-act session run --file steps.jsonl   # multiple RPCs, one connection
xq-ios-act session attach                   # long-lived, stdin JSON-RPC lines
```

Design v1 library so `DeviceKitClient` can accept a **shared transport instance** across multiple handler calls — enables `session` without rewriting the client.

### HTTP usage

| Endpoint | Use in v1 |
| --- | --- |
| `GET /health` | `health` subcommand only |
| `WS /ws` | All RPC (including via convenience wrappers) |
| `POST /rpc` | **Not used** in v1 CLI |
| `/mjpeg`, `/h264`, TCP broadcast | Document only; no CLI wrapper |

---

## DeviceKit lifecycle (v1)

**Document-only.** README sections:

1. Build/install DeviceKit on sim or device (link upstream docs)
2. Start server (XCUITest runner) — default `127.0.0.1:12004`
3. Real device: port-forward / tunnel (document `ios forward` / MobileCLI as optional ops path)
4. Point `xq-ios-act --base-url …` at reachable base URL

No `xq-ios-act devicekit install` in v1.

---

## Testing architecture

| Layer | What | DeviceKit required? |
| --- | --- | --- |
| Unit | JSON codec, URL builders, exit codes, mock transport | No |
| Static | `--help` examples, README contract strings | No (builds CLI) |
| Integration (opt-in) | Live RPC against running DeviceKit | Yes — `XQ_IOS_ACT_LIVE=1` |
| CI default | unit + static via `scripts/run-all.sh` | No |
| CI optional WP3 | `workflow_dispatch` live job on macOS + booted sim | Yes |

**Mock transport fixture:** canned responses for `device.info`, error `-32601`, connection failure injection.

**TSR:** `swift test --xunit-output tsr/junit-swift.xml` → copy to `tsr/junit.xml`; `tsr/summary.md` with test count.

---

## CI / devops notes (for parallel wave)

- Runner: `macos-14` or newer (Swift 5.9+)
- Trigger paths: `modules/xq-ios-act-cli/**`, `.github/workflows/ci-xq-ios-act-cli.yml`
- Job: `cd modules/xq-ios-act-cli && bash scripts/run-all.sh`
- No Linux job (URLSession WS + macOS host assumption)

---

## Follow-ons (not v1)

| Item | When |
| --- | --- |
| `skills/xq-ios-act/SKILL.md` | WP2 — after CLI stabilizes |
| `session` / REPL | v2 |
| `io swipe`, `orientation`, `device.url` wrappers | v1.1 or via `rpc` |
| MJPEG/H264 stream helpers | separate commands or docs-only |
| DeviceKit sim launcher script | if document-only proves insufficient |

---

## Design decisions (locked for wave unless user objects)

| # | Decision |
| --- | --- |
| D1 | Swift SPM module; library `XqIosAct` + executable `xq-ios-act` |
| D2 | WebSocket for all RPC; HTTP only for `health` |
| D3 | v1 = subcommands; no REPL |
| D4 | `rpc` escape hatch + curated convenience wrappers (see command tree) |
| D5 | `DeviceKitTransport` protocol for testability |
| D6 | Structured `--json` envelope with raw DeviceKit `result` |
| D7 | Verify scripts in `scripts/`; Swift tests in `Tests/` |
| D8 | DeviceKit lifecycle document-only in v1 |

---

## Open items for product-lead / user

1. **Confirm v1 command tree** — is `dump ui` + `io tap/text` + `apps launch/foreground` the right cut, or slimmer?
2. **Screenshot output** — `--json` returns base64 inline vs `--out PATH` writes file (recommend: both; default inline in JSON, optional `--out` for PNG file)
3. **Discard premature PR #8** — implementation predates this design; recommend close and re-implement from contract

---

## Handoff to parallel wave

When plan is `ready`:

| Role | Package | Starts from |
| --- | --- | --- |
| `engineer-in-dev` | WP1 — library + CLI per command tree | This doc § Package layout, seams |
| `engineer-in-test` | WP1 — mock transport tests + `scripts/` + TSR | § Testing architecture |
| `engineer-in-devops` | WP1 — macOS CI workflow | § CI notes |

**Contract pointer:** `plans/002-xq-ios-act-cli/PLAN.md#work-contract--xq-versastack`
