# Plan: xq-ios-act-cli — agent-native iOS device CLI

- **ID**: `002-xq-ios-act-cli`
- **Hub issue**: _(not opened — plan not approved yet)_
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: **ready** — design locked; WP0.5 prototype sign-off → WP1 implementation

## Goal

Ship `modules/xq-ios-act-cli/` in `xq-versastack`: **dual clients** (Python primary + optional Swift) for a **stateful, agent-native CLI** that controls iOS simulators/devices through **DeviceKit** over **WebSocket JSON-RPC**, with the same Vibium-shaped contract and Python transport layer for a future **Android** backend.

## Non-goals

- Vendoring [devicekit-ios](https://github.com/mobile-next/devicekit-ios) into this repo
- MobileCLI as a runtime dependency (we own **devicekit lifecycle**; borrow patterns only)
- Cloud device farms in v1 (Perfecto, BrowserStack, Mobile Next Fleet → v2)
- MJPEG/H264 streaming helpers in v1 (RPC-thin first)
- Changes to `xq-harness` or hub org glossaries
- Android backend in v1 (Python transport follow-on)
- Requiring both clients on PATH at once (pick Python **or** Swift)
- Implementation before this plan is approved by user/product-lead

## Before / After

| Aspect | Before | After |
| --- | --- | --- |
| Behavior | Research only (`docs/research/xq-ios-act-cli.md`) | Shipped module with documented CLI, tests, CI |
| Surfaces | No CLI | `xq-ios-act` via **Python** (`uv tool`) or **Swift** (`swift build`) — same verbs |
| Evidence | None | Module `tsr/` + CI workflow scoped to the module |

## Test approach

- **Layers**: unit (JSON-RPC codec, URL helpers, mock transport), static (help/README contract), integration optional behind env flag when DeviceKit is reachable
- **Seams**: `DeviceKitTransport` protocol + mock in unit tests; default `run-all` must not require live sim/DeviceKit
- **Fixtures**: canned request/response pairs; optional recorded DeviceKit responses when live gate exists
- **Environments**: local dev on macOS (live DeviceKit); CI default on Linux (unit/static only)
- **Out of scope for v1 CI**: real-device tunnel automation, broadcast/MJPEG/H264 streams

## Test coverage

- [ ] Happy path: CLI parses flags, encodes JSON-RPC, decodes success result
- [ ] Failure / negative: connection refused, JSON-RPC error, missing required flags
- [ ] Edge / boundary: empty params, large base64 screenshot payload
- [ ] Regression: WS is default transport for RPC loops (not one-shot HTTP per command)
- [ ] Evidence: `tsr/summary.md` + `tsr/junit.xml` (pytest junit output)

## Target repos

| Order | Repo | Branch (proposed) | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | `xq-versastack` | `xq/xq-ios-act-cli-f8f1` | design → dev+test+devops | Checkout: `checkouts/xq-versastack` |

## Acceptance criteria (locked)

- [ ] `modules/xq-ios-act-cli/` with `python/` (pyproject, uv.lock) and `swift/` (Package.swift), tests, README
- [ ] README: both clients; prerequisites; `uv tool install` (Python) and `swift build` (Swift)
- [ ] Vibium-shaped verbs: `map`, `tap @eN`, `diff map`, `rpc`; `MapStore` + `ensure_runtime()`
- [ ] Python: `[project.scripts]` + `uv tool install xq-ios-act`
- [ ] Swift: `xq-ios-act` executable via SPM; `swift test` on macOS
- [ ] **DeviceKit lifecycle** — `devicekit install`, `devicekit start`, `devicekit status`; `ensure_runtime()` on RPC verbs; not MobileCLI
- [ ] Default verification passes **without** live DeviceKit
- [ ] CI: Linux (Python) + macOS (Swift tests)
- [ ] Root `README.md`, `modules/README.md`, `CONSUMER_CONTEXT.md` updated when module ships
- [ ] Research doc status updated when module ships

## Work Contract — xq-versastack

**Branch:** `xq/xq-ios-act-cli-f8f1` _(proposed; no wave until plan approved)_  
**Goal:** Land MVP `xq-ios-act-cli` per approved scope below.

### Interfaces / seams _(draft)_

1. **CLI contract** — same verbs, flags, JSON envelope, exit codes (Python Fire + Swift ArgumentParser)
2. **Python** — `python/src/xq_ios_act/`; `uv tool install`
3. **Swift (optional)** — `swift/Sources/`; `swift build`
4. **Packaging** — uv + pyproject (Python); SPM (Swift)
5. **Distribution** — Python: `uv tool install`; Swift: `swift build -c release`
6. **DeviceKit lifecycle** — `devicekit install` + `start` + `status` (MobileCLI patterns); `ensure_runtime()` for Vibium-like auto-start; no MobileCLI binary
7. **Runtime** — DeviceKit @ `http://127.0.0.1:12004`; WS `/ws` for all RPC
8. **Transport** — WebSocket RPC; HTTP `/health` only
9. **Verification** — `scripts/run-python.sh`, `scripts/run-swift.sh`, `scripts/run-all.sh`
10. **CI** — Linux + macOS jobs, path-scoped workflow

### File ownership _(for parallel wave)_

| Role | Owns | Must not touch |
| --- | --- | --- |
| design | Contract/seams, command surface decision | Product implementation |
| dev (python) | `python/src/**`, `python/pyproject.toml`, `python/uv.lock` | `swift/**` |
| dev (swift) | `swift/Sources/**`, `swift/Package.swift` | `python/**` |
| test | `python/tests/**`, `swift/Tests/**`, `scripts/**`, `tsr/` | `.github/**` |
| devops | `.github/workflows/ci-xq-ios-act-cli.yml` | CLI logic |

### Acceptance _(draft)_

- [ ] Documented snap commands pass without live DeviceKit (Linux or macOS)
- [ ] Approved v1 command surface works against live DeviceKit (manual or opt-in CI)
- [ ] CI green on module PR

### Snap commands _(draft)_

```bash
cd checkouts/xq-versastack/modules/xq-ios-act-cli
bash scripts/run-python.sh
bash scripts/run-swift.sh          # macOS
# Python install path:
cd python && uv sync --all-extras && uv run xq-ios-act health
# Swift install path:
cd swift && swift build && .build/debug/xq-ios-act health
```

## Work packages

### WP0.5 — throwaway prototypes (**next — before WP1**)

Quick spikes to validate **both stacks** against the locked contract. Code lives under `prototypes/` and is **deleted or replaced** before WP1 — not merged as product.

| Goal | Validate |
| --- | --- |
| Python | Fire globals, JSON-default + `--pretty`, `health` + `rpc`, mock/offline test |
| Swift | ArgumentParser, same output envelope, `health` + `rpc`, `swift test` offline |
| Contract | Same exit codes and JSON envelope shape on both |

**Location:** `modules/xq-ios-act-cli/prototypes/python/` and `prototypes/swift/`

**Done when:**

- [ ] `uv run` / `swift run` — `health` and `rpc` work with mock or fail gracefully without DeviceKit
- [ ] JSON default + `--pretty` demonstrated on both
- [ ] Short `prototypes/LEARNINGS.md` — what worked, what to change for WP1
- [ ] User/product-lead sign-off → plan `ready` → **discard `prototypes/`** and start WP1 clean layout (`python/`, `swift/`)

**Explicitly out of scope for prototypes:** full verb tree, MapStore, CI, `uv tool install`, live DeviceKit gate.

### WP0 — contract / design (**complete**)

- **Role**: `engineer-in-design` + product-lead + user approval
- **Design artifact**: [`DESIGN.md`](DESIGN.md) — hybrid Vibium UX + MobileCLI DeviceKit lifecycle
- **Dev spec**: [`DEV-SPEC.md`](DEV-SPEC.md) — implementation phases, file tree, APIs, tests
- **Done when**: ~~open questions resolved~~ ✓ — plan status → `ready`

### WP1 — Python (after approval)

| Role | Package | Ownership |
| --- | --- | --- |
| dev | Fire CLI + JSON-RPC client | `python/src/**`, `python/pyproject.toml` |
| test | pytest + static verify | `python/tests/**` |
| devops | Linux CI job | workflow |

### WP1b — Swift optional (parallel or immediately after Python)

| Role | Package | Ownership |
| --- | --- | --- |
| dev | ArgumentParser CLI + client | `swift/Sources/**`, `swift/Package.swift` |
| test | `swift test` + contract parity checks | `swift/Tests/**` |
| devops | macOS CI job | workflow |

### WP1c — DeviceKit lifecycle (with WP1, macOS)

Hybrid: MobileCLI install/start patterns + Vibium `ensure_runtime`.

| Role | Package | Ownership |
| --- | --- | --- |
| dev | `devicekit install` / `start` / `status` + `ensure_runtime()` | `python/src/.../devicekit/`, `runtime.py`, `scripts/devicekit/` |
| test | mock/signing smoke; opt-in sim live test | `tests/` |
| docs | provisioning, tunnel, zero→loop in README | module README |

**Done when:**

- [ ] `devicekit install --sim` end-to-end on booted simulator
- [ ] `devicekit start` launches runner; `health` returns ok
- [ ] `map` auto-calls `ensure_runtime()` when server down (sim)
- [ ] Real device: install + start documented with profile + forward

### WP2 — agent skill (likely follow-on)

- **Role**: dev
- **Done when**: `skills/xq-ios-act/SKILL.md` if in scope for v1

### WP3 — live integration gate (optional follow-on)

- **Role**: test + devops
- **Done when**: `workflow_dispatch` job against booted sim + DeviceKit on macOS

## Decisions (locked)

| # | Topic | Decision |
| --- | --- | --- |
| 1 | Interaction model | Subcommands only v1; session v2 |
| 2 | Command surface | Vibium flat verbs + `map`/`@ref`/`diff map` |
| 3 | Architecture | Vibium agent UX + MobileCLI DeviceKit lifecycle; WS `/ws` RPC |
| 4 | DeviceKit lifecycle | `devicekit install` + `start` + `status`; `ensure_runtime()` |
| 5 | Real device | Own re-sign + tunnel/forward docs; wildcard profile recommended |
| 6 | Clients | Python primary + Swift optional (WP1b) |
| 7 | Distribution | `uv tool install` / `swift build` |
| 8 | Output | JSON default; `--pretty`; exit codes 0/2/3/4/5 |
| 9 | Screenshot | positional PATH; action-tier `{"ok":true}` |
| 10 | CLI argv | **Positional-first** — no `--` on hot path; env for globals |
| 11 | Response contract | Action → `{"ok":true}`; Data → map/diff/dump/rpc/health |
| 10 | Skill | WP2 follow-on |
| 11 | CI | Linux unit default; optional macOS live gate WP3 |
| 12 | Cloud (Perfecto, etc.) | **v2** — fleet proxy or Appium adapter |

## Notes / decisions

- **Hybrid (locked):** Vibium-shaped CLI on DeviceKit WS; MobileCLI patterns for install/start without MobileCLI binary
- **Clients (locked):** Python 3.14 (primary, Fire, uv tool) + Swift 5.9+ (optional, ArgumentParser, swift build)
- **Shared:** CLI contract only — no shared source; same `~/.xq-ios-act/` state
- **Distribution:** Python `uv tool install`; Swift `swift build -c release`
- **Agent UX:** see [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md) + [`DESIGN.md`](DESIGN.md) § Design wrap-up
- **Android path:** Python `xq_ios_act` transport only (follow-on)
- **Premature work:** versastack PR #8 Swift scaffold → rebase into `swift/` subdirectory

## Sequencing

```text
DONE:    WP0 — design locked (Vibium UX + MobileCLI lifecycle + WS DeviceKit)
NOW:     WP0.5 — prototype sign-off → discard prototypes/
NEXT:    WP1 (python/) + WP1b (swift/) + WP1c (devicekit lifecycle)
THEN:    WP2 skill; optional WP3 live CI gate
SNAP:    product-lead/root — run snap commands
REVIEW:  engineer-in-review → one PR (user-approved remote_writes)
```

## Links

- **Design**: [`DESIGN.md`](DESIGN.md)
- **Dev spec**: [`DEV-SPEC.md`](DEV-SPEC.md)
- **Benchmark**: [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
- Research: `checkouts/xq-versastack/docs/research/xq-ios-act-cli.md`
- DeviceKit iOS: https://github.com/mobile-next/devicekit-ios
- DeviceKit Android: https://github.com/mobile-next/devicekit-android
- Domain: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
