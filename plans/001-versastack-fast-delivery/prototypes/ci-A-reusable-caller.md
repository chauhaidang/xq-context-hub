# Prototype A — Reusable `module-ci.yml` + path-filtered callers

**Status:** Phase 0 sketch only — do **not** enable live workflows in `checkouts/xq-versastack` this wave.  
**Aligns with:** Work Contract § CI path filters (plan `001-versastack-fast-delivery`).  
**Companion YAML:** [`ci-TEMPLATE-snippets/`](ci-TEMPLATE-snippets/).

## Shape

```text
.github/workflows/
  module-ci.yml          # reusable workflow_call (inputs: module, setup, command)
  repo-meta.yml          # path-filtered root/docs/templates/CI lint only
  ci-<module>.yml        # one thin caller per module (paths + gate + optional dispatch)
```

No root install, no matrix-of-all-modules, no `./scripts/module` orchestrator.

## 1. Reusable workflow (`module-ci.yml`)

Called by per-module callers. Responsibilities:

| Step | Behavior |
| --- | --- |
| checkout | `actions/checkout` only |
| setup | switch on `setup`: `node` → setup-node; `swift` → setup-swift; `none` → skip |
| run | `cd modules/<module>` then run `command` (default `./scripts/ci.sh`) |

**Hard rules**

- Never `npm i` / `swift build` at repo root.
- Never discover sibling modules.
- Fail if `modules/<module>/scripts/ci.sh` (or override command) is missing — that is a module contract bug, not a CI orchestration bug.

Annotated sketch (see also `ci-TEMPLATE-snippets/module-ci.yml`):

```yaml
# .github/workflows/module-ci.yml
name: module-ci (reusable)

on:
  workflow_call:
    inputs:
      module:
        description: Directory name under modules/
        required: true
        type: string
      setup:
        description: Toolchain setup — node | swift | none
        required: false
        type: string
        default: none
      command:
        description: Verify entry relative to module root
        required: false
        type: string
        default: ./scripts/ci.sh
      node-version:
        required: false
        type: string
        default: "22"
      # Future: swift-version when setup=swift callers need pins

jobs:
  verify:
    runs-on: ubuntu-latest   # Swift modules may later use macos-*; caller can pass runner via extension later
    defaults:
      run:
        working-directory: modules/${{ inputs.module }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        if: inputs.setup == 'node'
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          # cache: do NOT use root lockfile; optional cache-dependency-path under module later

      - name: Setup Swift
        if: inputs.setup == 'swift'
        # Placeholder — devops picks concrete action in Phase 1 (e.g. swift-actions/setup-swift)
        run: echo "TODO: install Swift toolchain for modules/${{ inputs.module }}"

      - name: Module verify
        run: |
          set -euo pipefail
          test -x "${{ inputs.command }}" || test -f "${{ inputs.command }}"
          ${{ inputs.command }}
```

**Polyglot note:** `setup` is an input, not a root matrix. Node modules pass `setup: node`; Swift modules pass `setup: swift` (and may need `runs-on: macos-14` — extend reusable workflow with a `runner` input in Phase 1 if needed). Language choice stays inside the module; CI only boots the toolchain the caller declares.

## 2. Path-filtered caller + gate job

One file per shipped module. Example for a future `modules/hello-cli/` (not created this wave):

```yaml
# .github/workflows/ci-hello-cli.yml  (example — see module-caller.example.yml)
name: ci-hello-cli

on:
  pull_request:
    paths:
      - "modules/hello-cli/**"
      - ".github/workflows/ci-hello-cli.yml"
      - ".github/workflows/module-ci.yml"
  push:
    branches: [main]
    paths:
      - "modules/hello-cli/**"
      - ".github/workflows/ci-hello-cli.yml"
      - ".github/workflows/module-ci.yml"
  workflow_dispatch: {}

jobs:
  # --- Pattern: always-green required check name = "gate" ---
  changes:
    runs-on: ubuntu-latest
    outputs:
      run_ci: ${{ steps.filter.outputs.module }}
    steps:
      - uses: actions/checkout@v4
      - id: filter
        uses: dorny/paths-filter@v3
        with:
          filters: |
            module:
              - 'modules/hello-cli/**'
              - '.github/workflows/ci-hello-cli.yml'
              - '.github/workflows/module-ci.yml'

  verify:
    needs: changes
    if: needs.changes.outputs.run_ci == 'true'
    uses: ./.github/workflows/module-ci.yml
    with:
      module: hello-cli
      setup: node          # or swift | none
      command: ./scripts/ci.sh

  # Required check in branch protection: "ci-hello-cli / gate"
  gate:
    needs: [changes, verify]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Enforce module gate
        run: |
          set -euo pipefail
          if [[ "${{ needs.changes.outputs.run_ci }}" != "true" ]]; then
            echo "Paths outside hello-cli — gate green (no-op)"
            exit 0
          fi
          result="${{ needs.verify.result }}"
          if [[ "$result" == "success" ]]; then
            exit 0
          fi
          echo "verify job result=$result"
          exit 1
```

