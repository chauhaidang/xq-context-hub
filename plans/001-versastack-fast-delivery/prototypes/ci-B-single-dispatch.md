# Prototype B — Single dispatch workflow (path filters / detected modules)

**Status:** Phase 0 alternative sketch — not recommended for this wave (see [`ci-RECOMMENDATION.md`](ci-RECOMMENDATION.md)).  
**Constraint check:** Must still avoid a central monorepo *build* runner; this is CI dispatch only.

## Shape

```text
.github/workflows/
  ci.yml           # one workflow: detect changed modules → matrix → call steps or reusable job
  repo-meta.yml    # same root-meta idea as prototype A (can merge into ci.yml; keep separate preferred)
```

No per-module caller files. A single PR workflow decides which modules to verify.

## Sketch

```yaml
# .github/workflows/ci.yml  (illustrative — NOT copy-paste canonical)
name: ci

on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      module:
        description: Force one module (optional)
        required: false
        type: string

jobs:
  detect:
    runs-on: ubuntu-latest
    outputs:
      modules: ${{ steps.set.outputs.modules }}
      any: ${{ steps.set.outputs.any }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - id: set
        run: |
          set -euo pipefail
          # Option 1: dorny/paths-filter with a hand-maintained filter per module
          # Option 2: git diff → modules/* basenames (scripts/changed-modules.sh)
          # Option 3: workflow_dispatch input override
          #
          # Emit JSON array for matrix, e.g. ["hello-cli"] or []
          echo 'modules=[]' >> "$GITHUB_OUTPUT"
          echo 'any=false' >> "$GITHUB_OUTPUT"

  verify:
    needs: detect
    if: needs.detect.outputs.any == 'true'
    strategy:
      fail-fast: false
      matrix:
        module: ${{ fromJson(needs.detect.outputs.modules) }}
        # Problem: setup/toolchain is per-module — needs a second map:
        # include:
        #   - module: hello-cli
        #     setup: node
        #   - module: ios-act-cli
        #     setup: swift
        #     runner: macos-14
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: modules/${{ matrix.module }}
    steps:
      - uses: actions/checkout@v4
      # setup keyed off matrix.setup …
      - run: ./scripts/ci.sh

  gate:
    needs: [detect, verify]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Repo CI gate
        run: |
          set -euo pipefail
          if [[ "${{ needs.detect.outputs.any }}" != "true" ]]; then
            echo "No modules changed — gate green"
            exit 0
          fi
          [[ "${{ needs.verify.result }}" == "success" ]]
```

### Detection strategies

| Strategy | Pros | Cons |
| --- | --- | --- |
| Hand-maintained `paths-filter` map | Explicit, reviewable | New module = edit central workflow (collision with devops ownership) |
| `git diff` → `modules/*` | Auto-discovers dirs | Silent pick-up of broken/incomplete modules; still need setup map |
| Manifest (`modules.yaml`) | Clear registry | **Anti-pattern** for versastack — smells like harness runner |

## Pros vs Prototype A

| Dimension | B advantage |
| --- | --- |
| File count | One workflow instead of N callers |
| Adding a module | Might avoid a new YAML if using auto-detect |
| Single required check | One `ci / gate` name in branch protection |

## Cons vs Prototype A

| Dimension | B risk |
| --- | --- |
| Independence invariant | Central path→setup→runner map becomes a mini orchestrator |
| Polyglot | Matrix `include` must encode Node vs Swift (+ macOS runners) in one file |
| Ownership | Every new module touches the same `.github/workflows/ci.yml` → wave collisions |
| Required checks granularity | Cannot require “only hello-cli gate” without reintroducing per-module jobs |
| Empty / template-only PRs | Must carefully no-op when `modules/` absent — easy to get wrong |
| Plan alignment | Work Contract already specifies reusable + per-module caller |

## When B could be revisited

- Many tiny modules with identical `setup: none` and Linux-only runners.
- Org later accepts a thin detect script **without** a build orchestrator — still prefer reusable `module-ci.yml` underneath.

For Phase 0 → Phase 1 of this plan: **prefer A**.
