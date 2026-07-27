# Design: xq-ios-act-cli

- **Plan**: [`PLAN.md`](PLAN.md)
- **Benchmark**: [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
- **Role**: `engineer-in-design`
- **Status**: draft for product-lead / user review
- **Repo**: `xq-versastack` → `modules/xq-ios-act-cli/`

## Summary

`xq-ios-act` is a **host-side Python CLI** that speaks **DeviceKit JSON-RPC over WebSocket**. It gives coding agents stable JSON output by default, optional `--pretty` for humans, and predictable exit codes — without MobileCLI as the control plane.

**Language (locked):** **Python 3.14** — fast iteration, strong test ergonomics, and a transport/JSON-RPC layer that can be **shared with a future Android client** ([devicekit-android](https://github.com/mobile-next/devicekit-android) uses the same JSON-RPC methods over HTTP via `adb forward`).

**Packaging (locked):** **[uv](https://docs.astral.sh/uv/)** + **`pyproject.toml`** + **`uv.lock`** — `uv sync` for dev, **`uv tool install`** for distribution.

**CLI (locked):** **[Google Fire](https://github.com/google/python-fire)** — flat methods as verbs; nested component for `diff map`.

**Distribution (locked):** **`uv tool install xq-ios-act`** — publishable wheel via `uv build` / `uv publish`; no single-file binary or PyInstaller in v1.

**Agent UX (locked):** Vibium-shaped flat verbs — `map` → `@ref` → `tap` → `diff map` (see [VIBIUM-BENCHMARK.md](VIBIUM-BENCHMARK.md)).

**v1 interaction model:** subcommands only (no REPL). Each invocation is a short-lived process that opens a WS connection, performs one or more RPC round-trips defined by that subcommand, then exits. A persistent session/daemon is **v2**.

---

## Problem & constraints

| Constraint | Implication |
| --- | --- |
| DeviceKit runs on sim/device as XCUITest server | CLI is a **host-side client**; we do not vendor or embed DeviceKit |
| Agents need headless, composable tools | **JSON by default**; `--pretty` for humans; examples on `--help` |
| Versastack module independence | **`pyproject.toml`** + **`uv.lock`** + module-local verify + path-scoped CI |
| Future Android parity | Keep JSON-RPC codec, transport protocol, `MapStore`, and output envelope **platform-agnostic** in `xq_ios_act/` |
| FSL-1.1 DeviceKit license | Document runtime dependency; no source bundling |

---

## Tech stack

| Layer | Choice | Alternatives considered | Why this choice |
| --- | --- | --- | --- |
| Language | **Python 3.14** | Swift, Go, 3.11+ | User decision; shared client core for iOS + future Android |
| Packaging | **[uv](https://docs.astral.sh/uv/)** + **`pyproject.toml`** + **`uv.lock`** | pip, Poetry, shiv/pex | Fast sync/lock; **`uv tool install`** for agent/user distribution |
| CLI framework | **[Google Fire](https://github.com/google/python-fire)** | Typer, Click | Flat method-per-verb mapping; minimal boilerplate |
| WebSocket transport | **[websockets](https://github.com/python-websockets/websockets)** | websocket-client | Async-native; one `asyncio.run()` per command |
| HTTP (health) | **[httpx](https://www.python-httpx.org/)** | urllib, requests | Sync health check; clear timeout/error types |
| JSON | **stdlib `json`** | pydantic | Dynamic RPC params; minimal deps |
| Concurrency | **`asyncio`** per command | threaded sync WS | Matches `websockets`; keeps CLI code simple |
| Tests | **pytest** + **pytest-asyncio** | unittest | Fast unit tests; mock transport; `tsr/junit.xml` via pytest |
| Verify wrappers | **bash in `scripts/`** | Makefile | Matches `xq-scout-kit` pattern |

### Stdlib vs dependencies

| Capability | Stdlib | Dependency |
| --- | --- | --- |
| JSON-RPC codec | `json`, `dataclasses` / `TypedDict` | — |
| HTTP health | — | **httpx** |
| WebSocket RPC | — | **websockets** |
| File map cache | `pathlib`, `json` | — |
| CLI parsing + dispatch | — | **fire** |
| Tests | — | **pytest**, **pytest-asyncio** |

**Explicitly not in v1 stack:** MobileCLI, vendored DeviceKit, MJPEG/H264, REPL, MCP server, Android backend implementation, **shiv/pex/PyInstaller/single-file bundles**.

---

## Distribution

**End-user and agent install (locked):** [`uv tool install`](https://docs.astral.sh/uv/guides/tools/)

```bash
# After publish to PyPI (or private index)
uv tool install xq-ios-act
xq-ios-act health

# One-shot without global install
uvx xq-ios-act health
```

**Local / monorepo dev:**

```bash
cd modules/xq-ios-act-cli
uv sync --all-extras
uv run xq-ios-act health          # project venv
uv tool install -e .              # optional: install into uv tool env for PATH testing
```

**Publish path (when module ships publicly):**

```bash
uv version --bump patch           # optional
uv build --no-sources
uv publish                        # PyPI or [[tool.uv.index]] with publish-url
```

`pyproject.toml` must declare the console script:

```toml
[project.scripts]
xq-ios-act = "xq_ios_act.app:main"
```

**Prerequisites for users:** [uv](https://docs.astral.sh/uv/) installed (uv manages Python 3.14 via `uv python install` if needed). DeviceKit on sim/device is separate (documented in README).

**Not v1:** standalone binaries, `.pyz` zipapps, bundling the Python interpreter into one artifact.

---

## Architecture

### Layer diagram

```text
┌─────────────────────────────────────────────────────────────┐
│  xq-ios-act (console script / uv run)                        │
│  Fire · flat methods: map, tap, screenshot, rpc              │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  xq_ios_act (library package)                                │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐ │
│  │ output      │  │ kit_call()   │  │ DeviceKitClient     │ │
│  └─────────────┘  └──────────────┘  └──────────┬──────────┘ │
│  ┌─────────────┐  ┌──────────────┐             │            │
│  │ jsonrpc     │  │ MapStore     │             │            │
│  └─────────────┘  └──────────────┘             │            │
└────────────────────────────────────────────────┼────────────┘
                                                 │
                    ┌────────────────────────────▼────────────┐
                    │  DeviceKitTransport (Protocol)           │
                    │  · WebSocketTransport (production)       │
                    │  · MockTransport (unit tests)            │
                    └────────────────────────────┬────────────┘
                                                 │
                    ┌────────────────────────────▼────────────┐
                    │  devicekit-ios (external)                │
                    │  GET /health · WS /ws JSON-RPC 2.0       │
                    └──────────────────────────────────────────┘
```

### Package layout (target)

```text
modules/xq-ios-act-cli/
  pyproject.toml                 # requires-python >=3.14; [project.scripts]
  uv.lock
  README.md
  src/xq_ios_act/
    __init__.py
    __main__.py                  # fire.Fire(...) entry when run as module
    app.py                       # Fire surface: XqIosAct + Diff components
    commands/                    # verb implementations (Vibium pattern)
      health.py
      map_cmd.py                 # `map` — avoid shadowing builtin
      tap.py
      ...
    jsonrpc.py
    urls.py
    errors.py
    transport.py                 # DeviceKitTransport Protocol
    websocket_transport.py
    mock_transport.py
    client.py
    map_store.py
    output.py
    kit_call.py
    config.py                    # base_url, timeout, pretty — shared CLI config
  tests/
    test_jsonrpc.py
    test_transport.py
    ...
  scripts/
    run-static.sh
    run-all.sh                   # uv run pytest + tsr/
  tsr/
```

**Fire wiring (sketch):**

```python
class XqIosAct:
    def __init__(self, base_url: str = "http://127.0.0.1:12004", timeout: int = 30, pretty: bool = False):
        self.config = Config(base_url, timeout, pretty)

    def health(self): ...
    def map(self, out: str | None = None): ...
    def tap(self, ref: str | None = None, x: int | None = None, y: int | None = None): ...
    # ...

class Diff:
    def __init__(self, parent: XqIosAct): ...
    def map(self): ...

def main():
    root = XqIosAct()
    fire.Fire({"": root, "diff": Diff(root)})
```

**Android later:** extend `xq_ios_act` with an Android transport (HTTP via `adb forward`) or a thin `xq-android-act` module that imports the shared package — same JSON-RPC surface, different default base URL.

### Core seams (for dev / test parallel wave)

```python
class DeviceKitTransport(Protocol):
    async def fetch_health(self) -> HealthResult: ...
    async def call(
        self, method: str, params: Any | None, id: int
    ) -> JSONRPCResponse: ...

async def kit_call(method: str, params: Any | None = None) -> Any: ...

class MapStore:
    """Last map + @ref table on disk under ~/.xq-ios-act/."""
```

---

## CLI design (v1)

### Global flags

| Flag | Default | Purpose |
| --- | --- | --- |
| `--base-url` | `http://127.0.0.1:12004` | DeviceKit HTTP base (WS derived as `/ws`) |
| `--timeout` | `30` | Per-request seconds |
| `--pretty` | `False` | Human-readable stdout (default is compact JSON envelope) |

**Env overrides (optional v1):** `XQ_IOS_ACT_BASE_URL`, `XQ_IOS_ACT_TIMEOUT`

**Fire note:** global flags are **constructor kwargs** on the root component (`xq-ios-act --base-url=… health`). Document canonical examples in README.

**Output rule:** stdout is always **one structured result per command**. Default = compact JSON; `--pretty` = concise human summary. Agents never need a flag to parse output.

### Command tree

> **Updated after [Vibium benchmark](VIBIUM-BENCHMARK.md):** prefer **flat verbs** and a **map → @ref → act → diff** loop (Vibium-shaped), not deep nesting.

```text
xq-ios-act [--pretty] [--base-url URL] [--timeout SEC]

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
5. **Success output** — default: compact JSON envelope (below); `--pretty`: concise human summary on stdout
6. **Errors follow the same mode** — default: JSON envelope with `ok: false`; `--pretty`: one-line message + `hint` on stderr

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

### Pretty output (human mode)

With `--pretty`, stdout is plain text — not JSON. Examples:

```text
$ xq-ios-act health --pretty
ok  devicekit reachable  http://127.0.0.1:12004  (12ms)

$ xq-ios-act map --pretty
map  42 elements  @e1..@e42  saved ~/.xq-ios-act/last-map.json

$ xq-ios-act tap @e3 --pretty
tap  @e3  (120, 44)  ok
```

Errors with `--pretty`: stderr shows `error: …` and `hint: …`; exit code unchanged.

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
Agent runs: xq-ios-act dump

  CLI parse flags
    → asyncio.run: open WS to ws://127.0.0.1:12004/ws
    → send {"jsonrpc":"2.0","method":"device.dump.ui","id":1}
    → receive response
    → close WS
    → print JSON envelope (or pretty text if --pretty) / exit
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
| Static | `--help` / README examples, contract strings | No (`uv sync` only) |
| Integration (opt-in) | Live RPC against running DeviceKit | Yes — `XQ_IOS_ACT_LIVE=1` |
| CI default | unit + static via `scripts/run-all.sh` | No |
| CI optional WP3 | `workflow_dispatch` live job on macOS + booted sim | Yes |

**Mock transport fixture:** canned responses for `device.info`, error `-32601`, connection failure injection.

**TSR:** `uv run pytest --junitxml=tsr/junit.xml`; `tsr/summary.md` with test count.

**CI runner advantage:** default unit/static CI can run on **Linux** (no Xcode required); live DeviceKit gate stays on **macOS**.

---

## CI / devops notes (for parallel wave)

- **Default CI:** `ubuntu-latest` — install uv, `uv sync --all-extras`, `bash scripts/run-all.sh`
- Pin **Python 3.14** in CI (`uv python install 3.14` or `setup-python` + uv)
- **Optional live gate (WP3):** `macos-14` + booted sim + DeviceKit
- Trigger paths: `modules/xq-ios-act-cli/**`, `.github/workflows/ci-xq-ios-act-cli.yml`

---

## Follow-ons (not v1)

| Item | When |
| --- | --- |
| `skills/xq-ios-act/SKILL.md` | WP2 — after CLI stabilizes |
| `session` / REPL | v2 |
| Android transport (`adb forward` + devicekit-android) | v1.1+ — reuse `xq_ios_act` core |
| `io swipe`, `orientation`, `device.url` wrappers | v1.1 or via `rpc` |
| MJPEG/H264 stream helpers | separate commands or docs-only |
| DeviceKit sim launcher script | if document-only proves insufficient |

---

## Design decisions (locked for wave unless user objects)

| # | Decision |
| --- | --- |
| D1 | **Python 3.14** — `uv` + `pyproject.toml` + `uv.lock`; package `xq_ios_act` + script `xq-ios-act` |
| D2 | WebSocket for all RPC; HTTP only for `health` |
| D3 | v1 = flat **Fire** methods; nested `diff map`; no REPL |
| D4 | Vibium-shaped `map` / `@ref` / `diff map` + `rpc` escape hatch |
| D5 | `DeviceKitTransport` protocol + `MapStore` |
| D6 | **JSON envelope by default**; `--pretty` for human stdout |
| D7 | `scripts/run-all.sh` → `pytest` + TSR |
| D8 | DeviceKit lifecycle document-only in v1 |
| D9 | Android = shared Python transport/core later (not v1 scope) |
| D10 | **Distribution via `uv tool install`**; `uv build` + `uv publish` when on PyPI; no binary bundler in v1 |

---

## Open items for product-lead / user

1. **Screenshot output** — default JSON includes base64 in `result`; optional `-o PATH` writes PNG file; `--pretty` prints path/summary?
2. **Discard premature versastack PR #8** — Swift scaffold predates approved design; re-implement in Python after approval?

---

## Handoff to parallel wave

When plan is `ready`:

| Role | Package | Starts from |
| --- | --- | --- |
| `engineer-in-dev` | WP1 — library + CLI per command tree | This doc § Package layout, seams |
| `engineer-in-test` | WP1 — mock transport tests + `scripts/` + TSR | § Testing architecture |
| `engineer-in-devops` | WP1 — Linux CI workflow (+ optional macOS live gate) | § CI notes |

**Contract pointer:** `plans/002-xq-ios-act-cli/PLAN.md#work-contract--xq-versastack`
