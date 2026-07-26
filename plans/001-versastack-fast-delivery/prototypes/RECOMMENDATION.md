# Recommendation — WP0 layout for this wave

## Primary pick: **Prototype B (layout) + CI Prototype C**

Ship a **documented empty** `modules/` (`modules/.gitkeep` + `modules/README.md`) and root context.  
**Do not** build a generic reusable CI layer. **Do not** mandate a shared `templates/module/` kit unless the maintainer still wants a soft example — default for “not generic”: **checklist in `modules/README.md` only**.

### Why layout B still

- Agents get a real `modules/` path + add-module how-to without a fake product module.
- Cost is two small files.

### Why CI C (maintainer)

- Each module owns its scripts and a **full** `.github/workflows/ci-<name>.yml`.
- No `module-ci.yml`, no shared `setup` inputs, no forced `scripts/ci.sh`.
- Duplication across workflows is fine; a fake framework is not.

### Confirmed conventions

| Seam | Decision |
| --- | --- |
| Module scripts | Owned per module; names documented in that module’s README |
| Module CI | Full self-contained `ci-<name>.yml` at repo `.github/workflows/` |
| Shared reusable CI | **None** |
| Generic template kit | **Optional / prefer skip** — checklist > generator |
| Skeleton | **Out** this wave |
| Central runner | **Forbidden** |

### Target tree (this wave + later modules)

```text
xq-versastack/
├── AGENTS.md
├── CONSUMER_CONTEXT.md
├── README.md
├── docs/research/…
├── modules/
│   ├── .gitkeep
│   └── README.md              # checklist: folder + scripts + ci-<name>.yml
└── .github/workflows/
    └── repo-meta.yml          # OPTIONAL root-docs only
# When a module ships:
#   modules/<name>/**          # including its own scripts
#   .github/workflows/ci-<name>.yml   # full workflow, module-owned
```

**Not at root:** reusable `module-ci.yml`, workspaces, `./scripts/module`, forced verify script names, polyglot setup abstractions.

---

## Phase 1 ownership (parallel wave)

Branch: `feat/versastack-fast-delivery`

| Role | Owns | Must not touch |
| --- | --- | --- |
| **dev** | `modules/.gitkeep`, `modules/README.md` (add-module checklist), root context docs | Inventing reusable CI; product modules |
| **test** | Examples/docs of how a module might prove verify (in README snippets only this wave) | Authoring a shared CI framework |
| **devops** | Optional `repo-meta.yml`; document that each module brings its own `ci-<name>.yml` | `module-ci.yml` / matrix runner |

**Snap:** context files + `modules/README.md` exist; **no** requirement for `module-ci.yml`.

---

## Follow-on

- First real module plan: land `modules/<name>/` **and** `.github/workflows/ci-<name>.yml` together in one PR.
- Revisit a soft copy-paste example only if the first two modules show painful duplication — still prefer copy over framework.

## Open questions

1. Optional `repo-meta.yml` this wave, or zero workflows until first module?
2. Confirm **no** `templates/module/` in versastack (hub prototypes only)?

