# Plan: xq-ios-act-cli — agent-native iOS device CLI

- **ID**: `002-xq-ios-act-cli`
- **Hub issue**: https://github.com/chauhaidang/xq-context-hub/issues/7
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: **done** (module merged) — follow-ons tracked on [issue #7](https://github.com/chauhaidang/xq-context-hub/issues/7)

## Goal

Ship `modules/xq-ios-act-cli/` in `xq-versastack`: a **Swift CLI** (`xq-ios-act`) for agent-native iOS automation via DeviceKit WebSocket JSON-RPC (Vibium-shaped contract).

## Where things live

| Concern | Location |
| --- | --- |
| **Progress / checklist** | [Hub issue #7](https://github.com/chauhaidang/xq-context-hub/issues/7) |
| **Code, tests, README** | `xq-versastack` `modules/xq-ios-act-cli/` ([merged PR #8](https://github.com/chauhaidang/xq-versastack/pull/8)) |
| **Historical design** | [`archive/`](archive/) — original dual-client DESIGN/DEV-SPEC; not source of truth |

## Target repo

| Repo | Branch | PR |
| --- | --- | --- |
| `xq-versastack` | `xq/xq-ios-act-cli-f8f1` | [#8](https://github.com/chauhaidang/xq-versastack/pull/8) |

## Acceptance criteria

Tracked on [issue #7](https://github.com/chauhaidang/xq-context-hub/issues/7). Summary:

- [x] Swift CLI + `devicekit install` / `start` / `status`
- [x] `swift test` + macOS CI without live DeviceKit
- [x] Versastack PR merged ([#8](https://github.com/chauhaidang/xq-versastack/pull/8))
- [ ] Consumer docs updated in versastack

## Snap commands

```bash
cd checkouts/xq-versastack/modules/xq-ios-act-cli
bash scripts/run-all.sh
cd swift && swift build && .build/debug/xq-ios-act --help
```

## Links

- Domain: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
- Research: `checkouts/xq-versastack/docs/research/xq-ios-act-cli.md`
- DeviceKit iOS: https://github.com/mobile-next/devicekit-ios
