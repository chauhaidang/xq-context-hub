# Agent Instructions

`xq-context-hub` is the org-level AI context home for `chauhaidang` / XQ.
It holds the org map, shared conventions, domain glossaries, and portable
skills/rules. It is **not** a product application codebase.

## Startup Workflow

Before answering org/architecture questions or writing context docs:

1. Confirm working directory with `pwd`
2. Read this file completely
3. Read [`CONTEXT-MAP.md`](CONTEXT-MAP.md) and select the relevant domain row
4. Read only that domain’s `domains/<area>/CONTEXT.md` (plus
   [`org/conventions.md`](org/conventions.md) when the task involves coding
   standards or package naming)
5. Restate Situation, Task, Action, and expected Result before edits

Do **not** preload every file under `org/` or `domains/` unless the task
explicitly spans the whole organization.

## Working Rules

- **Map first**: Always resolve area → domain via `CONTEXT-MAP.md` before deep
  reading
- **Targeted loading**: Open only the domain and org files needed for the task
- **Vocabulary**: Use terms from the relevant `CONTEXT.md` glossary; avoid
  synonyms the glossary rejects
- **Minimal diffs**: Match existing doc tone and structure; do not rewrite
  unrelated domains
- **No secrets in git**: Never commit tokens, `.env` contents, or credentials
- **Commits and pushes**: Only when the user asks

## Where things live

| Need | Location |
| --- | --- |
| Org overview | [`org/overview.md`](org/overview.md) |
| Repo catalogue | [`org/catalogue.md`](org/catalogue.md) |
| Shared conventions | [`org/conventions.md`](org/conventions.md) |
| Domain glossaries | [`domains/*/CONTEXT.md`](domains/) |
| Navigate this hub | skill `use-context-hub` |
| Add a new domain | skill `add-domain-context` |
| Engineering workflows (grill, wayfinder, triage, …) | `xq-harness` `.agents/skills/` |

## Definition of Done

Work is done only when all of the following are true:

- [ ] Target context or skill change is written
- [ ] `CONTEXT-MAP.md` updated if a new domain or major repo mapping was added
- [ ] Glossary terms stay consistent with related domain files
- [ ] Known gaps (missing repos, unclear ownership) are called out in the change
  or in the reply

## Escalation

- **Unknown product area**: check `org/catalogue.md`, then ask which domain to
  create or extend
- **Conflict with a product repo’s local `CONTEXT.md`**: prefer the product
  repo for implementation detail; update this hub only for org-wide vocabulary
- **Workflow / ticket / PRD process**: use `xq-harness` agent docs and skills,
  not this hub
