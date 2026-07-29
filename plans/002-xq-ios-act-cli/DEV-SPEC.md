# Dev spec: xq-ios-act-cli (v1)

- **Plan**: [`PLAN.md`](PLAN.md)
- **Design**: [`DESIGN.md`](DESIGN.md)
- **Role**: `engineer-in-design` → handoff to `engineer-in-dev` / `engineer-in-test` / `engineer-in-devops`
- **Target repo**: `xq-versastack` → `modules/xq-ios-act-cli/`
- **Branch**: `xq/xq-ios-act-cli-f8f1`

This document is the **implementation contract**. If DEV-SPEC disagrees with DESIGN on implementation detail, fix DEV-SPEC or escalate. Product behavior is locked in DESIGN.

---

## 1. Implementation phases

Build in order within each workstream. **WP1c** can start after transport + envelope land.

| Phase | Owner | Deliverable | Depends on |
| --- | --- | --- | --- |
| **P0** | dev | `config`, `envelope`, `exit_codes`, `cli/__main__` smoke | — |
| **P1** | dev | `transport/` (health HTTP + WS JSON-RPC), `kit_call`, mock transport | P0 |
| **P2** | dev | `health`, `rpc` commands | P1 |
| **P3** | dev | `MapStore`, `map`, `diff map`, `tap`, `type` | P1, P2 |
| **P4** | dev | `screenshot`, `launch`, `foreground`, `dump` | P1 |
| **P5** | dev | `runtime.ensure_runtime` | P1, devicekit status/start stubs |
| **P6** | dev | `devicekit/` + `scripts/devicekit/*` | P0 (macOS only) |
| **P7** | dev | Wire `ensure_runtime` into P3–P4 verbs | P5, P6 |
| **P8** | dev (Swift) | Mirror P0–P4 in `swift/` | Python contract fixtures |
| **P9** | test | pytest + `swift test`, `contract/` golden JSON | P2+ |
| **P10** | devops | `.github/workflows/ci-xq-ios-act-cli.yml` | P9 scripts |

**Prototype handling:** Delete `prototypes/` before P0. Do not merge prototype tree into product paths.

---

## 2. Repository layout (final)

```text
modules/xq-ios-act-cli/
  README.md
  scripts/
    run-python.sh              # cd python && uv sync && pytest + static
    run-swift.sh               # macOS: swift test; else exit 0 with skip message
    run-all.sh                 # both
    devicekit/
      fetch-release.sh         # stdout: path to downloaded artifact
      resign-ipa.sh            # argv: ipa profile udid [identity] → stdout: signed ipa path
      install-sim.sh           # argv: zip_or_app udid
      install-device.sh        # argv: ipa udid
      start-sim.sh             # argv: udid [port] → writes device.json fields
      start-device.sh          # argv: udid [port]
  contract/                    # golden envelopes (optional P9, recommended)
    action.ok.json             # {"ok":true}
    map.ok.json
    diff-map.ok.json
    error.transport.json
  tsr/                         # test evidence (gitignored or committed per module policy)
  python/
    pyproject.toml
    uv.lock
    src/xq_ios_act/
      __init__.py
      __main__.py              # entry: fire.Fire(...)
      cli/
        root.py                # XqIosAct, Diff, DeviceKit Fire classes
      config.py                # Config, paths, env overrides
      envelope.py              # success/failure JSON + pretty formatters
      exit_codes.py
      runtime.py               # ensure_runtime()
      kit_call.py              # kit_call + kit_action
      map_store.py             # MapStore: load/save/invalidate/resolve
      map_refs.py              # assign @e1..@eN from device.dump.ui tree
      diff_map.py              # line diff for diff map
      transport/
        __init__.py
        protocol.py            # DeviceKitTransport Protocol
        http_health.py
        ws_jsonrpc.py
        mock.py
      commands/
        health.py
        rpc.py
        map_cmd.py
        tap.py
        type_cmd.py
        screenshot.py
        launch.py
        foreground.py
        dump.py
      devicekit/
        __init__.py
        install.py
        start.py
        status.py
        constants.py           # pinned version, checksums, bundle id suffix
    tests/
      test_envelope.py
      test_exit_codes.py
      test_map_store.py
      test_map_refs.py
      test_diff_map.py
      test_transport_mock.py
      test_ws_jsonrpc_codec.py
      test_commands_health.py
      test_commands_rpc.py
      test_kit_call.py
      conftest.py              # mock transport fixtures
  swift/
    Package.swift
    Sources/
      XqIosAct/
        Config.swift
        Envelope.swift
        ExitCodes.swift
        MapStore.swift
        MapRefs.swift
        DiffMap.swift
        KitCall.swift
        Runtime.swift
        Transport/
          DeviceKitTransport.swift
          HTTPHealth.swift
          WSJSONRPC.swift
          MockTransport.swift
        Commands/              # thin; called from executable
          ...
      xq-ios-act/
        XqIosActCLI.swift      # @main ArgumentParser root
        Commands/
          HealthCommand.swift
          RpcCommand.swift
          MapCommand.swift
          ...
    Tests/XqIosActTests/
      EnvelopeTests.swift
      MapStoreTests.swift
      ...
```

