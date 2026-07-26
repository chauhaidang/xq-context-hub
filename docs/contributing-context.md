# Contributing context

How to extend `xq-context-hub` without turning it into a dump of every product
doc.

## Principles

1. **Org-scoped** — prefer vocabulary, ownership, and maps over implementation
   tutorials
2. **Map first** — every new domain must appear in `CONTEXT-MAP.md`
3. **Lean glossaries** — define preferred terms and rejected synonyms; deep ADRs
   stay in product repos
4. **Targeted loading** — write so an agent can open one domain file and stop

## Add a domain

Use the `add-domain-context` skill, or:

1. Create `domains/<area>/CONTEXT.md` (Purpose, Boundary, Glossary, Related
   repos, Notes)
2. Add a row to `CONTEXT-MAP.md`
3. Update `org/catalogue.md` for any new or reclassified repos

## Update the catalogue

When a repo is created, renamed, or its role changes:

1. Edit `org/catalogue.md` (one-line role)
2. If the hub should **checkout** it, add it to `org/links.yaml` (url, domain,
   default_branch) — keep the active set intentional (today: harness + versastack)
3. If it belongs to a domain, update that domain’s Related repos table
4. If it deserves a new domain, follow “Add a domain”

## Checkouts

- Local clones belong only under `checkouts/<repo>/`
- `.gitignore` ignores `checkouts/*` except `checkouts/README.md`
- Do not add product source trees to git; sync with `./scripts/sync-repos.sh`
- Keep `checkout_root` in `org/links.yaml` aligned with the real folder name

## Update conventions

Change `org/conventions.md` only for rules that apply across products (package
scope, secrets, commit etiquette). Product-local build/test commands belong in
that product’s `AGENTS.md`.

## Multi-repo plans

- New cross-repo requirements live under `plans/<NNN>-<slug>/` (see
  [`plans/README.md`](../plans/README.md))
- Intake via `requirement-triage`; plan/progress via `product-lead`; code via
  `engineer-in-<role>` (see `docs/agents/engineers.md`); do not grow root
  `AGENTS.md`
- Team roster: [`.cursor/TEAM.md`](../.cursor/TEAM.md)
- Process: [`docs/agents/requirement-fanout.md`](agents/requirement-fanout.md)

## Skills and rules

- Portable skills live under `.agents/skills/<name>/SKILL.md`
- Cursor always-on guidance for this repo lives under `.cursor/rules/`
- Do **not** copy Matt Pocock / harness engineering skills here — link to
  `checkouts/xq-harness` after sync

## Consumption from other repos

Other XQ repos should point at this hub with a short `AGENTS.md` blurb (see
root `README.md`). Hub-driven edits happen under `checkouts/` and fan out as
per-repo PRs tracked by hub plans + issues.

## Review checklist

- [ ] Diff is limited to the domains/org/plans/docs files that changed
- [ ] New terms do not contradict an existing glossary without calling it out
- [ ] No secrets or environment-specific hostnames required to understand the
      docs
- [ ] `CONTEXT-MAP.md` still routes correctly
- [ ] No product clone contents under `checkouts/` are staged for commit
- [ ] New plans include `PLAN.md` and a linked hub issue with a per-repo
      checklist (no `PROGRESS.md`)
