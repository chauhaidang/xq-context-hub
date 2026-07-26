# WP0 prototypes — xq-versastack module layout

Phase 0 design spikes for **hub issue** [#2](https://github.com/chauhaidang/xq-context-hub/issues/2).  
Artifacts live on the **hub** under this directory. Do **not** implement under `checkouts/xq-versastack` until a layout is chosen.

## Maintainer constraints (fixed)

| Decision | Implication |
| --- | --- |
| No thin skeleton module this wave | No `modules/<product>/` product code in Phase 1 |
| Template + docs + CI foundation only | Ship scaffold + root context + path-filtered CI |
| Preserve independent modules | No root workspace, no `./scripts/module`, no central runner |

## How to choose

| Need | Prefer |
| --- | --- |
| Match Work Contract `templates/module/` + prove `modules/` exists for agents | **B** (recommended) |
| Absolute minimal diff; create `modules/` only when first real module lands | **A** |
| Language-specific scaffolds up front (Node scout vs Swift ios-act) | **C** (defer unless template stubs collide badly) |

Read order:

1. [A-minimal-template.md](./A-minimal-template.md) — template only; no committed `modules/`
2. [B-documented-modules-dir.md](./B-documented-modules-dir.md) — template + empty documented `modules/`
3. [C-polyglot-template-variants.md](./C-polyglot-template-variants.md) — Node + Swift template variants
4. [RECOMMENDATION.md](./RECOMMENDATION.md) — primary pick + Phase 1 ownership + open questions

### Sibling CI prototypes (devops design)

| Proto | Idea | Status |
| --- | --- | --- |
| [ci-A](./ci-A-reusable-caller.md) | Reusable `module-ci.yml` + thin callers | **Rejected** — too generic |
| [ci-B](./ci-B-single-dispatch.md) | Single matrix / dispatch | **Rejected** |
| [ci-C](./ci-C-per-module-owned.md) | Each module owns full CI + scripts | **Chosen** (maintainer) |

See [ci-RECOMMENDATION.md](./ci-RECOMMENDATION.md). Snippets under `ci-TEMPLATE-snippets/` are historical for A — prefer sketches in **ci-C**.

## Shared invariants (all layout options)

- One module ≈ one activity CLI; own language, toolchain, tests, skills, **scripts**, and **CI workflow**
- Agent skills live **inside** the module — not at repo root
- Research stays under `docs/research/`; shipping means `modules/<name>/` + `.github/workflows/ci-<name>.yml`
- Root holds **context** (+ optional meta lint) — never a shared module CI framework or product toolchain

## Research drivers (polyglot reality)

| Future module | Language | Notes |
| --- | --- | --- |
| `xq-scout-cli` | Node (≥22) | Scout scenarios + first-party skill; `scripts/ci.sh` wraps scout report |
| `xq-ios-act-cli` | Swift | DeviceKit WS client; `Package.swift` / module-local Xcode |

CI already plans `setup: node | swift | none` on the reusable workflow — language variance is primarily a **module** and **caller** concern, not a reason to invent a monorepo runner.
