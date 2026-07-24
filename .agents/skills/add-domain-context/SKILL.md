---
name: add-domain-context
description: >-
  Add or extend a domain CONTEXT.md in xq-context-hub. Use when introducing a
  new product area, promoting repos out of the “not first-class” list, or
  expanding an existing domain glossary and related-repo table.
---

# Add Domain Context

## When to use

- A product area repeatedly needs glossary terms not covered by fitness,
  harness, or platform
- Repos listed under “Related but not first-class” in `CONTEXT-MAP.md` deserve
  their own domain
- An existing `domains/*/CONTEXT.md` needs new terms or related repos

## Steps

1. Confirm the domain name (lowercase kebab folder, e.g. `qa`, `mobile`).
2. Create or update `domains/<area>/CONTEXT.md` with:
   - **Purpose** — one short paragraph
   - **Boundary** — owns / does not own
   - **Glossary** — preferred terms and rejected synonyms
   - **Related repos** — table of repo → role
   - **Notes for agents** — loading and conflict rules
3. Add or update a row in [`CONTEXT-MAP.md`](../../../CONTEXT-MAP.md).
4. Ensure repos appear in [`org/catalogue.md`](../../../org/catalogue.md) with
   accurate one-line roles.
5. Keep vocabulary lean — prefer pointing to product-repo `CONTEXT.md` for deep
   implementation detail.
6. Do not invent ADRs here; record only org-scoped language and ownership.

## Template

```markdown
# <Area> domain context

## Purpose

…

## Boundary

… owns:

- …

… does not own:

- …

## Glossary

### Term

Definition. Prefer **Term**, not *rejected synonym*.

## Related repos

| Repo | Role in this domain |
| --- | --- |
| `…` | … |

## Notes for agents

- …
```

## Done when

- [ ] `domains/<area>/CONTEXT.md` exists and matches the template sections
- [ ] `CONTEXT-MAP.md` routes to it
- [ ] Catalogue entries exist for listed repos
- [ ] No secrets or speculative product claims without a source repo
