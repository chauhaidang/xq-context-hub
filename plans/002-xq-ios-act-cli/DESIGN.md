# Design: xq-ios-act-cli

- **Plan**: [`PLAN.md`](PLAN.md)
- **Benchmark**: [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
- **Role**: `engineer-in-design`
- **Status**: draft for product-lead / user review
- **Repo**: `xq-versastack` → `modules/xq-ios-act-cli/`

## Summary

`xq-ios-act` is a **host-side CLI** (Python and optional Swift clients) that speaks **DeviceKit JSON-RPC over WebSocket**. It gives coding agents stable JSON output by default, optional `--pretty` for humans, and predictable exit codes — without MobileCLI as the control plane.

**Clients (locked):**

| Client | Role | Distribution |
| --- | --- | --- |
| **Python 3.14** (primary) | Default for agents, Android path, Linux CI | **`uv tool install xq-ios-act`** |
| **Swift 5.9+** (optional) | macOS-native alternative; Xcode/sim toolchain alignment | **`swift build`** → `.build/release/xq-ios-act` |

Both clients implement the **same CLI contract** (verbs, flags, JSON envelope, exit codes, `~/.xq-ios-act/` state). Install **one** on `PATH` — not both as `xq-ios-act` simultaneously.

**Packaging (Python, locked):** **[uv](https://docs.astral.sh/uv/)** + **`pyproject.toml`** + **`uv.lock`**.

**CLI (Python, locked):** **[Google Fire](https://github.com/google/python-fire)**.

**CLI (Swift, locked):** **[swift-argument-parser](https://github.com/apple/swift-argument-parser)** — same flat verb tree as Python.

**Agent UX (locked):** Vibium-shaped flat verbs — `map` → `@ref` → `tap` → `diff map` (see [VIBIUM-BENCHMARK.md](VIBIUM-BENCHMARK.md)).

**v1 interaction model:** subcommands only (no REPL). Each invocation is a short-lived process that opens a WS connection, performs one or more RPC round-trips defined by that subcommand, then exits. A persistent session/daemon is **v2**.

---

## Problem & constraints

| Constraint | Implication |
| --- | --- |
| DeviceKit runs on sim/device as XCUITest server | CLI is a **host-side client**; we do not vendor or embed DeviceKit |
| Agents need headless, composable tools | **JSON by default**; `--pretty` for humans; examples on `--help` |
| Versastack module independence | **`python/`** + **`swift/`** subdirs; module-local verify + path-scoped CI |
| Future Android parity | Python `xq_ios_act` transport/core; Swift iOS-only |
| FSL-1.1 DeviceKit license | Document runtime dependency; no source bundling |

---

## Tech stack

### Python client (primary)

| Layer | Choice |
| --- | --- |
| Language | **Python 3.14** |
| Packaging | **uv** + `pyproject.toml` + `uv.lock` |
| CLI | **Google Fire** |
| WebSocket | **websockets** + `asyncio` |
| HTTP (health) | **httpx** |
| Tests | **pytest** + **pytest-asyncio** |
| Distribution | **`uv tool install xq-ios-act`** |

### Swift client (optional)

| Layer | Choice |
| --- | --- |
| Language | **Swift 5.9+** |
| Packaging | **Swift Package Manager** (`Package.swift`) |
| CLI | **swift-argument-parser** |
| WebSocket | **URLSessionWebSocketTask** |
| HTTP (health) | **URLSession** |
| Tests | **`swift test`** + xunit → `tsr/` |
| Distribution | **`swift build -c release`**; optional Homebrew formula later |

### Shared contract (both clients)

| Item | Spec |
| --- | --- |
| Command tree | § CLI design — identical verbs |
| Default output | Compact JSON envelope |
| Human output | `--pretty` |
| State dir | `~/.xq-ios-act/` (`$XQ_IOS_ACT_STATE_DIR`) |
| Exit codes | 0 / 2 / 3 / 4 / 5 — same semantics |
| Transport | WS `/ws` for RPC; HTTP `/health` only |

**Explicitly not in v1 stack:** vendored DeviceKit **source**, MobileCLI as install/runtime dependency, MJPEG/H264, REPL, MCP server, Android in Swift client, shiv/pex/PyInstaller.

---

## Distribution

### Python (primary)

**End-user and agent install:** [`uv tool install`](https://docs.astral.sh/uv/guides/tools/)

```bash
uv tool install xq-ios-act
xq-ios-act health
uvx xq-ios-act health              # one-shot
```

**Local dev:**

```bash
cd modules/xq-ios-act-cli/python
uv sync --all-extras
uv run xq-ios-act health
```

**Publish:** `uv build --no-sources` → `uv publish` (when on PyPI/index).

### Swift (optional)

**macOS dev / install:**

```bash
cd modules/xq-ios-act-cli/swift
swift build -c release
.build/release/xq-ios-act health
# optional: cp .build/release/xq-ios-act ~/.local/bin/
```

No `uv tool` path for Swift. README documents when to prefer Swift (macOS-only, no Python/uv, Xcode toolchain already present).

### Choosing a client

| Prefer Python when… | Prefer Swift when… |
| --- | --- |
| Agents, cross-platform dev, future Android | macOS-only, native binary feel |
| `uv tool install` workflow | Already in Swift/iOS workflow |
| Linux CI for unit tests | No Python/uv on machine |

**Not v1:** bundling Python into a single binary; Swift Homebrew tap (follow-on).

---

## Prototype spike (WP0.5)

Throwaway validation **before** WP1. Lives in `prototypes/` only — **not** shipped.

| Client | Min scope | Pass criteria |
| --- | --- | --- |
| Python | Fire, `health`, `rpc`, JSON default, `--pretty` | `uv run` + offline pytest |
| Swift | ArgumentParser, `health`, `rpc`, same envelope | `swift test` without DeviceKit |

Output: `prototypes/LEARNINGS.md` → user sign-off → delete `prototypes/` → WP1 clean tree.

---

## Architecture

### Module layout (dual client — target after prototypes)

```text
modules/xq-ios-act-cli/
  README.md                      # both clients; when to use which
  scripts/
    run-all.sh                   # python tests + swift test (macOS)
    run-python.sh
    run-swift.sh                 # macOS only; skip gracefully on Linux CI
  tsr/
  python/
    pyproject.toml
    uv.lock
    src/xq_ios_act/              # Fire CLI + library
    tests/
  swift/
    Package.swift
    Sources/
      XqIosAct/                  # library
      xq-ios-act/                # executable + Commands/
    Tests/
```

**No shared source code** between Python and Swift — **shared CLI contract** only (documented in this design). Optional `contract/` fixtures later: golden JSON outputs per command.

### Python architecture

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

**Android later:** Python `xq_ios_act` only.

### Swift architecture

Same layers as Python: `XqIosAct` library + `xq-ios-act` executable, `DeviceKitTransport` protocol, `MapStore`, `kitCall()`. Mirror Python seams; no code sharing.

### Core seams (Python)

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

### Core seams (Swift)

```swift
protocol DeviceKitTransport: Sendable {
    func fetchHealth() async throws -> HealthResult
    func call(method: String, params: JSONValue?, id: Int) async throws -> JSONRPCResponse
}

func kitCall(_ method: String, params: JSONValue? = nil) async throws -> JSONValue
struct MapStore { /* same paths as Python */ }
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

**Fire note (Python):** global flags are constructor kwargs (`xq-ios-act --base-url=… health`).

**ArgumentParser note (Swift):** same global flags on root command (`xq-ios-act --base-url … health`).

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
  dump
  rpc --method NAME [--params JSON]
  devicekit install [--sim | --device UDID] [--provisioning-profile PATH] ...
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

## DeviceKit install (v1 — first-party)

We **own** sign + install. We do **not** vendor DeviceKit source; we fetch **release artifacts** from [devicekit-ios](https://github.com/mobile-next/devicekit-ios) and install with the user's Apple credentials.

**Not using MobileCLI** for install — same outcome, our CLI contract.

### Command surface

```text
xq-ios-act devicekit install [--sim | --device UDID]
  [--provisioning-profile PATH]   # required for real device
  [--signing-identity NAME]       # optional; default: search keychain
  [--version TAG]                 # default: latest release
  [--ipa PATH]                    # skip download; use local unsigned IPA
  [--json]                        # follows global output rules (default JSON)
```

Follow-on (not v1): `devicekit start`, `devicekit status`, `devicekit uninstall`.

### Install flows

| Target | Artifact | Signing | Install tool |
| --- | --- | --- | --- |
| **Simulator** | `devicekit-ios-Sim-*.zip` from releases | None | `simctl install` / XCTest launch |
| **Real device** | `devicekit-ios-runner.ipa` (unsigned) | **Re-sign** with user's `.mobileprovision` | `xcrun devicectl` or `go-ios` |

### Re-sign requirements (real device)

Agent bundle id (upstream, fixed):

`com.mobilenext.devicekit-iosUITests.xctrunner`

| Profile type | Notes |
| --- | --- |
| **Wildcard** (`App ID *`) | Simplest — recommended in README |
| **Explicit** | Requires Apple Developer App ID for bundle above; **not** on free Personal Team |

Re-sign steps (implementation detail for dev):

1. Download or accept `--ipa` (unsigned)
2. Unzip → inject `embedded.mobileprovision`
3. `codesign` app + embedded frameworks with matching identity
4. Repackage → install to device

### After install

1. Launch XCTest runner on sim/device (v1: document `xcodebuild test` or thin launcher in WP1c+)
2. Real device: port-forward `12004` (document `ios forward` / tunnel — host must reach `127.0.0.1:12004` on device)
3. `xq-ios-act health --base-url http://127.0.0.1:12004`

### Implementation layout

```text
modules/xq-ios-act-cli/
  scripts/devicekit/
    fetch-release.sh          # curl GitHub release asset
    resign-ipa.sh             # unzip, provision, codesign, zip
    install-sim.sh
    install-device.sh
  python/src/xq_ios_act/devicekit/
    install.py                # orchestrates scripts; JSON envelope
```

Swift client may shell out to same scripts (macOS-only) to avoid duplicating sign logic.

### Errors (agent-native)

On failure, return JSON with `hint`, e.g.:

- missing `--provisioning-profile` on device install
- `ApplicationVerificationFailed` → check wildcard vs explicit profile
- device not trusted / Developer Mode off

---

## Testing architecture

| Layer | What | DeviceKit required? |
| --- | --- | --- |
| Unit (Python) | JSON codec, mock transport, exit codes | No |
| Unit (Swift) | JSON codec, mock transport, exit codes | No |
| Static | `--help` / README contract | No |
| Contract (opt-in) | Same golden commands, Python vs Swift on macOS | No (mock) / Yes (live) |
| Integration (opt-in) | Live RPC | Yes — `XQ_IOS_ACT_LIVE=1` |
| CI default | Python unit + static on **Linux** | No |
| CI Swift | `swift test` on **macos-14** | No |
| CI live (WP3) | DeviceKit on macOS | Yes |

**TSR:** pytest junit + swift xunit merged under `tsr/`.

---

## CI / devops notes (for parallel wave)

- **Linux job:** `cd python && uv sync --all-extras && bash ../scripts/run-python.sh`
- **macOS job:** Python smoke + `cd swift && swift test` via `scripts/run-swift.sh`
- **Optional live gate (WP3):** macos-14 + booted sim + DeviceKit (either client)
- Trigger paths: `modules/xq-ios-act-cli/**`, `.github/workflows/ci-xq-ios-act-cli.yml`

---

## Follow-ons (not v1)

| Item | When |
| --- | --- |
| `skills/xq-ios-act/SKILL.md` | WP2 — after CLI stabilizes |
| `session` / REPL | v2 |
| Android transport (Python only) | v1.1+ |
| Swift Homebrew tap | follow-on |
| `io swipe`, `orientation`, `device.url` wrappers | v1.1 or via `rpc` |
| MJPEG/H264 stream helpers | separate commands or docs-only |
| DeviceKit sim launcher script | merged into `devicekit install --sim` |

---

## Design decisions (locked for wave unless user objects)

| # | Decision |
| --- | --- |
| D1 | **Dual client:** Python 3.14 (primary) + Swift 5.9+ (optional); same CLI contract |
| D2 | WebSocket for all RPC; HTTP only for `health` |
| D3 | Python = Fire; Swift = ArgumentParser; same flat verbs |
| D4 | Vibium-shaped `map` / `@ref` / `diff map` + `rpc` escape hatch |
| D5 | `DeviceKitTransport` + `MapStore` per language (no shared code) |
| D6 | **JSON by default**; `--pretty` for human stdout (both clients) |
| D7 | `python/` + `swift/` subdirs under one module |
| D8 | Python dist: **`uv tool install`**; Swift dist: **`swift build`** |
| D9 | Android = Python transport only (follow-on) |
| D10 | **First-party `devicekit install`** — fetch release, re-sign (device), install; no MobileCLI |
| D11 | DeviceKit **artifacts** from upstream releases; no vendored source |

---

## Open items for product-lead / user

1. **Screenshot output** — default JSON includes base64 in `result`; optional `-o PATH` writes PNG file; `--pretty` prints path/summary?
2. **Swift in v1 scope?** — ship with Python in WP1, or WP1b immediately after? _(recommend: WP1b parallel if capacity)_
3. **Discard/rebase versastack PR #8** — move Swift scaffold into `swift/` per this layout

---

## Handoff to parallel wave

When plan is `ready`:

| Role | Package | Starts from |
| --- | --- | --- |
| `engineer-in-dev` | WP1 — library + CLI per command tree | This doc § Package layout, seams |
| `engineer-in-test` | WP1 — mock transport tests + `scripts/` + TSR | § Testing architecture |
| `engineer-in-devops` | WP1 — Linux CI workflow (+ optional macOS live gate) | § CI notes |

**Contract pointer:** `plans/002-xq-ios-act-cli/PLAN.md#work-contract--xq-versastack`
