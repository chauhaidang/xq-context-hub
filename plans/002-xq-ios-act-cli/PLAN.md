# Plan: xq-ios-act-cli — agent-native iOS device CLI

- **ID**: `002-xq-ios-act-cli`
- **Hub issue**: _(not opened)_
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: **implemented (Swift-only)** — versastack [PR #8](https://github.com/chauhaidang/xq-versastack/pull/8); see [`IMPLEMENTATION.md`](IMPLEMENTATION.md)

## Goal

Ship `modules/xq-ios-act-cli/` in `xq-versastack`: a **Swift CLI** (`xq-ios-act`) for a **stateful, agent-native** iOS automation tool that controls simulators/devices through **DeviceKit** over **WebSocket JSON-RPC**, with a Vibium-shaped contract.

> **Note:** Original plan targeted dual Python + Swift clients. The versastack module shipped **Swift-only** after removing the Python POC. Python may return later for Android transport only.

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
| Surfaces | No CLI | `xq-ios-act` via **Swift** (`swift build`) |
| Evidence | None | Module `tsr/` + CI workflow scoped to the module |

## Test approach

- **Layers**: unit (JSON-RPC codec, URL helpers, mock transport), static (help/README contract), integration optional behind env flag when DeviceKit is reachable
- **Seams**: `DeviceKitTransport` protocol + mock in unit tests; default `run-all` must not require live sim/DeviceKit
- **Fixtures**: canned request/response pairs; optional recorded DeviceKit responses when live gate exists
- **Environments**: local dev on macOS (live DeviceKit); CI on macOS (`swift test`)
- **Out of scope for v1 CI**: broadcast/MJPEG/H264 streams

## Test coverage

- [x] Happy path: CLI parses flags, encodes JSON-RPC, decodes success result
- [x] Failure / negative: connection refused, JSON-RPC error, missing required flags
- [x] Edge / boundary: empty params, contract fixtures
- [x] Regression: WS is default transport for RPC loops (not one-shot HTTP per command)
- [x] Evidence: `swift test` (10 tests) + macOS CI

## Target repos

| Order | Repo | Branch (proposed) | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | `xq-versastack` | `xq/xq-ios-act-cli-f8f1` | design → dev+test+devops | Checkout: `checkouts/xq-versastack` |

## Acceptance criteria (locked)

- [x] `modules/xq-ios-act-cli/` with `swift/` (Package.swift), tests, README
- [x] README: prerequisites; `swift build` / `swift test`
- [x] Vibium-shaped verbs: `map`, `tap @eN`, `diff map`, `rpc`; `MapStore`
- [x] Swift: `xq-ios-act` executable via SPM; `swift test` on macOS
- [x] **Devicekit lifecycle** — `devicekit install`, `devicekit start`, `devicekit status`
- [x] Default verification passes **without** live DeviceKit
- [x] CI: macOS Swift tests
- [ ] Root `README.md`, `modules/README.md`, `CONSUMER_CONTEXT.md` updated when module merges
- [ ] Research doc status updated when module merges

## Work Contract — xq-versastack

**Branch:** `xq/xq-ios-act-cli-f8f1`  
**Goal:** Land MVP `xq-ios-act-cli` per approved scope below. **Status: implemented** — see [`IMPLEMENTATION.md`](IMPLEMENTATION.md).

### Interfaces / seams _(as built)_

1. **CLI contract** — verbs, flags, JSON envelope, exit codes (Swift ArgumentParser)
2. **Swift** — `swift/Sources/IosAct` + `IosActCommand`; `swift build`
3. **Packaging** — SPM
4. **Distribution** — `swift build -c release`
5. **DeviceKit lifecycle** — `devicekit install` + `start` + `status`; `ensure_runtime()` partial
6. **Runtime** — DeviceKit @ `http://127.0.0.1:12004`; WS `/ws` for all RPC
7. **Transport** — WebSocket RPC; HTTP `/health` only
8. **Verification** — `scripts/run-swift.sh`, `scripts/run-all.sh`
9. **CI** — macOS job, path-scoped workflow

### File ownership _(as built)_

| Role | Owns |
| --- | --- |
| dev (swift) | `swift/Sources/**`, `swift/Package.swift`, devicekit Swift helpers |
| test | `swift/Tests/**`, `scripts/**`, `contract/` |
| devops | `.github/workflows/ci-xq-ios-act-cli.yml` |

### Acceptance _(as built)_

- [x] Documented snap commands pass without live DeviceKit
- [x] CI green on module PR
- [ ] Approved v1 command surface works against live DeviceKit (manual or opt-in CI — WP3)

### Snap commands

```bash
cd checkouts/xq-versastack/modules/xq-ios-act-cli
bash scripts/run-all.sh          # swift test on macOS
cd swift && swift build && .build/debug/xq-ios-act --help
```

## Work packages

### WP0.5 — throwaway prototypes _(skipped — shipped Swift directly)_

Original plan: dual-stack prototypes under `prototypes/`. Versastack shipped Swift CLI without retaining prototypes.

### WP0 — contract / design (**complete**)

- **Role**: `engineer-in-design` + product-lead + user approval
- **Design artifact**: [`DESIGN.md`](DESIGN.md) — hybrid Vibium UX + MobileCLI DeviceKit lifecycle
- **Dev spec**: [`DEV-SPEC.md`](DEV-SPEC.md) — implementation phases, file tree, APIs, tests
- **Done when**: ~~open questions resolved~~ ✓ — plan status → `ready`

### WP1 — Python _(cancelled — not shipped)_

### WP1b — Swift CLI (**complete** — versastack PR #8)

### WP1c — DeviceKit lifecycle (**complete** — versastack PR #8)

Hybrid: MobileCLI install/start patterns + Vibium `ensure_runtime`.

**Done when:**

- [x] `devicekit install --sim` end-to-end on booted simulator
- [x] `devicekit start` launches runner; `health` returns ok
- [ ] `map` auto-calls `ensure_runtime()` when server down (sim) — partial
- [x] Real device: install + start via resign + `xcodebuild` (documented in IMPLEMENTATION.md)

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
| 5 | Real device | Swift resign + `devicectl` install; `xcodebuild` start (no tunnel/iproxy) |
| 6 | Clients | **Swift-only** in versastack (Python cancelled; Android follow-on) |
| 7 | Distribution | `swift build -c release` |
| 8 | Output | JSON default; `--pretty`; exit codes 0/2/3/4/5 |
| 9 | Screenshot | positional PATH; action-tier `{"ok":true}` |
| 10 | CLI argv | **Positional-first** — no `--` on hot path; env for globals |
| 11 | Response contract | Action → `{"ok":true}`; Data → map/diff/dump/rpc/health |
| 10 | Skill | WP2 follow-on |
| 11 | CI | macOS `swift test` default; optional live gate WP3 |
| 12 | Cloud (Perfecto, etc.) | **v2** — fleet proxy or Appium adapter |

## Notes / decisions

- **Hybrid (locked):** Vibium-shaped CLI on DeviceKit WS; MobileCLI patterns for install/start without MobileCLI binary
- **Clients (as built):** Swift 5.9+ only in versastack (`IosAct` + `xq-ios-act`); Python POC removed
- **Real device start (as built):** `xcodebuild test-without-building` on installed runner from unsigned IPA; no go-ios tunnel, no iproxy
- **Shared:** CLI contract via `contract/` fixtures; state in `~/.xq-ios-act/`
- **Distribution:** `swift build -c release`
- **Android path:** separate Python client follow-on (not in versastack module)

## Sequencing

```text
DONE:    WP0 — design locked
DONE:    WP1b + WP1c — Swift CLI + devicekit lifecycle (versastack PR #8)
NEXT:    WP2 skill; optional WP3 live CI gate; merge + consumer doc updates
```

## Links

- **Design**: [`DESIGN.md`](DESIGN.md) — contract reference; as-built deltas in IMPLEMENTATION.md
- **Implementation**: [`IMPLEMENTATION.md`](IMPLEMENTATION.md) _(as-built Swift-only)_
- **Dev spec**: [`DEV-SPEC.md`](DEV-SPEC.md) — original dual-client spec; as-built in IMPLEMENTATION.md
- **Benchmark**: [`VIBIUM-BENCHMARK.md`](VIBIUM-BENCHMARK.md)
- Research: `checkouts/xq-versastack/docs/research/xq-ios-act-cli.md`
- DeviceKit iOS: https://github.com/mobile-next/devicekit-ios
- DeviceKit Android: https://github.com/mobile-next/devicekit-android
- Domain: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
