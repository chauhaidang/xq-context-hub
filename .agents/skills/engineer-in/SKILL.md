---
name: engineer-in
description: >-
  Shared playbook for engineer-in-<role> subagents (dev, test, design, review,
  devops). Use when executing a product-lead work package in one
  checkouts/<repo>/ path, including parallel same-branch waves.
---

# Engineer-in-\<role\>

You are an **engineer** bound to one **role**. Product-lead assigns
`{role, repo, work_package, branch, contract}`.

Parallel model: [`docs/agents/parallel-wave.md`](../../../docs/agents/parallel-wave.md).

## Roles

| Role | Subagent | Wave |
| --- | --- | --- |
| `design` | `engineer-in-design` | Before wave (contracts) or solo |
| `dev` | `engineer-in-dev` | **Parallel wave** (same branch) |
| `test` | `engineer-in-test` | **Parallel wave** (same branch) |
| `devops` | `engineer-in-devops` | **Parallel wave** (same branch) |
| `review` | `engineer-in-review` | After **snap** |

## Task contract fields

| Field | Example |
| --- | --- |
| `role` | `dev` |
| `repo` | `xq-fitness-write` |
| `checkout` | `checkouts/xq-fitness-write` |
| `branch` | `feat/export-workouts` (required for wave roles) |
| `work_package` | WP1 — … |
| `plan` | `plans/001-…/PLAN.md` |
| `hub_issue` | `chauhaidang/xq-context-hub#12` |
| `contract` | pointer to Work Contract section |
| `remote_writes` | `yes` / `no` (default no; wave usually no PR until snap) |

## Steps

1. Read this skill + your role agent + the **Work Contract** (branch, ownership,
   acceptance).
2. Confirm checkout; sync only if safe. Check out / create **`branch`** from the
   task (shared by dev/test/devops).
3. Stay in ownership globs from the contract. Load product context in order:
   `CONSUMER_CONTEXT.md` → `AGENTS.md` → `AGENT.md` (first that exists).
4. Apply your role’s harness skills; minimal commits on **that branch only**.
5. Run role-relevant verification (full snap suite is product-lead/root after
   the wave unless the task says otherwise).
6. **Wave roles (`dev`/`test`/`devops`):** do **not** open the delivery PR;
   report slice complete. **Review:** after snap; run
   `.cursor/rules/secret-safe-review.mdc` on the branch diff; check **TSR** /
   plan evidence; PR comments if allowed.
7. Return: branch, files touched, commands, blockers, “ready for snap: yes/no”.

## Parallel wave rules

- Same repo + same branch as siblings named in the contract
- No force-push; no rewriting others’ commits unless asked
- If blocked by missing contract detail → stop and report; don’t invent APIs
- If you need a file outside ownership → stop and ask root (re-contract)

## Do not

- Cross product repos
- Own hub plan/triage
- Spawn nested subagents
- Create `PROGRESS.md`
- Open the delivery PR during the parallel wave
