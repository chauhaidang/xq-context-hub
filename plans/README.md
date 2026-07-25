# Plans

Versioned multi-repo requirement specs owned by this hub.

**Progress** is tracked on the umbrella **GitHub issue** (checklist + comments),
not in a `PROGRESS.md` file.

## Naming

```text
plans/<NNN>-<slug>/
  PLAN.md
```

- `NNN` — zero-padded sequence (`001`, `002`, …). Next number = highest existing
  + 1 (ignore `_templates/`).
- `slug` — lowercase kebab-case short name (`add-fitness-export`).

Example: `plans/001-add-fitness-export/`.

## Templates

```bash
N=001
SLUG=add-fitness-export
mkdir -p "plans/${N}-${SLUG}"
cp plans/_templates/PLAN.md "plans/${N}-${SLUG}/PLAN.md"
```

Fill `PLAN.md`, then open a hub GitHub Issue that links
`plans/${N}-${SLUG}/PLAN.md` and holds the per-repo checklist.

## When to open an issue

Open an umbrella issue on `xq-context-hub` when the plan has:

- Clear goal and non-goals
- At least one target repo from `org/links.yaml`
- Acceptance criteria

Put a markdown checklist on the issue (one line per target repo). Update that
checklist as PRs open/merge. Label `ready-for-agent` when an agent can execute
without further clarifying questions.

## Agent entrypoints

- Intake / labels: subagent `requirement-triage`
- Plan + issue progress: subagent `product-lead`
- Parallel wave: [`docs/agents/parallel-wave.md`](../docs/agents/parallel-wave.md)
- Team roster: [`.cursor/TEAM.md`](../.cursor/TEAM.md)
- Process doc: [`docs/agents/requirement-fanout.md`](../docs/agents/requirement-fanout.md)