---

## 3. Python package metadata (`pyproject.toml`)

```toml
[project]
name = "xq-ios-act"
version = "0.1.0"
requires-python = ">=3.14"
dependencies = [
  "fire>=0.7",
  "httpx>=0.28",
  "websockets>=14.0",
]

[project.optional-dependencies]
dev = ["pytest>=8.0", "pytest-asyncio>=0.24"]

[project.scripts]
xq-ios-act = "xq_ios_act.__main__:main"

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

Lock with `uv lock` on implementation branch.

---

## 4. Configuration

### 4.1 `Config` dataclass

```python
@dataclass(frozen=True)
class Config:
    base_url: str = "http://127.0.0.1:12004"
    timeout_sec: float = 30.0
    pretty: bool = False
    ensure_runtime: bool = True
    state_dir: Path = field(default_factory=default_state_dir)
    device_id: str | None = None  # UDID for devicekit start/status
```

**Resolution order:** CLI kwargs → env → defaults.

| Env var | Maps to |
| --- | --- |
| `XQ_IOS_ACT_BASE_URL` | `base_url` |
| `XQ_IOS_ACT_TIMEOUT` | `timeout_sec` (int seconds) |
| `XQ_IOS_ACT_STATE_DIR` | `state_dir` |
| `XQ_IOS_ACT_DEVICE` | `device_id` |

### 4.2 Derived URLs

```python
def ws_url(base_url: str) -> str:
    # http://127.0.0.1:12004 → ws://127.0.0.1:12004/ws
    parsed = urlparse(base_url)
    scheme = "wss" if parsed.scheme == "https" else "ws"
    return urlunparse((scheme, parsed.netloc, "/ws", "", "", ""))

def health_url(base_url: str) -> str:
    return urljoin(base_url.rstrip("/") + "/", "health")
```

### 4.3 State files

| File | Purpose |
| --- | --- |
| `{state_dir}/last-map.json` | Last map payload + refs |
| `{state_dir}/device.json` | `deviceId`, `forwardPort`, `bundleId`, `baseUrl` |

Default `state_dir`: `Path.home() / ".xq-ios-act"`.

---

## 5. JSON envelope (normative)

### 5.0 Response tiers (locked)

| Tier | Commands | Success JSON |
| --- | --- | --- |
| **action** | `tap`, `type`, `launch`, `foreground`, `screenshot PATH`, `devicekit install`, `devicekit start` | `{"ok":true}` |
| **data** | `map`, `diff map`, `dump`, `rpc`, `health`, `devicekit status` | envelope with `command`, `result`, optional `meta` |

```python
class ResponseTier(StrEnum):
    ACTION = "action"
    DATA = "data"

COMMAND_TIER: dict[str, ResponseTier] = {
    "tap": ResponseTier.ACTION,
    "type": ResponseTier.ACTION,
    "launch": ResponseTier.ACTION,
    "foreground": ResponseTier.ACTION,
    "screenshot": ResponseTier.ACTION,
    "devicekit.install": ResponseTier.ACTION,
    "devicekit.start": ResponseTier.ACTION,
    "map": ResponseTier.DATA,
    "diff.map": ResponseTier.DATA,
    "dump": ResponseTier.DATA,
    "rpc": ResponseTier.DATA,
    "health": ResponseTier.DATA,
    "devicekit.status": ResponseTier.DATA,
}
```

### 5.1 Action tier success

```python
ACTION_OK: dict[str, bool] = {"ok": True}

