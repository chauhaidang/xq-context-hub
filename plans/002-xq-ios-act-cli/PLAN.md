# Plan: xq-ios-act-cli — agent-native iOS device CLI

- **ID**: `002-xq-ios-act-cli`
- **Hub issue**: _(not opened — plan not approved yet)_
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: drafting

## Goal

Ship `modules/xq-ios-act-cli/` in `xq-versastack`: a **stateful, agent-native Swift CLI** that controls and inspects iOS simulators and devices through **Mobile Next DeviceKit** over **WebSocket JSON-RPC**. Agents get stable verbs, `--json` output, predictable exit codes, and copy-pasteable verification — without MobileCLI as the control plane.

## Non-goals

- Vendoring [devicekit-ios](https://github.com/mobile-next/devicekit-ios) into this repo
- MobileCLI as the runtime API (optional ops helper only, documented later)
- MJPEG/H264 streaming helpers in v1 (RPC-thin first)
- Changes to `xq-harness` or hub org glossaries
- Implementation before this plan is approved by user/product-lead

## Before / After

| Aspect | Before | After |
| --- | --- | --- |
| Behavior | Research only (`docs/research/xq-ios-act-cli.md`) | Shipped module with documented CLI, tests, CI |
| Surfaces | No CLI | `xq-ios-act` binary with agent-native subcommands (TBD — see open questions) |
| Evidence | None | Module `tsr/` + macOS CI workflow scoped to the module |

## Test approach

- **Layers**: unit (JSON-RPC codec, URL/session helpers), static (help/README contract), integration optional behind env flag when DeviceKit is reachable
- **Seams**: mock JSON-RPC in unit tests; default `run-all` must not require live sim/DeviceKit
- **Fixtures**: canned request/response pairs; optional recorded DeviceKit responses when live gate exists
- **Environments**: local snap on macOS; CI on `macos-14` (or newer) runner
- **Out of scope for v1 CI**: real-device tunnel automation, broadcast/MJPEG/H264 streams

## Test coverage

- [ ] Happy path: CLI parses flags, encodes JSON-RPC, decodes success result
- [ ] Failure / negative: connection refused, JSON-RPC error, missing required flags
- [ ] Edge / boundary: empty params, large base64 screenshot payload
- [ ] Regression: WS is default transport for RPC loops (not one-shot HTTP per command)
- [ ] Evidence: `tsr/summary.md` + `tsr/junit.xml` (or swift xunit equivalent)

## Target repos

| Order | Repo | Branch (proposed) | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | `xq-versastack` | `xq/xq-ios-act-cli-f8f1` | design → dev+test+devops | Checkout: `checkouts/xq-versastack` |

## Acceptance criteria

_(Draft — finalize after open questions below.)_

- [ ] `modules/xq-ios-act-cli/` with `Package.swift`, CLI, tests, README
- [ ] README: prerequisites (Swift 5.9+, Xcode 15+, DeviceKit runtime), install, usage, exact verification commands
- [ ] Agent-native CLI: `--help` with examples, `--json`, non-interactive flags, actionable errors
- [ ] Default verification passes **without** live DeviceKit
- [ ] `.github/workflows/ci-xq-ios-act-cli.yml` runs documented checks (macOS, path-filtered)
- [ ] Root `README.md`, `modules/README.md`, `CONSUMER_CONTEXT.md` updated when module ships
- [ ] Research doc status updated when module ships

## Work Contract — xq-versastack

**Branch:** `xq/xq-ios-act-cli-f8f1` _(proposed; no wave until plan approved)_  
**Goal:** Land MVP `xq-ios-act-cli` per approved scope below.

### Interfaces / seams _(draft)_

1. **CLI binary** — `xq-ios-act` (Swift `Package.swift`, module-local only)
2. **Runtime dependency** — DeviceKit reachable at documented default `http://127.0.0.1:12004` (not vendored)
3. **Transport** — WebSocket JSON-RPC for RPC; HTTP acceptable for `/health` only
4. **Verification** — module-owned scripts (exact names TBD; avoid `tests/` vs Swift `Tests/` collision on macOS — prefer `scripts/`)
5. **CI** — full root workflow `.github/workflows/ci-xq-ios-act-cli.yml`, path-scoped to module

### File ownership _(for parallel wave)_

| Role | Owns | Must not touch |
| --- | --- | --- |
| design | Contract/seams, command surface decision | Product implementation |
| dev | `modules/xq-ios-act-cli/Sources/**`, `Package.swift`, module `README.md`, consumer pointers | unrelated modules; root runner |
| test | `modules/xq-ios-act-cli/Tests/**`, verify scripts, `tsr/` | `.github/**` |
| devops | `.github/workflows/ci-xq-ios-act-cli.yml` | CLI logic |

### Acceptance _(draft)_

- [ ] Documented snap commands pass on macOS without DeviceKit
- [ ] Approved v1 command surface works against live DeviceKit (manual or opt-in CI)
- [ ] CI green on module PR

### Snap commands _(draft)_

```bash
cd checkouts/xq-versastack/modules/xq-ios-act-cli
# exact commands = module README (written by dev/test)
```

## Work packages

### WP0 — contract / design (**now**)

- **Role**: `engineer-in-design` (optional) + product-lead + user approval
- **Done when**: open questions resolved; acceptance criteria locked; plan status → `ready`

### WP1 — parallel wave (after approval)

| Role | Package | Ownership |
| --- | --- | --- |
| dev | CLI + JSON-RPC client + module README | `Sources/**`, `Package.swift` |
| test | unit/static verify + TSR | `Tests/**`, `scripts/**` |
| devops | macOS CI workflow | `.github/workflows/ci-xq-ios-act-cli.yml` |

### WP2 — agent skill (likely follow-on)

- **Role**: dev
- **Done when**: `skills/xq-ios-act/SKILL.md` if in scope for v1

### WP3 — live integration gate (optional follow-on)

- **Role**: test + devops
- **Done when**: `workflow_dispatch` job against booted sim + DeviceKit

## Open questions — **need your decisions**

| # | Question | Options | Recommendation |
| --- | --- | --- | --- |
| 1 | **v1 interaction model** | A) subcommands only B) REPL/session mode C) both | **A** for v1; session in WP2+ |
| 2 | **v1 command surface** | Minimal (`health`, `rpc`, `device info`) vs broader (`tap`, `type`, `dump ui`, `apps launch`, …) | **Minimal + `rpc` escape hatch**; add convenience wrappers for top 3–5 methods |
| 3 | **DeviceKit lifecycle** | A) document-only B) thin sim launcher helper | **A** for v1 |
| 4 | **Real-device setup** | A) document port-forward/tunnel B) optional MobileCLI `agent install` docs C) own scripts | **A + B** documented; no hard dep on MobileCLI |
| 5 | **Agent skill in v1?** | Ship with module vs follow-on | **Follow-on** (match scout-kit maturity path) |
| 6 | **Live CI gate** | Default CI unit-only vs optional `workflow_dispatch` live DeviceKit | **Unit-only default**; live gate optional WP3 |
| 7 | **Screenshot in v1** | Convenience `device screenshot` vs `rpc` only | **Convenience wrapper** (common agent need) |

## Notes / decisions

- Research source: `checkouts/xq-versastack/docs/research/xq-ios-act-cli.md`
- Prior versastack structure: [`plans/001-versastack-fast-delivery/PLAN.md`](../001-versastack-fast-delivery/PLAN.md) (module independence, per-module CI)
- Reference module pattern: `modules/xq-scout-kit` (verify scripts, `tsr/`, path-scoped CI)
- **Premature work:** an implementation branch/PR was opened before plan approval — treat as **discard or rebase after approval**, not as accepted scope

## Sequencing

```text
NOW:     product-lead + user — resolve open questions; lock plan
NEXT:    optional engineer-in-design — refine CLI contract / command tree
THEN:    parallel wave (dev + test + devops) on approved branch
SNAP:    product-lead/root — run snap commands
REVIEW:  engineer-in-review → one PR (user-approved remote_writes)
```

## Links

- Research: `checkouts/xq-versastack/docs/research/xq-ios-act-cli.md`
- DeviceKit: https://github.com/mobile-next/devicekit-ios
- Domain: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
