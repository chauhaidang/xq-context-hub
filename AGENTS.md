# Agent Instructions

`xq-context-hub` is the org-level AI context home for `chauhaidang` / XQ.
It is **not** a product application codebase.

## Startup

1. `pwd` — confirm you are in this hub
2. Read [`CONTEXT-MAP.md`](CONTEXT-MAP.md); load only the matching domain
   `CONTEXT.md` (and [`org/conventions.md`](org/conventions.md) if coding rules matter)
3. For who-does-what: read [`.cursor/TEAM.md`](.cursor/TEAM.md) and **delegate**
4. Restate Situation → Task → Action → Result before edits

Do not preload the whole hub. Do not paste long procedures into this file.

## Hard rules

- Product clones live only under `checkouts/<repo>/` ([`org/links.yaml`](org/links.yaml))
- Never commit `checkouts/*` (only `checkouts/README.md` is tracked)
- No secrets in git; commits / pushes / PRs only when the user asks
- One PR per product repo

## Delegate (do not inline)

| Work | Delegate to |
| --- | --- |
| Navigate map / glossary | skill `use-context-hub` |
| Add a domain | skill `add-domain-context` |
| Triage requirement / hub issue | subagent `requirement-triage` |
| Plan / contract / snap / issue progress | subagent `product-lead` |
| Parallel wave (same branch) | `engineer-in-dev` + `test` + `devops` |
| Post-snap review | `engineer-in-review` |

Way of work: [`docs/agents/parallel-wave.md`](docs/agents/parallel-wave.md).