def emit_action_ok(*, pretty: bool) -> None:
    if pretty:
        print("ok")
    else:
        print('{"ok":true}')
    sys.exit(0)
```

No `command`, `result`, or `meta` on success. Agents chain with `&&` and only parse stdout on `map` / `diff map`.

### 5.2 Data tier success

```python
def success_envelope(
    command: str,
    result: Any,
    *,
    base_url: str,
    method: str | None = None,
    duration_ms: int | None = None,
    extra_meta: dict[str, Any] | None = None,
) -> dict[str, Any]: ...
```

```json
{
  "ok": true,
  "command": "map",
  "result": {
    "refs": { "@e1": { "label": "Sign In", "role": "button", "center": {"x": 60, "y": 42} } },
    "summary": { "count": 42, "refRange": ["@e1", "@e42"] }
  },
  "meta": { "baseUrl": "http://127.0.0.1:12004", "method": "device.dump.ui", "durationMs": 38 }
}
```

**`map` result** is CLI-shaped (refs + summary). Optional `--include-raw` adds `raw` key (DeviceKit tree). Default off for speed/size.

**`dump` / `rpc`:** `result` = upstream DeviceKit JSON-RPC `result` verbatim.

### 5.3 Failure (all tiers)

```python
class ErrorKind(StrEnum):
    USAGE = "usage"
    TRANSPORT = "transport"
    RPC = "rpc"
    INTERNAL = "internal"
    RUNTIME = "runtime"  # ensure_runtime / devicekit lifecycle

def failure_envelope(
    command: str,
    kind: ErrorKind,
    message: str,
    hint: str,
    exit_code: int,
) -> dict[str, Any]: ...
```

### 5.4 Emit

```python
def emit(envelope: dict | None, *, pretty: bool, tier: ResponseTier) -> None:
    if tier == ResponseTier.ACTION and envelope is None:
        emit_action_ok(pretty=pretty)
        return
    ...
```

**Rule:** JSON mode: action success is exactly `{"ok":true}` (no trailing newline requirement beyond one `\n`). Data/failure use compact `json.dumps`.

---

## 6. Transport layer

### 6.1 Protocol

```python
class DeviceKitTransport(Protocol):
    async def fetch_health(self) -> HealthResult: ...
    async def call(self, method: str, params: Any | None, *, rpc_id: int = 1) -> JSONRPCResponse: ...

@dataclass
class HealthResult:
    ok: bool
    status_code: int
    duration_ms: int

@dataclass
class JSONRPCResponse:
    result: Any | None
    error: JSONRPCError | None
    id: int

@dataclass
class JSONRPCError:
    code: int
    message: str
```

### 6.2 WebSocket JSON-RPC (`ws_jsonrpc.py`)

One connection per `call()` in v1.

**Request:**

```json
{"jsonrpc": "2.0", "method": "device.dump.ui", "params": {}, "id": 1}
```

**Response handling:**

- Parse JSON frame; if `error` present → raise `RpcError` (exit 4)
- **Action calls:** use `call_action()` — verify `error` is absent; **do not parse/decode `result`**
- **Data calls:** use `call()` — return `result` verbatim
- WS connect/read timeouts → `TransportError` (exit 3)
- Malformed JSON → `InternalError` (exit 5)

```python
async def call_action(self, method: str, params: Any | None, *, rpc_id: int = 1) -> None:
    """Success = no JSON-RPC error. Discards result body for speed."""

async def call(self, method: str, params: Any | None, *, rpc_id: int = 1) -> JSONRPCResponse:
    """Full parse for data tier."""
```

### 6.3 HTTP health (`http_health.py`)

`GET {base_url}/health` — any 2xx = reachable.

### 6.4 Mock transport (`mock.py`)

For unit tests. Configurable canned responses per method. Default: connection refused for integration-style negative tests.

### 6.5 `kit_call` / `kit_action`

```python
async def kit_action(
    config: Config,
    transport: DeviceKitTransport,
    method: str,
    params: Any | None = None,
) -> None:
    await transport.call_action(method, params)  # raises on error

