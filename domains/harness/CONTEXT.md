# Harness / tooling domain context

## Purpose

Harness is the XQ testing and agent-tooling platform: publishable libraries,
module runners, stubs, MCP test servers, and related CLIs. New shared test
packages should come from the harness lineage unless a product repo documents
otherwise.

## Boundary

Harness owns:

- polyglot testing monorepo layout and module runner (`xq-harness`,
  `modules.yaml`, `./scripts/module`)
- published packages `@chauhaidang/xq-harness-*` on GitHub Packages
- engineering agent skills shipped with harness (`.agents/skills/`)
- test environment CLI (`xq-test-infra`)
- stub servers (`xq-stubby`, `xq-stub-server`)
- agent CLI toolbox (`xq-versastacks`)

Harness does not own:

- fitness product business logic (fitness domain)
- platform contracts / plugins as product APIs (platform domain)
- org map and domain glossaries (this hub)

## Glossary

### Harness lineage

Packages published as `@chauhaidang/xq-harness-*` from `xq-harness` (v0.1.0+).
Prefer this name over *toolbox packages* for new installs.

### Toolbox lineage

Legacy shorter `@chauhaidang/xq-*` packages from `xq-toolbox`. Still on the
registry as a separate line — do not treat them as interchangeable with
harness-lineage names.

### Module

A registered unit under `xq-harness` (`modules.yaml` + `modules/<name>/`).
Install, build, test, and CI go through `./scripts/module`.

### Catalogue

Consumer-facing package index for harness (`CATALOGUE.md` in `xq-harness`).
Use it to pick install targets.

### Stub server

Centralized or Camouflage-based HTTP stubbing (`xq-stubby`, `xq-stub-server`).
Prefer the concrete repo name in task plans.

## Related repos

| Repo | Role in this domain |
| --- | --- |
| `xq-harness` | Testing monorepo + harness packages + agent skills |
| `xq-versastacks` | CLI tools for AI agents |
| `xq-test-infra` | Spin up test environments |
| `xq-stubby` | Centralized stub server |
| `xq-stub-server` | Stub framework (Camouflage) |
| `xq-toolbox` | Legacy tools monorepo |
| `xq-e2e` | E2E tests (nearest: harness / QA) |
| `xq-services-test` | Services e2e |
| `grpc-mock` | gRPC mocks |

## Notes for agents

- For package choice, start at `xq-harness` `CATALOGUE.md`
- Engineering workflow skills stay in harness; do not duplicate them here
- When migrating from toolbox → harness, keep package rename ADR language
  (`harness-` prefix) explicit
