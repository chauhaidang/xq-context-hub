# Prototype C — Per-module owned CI (no generic reusable workflow)

**Status:** Phase 0 — maintainer preference (2026-07-25): each module owns its CI definition and scripts; **do not** make the repo generic.  
**Supersedes:** CI Prototype A (reusable `module-ci.yml` + thin callers) and B (single matrix) for this plan.

## Principle

```text
Module = product + scripts + CI definition
Repo root = context docs + (optional) meta lint only
```

No shared `module-ci.yml`, no `setup: node|swift|none` abstraction, no forced `scripts/ci.sh` name, no polyglot template kit that pretends every module looks the same.

## Shape

```text
xq-versastack/
├── AGENTS.md / CONSUMER_CONTEXT.md / README.md
├── modules/
│   ├── README.md                 # how to add a module (checklist, not a generator)
│   └── <name>/                   # when a real module ships
│       ├── README.md             # documents THAT module’s verify commands
│       ├── scripts/              # whatever THAT module needs
│       └── …                     # language/toolchain of choice
└── .github/workflows/
    ├── repo-meta.yml             # OPTIONAL — root docs only; never builds modules
    └── ci-<name>.yml             # ONE full workflow per module (module-owned)
```

GitHub requires workflows under **repo-root** `.github/workflows/`. “Module-owned” means:

- The file `ci-<name>.yml` is created **with** that module and maintained by whoever owns the module.
- It is **self-contained**: checkout, install toolchain, `cd modules/<name>`, run that module’s scripts — no `workflow_call` into a shared reusable.
- Path filters / job-level gates so unrelated PRs are not blocked.

## Example — Node module (sketch)

`.github/workflows/ci-xq-scout-cli.yml` (owned with `modules/xq-scout-cli/`):

```yaml
name: ci-xq-scout-cli
on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      run: ${{ steps.filter.outputs.module }}
    steps:
      - uses: actions/checkout@v4
      - id: filter
        uses: dorny/paths-filter@v3
        with:
          filters: |
            module:
              - 'modules/xq-scout-cli/**'
              - '.github/workflows/ci-xq-scout-cli.yml'

  verify:
    needs: changes
    if: needs.changes.outputs.run == 'true'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: modules/xq-scout-cli
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
      # Module-defined — names/steps live with the module, not a repo standard
      - run: npm ci
      - run: npm test
      # or: ./scripts/whatever-this-module-uses.sh

  gate:
    needs: [changes, verify]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: gate
        run: |
          if [ "${{ needs.changes.outputs.run }}" != "true" ]; then exit 0; fi
          if [ "${{ needs.verify.result }}" != "success" ]; then exit 1; fi
```

## Example — Swift module (sketch)

Different runner, different steps, different script names — **by design**:

```yaml
# .github/workflows/ci-xq-ios-act-cli.yml
# working-directory: modules/xq-ios-act-cli
# runs-on: macos-14
# steps: xcode setup → swift test / module scripts
```

No attempt to unify these behind one reusable workflow.

## What this wave ships (no product modules yet)

| Ship | Skip |
| --- | --- |
| Root context docs (`AGENTS`, `CONSUMER`, `README`) describing the rule | Reusable `module-ci.yml` |
| `modules/README.md` checklist: “add folder + own scripts + own `ci-<name>.yml`” | Generic `templates/module/` kit (optional tiny example in docs only) |
| Optional `repo-meta.yml` for root-doc PRs | Live `ci-*.yml` (none until first real module) |
| Prototype sketches under hub `prototypes/` | Central `scripts/changed-modules.sh` orchestrator |

## Pros

- Matches independence invariant: each module is a full delivery unit
- Fast for polyglot: Swift vs Node never fight over shared inputs
- No abstraction tax / “make the repo generic” work

## Cons / watch-outs

- Workflow YAML lives at repo root (GitHub constraint) — discipline: treat `ci-<name>.yml` as part of the module’s surface
- Branch protection: add `ci-<name> / gate` when that module lands; don’t require checks that don’t exist
- Some copy-paste across workflows is OK — prefer duplication over a fake shared framework

## Anti-patterns (rejected)

- Reusable `module-ci.yml` with `setup` / `command` inputs
- Repo-wide matrix discovering all modules
- Mandating one script name (`scripts/ci.sh`) for every module
- Root `package.json` / workspace / `./scripts/module`
