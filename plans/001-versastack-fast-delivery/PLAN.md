# Plan: Versastack structure for fast delivery

- **ID**: `001-versastack-fast-delivery`
- **Hub issue**: https://github.com/chauhaidang/xq-context-hub/issues/2
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: in_progress

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
| 1 | `xq-versastack` | `feat/versastack-fast-delivery` | design (Phase 0) → then parallel `dev+test+devops` | Checkout: `checkouts/xq-versastack` (synced). Only delivery unit. |

## Acceptance criteria

- [ ] `modules/` exists with a documented layout and an **add-module** scaffold (template and/or generator docs) that preserves independent language/toolchain per module
- [ ] Root `README.md` / `AGENTS.md` / `CONSUMER_CONTEXT.md` describe how to create, work in, and consume a module under `modules/<name>/` (still: no central runner)
- [ ] Module-local verify pattern is documented on the scaffold (`templates/module/` + `scripts/ci.sh`) — agents know what to run inside a module dir
- [ ] Path-filtered CI lands: reusable `module-ci.yml` + per-module caller; required checks use always-green **gate** jobs so untouched modules do not block PRs
- [ ] File ownership in the Work Contract is clear enough for a parallel `dev` / `test` / `devops` wave on one branch without collisions
- [ ] Explicit boundary vs `xq-harness` remains in docs (versastack ≠ harness module runner)

## Work Contract — xq-versastack

**Branch:** `feat/versastack-fast-delivery`  
**Goal:** Land the fast-delivery structure (template + context + module-scoped CI seams; **no skeleton**) while keeping modules fully independent.

### Interfaces / seams

1. **Module template / scaffold**  
   - Location: `templates/module/` (not a runnable root package).  
   - Minimum files: `README.md` (Verify section), `scripts/ci.sh` (canonical entry), optional `Makefile` (`make ci` → `./scripts/ci.sh`), language stub, skill stub, `.gitignore` as needed.  
   - Contract: copying a module does **not** register it in any root workspace.

2. **CI path filters** (devops input folded in)  
   - Reusable `.github/workflows/module-ci.yml` — inputs: `module`, `setup` (`node` / `swift` / `none`), `command` (default `./scripts/ci.sh`). Steps: checkout → setup → `cd modules/<name>` → run. **No** root install/build.  
   - One thin path-filtered caller per module + `workflow_dispatch`.  
   - Root-meta job on `AGENTS.md`, `CONSUMER_CONTEXT.md`, `README.md`, `.github/**`, `templates/**`, `modules/README.md` — parse/lint only; do not build modules.  
   - Required checks: per-module **gate** jobs that succeed when paths don’t match (avoids missing required checks).  
   - Optional `scripts/changed-modules.sh` lists changed `modules/*` only — must not orchestrate builds.  
   - No root pre-commit gate; no full-repo matrix on every PR.

3. **Docs / context**  
   - Update root `README.md`, `AGENTS.md`, `CONSUMER_CONTEXT.md` for `modules/` presence, scaffold usage, and “how to load one module.”  
   - Keep research docs under `docs/research/` as research-only; do not treat them as shipped modules.

4. **First module skeleton** — **out of scope** (maintainer: skip). First real modules land in follow-on plans from research docs.

### File ownership

| Role | Owns (paths / globs) | Must not touch |
| --- | --- | --- |
| design (Phase 0) | Contract refinement; prototypes under `plans/001-versastack-fast-delivery/prototypes/`; optional design notes | Shipping final product CI/modules without handoff |
| dev | `templates/module/**` (non-CI body as agreed), `modules/.gitkeep`, `modules/README.md`, root `README.md`, `AGENTS.md`, `CONSUMER_CONTEXT.md`, scaffold docs under `docs/` | `.github/**`; inventing a root build/runner; harness-style `modules.yaml`; creating `modules/<product>/` in this wave |
| test | Template `scripts/ci.sh` / test stubs proving the verify pattern; docs snippets for verify commands | Production module freelancing; `.github/**` workflow authorship |
| devops | `.github/**`, CI-facing comments/expectations in `templates/module/**`, optional `scripts/changed-modules.sh`, CI convention docs | Module business/CLI logic; inventing a monorepo runner |

**Layout decision (WP0):** Prototype **B** — single `templates/module/` + committed empty documented `modules/` (no product skeleton; no polyglot template split this wave). See `prototypes/RECOMMENDATION.md`.

Cross-cutting: if a role must touch another’s globs, stop and ask root / product-lead — do not “just fix it.”

### Acceptance

- [ ] Scaffold documented and present; a new module can be started by copying/following it without a root toolchain
- [ ] Root agent/consumer docs match the independent-module contract and mention verify-inside-module
- [ ] No `modules/<product>/` created in this wave (skeleton skipped)
- [ ] Devops slice: reusable `module-ci.yml` + example path-filtered caller (from template) + gate pattern; root-meta job for docs/CI-only PRs
- [ ] No root `package.json` / workspace / central `scripts/module` runner introduced

### Snap commands

```bash
cd checkouts/xq-versastack

# Context / contract sanity (no central build)
test -f README.md && test -f AGENTS.md && test -f CONSUMER_CONTEXT.md
test -d templates/module
test -f modules/README.md
test -f .github/workflows/module-ci.yml

# Per touched module only:
# cd modules/<name> && ./scripts/ci.sh

# Root-meta-only changes: rely on repo-meta workflow (do not full-matrix modules)
```

> Snap must not invent a repo-root `make ci` that builds all modules.

## Work packages

### WP0 — contract / scaffold design (**recommended before wave**)

- **Role**: design
- **Engineer**: `engineer-in-design`
- **Done when**:
  - Publish structure prototypes under `plans/001-versastack-fast-delivery/prototypes/` — **done**
  - Recommend one layout; update Work Contract if seams change — **B recommended**; ownership/`modules/` seams updated
  - Confirm `templates/module/` + `scripts/ci.sh` (or document override) — **confirmed**
- **Why Phase 0**: Empty repo + polyglot future modules — lock layout/CI seams before parallel wave.
- **Status**: awaiting user/product-lead approval of Prototype **B** before Phase 1 wave.

### Parallel wave — same branch (`feat/versastack-fast-delivery`)

| Role | Engineer | Package | Ownership |
| --- | --- | --- | --- |
| dev | `engineer-in-dev` | WP1 — scaffold + root context + empty `modules/` docs | `templates/module/**` (non-CI), `modules/.gitkeep`, `modules/README.md`, root context files |
| test | `engineer-in-test` | WP2 — template `scripts/ci.sh` / verify pattern | `templates/module/scripts/ci.sh` + verify doc snippets |
| devops | `engineer-in-devops` | WP3 — reusable module-ci + path-filtered callers + gate jobs | `.github/**`, CI-facing notes in `templates/module/**`, optional `scripts/changed-modules.sh` |

### After snap

| Role | Engineer | Package |
| --- | --- | --- |
| review | `engineer-in-review` | Review `feat/versastack-fast-delivery` → one PR (when user allows `remote_writes`) |

## Sequencing (recommended)

```text
Phase 0: engineer-in-design  — finish scaffold/CI seams; update this contract
Phase 1: PARALLEL on feat/versastack-fast-delivery
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
- **CI:** path-filtered reusable workflow + per-module callers + gate jobs (devops advisory folded into Work Contract). Branch for this plan remains `feat/versastack-fast-delivery` (not a separate chore-only branch).
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