async def kit_call(
    config: Config,
    transport: DeviceKitTransport,
    method: str,
    params: Any | None = None,
) -> tuple[Any, int]:
    started = time.perf_counter()
    resp = await transport.call(method, params)
    if resp.error:
        raise RpcError(resp.error)
    return resp.result, int((time.perf_counter() - started) * 1000)
```

Action command handlers call `kit_action` then `emit_action_ok`. Map/dump/rpc call `kit_call`.

---

## 7. MapStore and refs

### 7.1 `last-map.json` schema

```json
{
  "version": 1,
  "createdAt": "2026-07-28T16:00:00Z",
  "baseUrl": "http://127.0.0.1:12004",
  "bundleId": "com.example.app",
  "raw": {},
  "refs": {
    "@e1": {
      "label": "Sign In",
      "role": "button",
      "frame": {"x": 10, "y": 20, "width": 100, "height": 44},
      "center": {"x": 60, "y": 42},
      "path": ["0", "2", "1"]
    }
  },
  "summary": {
    "count": 42,
    "refRange": ["@e1", "@e42"]
  }
}
```

- `raw`: unmodified `device.dump.ui` result
- `path`: stable index path into `raw` tree (implementation-defined but deterministic)
- `center`: tap target for `tap @eN`

### 7.2 Ref assignment (`map_refs.py`)

1. Walk accessibility tree from `device.dump.ui` result
2. Include nodes that are **actionable** (button, text field, link, switch, or has tap frame)
3. Depth-first order → `@e1`, `@e2`, …
4. Skip zero-size or off-screen nodes (document heuristic in code comment)

### 7.3 `MapStore` API

```python
class MapStore:
    def __init__(self, state_dir: Path): ...
    def save(self, payload: MapDocument) -> Path: ...
    def load(self) -> MapDocument: ...
    def invalidate(self) -> None: ...  # delete or mark stale; tap/type/launch call this
    def resolve_tap(self, ref: str | None, x: int | None, y: int | None) -> dict:
        # ref → {"x": int, "y": int, "deviceId": "any"}
        # x,y → same
        # else UsageError
    def resolve_type_target(self, ref: str | None) -> dict | None:
        # optional: tap field before type if ref given
```

### 7.4 `diff map`

Line-oriented diff of **pretty-printed ref summaries** (not full raw JSON):

```text
@e1 [button] "Sign In"
@e2 [text] placeholder="Email"
```

Output in `result`:

```json
{
  "added": ["@e5 [button] \"OK\""],
  "removed": ["@e3 [button] \"Cancel\""],
  "unchanged": 38
}
```

No RPC; reads `last-map.json` only. If missing → `usage` error with hint `xq-ios-act map`.

---

## 8. Command → RPC mapping

| CLI command | `ensure_runtime` | DeviceKit method | Tier / notes |
| --- | --- | --- | --- |
| `health` | no | _(HTTP only)_ | **data** — `{reachable, baseUrl}` |
| `map` | yes | `device.dump.ui` | **data** — refs + summary; save MapStore |
| `diff map` | no | — | **data** — local diff |
| `tap` | yes | `device.io.tap` | **action** → `{"ok":true}` |
| `type` | yes | `device.io.text` (+ optional pre-tap) | **action** |
| `screenshot` | yes | `device.screenshot` | **action**; **positional PATH** |
| `launch` | yes | `device.apps.launch` | **action** |
| `foreground` | yes | `device.apps.foreground` | **data** — bundle info |
| `dump` | yes | `device.dump.ui` | **data** — raw upstream `result` |
| `rpc` | yes (default) | user `--method` | **data** — raw `result`; `--params` JSON |
| `devicekit install` | no | — | **action** |
| `devicekit start` | no | — | **action** |
| `devicekit status` | no | — | **data** |

### 8.1 CLI invocation — positional-first (locked)

No `--` required on the agent hot path. Match Vibium brevity.

```bash
xq-ios-act map
xq-ios-act tap @e3
xq-ios-act tap 120 44
xq-ios-act type @e2 hello
xq-ios-act screenshot /tmp/s.png
xq-ios-act launch com.example.app
xq-ios-act diff map
```

Optional long flags for scripts: `--x`, `--y`, `--ref`, `--path`, `--bundle-id`, `--method`.

**Globals via env** (keeps argv short): `XQ_IOS_ACT_BASE_URL`, `XQ_IOS_ACT_TIMEOUT`. Constructor flags `--base-url` / `--timeout` override when set.

### 8.2 Fire CLI wiring (`cli/root.py`)

```python
class XqIosAct:
    def __init__(self, base_url=..., timeout=30, pretty=False, ensure_runtime=True): ...
    def health(self): ...
    def map(self, out=None): ...
    def tap(self, *args): ...       # @e3 | x y ints — parse positionals
    def type(self, *args): ...      # [@eN] TEXT
    def screenshot(self, path): ... # positional path
    def launch(self, bundle_id): ...
    def foreground(self): ...
    def dump(self): ...
    def rpc(self, method, params=None): ...  # method positional; params JSON string optional 2nd

