# Plan: Versastack structure for fast delivery

- **ID**: `001-versastack-fast-delivery`
- **Hub issue**: _(not created — ask user)_
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastack` only
- **Status**: drafting

## Goal

Establish a **repeatable structure** in `xq-versastack` so new agent-native CLI modules can be added and verified quickly, without introducing a central monorepo build or runner. Success means: a documented module contract + scaffold, path-aware CI hooks (module-scoped), updated consumer/agent context that points at `modules/<name>/`, and a clear “add a module” path that engineers can execute in parallel waves with minimal cross-file collisions.

## Non-goals

- Implement full product modules (`xq-ios-act-cli`, `xq-scout-cli`, etc.) beyond an optional thin skeleton
- Add a root-level build, workspace, or `./scripts/module`-style central runner (that belongs to `xq-harness`, not versastack)
- Vendor upstream CLIs/engines into the repo root
- Change `xq-harness` layout or published packages
- Open GitHub issues / PRs in this planning pass (`remote_writes=no`)

## Target repos

| Order | Repo | Branch | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | `xq-versastack` | `feat/versastack-fast-delivery` | design (Phase 0) → then parallel `dev+test+devops` | Checkout: `checkouts/xq-versastack` (synced). Only delivery unit. |

## Acceptance criteria

- [ ] `modules/` exists with a documented layout and an **add-module** scaffold (template and/or generator docs) that preserves independent language/toolchain per module
- [ ] Root `README.md` / `AGENTS.md` / `CONSUMER_CONTEXT.md` describe how to create, work in, and consume a module under `modules/<name>/` (still: no central runner)
- [ ] Module-local verify pattern is documented (and demonstrated on the scaffold or optional skeleton) — agents know what to run inside a module dir
- [ ] CI / hooks leave room for **path filters** so only changed modules run — concrete workflow files owned by devops (**pending devops input** where TBD)
- [ ] File ownership in the Work Contract is clear enough for a parallel `dev` / `test` / `devops` wave on one branch without collisions
- [ ] Explicit boundary vs `xq-harness` remains in docs (versastack ≠ harness module runner)

## Work Contract — xq-versastack

**Branch:** `feat/versastack-fast-delivery`  
**Goal:** Land the fast-delivery structure (template + context + module-scoped CI seams + optional skeleton) while keeping modules fully independent.

### Interfaces / seams

1. **Module template / scaffold**  
   - Proposed location (design to confirm): e.g. `templates/module/` or `modules/_scaffold/` — **not** a runnable root package.  
   - Minimum files a new module should get: `README.md`, language-appropriate project stub, `scripts/verify` (or equivalent), agent skill stub path (`skills/` or module-local equivalent), `.gitignore` as needed.  
   - Contract: copying/scaffolding a module does **not** register it in any root workspace.

2. **CI path filters** (**pending devops input**)  
   - Desired behavior: PRs that touch `modules/<name>/**` run that module’s verify only; root/docs-only changes skip module matrices.  
   - Ownership: `.github/**` (workflows, path filters, reusable workflows if any). Exact YAML / matrix design TBD by devops after Phase 0.

3. **Docs / context**  
   - Update root `README.md`, `AGENTS.md`, `CONSUMER_CONTEXT.md` for `modules/` presence, scaffold usage, and “how to load one module.”  
   - Keep research docs under `docs/research/` as research-only; do not treat them as shipped modules.

4. **First module skeleton (optional, thin)**  
   - If included in this wave: a minimal `modules/<name>/` that proves the template (e.g. placeholder CLI + verify script).  
   - Prefer **not** starting `xq-ios-act-cli` / `xq-scout-cli` product implementation here — those are follow-on plans. Skeleton name TBD in Phase 0 (e.g. `modules/_example/` or a trivial `modules/hello-cli/`).

### File ownership

| Role | Owns (paths / globs) | Must not touch |
| --- | --- | --- |
| design (Phase 0) | Contract refinement in this plan; design notes under `docs/` if needed (e.g. `docs/module-scaffold.md`) | Implementation freelancing under `modules/**` product code; `.github/**` final workflows |
| dev | `templates/**` (or agreed scaffold path), `modules/<skeleton>/**` (non-test primary sources + module README), root `README.md`, `AGENTS.md`, `CONSUMER_CONTEXT.md`, scaffold-related docs under `docs/` (non-research productization notes) | `.github/**`; inventing a root build/runner; harness-style `modules.yaml` |
| test | Module-local test trees / `**/tests/**` / `**/*test*` inside scaffold + skeleton; module `scripts/verify` (or test entry) content proving the pattern; any `docs/` snippets that document verify commands | Production feature freelancing beyond test harnesses; `.github/**` workflow authorship |
| devops | `.github/**`, repo hooks if added, path-filter / matrix wiring, any root CI helper scripts that **only** dispatch into module dirs (no business logic) | Module business/CLI logic; changing independent-module contract to a monorepo runner |

Cross-cutting: if a role must touch another’s globs, stop and ask root / product-lead — do not “just fix it.”

### Acceptance

- [ ] Scaffold documented and present; a new module can be started by copying/following it without a root toolchain
- [ ] Root agent/consumer docs match the independent-module contract and mention verify-inside-module
- [ ] Optional skeleton (if in-scope) passes its **module-local** verify
- [ ] Devops slice: CI stub or workflow with path-filter placeholders merged on the branch — details marked where still TBD
- [ ] No root `package.json` / workspace / central `scripts/module` runner introduced

### Snap commands

```bash
# From hub checkout of versastack — module-local verify patterns (adjust names after Phase 0)
cd checkouts/xq-versastack

# Context / contract sanity (no central build)
test -f README.md && test -f AGENTS.md && test -f CONSUMER_CONTEXT.md
test -d modules || test -d templates   # structure present as designed
rg -n "no central|independent module|modules/<" README.md AGENTS.md CONSUMER_CONTEXT.md

# If skeleton shipped — run ONLY inside that module (example; exact script TBD by test/dev)
# cd modules/<skeleton-name> && ./scripts/verify
# or: cd modules/<skeleton-name> && <module-documented test command>

# Devops — pending concrete workflow; after devops lands CI:
# gh workflow list   # or act / local actionlint if adopted
# actionlint .github/workflows/*   # if actionlint is chosen (pending devops input)
```

> **Note:** Exact verify binaries and workflow lint commands are **pending devops + Phase 0 design**. Snap must not invent a repo-root `make ci` that builds all modules.

## Work packages

### WP0 — contract / scaffold design (**recommended before wave**)

- **Role**: design
- **Engineer**: `engineer-in-design`
- **Done when**:
  - Scaffold path + minimum file set finalized
  - Skeleton in/out decision + name (if in)
  - Module verify convention named (`scripts/verify` vs language-native)
  - Devops inputs listed (path-filter grammar, required checks) — still may leave YAML TBD
  - Work Contract above updated if seams change
- **Why Phase 0**: Repo is nearly empty; template shape and CI seams are unclear enough that a parallel wave would thrash ownership and invent a root runner by accident.

### Parallel wave — same branch (`feat/versastack-fast-delivery`)

| Role | Engineer | Package | Ownership |
| --- | --- | --- | --- |
| dev | `engineer-in-dev` | WP1 — scaffold + root context + optional skeleton sources | `templates/**`, `modules/<skeleton>/**` (src/docs), root context files |
| test | `engineer-in-test` | WP2 — module-local verify / tests for scaffold+skeleton | module test paths + verify scripts |
| devops | `engineer-in-devops` | WP3 — path-filtered CI / hooks | `.github/**` (+ dispatch-only helpers); **pending devops input** on filter details |

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

**Do not** start the parallel wave until WP0 closes open questions that would collide ownership (scaffold path, skeleton yes/no, verify command name).

### Follow-on (out of this plan)

- Separate plans/waves for real modules from research: `xq-ios-act-cli`, `xq-scout-cli`
- Hub umbrella issue checklist when user asks to create the issue

## Notes / decisions

- **Independence invariant:** Each module owns language, toolchain, build, test, versioning, docs/skills. Versastack must not grow a harness-like central `./scripts/module` runner.
- **Domain:** harness tooling box for agents; distinct from `xq-harness` polyglot test monorepo.
- **Research docs** stay under `docs/research/`; shipping a module means `modules/<name>/` + consumer pointers, not promoting research in place.
- **CI:** path filters and required checks are devops-owned; plan explicitly allows “pending devops input” until WP0/WP3 land.
- **Hub progress:** GitHub issue only when user requests; no `PROGRESS.md`.

## Links

- Hub issue: _(not created — ask user)_
- Domain context: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
- Checkout context: `checkouts/xq-versastack/{AGENTS.md,CONSUMER_CONTEXT.md,README.md}`
- Research (future modules): `checkouts/xq-versastack/docs/research/`
- Process: [`docs/agents/requirement-fanout.md`](../../docs/agents/requirement-fanout.md), [`docs/agents/parallel-wave.md`](../../docs/agents/parallel-wave.md)

---

## Draft umbrella issue (for later — do not create yet)

**Title:** `[plan] 001-versastack-fast-delivery — structure xq-versastack for fast delivery`

**Body (checklist draft):**

```markdown
Plan: `plans/001-versastack-fast-delivery/PLAN.md`

## Goal
Structure `xq-versastack` for fast, independent module delivery (no central monorepo runner).

## Checklist
- [ ] Phase 0 — `engineer-in-design`: finalize Work Contract / scaffold seams
- [ ] Phase 1 wave — `xq-versastack` @ `feat/versastack-fast-delivery`
  - [ ] WP1 `engineer-in-dev` — scaffold + root context (+ optional skeleton)
  - [ ] WP2 `engineer-in-test` — module-local verify/tests
  - [ ] WP3 `engineer-in-devops` — path-filtered CI (pending devops input)
- [ ] Phase 2 — Snap (module-local verify + context sanity)
- [ ] Phase 3 — `engineer-in-review` on branch
- [ ] Phase 4 — One PR: `xq-versastack` (link when open)
- [ ] Merged / done

## Non-goals (reminder)
No full ios-act / scout product modules; no harness-style root runner.

## Contract
See plan § Work Contract — xq-versastack
```
