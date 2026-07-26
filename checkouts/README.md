# Temporary repo checkouts

Local clones of linked `chauhaidang` repositories live **here**.

```text
checkouts/<repo-name>/   # e.g. checkouts/xq-fitness-write/
```

## Rules

- This directory is the hub’s only checkout root for product repos
- Contents are **local-only** — gitignored except this README
- Never commit clones, worktrees, or build artifacts from under `checkouts/`
- Agents and scripts must resolve repos as `checkouts/<name>`, not sibling paths outside this hub

## Sync

```bash
./scripts/sync-repos.sh                 # all repos in org/links.yaml
./scripts/sync-repos.sh --domain fitness
./scripts/sync-repos.sh --repo xq-harness
```

See [`org/links.yaml`](../org/links.yaml) for the registry (`checkout_root` + remotes).

After sync, each checkout should contain `CONSUMER_CONTEXT.md`, `AGENTS.md`, or
`AGENT.md`. Audit with `./scripts/audit-consumer-context.sh`.