class Diff:
    def __init__(self, parent: XqIosAct): ...
    def map(self): ...

class DeviceKit:
    def __init__(self, parent: XqIosAct): ...
    def install(self, sim=False, device=None, provisioning_profile=None, ...): ...
    def start(self, sim=False, device=None): ...
    def status(self, device=None): ...
```

**Fire positionals:** thin `argv` preprocessor before Fire for `tap @e3`, `type @e2 text`, `screenshot /path` (Fire mishandles `@refs`). Long `--flags` remain optional.

---

## 9. `ensure_runtime` (`runtime.py`)

```python
async def ensure_runtime(config: Config, transport: DeviceKitTransport) -> None:
    if not config.ensure_runtime:
        return
    try:
        h = await transport.fetch_health()
        if h.ok:
            return
    except TransportError:
        pass

    status = devicekit_status(config)  # sync subprocess or inline
    if not status.installed:
        raise RuntimeError(
            hint="xq-ios-act devicekit install --sim",
            message="DeviceKit runner not installed",
        )

    devicekit_start(config)  # sync

    h = await transport.fetch_health()
    if not h.ok:
        raise RuntimeError(
            hint="xq-ios-act devicekit start --sim && xq-ios-act health",
            message="DeviceKit server not reachable after start",
        )
```

Called from command handlers, not from `health` / `devicekit *` / `diff map`.

---

## 10. DeviceKit lifecycle (WP1c)

### 10.1 Constants (`devicekit/constants.py`)

Mirror MobileCLI pins (update deliberately):

```python
AGENT_VERSION_IOS = "0.0.20"
IOS_RUNNER_BUNDLE_SUFFIX = "devicekit-iosUITests.xctrunner"
CHECKSUMS = {
    "devicekit-ios-Sim-arm64.zip": "8040f491...",
    "devicekit-ios-Sim-x86_64.zip": "78a8f2d2...",
    "devicekit-ios-runner.ipa": "f5fe88d4...",
}
```

### 10.2 Script contracts

All scripts: exit 0 on success; non-zero + stderr message on failure. Python captures stderr for `hint`.

**`fetch-release.sh`**

```bash
fetch-release.sh --version 0.0.20 --artifact devicekit-ios-Sim-arm64.zip --out /tmp/xq-dk.zip
# verifies sha256; prints absolute path to stdout
```

**`resign-ipa.sh`**

```bash
resign-ipa.sh INPUT.ipa PROFILE.mobileprovision UDID [SIGNING_IDENTITY]
# prints path to signed ipa on stdout
```

**`install-sim.sh`**

```bash
install-sim.sh ARTIFACT.zip|ARTIFACT.app UDID
```

**`start-sim.sh`**

```bash
start-sim.sh UDID [PORT=12004]
# launches runner; polls health; updates $STATE_DIR/device.json
```

Real-device scripts (`install-device.sh`, `start-device.sh`): implement after sim path green; document tunnel prerequisite in stderr on failure.

### 10.3 `devicekit status` result shape

```python
@dataclass
class DeviceKitStatus:
    installed: bool
    bundle_id: str | None
    version: str | None
    server_reachable: bool
    base_url: str
