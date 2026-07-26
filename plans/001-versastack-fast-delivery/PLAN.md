# Plan: Versastack structure for fast delivery

- **ID**: `001-versastack-fast-delivery`
- **Hub issue**: https://github.com/chauhaidang/xq-context-hub/issues/2
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: done — product PR https://github.com/chauhaidang/xq-versastack/pull/3 merged 2026-07-25 (`8286966`); hub issue #2 closed

## Goal

Establish a **repeatable structure** in `xq-versastack` so new agent-native CLI modules can be added and verified quickly, without introducing a central monorepo build or runner. Success means: a documented module contract + scaffold, path-aware CI hooks (module-scoped), updated consumer/agent context that points at `modules/<name>/`, and a clear “add a module” path that engineers can execute in parallel waves with minimal cross-file collisions.

## Non-goals

- Implement full product modules (`xq-ios-act-cli`, `xq-scout-cli`, etc.)
- Thin skeleton / example module in this wave (**skipped by maintainer**)
- Add a root-level build, workspace, or `./scripts/module`-style central runner (that belongs to `xq-harness`, not versastack)
- Vendor upstream CLIs/engines into the repo root
- Change `xq-harness` layout or published packages

## Target repos

| Order | Repo | Branch | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | `xq-versastack` | `xq/versastack-fast-delivery` | design (Phase 0) → then parallel `dev+test+devops` | Checkout: `checkouts/xq-versastack` (synced). Only delivery unit. |

## Acceptance criteria

- [x] `modules/` exists with a documented **add-module checklist** (own scripts + own `ci-<name>.yml`); no generic reusable module CI
- [x] Root `README.md` / `AGENTS.md` / `CONSUMER_CONTEXT.md` describe independent modules (still: no central runner / no shared CI framework)
- [x] Module verify is **per-module** (documented in that module’s README when it exists) — no forced repo-wide script name
- [x] CI: each future module brings a **full** `.github/workflows/ci-<name>.yml`; this wave deliberately ships zero workflows
- [x] File ownership supported a collision-free parallel `dev` / `test` / `devops` wave
- [x] Explicit boundary vs `xq-harness` remains in docs (versastack ≠ harness module runner)

## Work Contract — xq-versastack

**Branch:** `xq/versastack-fast-delivery`  
**Goal:** Land fast-delivery **docs + empty `modules/` checklist**; each future module owns its scripts and full CI workflow. **No** generic reusable CI. **No** skeleton.

### Interfaces / seams

1. **Add-module path (not a generic scaffold kit)**  
   - `modules/README.md` checklist: create `modules/<name>/`, own scripts, own `.github/workflows/ci-<name>.yml`.  
   - Prefer **no** `templates/module/` generator unless explicitly re-requested.  
   - Copy-paste examples may live under hub `plans/.../prototypes/` only.

2. **CI — per-module owned (maintainer: not generic)**  
   - Each module ships a **full** `.github/workflows/ci-<name>.yml` (self-contained setup + `cd modules/<name>` + that module’s scripts).  
   - Path filters / gate jobs so unrelated PRs are not blocked.  
   - **No** reusable `module-ci.yml`, **no** shared `setup`/`command` inputs, **no** repo-wide matrix.  
   - This wave: **zero workflows** — no module CI and no `repo-meta.yml`.

3. **Docs / context**  
   - Update root `README.md`, `AGENTS.md`, `CONSUMER_CONTEXT.md` for independent modules + “CI/scripts live with the module.”  
   - Research stays under `docs/research/`.

4. **First module skeleton** — **out of scope** (maintainer: skip).

### File ownership

| Role | Owns (paths / globs) | Must not touch |
| --- | --- | --- |
| design (Phase 0) | Prototypes under `plans/001-versastack-fast-delivery/prototypes/` | Shipping product modules without handoff |
| dev | `modules/.gitkeep`, `modules/README.md`, root context docs | `.github/workflows/module-ci.yml`; product modules; shared CI framework |
| test | Verify/docs snippets in checklist / examples only this wave | Shared CI framework; product modules |
| devops | Document per-module `ci-<name>.yml` convention | Any workflow this wave; reusable `module-ci.yml`; matrix orchestrator |

**Layout + CI:** layout **B** (documented empty `modules/`) + CI **C** (per-module owned). See `prototypes/RECOMMENDATION.md` + `prototypes/ci-RECOMMENDATION.md`.

Cross-cutting: if a role must touch another’s globs, stop and ask root / product-lead.

### Acceptance

