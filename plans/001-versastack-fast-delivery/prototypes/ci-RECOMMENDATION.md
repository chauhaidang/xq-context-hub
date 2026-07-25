# CI recommendation — WP0 Phase 0

**Pick: Prototype A** (reusable `module-ci.yml` + path-filtered per-module callers + gate jobs + `repo-meta`).

Not B for this wave: a single-dispatch matrix centralizes path→setup→runner mapping and fights the independence invariant already in the Work Contract.

## Why A

1. Matches plan seams already folded from devops (reusable + thin callers + gates + root-meta).
2. Polyglot stays local: each caller sets `setup` / `runner` (Node on Linux, Swift on macOS later).
3. Empty / template-only PRs only need `repo-meta` — no empty matrix edge cases.
4. Parallel waves: new module = new caller file (low collision) vs everyone editing one `ci.yml`.

## What to ship in Phase 1 (engineer-in-devops)

| Artifact | Dest in `xq-versastack` | This wave? |
| --- | --- | --- |
| `ci-TEMPLATE-snippets/module-ci.yml` | `.github/workflows/module-ci.yml` | **Yes** |
| `ci-TEMPLATE-snippets/repo-meta.yml` | `.github/workflows/repo-meta.yml` | **Yes** |
| `ci-TEMPLATE-snippets/module-caller.example.yml` | Keep under `templates/module/` or docs as example; **or** materialize only when first module lands | **Example only** (no fake module caller required) |
| Optional `scripts/changed-modules.sh` | List-only helper | Optional |

**Do not** enable live workflows before Phase 1; these files under `plans/.../prototypes/` are sketches for handoff.

## Snap commands (CI-relevant)

```bash
cd checkouts/xq-versastack

# After devops lands workflows (Phase 1), not during Phase 0 prototypes-only:
test -f .github/workflows/module-ci.yml
test -f .github/workflows/repo-meta.yml

# No product modules this wave — do NOT require:
#   test -f .github/workflows/ci-<module>.yml

# Per touched module only (future):
#   cd modules/<name> && ./scripts/ci.sh

# Never:
#   make ci          # at repo root across all modules
#   ./scripts/module # harness-style runner
```

Hub / plan snap remains documentation + file presence; Actions green is validated on the delivery PR once workflows are live.

## Branch protection notes

### This wave (template + docs + CI definitions, no `modules/<product>/`)

Require **only**:

- `repo-meta / gate`

Do **not** require per-module gates yet (they will not exist / will not run).

`repo-meta` must use `on.pull_request: {}` (no workflow-level `paths:`) so the required gate always appears.

Optional until first module: leave protection unset and rely on PR review + snap; then turn on `repo-meta / gate` when workflows merge to `main`.

### When first module lands (follow-on PR or later wave)

1. Add `.github/workflows/ci-<module>.yml` from `module-caller.example.yml` (**job-level** path filter; no PR `paths:`).
2. Require `ci-<module> / gate` **in addition to** `repo-meta / gate`.
3. Never require raw `verify` jobs that are skipped — only **gate** job names.

### Anti-patterns

- Requiring every historical module gate on every PR without no-op gates.
- A single required check that runs all modules.
- Root pre-commit that builds the world.

## How a template-only PR gets green

```text
PR touches: templates/**, README.md, AGENTS.md, CONSUMER_CONTEXT.md, .github/**
         └─► repo-meta workflow runs
               ├─ meta: file presence + workflow YAML parse
               └─ gate: success if meta success
         └─► no ci-<module> workflows exist → nothing else required
Branch protection: repo-meta / gate only → PR green
```

Local pre-push not required. Agents verify with snap commands above.

## Interaction with module-layout prototypes A / B / C

Sibling layout pick: **B** (`templates/module/` + empty documented `modules/` — see [`RECOMMENDATION.md`](RECOMMENDATION.md)).

| Layout | CI Prototype A behavior |
| --- | --- |
| **A** — template only, no `modules/` dir | Works; `repo-meta` soft-warns if `modules/` absent |
| **B** — empty `modules/` + README (chosen) | **Best fit.** No callers this wave; `repo-meta` can assert `modules/README.md` once landed; first product module adds one caller |
| **C** — polyglot template variants | Callers still one-per-module; only `setup`/`runner` differ — no CI change required if verify stays `scripts/ci.sh` |

**Stable seams with layout B:** path filter `modules/<name>/**`, verify `./scripts/ci.sh`, reusable inputs `module` / `setup` / `command` / `runner`.

CI does **not** care about internal src layout beyond those seams.

## Follow-on for engineer-in-devops (Phase 1 / WP3)

1. Copy `module-ci.yml` + `repo-meta.yml` into `checkouts/xq-versastack/.github/workflows/` on `feat/versastack-fast-delivery`.
2. Pin concrete actions (`actions/checkout@v4`, `setup-node`, Swift setup action, `dorny/paths-filter@v3`).
3. Decide PyYAML vs structural-only parse for `repo-meta` (prototype allows both).
4. Place `module-caller.example.yml` under `templates/module/` or docs as example — **do not** invent a skeleton module or a live `ci-*.yml` just to hang a caller (aligns with layout B).
5. Document required-check names in module/`modules/README.md` add-module steps (“copy caller + ask for branch protection update”).
6. Optional: `scripts/changed-modules.sh` (list only; never called by workflows as orchestrator).
7. Coordinate with test role: `templates/module/scripts/ci.sh` must be bash-safe for reusable workflow.
8. Include `modules/README.md` in meta expectations once layout B lands.
9. After first real module wave: materialize caller + update branch protection.

## Open questions for user

1. **Branch protection timing:** enable `repo-meta / gate` on first merge to `main`, or wait until after scaffold PR merges?
2. **Swift runner default:** prototype uses `runner` input defaulting to `ubuntu-latest`; OK to require `macos-14` (or latest) only on Swift callers?
3. **Caller example location:** `templates/module/` vs `docs/ci/` vs only under hub `prototypes/` until first module? (CI design default: keep example in hub prototypes + short pointer in `modules/README.md`.)
4. **`dorny/paths-filter` dependency:** acceptable third-party action, or prefer pure `git diff` in the `changes` job?
5. **Confirm zero live callers this wave:** layout B + no skeleton → ship only `module-ci.yml` + `repo-meta.yml` (yes — recommended).
6. **Approve CI Prototype A + layout B together?** Structure sibling already recommends B; CI recommends A — product-lead should snap both before Phase 1.
