---
name: fan-out-requirement
description: >-
  Plan and fan out a multi-repo requirement from xq-context-hub. Use when a new
  requirement spans linked product repos, needs a hub plan folder and umbrella
  issue, or should open one PR per target repo under checkouts/ via
  engineer-in-<role> agents (dev|test|design|review|devops).
---

# Fan-out Requirement

Prefer the subagent path: `requirement-triage` → `product-lead` → parallel
`engineer-in-<role>`. Use this skill only for a serial root-driven walkthrough.

## When to use

- Requirement touches more than one repo in `org/links.yaml`
- User asks to plan then implement across fitness / harness / platform repos
- Need a durable plan + GitHub issue tracker before coding

## Hard rules

- One PR per product repo
- Work only under `checkouts/<repo>/` for product code via `engineer-in-<role>`
- Never commit `checkouts/*` into the hub (except tracked README)
- Push, open PRs, merge, or close issues only when the user asks
- Skip `./scripts/sync-repos.sh` for a repo that is dirty or not on its default
  branch if an agent is already working there
- Progress lives on the hub **GitHub issue** — do not create `PROGRESS.md`
- No generic fan-out worker

## Steps

### 1. Orient

1. Read hub [`AGENTS.md`](../../../AGENTS.md) and
   [`docs/agents/requirement-fanout.md`](../../../docs/agents/requirement-fanout.md).
2. Resolve domains via [`CONTEXT-MAP.md`](../../../CONTEXT-MAP.md); load only
   needed `domains/*/CONTEXT.md`.
3. If the requirement is fuzzy, sync harness and use its clarification skills
   (`grill-with-docs` / `wayfinder`), then return here.

### 2. Create the plan folder

1. Pick next `NNN` per [`plans/README.md`](../../../plans/README.md).
2. Copy template:

```bash
N=001
SLUG=short-name
mkdir -p "plans/${N}-${SLUG}"
cp plans/_templates/PLAN.md "plans/${N}-${SLUG}/PLAN.md"
```

3. Fill `PLAN.md` (goal, non-goals, ordered target repos from
   [`org/links.yaml`](../../../org/links.yaml), acceptance, work packages).

### 3. Open the umbrella issue (ask first)

When the user agrees:

```bash
gh issue create --repo chauhaidang/xq-context-hub \
  --title "<requirement title>" \
  --body "$(cat <<'EOF'
## Plan

`plans/<NNN>-<slug>/PLAN.md`

## Checklist

- [ ] <repo-1>: <work summary>
- [ ] <repo-2>: <work summary>

EOF
)"
```

Add label `ready-for-agent` when fully specified. Write the issue URL/number
into `PLAN.md`.

### 4. Execute via engineers (plan order)

For each work package, prefer spawning `engineer-in-<role>` (see
[`docs/agents/engineers.md`](../../../docs/agents/engineers.md)) with
`{role, repo, checkout, work_package, plan, hub_issue, remote_writes}`.

If running serially in-root instead: sync → branch → apply skill → verify →
PR (ask first) → comment on hub issue.

### 5. Finish

- Prefer subagent `product-lead` after PRs merge or stall — syncs the **issue**
  checklist.
- Close the hub issue only when the user asks and all checklist items are done
  or explicitly wontfix.
- Commit hub `PLAN.md` updates only when the user asks.

## Do not

- Open one PR that claims to cover multiple repos
- Clone outside `checkouts/`
- Fast-forward over a dirty agent checkout
- Create or update `PROGRESS.md`
- Use a generic fan-out worker