- [x] `modules/README.md` checklist present; no product module this wave
- [x] Root agent/consumer docs state: scripts + CI owned per module; no central runner
- [x] No reusable `module-ci.yml` / shared module CI framework
- [x] Zero workflows this wave
- [x] No root workspace / `./scripts/module` runner

### Snap commands

```bash
cd checkouts/xq-versastack

test -f README.md && test -f AGENTS.md && test -f CONSUMER_CONTEXT.md
test -f modules/README.md
test ! -d .github/workflows
# future: cd modules/<name> && <module-documented command>
```

> Snap must not invent a repo-root `make ci` that builds all modules.

## Work packages

### WP0 — contract / scaffold design (**recommended before wave**)

- **Role**: design
- **Engineer**: `engineer-in-design`
- **Done when**:
  - Publish structure prototypes under `plans/001-versastack-fast-delivery/prototypes/` — **done**
  - Recommend one layout; update Work Contract if seams change — **layout B + CI C** (per-module owned CI; no generic reusable)
  - Confirm verify/CI convention — **per module; no forced `scripts/ci.sh` / `module-ci.yml`**
- **Why Phase 0**: Lock independence before parallel wave.
- **Status**: approved — Phase 1 started (2026-07-25)

### Parallel wave — same branch (`xq/versastack-fast-delivery`)

| Role | Engineer | Package | Ownership |
| --- | --- | --- | --- |
| dev | `engineer-in-dev` | WP1 — empty `modules/` docs + root context | `modules/*` docs, root context |
| test | `engineer-in-test` | WP2 — checklist verify guidance (examples only) | docs snippets |
| devops | `engineer-in-devops` | WP3 — document per-module `ci-<name>.yml`; confirm zero workflows this wave | CI guidance in root/module docs; **no `.github/workflows/**` changes** |

**Wave status:** complete — five focused commits on the shared branch; snap passed.

### After snap

| Role | Engineer | Package |
| --- | --- | --- |
| review | `engineer-in-review` | Review `xq/versastack-fast-delivery` → one PR (when user allows `remote_writes`) |

**Review status:** complete. Delivery PR https://github.com/chauhaidang/xq-versastack/pull/3 **MERGED** 2026-07-25 (merge `8286966`; tip `040d712`).

## Sequencing (recommended)

```text
Phase 0: engineer-in-design  — finish scaffold/CI seams; update this contract
Phase 1: PARALLEL on xq/versastack-fast-delivery
           engineer-in-dev    + WP1
           engineer-in-test   + WP2
           engineer-in-devops + WP3
Phase 2: product-lead / root — snap commands; integrate only
Phase 3: engineer-in-review
Phase 4: one PR for xq-versastack (user-approved remote_writes)
```

**Do not** start the parallel wave until WP0 prototypes are reviewed and a layout is chosen.

### Follow-on (out of this plan)

- Separate plans/waves for real modules from research: `xq-ios-act-cli`, `xq-scout-cli`
- Hub umbrella issue checklist when user asks to create the issue

## Notes / decisions

- **Independence invariant:** Each module owns language, toolchain, build, test, versioning, docs/skills. Versastack must not grow a harness-like central `./scripts/module` runner.
- **Domain:** harness tooling box for agents; distinct from `xq-harness` polyglot test monorepo.
- **Research docs** stay under `docs/research/`; shipping a module means `modules/<name>/` + consumer pointers, not promoting research in place.
- **CI:** each future module owns its scripts and full `.github/workflows/ci-<name>.yml`. This wave ships **zero workflows**: no `repo-meta.yml`, reusable workflow, matrix, or live module caller.
- **Anti-patterns:** no central `./scripts/module`, no root workspace, no require-all-modules-green, no heavy root pre-commit.
- **Hub progress:** GitHub issue only when user requests; no `PROGRESS.md`.

## Links

- Hub issue: https://github.com/chauhaidang/xq-context-hub/issues/2
- Domain context: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
- Prototypes: [`prototypes/`](prototypes/) (Phase 0)
- Checkout context: `checkouts/xq-versastack/{AGENTS.md,CONSUMER_CONTEXT.md,README.md}`
- Research (future modules): `checkouts/xq-versastack/docs/research/`
- Process: [`docs/agents/requirement-fanout.md`](../../docs/agents/requirement-fanout.md), [`docs/agents/parallel-wave.md`](../../docs/agents/parallel-wave.md)

---

## Tracking

Umbrella issue: https://github.com/chauhaidang/xq-context-hub/issues/2  
Progress: issue checklist + comments only (no `PROGRESS.md`).
