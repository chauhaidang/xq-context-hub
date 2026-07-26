# CI recommendation — WP0 Phase 0 (updated)

**Pick: Prototype C — per-module owned CI**  
See [`ci-C-per-module-owned.md`](ci-C-per-module-owned.md).

Maintainer (2026-07-25): *each module has its own CI definition and scripts; we don’t need to make the repo generic.*

**Rejected for this plan:**

| Proto | Why rejected |
| --- | --- |
| **A** reusable `module-ci.yml` + thin callers | Makes the repo a generic CI framework |
| **B** single-dispatch matrix | Centralizes module discovery / setup map |

## Locked seams

1. **Module owns scripts** under `modules/<name>/scripts/` (any names that module documents).
2. **Module owns CI** as a **full** `.github/workflows/ci-<name>.yml` (self-contained; path-filtered; optional gate job). Not a caller into a shared reusable.
3. **Root does not** provide reusable module CI, forced verify script names, or polyglot setup abstractions.
4. **Optional** root `repo-meta.yml` only for hub-facing docs / workflow parse — never builds modules.
5. **This wave:** no product modules → no live `ci-*.yml`. Docs + checklist only; first real module brings its own workflow.

## Phase 1 (devops) after approval

| Do | Don’t |
| --- | --- |
| Document “add `ci-<name>.yml` with the module” in `modules/README.md` | Land `module-ci.yml` |
| Optional `repo-meta.yml` for root context paths | Invent shared workflow_call inputs |
| Keep YAML examples under hub `prototypes/ci-C-…` / snippets as **examples**, not repo law | Require `scripts/ci.sh` everywhere |

## Snap (this wave)

```bash
cd checkouts/xq-versastack
test -f README.md && test -f AGENTS.md && test -f CONSUMER_CONTEXT.md
test -f modules/README.md
# NO: test -f .github/workflows/module-ci.yml
# Optional: test -f .github/workflows/repo-meta.yml
# Future per module: cd modules/<name> && <that module’s documented verify>
```

## Branch protection

- This wave / until first module: require nothing module-specific (optional `repo-meta / gate` only).
- When `modules/foo` lands: require `ci-foo / gate` (if using gate pattern) for that module only.

## Open questions (narrowed)

1. Keep optional `repo-meta.yml` for root-doc PRs, or skip CI entirely until the first module?
2. Keep a **tiny** copy-paste example under hub prototypes only (recommended), or also a `docs/ci-examples/` in versastack?