```

Detection: `xcrun simctl listapps UDID` / suffix match on bundle id; health check for `server_reachable`.

---

## 11. Swift parity (WP1b)

Mirror Python seams. **Contract tests:** decode golden JSON from `contract/` in both languages.

```swift
// Package.swift targets
.target(name: "XqIosAct", ...),
.executableTarget(name: "xq-ios-act", dependencies: ["XqIosAct", .product(name: "ArgumentParser", ...)]),
.testTarget(name: "XqIosActTests", dependencies: ["XqIosAct"]),
```

`devicekit` scripts: Swift executable shells out to same `scripts/devicekit/*.sh` on macOS.

---

## 12. Testing spec

### 12.1 Unit (no DeviceKit)

| Test file | Covers |
| --- | --- |
| `test_envelope.py` | action `{"ok":true}`, data envelope, pretty format, exit mapping |
| `test_map_refs.py` | ref assignment on fixture tree |
| `test_map_store.py` | save/load/invalidate/resolve_tap |
| `test_diff_map.py` | added/removed lines |
| `test_ws_jsonrpc_codec.py` | request/response parse |
| `test_transport_mock.py` | kit_call success + rpc error |
| `test_commands_health.py` | mock 200 / connection refused |
| `test_commands_rpc.py` | params validation exit 2 |

### 12.2 Static

- `xq-ios-act --help` contains `Examples:` section per command group
- `uv run python -m xq_ios_act health` exits 3 without server (optional smoke)

### 12.3 Live (opt-in)

```bash
XQ_IOS_ACT_LIVE=1 pytest tests/integration/  # macOS only, booted sim
```

Not required for CI v1.

### 12.4 TSR

`scripts/run-python.sh` writes JUnit to `tsr/junit.xml`. `run-all.sh` merges Swift xunit when on macOS.

---

## 13. CI workflow (devops)

**Path:** `.github/workflows/ci-xq-ios-act-cli.yml`

```yaml
on:
  push:
    paths: ['modules/xq-ios-act-cli/**']
  pull_request:
    paths: ['modules/xq-ios-act-cli/**']

jobs:
  python-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: bash modules/xq-ios-act-cli/scripts/run-python.sh

  swift-macos:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: bash modules/xq-ios-act-cli/scripts/run-swift.sh
```

---

## 14. Error hints catalog (implement these strings)

| Condition | `kind` | `hint` |
| --- | --- | --- |
| Connection refused | `transport` | `xq-ios-act devicekit start --sim && xq-ios-act health` |
| Runner not installed | `runtime` | `xq-ios-act devicekit install --sim` |
| Missing `--method` | `usage` | `xq-ios-act rpc --method device.dump.ui` |
| Invalid `--params` JSON | `usage` | `xq-ios-act rpc --method device.io.tap --params '{"x":0,"y":0}'` |
| Unknown ref `@e99` | `usage` | `xq-ios-act map` |
| No last map | `usage` | `xq-ios-act map` |
| Missing profile (device install) | `usage` | `xq-ios-act devicekit install --device UDID --provisioning-profile PATH` |
| Missing screenshot path | `usage` | `xq-ios-act screenshot /tmp/screen.png` |
| DeviceKit RPC error | `rpc` | include upstream `message` in `error.message` |

---

## 15. Agent chaining (action tier)

```bash
xq-ios-act map                    # data — parse refs from .result
xq-ios-act tap @e3
xq-ios-act type @e2 hi
xq-ios-act diff map             # data
```

Action success never includes `command`, `result`, or `meta`. Failures always use full error envelope.

---

## 16. Dev wave handoff checklist

Before opening delivery PR:

- [ ] `bash scripts/run-python.sh` green on Linux
- [ ] `bash scripts/run-swift.sh` green on macOS (or skip message on Linux)
- [ ] All v1 commands in §8 implemented (Python)
- [ ] `devicekit install --sim` + `start` + `status` on booted sim (manual or live test)
- [ ] `ensure_runtime` wired; `map` works after cold start on sim
- [ ] README: prerequisites, zero→loop, real-device notes
- [ ] Golden `contract/` fixtures match Python output (Swift optional P8)

---

## 17. Links

- Design: [`DESIGN.md`](DESIGN.md)
- Plan: [`PLAN.md`](PLAN.md)
- Vibium benchmark: [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
- DeviceKit API: https://github.com/mobile-next/devicekit-ios/blob/main/README.md
