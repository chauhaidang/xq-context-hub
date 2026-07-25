---
name: use-context-hub
description: >-
  Navigate xq-context-hub for chauhaidang / XQ org context. Use when the task
  needs org map, repo roles, domain glossary, or shared conventions; or when
  unsure which XQ product area a question belongs to.
---

# Use Context Hub

## When to use

- “What repos exist for X?”
- “What’s the glossary for fitness / harness / platform?”
- “What are org package naming rules?”
- Starting work that spans more than one XQ repo

## Steps

1. Read [`AGENTS.md`](../../../AGENTS.md) if not already loaded in this session.
2. Open [`CONTEXT-MAP.md`](../../../CONTEXT-MAP.md).
3. Select the single best row for the task.
4. Load only:
   - that domain’s `domains/<area>/CONTEXT.md`, and
   - [`org/conventions.md`](../../../org/conventions.md) if coding standards or
     package names matter, and
   - [`org/catalogue.md`](../../../org/catalogue.md) if you need a repo list, and
   - [`org/links.yaml`](../../../org/links.yaml) if you need clone URLs or paths.
5. For product code: run `./scripts/sync-repos.sh` (optionally `--domain` /
   `--repo`) and work under `checkouts/<repo>/` only.
6. Answer or plan using that vocabulary. Do not read sibling domains unless the
   task clearly crosses them.
7. If no domain fits, say so and either map via catalogue to the nearest domain
   or suggest the `add-domain-context` skill.

## Do not

- Preload every file under `org/` and `domains/`
- Clone linked repos outside `checkouts/`
- Commit anything under `checkouts/` except the tracked README
- Duplicate engineering workflow skills from `xq-harness` into this hub
- Treat catalogue one-liners as authoritative architecture ADRs
