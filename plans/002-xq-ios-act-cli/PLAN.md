# Plan: xq-ios-act-cli — agent-native iOS device CLI

- **ID**: `002-xq-ios-act-cli`
- **Hub issue**: _(open when plan is approved)_
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: in_progress

## Goal

Ship `modules/xq-ios-act-cli/` in `xq-versastack`: a **stateful, agent-native Swift CLI** that controls and inspects iOS simulators and devices through **Mobile Next DeviceKit** over a long-lived **WebSocket JSON-RPC** connection. Agents get stable verbs, `--json` output, predictable exit codes, and copy-pasteable verification — without MobileCLI as the control plane.

## Non-goals

- Vendoring [devicekit-ios](https://github.com/mobile-next/devicekit-ios) into this repo
- MobileCLI as the runtime API (optional ops helper only, documented later)
- MJPEG/H264 streaming helpers in v1 (RPC-thin first)
- REPL mode in v1 (subcommands + one-shot `rpc` only)
- Real-device E2E in default CI (sim/DeviceKit live tests are opt-in / manual)
- Changes to `xq-harness` or hub org glossaries

## Before / After

| Aspect | Before | After |
| --- | --- | --- |
| Behavior | Research doc only (`docs/research/xq-ios-act-cli.md`) | Shipped module with working CLI, tests, CI, README |
| Surfaces | No CLI | `xq-ios-act` binary: `health`, `rpc`, `device info`, `device screenshot` (RPC-backed) |
| Evidence | None | Module `tsr/` from `swift test` + static shell checks; macOS CI workflow |

## Test approach

- **Layers**: unit (JSON-RPC encode/decode, URL helpers), static (README/help contract), integration optional behind env flag when DeviceKit is reachable
- **Seams**: mock JSON-RPC responses in unit tests; no live simulator required for default `run-all.sh`
- **Fixtures**: canned JSON-RPC request/response pairs under `Tests/`
- **Environments**: local `swift test` on macOS; CI on `macos-14` runner
- **Out of scope**: full XCUITest harness, broadcast extension, real-device tunnel automation in CI

## Test coverage

- [ ] Happy path: parse CLI flags, build JSON-RPC request, decode success result
- [ ] Failure / negative: connection refused, JSON-RPC error object, missing required flags
- [ ] Edge / boundary: empty params, base64 screenshot payload handling
- [ ] Regression: research contract preserved (WS transport, not HTTP-per-command default)
- [ ] Evidence artifact: `tsr/summary.md` + `tsr/junit.xml` from module test runner

## Target repos

| Order | Repo | Branch | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | `xq-versastack` | `xq/xq-ios-act-cli-f8f1` | dev+test+devops | Checkout: `checkouts/xq-versastack` |

## Acceptance criteria

- [ ] `modules/xq-ios-act-cli/` exists with `Package.swift`, CLI sources, tests, README
- [ ] README documents prerequisites (Swift 5.9+, Xcode 15+, DeviceKit runtime), install, usage, and exact verification commands
- [ ] Agent-native CLI: `--help` with examples, `--json`, non-interactive flags, actionable errors
- [ ] Default verification passes without a live DeviceKit server (`swift test` + static checks)
- [ ] `.github/workflows/ci-xq-ios-act-cli.yml` runs documented checks on path-filtered PRs (macOS)
- [ ] Root `README.md`, `modules/README.md`, `CONSUMER_CONTEXT.md` list the shipped module
- [ ] Research doc updated to point at the shipped module (status: shipped)

## Work Contract — xq-versastack

**Branch:** `xq/xq-ios-act-cli-f8f1`  
**Goal:** Land MVP `xq-ios-act-cli` module: Swift WS JSON-RPC client + agent-native CLI + deterministic tests + macOS CI.

### Interfaces / seams

1. **CLI binary** — `xq-ios-act` (built from module `Package.swift`)
   - `health --base-url <url>` — HTTP `/health`
   - `rpc --base-url <url> --method <name> [--params <json>] [--json]` — one-shot WS JSON-RPC
   - `device info|screenshot` — convenience wrappers over RPC methods
   - Global: `--json`, `--timeout <seconds>`

2. **Runtime dependency** — DeviceKit on device/sim at documented default `http://127.0.0.1:12004` (not vendored)

3. **Verification** — from `modules/xq-ios-act-cli/`:
   - `bash tests/run-static.sh`
   - `bash tests/run-all.sh` → `swift test` + TSR generation

4. **CI** — `.github/workflows/ci-xq-ios-act-cli.yml`, paths: `modules/xq-ios-act-cli/**`, workflow file

### File ownership

| Role | Owns (paths / globs) | Must not touch |
| --- | --- | --- |
| dev | `modules/xq-ios-act-cli/Sources/**`, `Package.swift`, module `README.md`, root consumer pointers | unrelated modules; root runner |
| test | `modules/xq-ios-act-cli/Tests/**`, `modules/xq-ios-act-cli/tests/**`, `tsr/` generation | `.github/**` unless coordinated |
| devops | `.github/workflows/ci-xq-ios-act-cli.yml` | CLI business logic |

### Acceptance

- [ ] `cd modules/xq-ios-act-cli && bash tests/run-all.sh` passes on macOS without DeviceKit
- [ ] `xq-ios-act --help` shows examples on subcommands
- [ ] CI green on module PR

### Snap commands

```bash
cd checkouts/xq-versastack/modules/xq-ios-act-cli
bash tests/run-static.sh
bash tests/run-all.sh

# Optional live check when DeviceKit is running:
swift run xq-ios-act health --base-url http://127.0.0.1:12004
swift run xq-ios-act device info --base-url http://127.0.0.1:12004 --json
```

## Work packages

### WP0 — contract (this turn)

- **Role**: design + dev bootstrap
- **Done when**: plan published; module skeleton compiles; default tests pass

### WP1 — core CLI + JSON-RPC client

- **Role**: dev
- **Done when**: `health`, `rpc`, `device info`, `device screenshot` work against live DeviceKit

### WP2 — agent skill + docs

- **Role**: dev
- **Done when**: `skills/xq-ios-act/SKILL.md` with install, safety, troubleshooting

### WP3 — live integration gate (optional follow-on)

- **Role**: test + devops
- **Done when**: workflow_dispatch job runs against booted sim + DeviceKit when secrets/runner available

## Notes / decisions

- **Transport:** WebSocket JSON-RPC for chatty automation; HTTP only for `health` and documented one-shots
- **Language:** Swift 5.9+ per DeviceKit alignment
- **Dependency:** [swift-argument-parser](https://github.com/apple/swift-argument-parser) for CLI structure
- **Research source:** [`docs/research/xq-ios-act-cli.md`](../../checkouts/xq-versastack/docs/research/xq-ios-act-cli.md)

## Links

- Research: `checkouts/xq-versastack/docs/research/xq-ios-act-cli.md`
- DeviceKit: https://github.com/mobile-next/devicekit-ios
- Prior structure plan: [`plans/001-versastack-fast-delivery/PLAN.md`](../001-versastack-fast-delivery/PLAN.md)
- Domain: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
