# Platform domain context

## Purpose

Platform is the shared XQ runtime, contracts, plugins, and SDKs that future
products build on. Agents should keep platform vocabulary distinct from
fitness feature work and harness test tooling.

## Boundary

Platform owns:

- platform runtime surfaces (`xq-platform`, `xq-platform-node`)
- shared contracts (`xq-contracts`)
- plugins and platform dependency sets (`xq-plugins`)
- Node SDK and common kits (`xq-sdk-node`, `xq-js-common-kit`, `xq-kit-common`)

Platform does not own:

- fitness CQRS services (fitness domain)
- harness module runner or `@chauhaidang/xq-harness-*` packages (harness domain)
- org-level AI context map (this hub)

## Glossary

### Platform

The shared XQ host / runtime that products plug into. Prefer **platform** or
the concrete repo (`xq-platform`, `xq-platform-node`), not *backend* when the
distinction from product services matters.

### Contract

A shared API or schema boundary published for consumers (`xq-contracts`).
Prefer **contract**, not *API doc* alone, when referring to the repo’s owned
artifacts.

### Plugin

An extension or dependency package registered for platform use (`xq-plugins`).
Prefer **plugin** for that boundary; do not use it as a synonym for harness
modules.

### SDK

Client libraries for calling platform capabilities (`xq-sdk-node`). Prefer
**SDK** when the consumer is an application integrating with platform.

### Common kit

Shared utilities reused across Node/JS XQ code (`xq-js-common-kit`,
`xq-kit-common`). Distinct from harness-lineage `xq-harness-common-kit`.

## Related repos

| Repo | Role in this domain |
| --- | --- |
| `xq-platform` | XQ Platform |
| `xq-platform-node` | Node platform runtime |
| `xq-contracts` | Shared contracts |
| `xq-plugins` | Plugins / platform dependencies |
| `xq-sdk-node` | Node SDK |
| `xq-js-common-kit` | JS common kit |
| `xq-kit-common` | Shared repeated utilities |
| `xq-obj-mgmt` | Object management (adjacent) |

## Notes for agents

- Do not install harness common-kit when the task needs platform/common-kit —
  check package names carefully
- Contract changes are cross-consumer; ask before widening public surfaces
- Product-specific domain terms still live in product or fitness/harness
  contexts, not here
