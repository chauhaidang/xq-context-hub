# Requirement fan-out

## Source of truth

| Concern | Where |
| --- | --- |
| Spec | `plans/<NNN>-<slug>/PLAN.md` (incl. Before/After, Test approach, Test coverage) |
| Work Contract | Plan section or hub issue (branch, ownership, acceptance) |
| Progress | Hub GitHub Issue checklist |
| Code | `checkouts/<repo>/` on the contract branch |
| Evidence | TSR (`**/tsr/` or plan equivalent) + one PR per repo after snap + review |

## Lifecycle

1. **Triage** — `requirement-triage`
2. **Plan + contracts** — `product-lead` (± `engineer-in-design`)
3. **Parallel wave** — `dev` + `test` + `devops` same branch ([`parallel-wave.md`](parallel-wave.md))
4. **Snap** — integrate slices; run snap commands
5. **Review** — `engineer-in-review` (contract + acceptance + **TSR**)
6. **Deliver** — one PR per repo (user-approved); update issue checklist

## Hard rules

- One delivery PR per product repo (after snap)
- Wave roles share a branch; respect file ownership in the contract
- Never commit `checkouts/*` into the hub (except README)
- No `PROGRESS.md`
- Engineers do not nest subagents

## Subagents

| Phase | Subagent |
| --- | --- |
| Intake | `requirement-triage` |
| Plan / contract / snap / progress | `product-lead` |
| Pre-wave | `engineer-in-design` |
| Parallel wave | `engineer-in-dev`, `engineer-in-test`, `engineer-in-devops` |
| Post-snap | `engineer-in-review` |
