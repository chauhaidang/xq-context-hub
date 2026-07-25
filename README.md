# xq-context-hub

Central **AI context home** for the `chauhaidang` / XQ organization.

This repo is a versioned knowledge base plus portable agent skills and Cursor
rules. Coding agents use it to learn org structure, product domains, and shared
conventions without loading every product repository.

## Who this is for

- **Humans** — orient on the org map and where domain context lives
- **Coding agents** — start at [`AGENTS.md`](AGENTS.md) and
  [`CONTEXT-MAP.md`](CONTEXT-MAP.md); load only the domain files needed for the
  task

## Layout

```text
AGENTS.md                 # agent entrypoint
CONTEXT-MAP.md            # route product/area → domain + repos
org/                      # overview, catalogue, conventions, links.yaml
domains/                  # per-domain CONTEXT.md glossaries
plans/                    # multi-repo specs (PLAN.md; progress on GitHub issues)
checkouts/                # local clones of linked repos (gitignored)
scripts/sync-repos.sh     # clone/update into checkouts/
.agents/skills/           # portable agent skills
.cursor/rules/            # Cursor rules for sessions in this hub
docs/                     # how to extend the hub
```

## Linked repo checkouts

Product repos are **not** git submodules. They clone into
[`checkouts/`](checkouts/README.md) (local-only; ignored by git except the
README):

```text
checkouts/xq-fitness-write/
checkouts/xq-harness/
…
```

Registry: [`org/links.yaml`](org/links.yaml) (`checkout_root: checkouts`).

```bash
./scripts/sync-repos.sh                 # all linked repos
./scripts/sync-repos.sh --domain fitness
./scripts/sync-repos.sh --repo xq-harness
```

Agents must implement and open PRs from paths under `checkouts/<repo>/`, never
from ad-hoc sibling directories outside this hub.

## Multi-repo requirements (subagents)

Root stays thin; specialists do the work ([`.cursor/TEAM.md`](.cursor/TEAM.md)):

1. **`requirement-triage`** — classify, grill, label
2. **`product-lead`** — plan, Work Contract, snap, issue progress
3. **Parallel wave** — `engineer-in-dev` + `test` + `devops` on **one branch**
4. **`engineer-in-review`** — after snap → one PR per repo

Process: [`docs/agents/parallel-wave.md`](docs/agents/parallel-wave.md).

## How agents should use this hub

1. Read [`AGENTS.md`](AGENTS.md)
2. Open [`CONTEXT-MAP.md`](CONTEXT-MAP.md) and pick the matching domain
3. Read that domain’s `CONTEXT.md` (and `org/conventions.md` when writing code)
4. For multi-repo work, follow the requirement fan-out process under `plans/`
5. Sync needed repos into `checkouts/` before editing product code
6. Do **not** preload the entire hub

Clarification skills (grill-with-docs, wayfinder, triage, etc.) live in
[`xq-harness`](https://github.com/chauhaidang/xq-harness) under `.agents/skills/`
(after sync: `checkouts/xq-harness/.agents/skills/`). This hub owns **org
context, domain glossaries, and multi-repo requirement fan-out**.

## How other repos consume this hub

In a product repo’s `AGENTS.md` (or Cursor rules), add a short pointer:

```markdown
## Org context

For chauhaidang / XQ org map, domains, and shared conventions, see
https://github.com/chauhaidang/xq-context-hub
(CONTEXT-MAP.md → domains/<area>/CONTEXT.md).
```

## Contributing

See [`docs/contributing-context.md`](docs/contributing-context.md).
