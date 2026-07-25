# Recommendation — WP0 layout for this wave

## Primary pick: **Prototype B**

Ship a **single** language-agnostic `templates/module/` plus a **committed, documented empty** `modules/` (`modules/.gitkeep` + `modules/README.md`). No product skeleton. No polyglot template split this wave.

### Why B over A

- Plan acceptance requires `modules/` with a documented add-module path — B meets it without inventing a fake module.
- Agents reading `AGENTS.md` (“pick one module under `modules/<name>/`”) get a real directory and a how-to instead of a missing path.
- Cost is two small files; first real-module PR stays focused on product + one CI caller.

### Why B over C

- Maintainer scope: template + docs + CI foundation only — C doubles template surface before any real module exists.
- Work Contract already specifies `templates/module/` and reusable CI `setup: node | swift | none`; polyglot is handled at **module copy time** and **caller workflow** time.
- Research (Node scout vs Swift ios-act) justifies **future** language variants; extract them from the first shipped module of each language (template-from-reality), not up front.

### Confirmed conventions (no change needed)

| Seam | Decision |
| --- | --- |
| Template path | `templates/module/` |
| Verify entry | `scripts/ci.sh` (+ optional `Makefile` → same) |
| Skills | Inside module: `skills/<name>/SKILL.md` |
| Skeleton | **Out** this wave |
| Central runner | **Forbidden** |

### Shared concrete tree (B — target for Phase 1)

```text
xq-versastack/
├── AGENTS.md
├── CONSUMER_CONTEXT.md
├── README.md
├── LICENSE
├── .gitignore
├── docs/research/…                 # research only
├── modules/
│   ├── .gitkeep
│   └── README.md                   # add-module how-to
├── templates/module/
│   ├── README.md                   # ## Verify
│   ├── Makefile                    # optional
│   ├── .gitignore
│   ├── scripts/ci.sh               # stub
│   └── skills/_example/SKILL.md
├── scripts/changed-modules.sh      # optional; list only
└── .github/workflows/
    ├── module-ci.yml
    └── repo-meta.yml
```

**Not at root:** `package.json`, `Package.swift`, workspaces, `./scripts/module`, `modules.yaml`, all-modules `make ci`, product sources, vendored engines, root agent skill trees for modules.

---

## Phase 1 ownership (parallel wave)

Branch: `feat/versastack-fast-delivery`  
Checkout: `checkouts/xq-versastack`

| Role | Owns | Must not touch |
| --- | --- | --- |
| **dev** | `templates/module/**` (README, skill stub, `.gitignore`, optional Makefile text), `modules/.gitkeep`, `modules/README.md`, root `README.md`, `AGENTS.md`, `CONSUMER_CONTEXT.md`, optional `docs/` scaffold notes | `.github/**`; any `modules/<product>/`; root toolchain; harness-style runner |
| **test** | Prove verify pattern: `templates/module/scripts/ci.sh` stub behavior + docs snippets for Verify commands; keep stub honest (`set -euo pipefail`, cd-to-module-root) | Authoring production workflows; freelancing product modules |
| **devops** | `.github/workflows/module-ci.yml` (reusable), `repo-meta.yml`, CI convention notes; align template CI comments with inputs (`module`, `setup`, `command`); optional `scripts/changed-modules.sh` | Module business/CLI logic; full-repo matrix; required checks without gate jobs |

**Collision note:** `templates/module/scripts/ci.sh` sits on the **test ↔ devops** seam. Contract: **test** owns script body/verify semantics; **devops** owns comments/env expectations that mirror `module-ci.yml`. If both must edit the same lines, stop and re-contract with product-lead.

**Snap (from plan):** context files exist; `templates/module` exists; `module-ci.yml` exists; **no** root all-modules build. With B: also `test -f modules/README.md`.

---

## Follow-on tasks

### Immediate — devops design sibling / Phase 1 prep

| Task | Role | Notes |
| --- | --- | --- |
| Detail reusable `module-ci.yml` inputs + gate-job pattern + example caller YAML (even with zero modules) | `engineer-in-devops` (design note or WP3) | Callers can wait until first module **or** ship a commented example under `.github/workflow-templates/` / docs — prefer docs to avoid fake required checks |
| Confirm root-meta path filters: `AGENTS.md`, `CONSUMER_CONTEXT.md`, `README.md`, `.github/**`, `templates/**`, `modules/README.md` | devops | Include `modules/README.md` so empty-dir doc edits still get meta CI |
| Optional `scripts/changed-modules.sh` contract (stdout list only) | devops | Must not invoke builds |

### Phase 1 wave (after layout approval)

| Package | Role | Done when |
| --- | --- | --- |
| WP1 | dev | B tree landed; root docs describe copy → `modules/<name>/` + verify-inside-module; boundary vs harness explicit |
| WP2 | test | Template `scripts/ci.sh` stub runs; Verify section accurate |
| WP3 | devops | Reusable module-ci + repo-meta + gate pattern documented; no full matrix |

### After this plan (separate plans)

- Land `modules/xq-scout-cli` (Node) and/or `modules/xq-ios-act-cli` (Swift) from research
- Revisit Prototype C only if copying the agnostic template twice proves painful — prefer extract-from-shipped-module

---

## Open questions for user / product-lead

1. **Example CI caller with zero modules:** Ship only docs + reusable workflow, or also a disabled/example workflow file? (Recommendation: docs-only until first module to avoid empty required checks.)
2. **`modules/README.md` ownership in wave:** Treated as **dev** above — confirm, or split “CI steps in that README” to devops?
3. **First follow-on module priority:** Node scout vs Swift ios-act — affects which language stub comments in the single template get emphasized (not blocking WP0/WP1).
4. **Hub issue #2 checklist:** Should product-lead mirror “choose B” + Phase 1 ready on the issue after you approve this recommendation?

No Work Contract path changes required if B is approved (`templates/module/` stays). If user prefers **A** or **C**, design will amend `plans/001-versastack-fast-delivery/PLAN.md` acceptance/`modules/` wording and ownership globs before the parallel wave starts.
