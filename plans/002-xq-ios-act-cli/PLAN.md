# Plan: xq-ios-act-cli — agent-native iOS device CLI

- **ID**: `002-xq-ios-act-cli`
- **Hub issue**: _(not opened — plan not approved yet)_
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: drafting — **WP0.5 prototypes next**

## Goal

Ship `modules/xq-ios-act-cli/` in `xq-versastack`: **dual clients** (Python primary + optional Swift) for a **stateful, agent-native CLI** that controls iOS simulators/devices through **DeviceKit** over **WebSocket JSON-RPC**, with the same Vibium-shaped contract and Python transport layer for a future **Android** backend.

## Non-goals

- Vendoring [devicekit-ios](https://github.com/mobile-next/devicekit-ios) into this repo
- MobileCLI as the runtime API (optional ops helper only, documented later)
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

## Acceptance criteria

_(Draft — finalize after open questions below.)_

- [ ] `modules/xq-ios-act-cli/` with `python/` (pyproject, uv.lock) and `swift/` (Package.swift), tests, README
- [ ] README: both clients; prerequisites; `uv tool install` (Python) and `swift build` (Swift)
- [ ] Agent-native CLI contract: **JSON by default**, `--pretty`, same verbs/exit codes in **both** clients
- [ ] Python: `[project.scripts]` + `uv tool install xq-ios-act`
- [ ] Swift: `xq-ios-act` executable via SPM; `swift test` on macOS
- [ ] Vibium-shaped command tree in both clients
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
6. **Runtime** — DeviceKit @ `http://127.0.0.1:12004` (not vendored)
7. **Transport** — WebSocket RPC; HTTP `/health` only
8. **Verification** — `scripts/run-python.sh`, `scripts/run-swift.sh`, `scripts/run-all.sh`
9. **CI** — Linux + macOS jobs, path-scoped workflow

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

### WP0 — contract / design (**now**)

- **Role**: `engineer-in-design` + product-lead + user approval
- **Design artifact**: [`DESIGN.md`](DESIGN.md) — CLI surface, tech stack, architecture, seams
- **Done when**: open questions resolved; acceptance criteria locked; plan status → `ready`

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

### WP2 — agent skill (likely follow-on)

- **Role**: dev
- **Done when**: `skills/xq-ios-act/SKILL.md` if in scope for v1

### WP3 — live integration gate (optional follow-on)

- **Role**: test + devops
- **Done when**: `workflow_dispatch` job against booted sim + DeviceKit on macOS

## Open questions — **need your decisions**

| # | Question | Options | Recommendation |
| --- | --- | --- | --- |
| 1 | **v1 interaction model** | A) subcommands only B) REPL/session mode C) both | **A** for v1; session in v2 _(locked in DESIGN)_ |
| 2 | **v1 command surface** | Minimal vs Vibium-shaped flat verbs | **Vibium-shaped** — `map`, `@ref`, `tap`, `diff map`, `rpc` escape hatch _(locked in DESIGN)_ |
| 3 | **DeviceKit lifecycle** | A) document-only B) thin sim launcher helper | **A** for v1 _(locked in DESIGN)_ |
| 4 | **Real-device setup** | A) document port-forward/tunnel B) optional MobileCLI `agent install` docs C) own scripts | **A + B** documented; no hard dep on MobileCLI |
| 5 | **Agent skill in v1?** | Ship with module vs follow-on | **Follow-on** (match scout-kit maturity path) |
| 6 | **Live CI gate** | Default CI unit-only vs optional `workflow_dispatch` live DeviceKit | **Unit-only default**; live gate optional WP3 on macOS |
| 7 | **Screenshot in v1** | Convenience `screenshot` vs `rpc` only | **Convenience wrapper** — default JSON base64 in `result` + optional `-o PATH`; `--pretty` shows summary |
| 8 | **Clients** | Python only vs Python + Swift | **Both** — Python primary, Swift optional _(locked)_ |
| 9 | **Python distribution** | `uv tool` vs binary bundle | **`uv tool install`** _(locked)_ |
| 10 | **Swift in v1?** | WP1 vs WP1b | **WP1b** — same contract; parallel if capacity |

## Notes / decisions

- **Clients (locked):** Python 3.14 (primary, Fire, uv tool) + Swift 5.9+ (optional, ArgumentParser, swift build)
- **Shared:** CLI contract only — no shared source; same `~/.xq-ios-act/` state
- **Distribution:** Python `uv tool install`; Swift `swift build -c release`
- **Agent UX (locked):** Vibium-shaped flat verbs — see [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
- **Android path:** Python `xq_ios_act` transport only (follow-on)
- **Premature work:** versastack PR #8 Swift scaffold → rebase into `swift/` subdirectory

## Sequencing

```text
NOW:     WP0.5 — throwaway prototypes (python + swift) under prototypes/
NEXT:    learnings → user sign-off → plan status ready
THEN:    discard prototypes/ → WP1 (python/) + WP1b (swift/) clean implementation
SNAP:    product-lead/root — run snap commands
REVIEW:  engineer-in-review → one PR (user-approved remote_writes)
```

## Links

- **Design**: [`DESIGN.md`](DESIGN.md)
- **Benchmark**: [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
- Research: `checkouts/xq-versastack/docs/research/xq-ios-act-cli.md`
- DeviceKit iOS: https://github.com/mobile-next/devicekit-ios
- DeviceKit Android: https://github.com/mobile-next/devicekit-android
- Domain: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
