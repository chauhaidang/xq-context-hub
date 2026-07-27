# Design: xq-ios-act-cli

- **Plan**: [`PLAN.md`](PLAN.md)
- **Benchmark**: [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
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
| Language | **Python 3.11+** | Swift, Go, Node | One codebase for iOS + future Android transports; Vibium ships a Python client; agents already run Python |
| Packaging | **`pyproject.toml` + `src/` layout** | Poetry-only, flat module | Standard PEP 517; `pip install -e .` for dev; entry point `xq-ios-act` |
| CLI framework | **[Typer](https://typer.tiangolo.com/)** (Click underneath) | argparse, Click direct | Layered `--help`, subcommands, examples; same family as many agent CLIs |
| iOS transport | **WebSocket JSON-RPC** (`websockets` lib) | httpx-ws, one-shot HTTP `/rpc` | Matches devicekit-ios; chatty loops; research default |
| Android transport (future) | **HTTP POST JSON-RPC** via `adb forward` | WS if Android adds it | devicekit-android resident server on `localabstract:devicekit` |
| HTTP helpers | **httpx** | urllib, requests | Health checks, Android RPC, consistent timeouts |
| JSON | **`json` stdlib** | pydantic models v1 | Dynamic RPC params/results; keep deps thin |
| Tests | **pytest** + pytest-xunit or junitxml plugin | unittest | Linux CI for unit tests; `tsr/junit.xml` |
| Verify wrappers | **bash in `scripts/`** | Makefile only | Matches `xq-scout-kit` module pattern |

### Built-in (stdlib) vs dependencies

| Capability | Stdlib | Third-party |
| --- | --- | --- |
| JSON-RPC encode/decode | `json` | — |
| File map cache | `pathlib`, `json` | — |
| Exit codes / argv | `sys` | — |
| CLI structure + `--help` | — | **typer** |
| iOS WebSocket | — | **websockets** |
| HTTP health / Android RPC | — | **httpx** |
| Tests | — | **pytest** |

**Explicitly not in v1 stack:** MobileCLI, vendored DeviceKit, MJPEG/H264, REPL, MCP server, root versastack workspace.

---

## Architecture

### Layer diagram

```text
┌─────────────────────────────────────────────────────────────┐
│  xq-ios-act (console script / typer app)                     │
│  flat verbs: map, tap, screenshot, rpc, health               │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  xq_ios_act (library)                                        │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐ │
│  │ output      │  │ commands     │  │ KitClient (facade)  │ │
│  │ envelope    │  │ kit_call()   │  │                     │ │
│  └─────────────┘  └──────────────┘  └──────────┬──────────┘ │
│  ┌─────────────┐  ┌──────────────┐             │            │
│  │ jsonrpc     │  │ mapstore     │             │            │
│  └─────────────┘  └──────────────┘             │            │
└────────────────────────────────────────────────┼────────────┘
                                                 │
                    ┌────────────────────────────▼────────────┐
                    │  Transport (Protocol)                      │
                    │  · IosWebSocketTransport  (v1)             │
                    │  · AndroidHttpTransport   (future)         │
                    │  · MockTransport          (tests)          │
                    └────────────────────────────┬────────────┘
                                                 │
         ┌───────────────────┬───────────────────┘
         ▼                   ▼ (future)
  devicekit-ios          devicekit-android
  WS /ws + /health       HTTP via adb forward
```

### Package layout (target)

```text
modules/xq-ios-act-cli/
  pyproject.toml              # deps, entry point xq-ios-act
  README.md
  src/xq_ios_act/
    __init__.py
    cli/
      __init__.py
      main.py                 # typer app, global flags
      health.py
      map_cmd.py
      tap.py
      ...
    jsonrpc.py
    kit_client.py             # kit_call(method, params)
    transports/
      base.py                 # Protocol
      ios_ws.py
      android_http.py         # stub / future
      mock.py
    mapstore.py
    output.py
    urls.py
  tests/
    test_jsonrpc.py
    test_mapstore.py
    ...
  scripts/
    run-static.sh
    run-all.sh                # pytest + tsr/
  tsr/
```

**Android later:** add `xq-android-act-cli` module *or* extend this package with `--platform android` and shared `xq_ios_act` → rename package to `xq_act` when both ship. v1 keeps module name `xq-ios-act-cli`, but **transport Protocol from day one**.

### Core seams (for dev / test parallel wave)

```python
# Transport — mock in unit tests; swap iOS vs Android later
class DeviceKitTransport(Protocol):
    def health(self) -> HealthResult: ...
    def call(self, method: str, params: dict | None = None) -> Any: ...

# Facade — every typer command calls this
def kit_call(method: str, params: dict | None = None) -> Any: ...

# Map store — Vibium-style @refs (platform-agnostic)
class MapStore: ...
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

- **Unit tests:** `ubuntu` runner — `pytest` with `MockTransport` (no DeviceKit)
- **Live iOS gate (optional WP3):** `macos-14` + booted sim + DeviceKit
- **Live Android gate (future):** emulator + `adb forward` + devicekit-android
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
| D1 | **Python 3.11+** with `pyproject.toml` + `src/xq_ios_act/` |
| D2 | iOS: WebSocket JSON-RPC; Android future: HTTP JSON-RPC via `adb forward` |
| D3 | v1 = flat typer verbs; no REPL |
| D4 | Vibium-shaped `map` / `@ref` / `diff map` + `rpc` escape hatch |
| D5 | `DeviceKitTransport` Protocol + `MapStore` from day one (Android-ready) |
| D6 | `--json` envelope `{"ok", "result", "error"}` (Vibium-compatible) |
| D7 | `scripts/run-all.sh` → `pytest` + TSR |
| D8 | DeviceKit lifecycle document-only in v1 |
| D9 | Sync Python v1 (`def kit_call`); async later if needed |

---

## Open items for product-lead / user

1. **Confirm Vibium-shaped UX** — flat verbs + `map` → `@ref` → `tap` → `diff map` as primary agent loop?
2. **Screenshot output** — `--json` inline base64 + optional `-o PATH` for PNG file?
3. **Discard premature PR #8** — re-implement from updated design?

---

## Handoff to parallel wave

When plan is `ready`:

| Role | Package | Starts from |
| --- | --- | --- |
| `engineer-in-dev` | WP1 — library + CLI per command tree | This doc § Package layout, seams |
| `engineer-in-test` | WP1 — mock transport tests + `scripts/` + TSR | § Testing architecture |
| `engineer-in-devops` | WP1 — macOS CI workflow | § CI notes |

**Contract pointer:** `plans/002-xq-ios-act-cli/PLAN.md#work-contract--xq-versastack`
