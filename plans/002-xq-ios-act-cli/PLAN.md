# Plan: xq-ios-act-cli — agent-native iOS device CLI

- **ID**: `002-xq-ios-act-cli`
- **Hub issue**: https://github.com/chauhaidang/xq-context-hub/issues/7
<<<<<<< HEAD
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastacks` only
=======
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
>>>>>>> origin/main
- **Status**: **done** (module merged) — follow-ons tracked on [issue #7](https://github.com/chauhaidang/xq-context-hub/issues/7)

## Goal

<<<<<<< HEAD
Ship `modules/xq-ios-act-cli/` in `xq-versastacks`: a **Swift CLI** (`xq-ios-act`) for agent-native iOS automation via DeviceKit WebSocket JSON-RPC (Vibium-shaped contract).
=======
Ship `modules/xq-ios-act-cli/` in `xq-versastack`: a **Swift CLI** (`xq-ios-act`) for agent-native iOS automation via DeviceKit WebSocket JSON-RPC (Vibium-shaped contract).
>>>>>>> origin/main

## Where things live

| Concern | Location |
| --- | --- |
| **Progress / checklist** | [Hub issue #7](https://github.com/chauhaidang/xq-context-hub/issues/7) |
<<<<<<< HEAD
| **Code, tests, README** | [`xq-versastacks`](https://github.com/chauhaidang/xq-versastacks) `modules/xq-ios-act-cli/` |
=======
| **Code, tests, README** | `xq-versastack` `modules/xq-ios-act-cli/` ([merged PR #8](https://github.com/chauhaidang/xq-versastack/pull/8)) |
>>>>>>> origin/main
| **Historical design** | [`archive/`](archive/) — original dual-client DESIGN/DEV-SPEC; not source of truth |

## Target repo

| Repo | Branch | PR |
| --- | --- | --- |
<<<<<<< HEAD
| `xq-versastacks` | `main` | https://github.com/chauhaidang/xq-versastacks |
=======
| `xq-versastack` | `xq/xq-ios-act-cli-f8f1` | [#8](https://github.com/chauhaidang/xq-versastack/pull/8) |
>>>>>>> origin/main

## Acceptance criteria

Tracked on [issue #7](https://github.com/chauhaidang/xq-context-hub/issues/7). Summary:

- [x] Swift CLI + `devicekit install` / `start` / `status`
- [x] `swift test` + macOS CI without live DeviceKit
<<<<<<< HEAD
- [x] Module on `xq-versastacks` main (includes `ensure_runtime`)
=======
- [x] Versastack PR merged ([#8](https://github.com/chauhaidang/xq-versastack/pull/8))
>>>>>>> origin/main
- [ ] Consumer docs updated in versastack

## Snap commands

```bash
<<<<<<< HEAD
cd checkouts/xq-versastacks/modules/xq-ios-act-cli
=======
cd checkouts/xq-versastack/modules/xq-ios-act-cli
>>>>>>> origin/main
bash scripts/run-all.sh
cd swift && swift build && .build/debug/xq-ios-act --help
```

## Links

- Domain: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
<<<<<<< HEAD
- Research: `checkouts/xq-versastacks/docs/research/xq-ios-act-cli.md`
=======
- Research: `checkouts/xq-versastack/docs/research/xq-ios-act-cli.md`
>>>>>>> origin/main
- DeviceKit iOS: https://github.com/mobile-next/devicekit-ios
