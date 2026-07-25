# Engineer-in-\<role\> agents

```text
engineer-in-<role>   →   .cursor/agents/engineer-in-<role>.md
```

## Roster

| Subagent | Role | Wave | Primary harness skills |
| --- | --- | --- | --- |
| `engineer-in-design` | `design` | Before wave | `codebase-design`, `design-an-interface`, `prototype` |
| `engineer-in-dev` | `dev` | **Parallel** same branch | `implement`, `tdd`, `diagnosing-bugs` |
| `engineer-in-test` | `test` | **Parallel** same branch | `tdd`, `qa` (evidence) |
| `engineer-in-devops` | `devops` | **Parallel** same branch | conflicts, pre-commit, CI files |
| `engineer-in-review` | `review` | After **snap** | `code-review`, `review` |

Shared playbook: [`.agents/skills/engineer-in/SKILL.md`](../../.agents/skills/engineer-in/SKILL.md).  
Parallel model: [`parallel-wave.md`](parallel-wave.md).

## Default way of work (one repo)

1. Contract (product-lead ± design)
2. **Parallel:** dev + test + devops on **one branch**
3. **Snap** all slices → green
4. review → one PR

Do not serialize test-after-dev by default when a contract exists — that is the
bottleneck this model removes.

## Task shape (wave)

```text
role: dev
repo: xq-fitness-write
checkout: checkouts/xq-fitness-write
branch: feat/export-workouts
contract: plans/001-…/PLAN.md#work-contract-write
work_package: WP1 — commands
plan: plans/001-…/PLAN.md
hub_issue: chauhaidang/xq-context-hub#12
remote_writes: no
```

## Related

- [`.cursor/TEAM.md`](../../.cursor/TEAM.md)
- [`requirement-fanout.md`](requirement-fanout.md)
