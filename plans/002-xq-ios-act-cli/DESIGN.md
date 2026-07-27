# Design: xq-ios-act-cli

- **Plan**: [`PLAN.md`](PLAN.md)
- **Benchmark**: [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
- **Role**: `engineer-in-design`
- **Status**: draft for product-lead / user review
- **Repo**: `xq-versastack` → `modules/xq-ios-act-cli/`

## Summary

`xq-ios-act` is a **macOS-hosted Swift CLI** that speaks **DeviceKit JSON-RPC over WebSocket**. It gives coding agents stable verbs, structured `--json` output, and predictable exit codes — without MobileCLI as the control plane.

**Language (locked):** **Swift 5.9+** — aligns with DeviceKit/iOS toolchain and Xcode sim workflow. Android automation is a **separate follow-on module** (not shared Swift codebase).

**Agent UX (locked):** Vibium-shaped flat verbs — `map` → `@ref` → `tap` → `diff map` (see [VIBIUM-BENCHMARK.md](VIBIUM-BENCHMARK.md)).

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
| Language | **Swift 5.9+** | Python, Go | DeviceKit/iOS alignment; stdlib networking; user decision |
| Packaging | **Swift Package Manager** | Xcode project only | `swift build` / `swift test`; no checked-in `.xcodeproj` for v1 |
| CLI framework | **[swift-argument-parser](https://github.com/apple/swift-argument-parser)** | Commander, raw `CommandLine` | Layered `--help`, subcommands, examples |
| WebSocket transport | **`URLSessionWebSocketTask`** | Starscream | Stdlib; no extra WS dependency |
| HTTP (health) | **`URLSession`** | curl subprocess | Same stack as WS client |
| JSON | **`Codable` + `JSONValue` enum** | SwiftyJSON | Typed envelope; dynamic RPC params |
| Concurrency | **`async/await`** | callbacks | Natural for URLSession |
| Tests | **`swift test` + xunit output** | XCTest via Xcode only | `tsr/junit.xml` |
| Verify wrappers | **bash in `scripts/`** | Makefile | Matches `xq-scout-kit`; avoids `Tests/` vs `tests/` collision |

### Built-in (Swift / Apple SDK) vs dependencies

| Capability | Built-in | Dependency |
| --- | --- | --- |
| JSON-RPC codec | `Codable`, `JSONEncoder` | — |
| HTTP + WebSocket | `URLSession`, `URLSessionWebSocketTask` | — |
| File map cache | `FileManager`, `Codable` | — |
| CLI parsing + `--help` | — | **swift-argument-parser** |
| Tests | `XCTest` via `swift test` | — |

**Explicitly not in v1 stack:** MobileCLI, vendored DeviceKit, MJPEG/H264, REPL, MCP server, Android transport.

---

## Architecture

### Layer diagram

```text
┌─────────────────────────────────────────────────────────────┐
│  xq-ios-act (executable)                                     │
│  ArgumentParser · flat verbs: map, tap, screenshot, rpc      │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  XqIosAct (library)                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐ │
│  │ Output      │  │ kitCall()    │  │ DeviceKitClient     │ │
│  └─────────────┘  └──────────────┘  └──────────┬──────────┘ │
│  ┌─────────────┐  ┌──────────────┐             │            │
│  │ JSONRPC     │  │ MapStore     │             │            │
│  └─────────────┘  └──────────────┘             │            │
└────────────────────────────────────────────────┼────────────┘
                                                 │
                    ┌────────────────────────────▼────────────┐
                    │  DeviceKitTransport (protocol)             │
                    │  · WebSocketTransport (production)         │
                    │  · MockTransport (unit tests)              │
                    └────────────────────────────┬────────────┘
                                                 │
                    ┌────────────────────────────▼────────────┐
                    │  devicekit-ios (external)                  │
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
      JSONRPC.swift
      DeviceKitURL.swift
      CLIError.swift
      DeviceKitTransport.swift
      WebSocketTransport.swift
      DeviceKitClient.swift
      MapStore.swift
      Output.swift
      KitCall.swift              # uniform dispatch
    xq-ios-act/
      XqIosActCLI.swift          # ArgumentParser root + global flags
      Commands/                  # one file per verb (Vibium pattern)
        Health.swift
        Map.swift
        Tap.swift
        ...
  Tests/
    XqIosActTests/
  scripts/
    run-static.sh
    run-all.sh                   # swift test + tsr/
  tsr/
```

**Android later:** separate versastack module (e.g. `xq-android-act-cli`); reuse agent UX patterns from this skill, not Swift code.

### Core seams (for dev / test parallel wave)

```swift
protocol DeviceKitTransport: Sendable {
    func fetchHealth() async throws -> HealthResult
    func call(method: String, params: JSONValue?, id: Int) async throws -> JSONRPCResponse
}

func kitCall(_ method: String, params: JSONValue? = nil) async throws -> JSONValue

struct MapStore { /* last map + @ref table on disk */ }
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
4. **Idempotent where possible** — `health`, `dump` are read-only; `launch` may no-op if already foreground (document DeviceKit behavior)
5. **Success output** — human: concise summary; `--json`: structured envelope (below)

### JSON output envelope

**Success:**

```json
{
  "ok": true,
  "command": "dump",
  "result": { "elements": [] },
  "meta": {
    "baseUrl": "http://127.0.0.1:12004",
    "method": "device.dump.ui",
    "durationMs": 38,
    "rpcId": 1
  }
}
```

**Failure:**

```json
{
  "ok": false,
  "command": "dump",
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
Agent runs: xq-ios-act dump --json

  CLI parse flags
    → open WS to ws://127.0.0.1:12004/ws
    → send {"jsonrpc":"2.0","method":"device.dump.ui","id":1}
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

- Runner: **`macos-14`** or newer (Swift 5.9+; URLSession WS)
- Job: `cd modules/xq-ios-act-cli && bash scripts/run-all.sh`
- Trigger paths: `modules/xq-ios-act-cli/**`, `.github/workflows/ci-xq-ios-act-cli.yml`
- Optional WP3: `workflow_dispatch` live DeviceKit on macOS + booted sim
- No Linux job (macOS-only host assumption for this module)

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
| D1 | **Swift 5.9+** SPM — library `XqIosAct` + executable `xq-ios-act` |
| D2 | WebSocket for all RPC; HTTP only for `health` |
| D3 | v1 = flat ArgumentParser verbs; no REPL |
| D4 | Vibium-shaped `map` / `@ref` / `diff map` + `rpc` escape hatch |
| D5 | `DeviceKitTransport` protocol + `MapStore` |
| D6 | `--json` envelope with raw DeviceKit `result` |
| D7 | `scripts/run-all.sh` → `swift test` + TSR |
| D8 | DeviceKit lifecycle document-only in v1 |
| D9 | Android = separate module later (not shared Swift codebase) |

---

## Open items for product-lead / user

1. **Screenshot output** — `--json` inline base64 + optional `-o PATH` for PNG file?
2. **Discard premature PR #8** — re-implement from Swift + Vibium-shaped design?

---

## Handoff to parallel wave

When plan is `ready`:

| Role | Package | Starts from |
| --- | --- | --- |
| `engineer-in-dev` | WP1 — library + CLI per command tree | This doc § Package layout, seams |
| `engineer-in-test` | WP1 — mock transport tests + `scripts/` + TSR | § Testing architecture |
| `engineer-in-devops` | WP1 — macOS CI workflow | § CI notes |

**Contract pointer:** `plans/002-xq-ios-act-cli/PLAN.md#work-contract--xq-versastack`
