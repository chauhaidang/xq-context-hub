# Consumer context on linked repos

Every repository listed in [`org/links.yaml`](../../org/links.yaml) (currently
`xq-harness` and `xq-versastack`) must expose **hub-readable context** so agents
in `xq-context-hub` know what that checkout is after sync.

## Accepted files (any one is enough)

| File | Meaning |
| --- | --- |
| `CONSUMER_CONTEXT.md` | Preferred — hub-facing identity, boundary, verify commands |
| `AGENTS.md` | Accepted — in-repo agent entrypoint |
| `AGENT.md` | Accepted alias (legacy spelling) |

Audit passes if **at least one** of these exists on the repo’s default branch.

## Prefer `CONSUMER_CONTEXT.md`

Use it when the repo has no agent entrypoint yet, or when hub consumers need a
short surface without loading a full `AGENTS.md`. Template:
[`templates/CONSUMER_CONTEXT.md`](../../templates/CONSUMER_CONTEXT.md).

## Scripts

```bash
./scripts/audit-consumer-context.sh          # report ok / missing
./scripts/ensure-consumer-context.sh         # dry-run: show who needs a file
./scripts/ensure-consumer-context.sh --apply # open PRs adding CONSUMER_CONTEXT.md
./scripts/ensure-consumer-context.sh --apply --repo xq-versastack
```

## Engineer loading order

In `checkouts/<repo>/`, load first existing:

1. `CONSUMER_CONTEXT.md`
2. `AGENTS.md`
3. `AGENT.md`