### Why the gate job

GitHub required checks fail a PR when the named check **never runs**. Path filters on `on.pull_request.paths` mean untouched-module workflows are skipped → missing required check → red PR.

**Two layers (intentional):**

1. **Workflow-level `paths:`** — skip the whole workflow when clearly irrelevant (saves Actions minutes; quieter checks list).
2. **In-workflow `changes` + `gate`** — still needed when the workflow *does* run because of shared reusable workflow edits, or when branch protection requires a stable job name. Also covers `workflow_dispatch`.

**This wave / no modules yet:** do **not** register per-module gates in branch protection. Only `repo-meta` is required. When the first real module lands, add its caller + require `ci-<module> / gate`.

### Path-filter nuance for empty-modules wave

If GitHub path filters alone skip callers that do not exist, there is nothing to protect. Prefer:

- Ship reusable + `repo-meta` first.
- Add `ci-<module>.yml` in the **same PR** that introduces `modules/<name>/` (devops + dev coordination).

## 3. Root-meta workflow (`repo-meta.yml`)

Runs on docs / template / CI-definition changes. **Parse/lint only** — never builds modules.

Triggers (sketch):

```text
AGENTS.md
CONSUMER_CONTEXT.md
README.md
LICENSE
.gitignore
docs/**
templates/**
.github/**
scripts/changed-modules.sh   # if present
```

Jobs (minimal Phase 1):

| Job | Purpose |
| --- | --- |
| `meta` | YAML syntax check on `.github/workflows/*.yml`; optional markdown link smoke; `test -d templates/module` once scaffold lands |
| `gate` | Always-green required name `repo-meta / gate` wrapping `meta` |

Does **not**:

- Enumerate `modules/*`
- Run any `scripts/ci.sh`
- Install Node/Swift at root

## 4. What CI runs on **this wave’s PR** (no product modules)

Wave scope: `templates/**`, root context docs, `.github/**` sketches — **no** `modules/<product>/`.

| Change set | Workflows expected |
| --- | --- |
| `templates/**`, `README.md`, `AGENTS.md`, `CONSUMER_CONTEXT.md` | `repo-meta` only |
| `.github/workflows/module-ci.yml`, `repo-meta.yml` | `repo-meta` only |
| Example caller checked in as **inactive template** under `templates/` or docs only | still `repo-meta` |
| Accidental `modules/foo/` | Should not happen this wave; if it does, add caller in same PR or leave unprotected until caller lands |

**Green path for template-only PR**

1. Enable `repo-meta.yml` (Phase 1 devops).
2. Branch protection requires only `repo-meta / gate` (or the single `meta` job if no gate wrapper yet).
3. Snap locally: `test -f .github/workflows/module-ci.yml && test -f .github/workflows/repo-meta.yml` — no module matrix.

## 5. Optional helper (not a runner)

`scripts/changed-modules.sh` may list changed `modules/*` dirs for humans/agents. It must **not** be invoked by CI to orchestrate builds. Prototype A does not depend on it.

## 6. Pros / cons (vs B)

| | A — reusable + callers | B — single dispatch |
| --- | --- | --- |
| Independence | Strong — each module owns its caller + setup inputs | Weaker — central path→module map |
| Required checks | Stable per-module gate names | One mega-gate or dynamic names (harder) |
| Polyglot | Per-caller `setup` / future `runner` | Matrix must encode setup per module |
| Boilerplate | One thin YAML per module | Less YAML, more workflow logic |
| Empty repo | Trivial — only repo-meta | Still need empty-matrix handling |

## 7. Interaction with module-layout prototypes

CI seam assumes **verify entry** = `modules/<name>/scripts/ci.sh` and path root = `modules/<name>/**`.

| Layout prototype (sibling) | CI coupling |
| --- | --- |
| **A** — flat `modules/<name>/` + `scripts/ci.sh` | Direct match; callers copy-paste |
| **B** — same tree + language stubs (`package.json` / `Package.swift`) | Same callers; only `setup:` differs |
| **C** — nested packages or alt verify path | Requires caller `command:` override or layout rejected for this plan |

If layout C moves verify away from `scripts/ci.sh`, update Work Contract before devops implements.
