# Project Agent Team

The **root agent** owns orchestration, user approvals, commits/pushes, and the
consolidated reply. Prefer subagents so the root stays thin and fast.

## Roles

| Agent | File | Owns |
| --- | --- | --- |
| `requirement-triage` | [agents/requirement-triage.md](agents/requirement-triage.md) | Intake, classify, grill, labels, briefs |
| `product-lead` | [agents/product-lead.md](agents/product-lead.md) | Plan, Work Contracts, progress, snap |
| `engineer-in-design` | [agents/engineer-in-design.md](agents/engineer-in-design.md) | Contracts / seams (before wave) |
| `engineer-in-dev` | [agents/engineer-in-dev.md](agents/engineer-in-dev.md) | App code slice (parallel wave) |
| `engineer-in-test` | [agents/engineer-in-test.md](agents/engineer-in-test.md) | Test slice (parallel wave) |
| `engineer-in-devops` | [agents/engineer-in-devops.md](agents/engineer-in-devops.md) | CI/hooks slice (parallel wave) |
| `engineer-in-review` | [agents/engineer-in-review.md](agents/engineer-in-review.md) | Post-snap review |

Parallel same-branch model: [`docs/agents/parallel-wave.md`](../docs/agents/parallel-wave.md).

## Sequencing (fast path)

1. `requirement-triage` if new/unclear.
2. `product-lead` → plan + **Work Contract** (branch, ownership, acceptance).
3. Optional: `engineer-in-design` to finish the contract.
4. **Parallel wave** on that contract’s branch: `dev` + `test` + `devops`.
5. **Snap** — product-lead/root runs snap commands; integrate if needed.
6. `engineer-in-review` → then one PR per repo (user-approved).
7. `product-lead` syncs hub issue checklist; root consolidates.

## Delegation contract

Every engineer Task must include:

- `role`, `repo`, `checkout`, `work_package`
- `branch` + `contract` pointer (required for `dev`/`test`/`devops`)
- `remote_writes` (default **no**; wave does not open the delivery PR)
- Expected output

Subagents must not spawn descendants. Root coordinates the parallel wave and snap.
