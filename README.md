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
org/                      # org overview, repo catalogue, conventions
domains/                  # per-domain CONTEXT.md glossaries
.agents/skills/           # portable agent skills
.cursor/rules/            # Cursor rules for sessions in this hub
docs/                     # how to extend the hub
```

## How agents should use this hub

1. Read [`AGENTS.md`](AGENTS.md)
2. Open [`CONTEXT-MAP.md`](CONTEXT-MAP.md) and pick the matching domain
3. Read that domain’s `CONTEXT.md` (and `org/conventions.md` when writing code)
4. Do **not** preload the entire hub

Engineering workflow skills (grill-with-docs, wayfinder, triage, etc.) live in
[`xq-harness`](https://github.com/chauhaidang/xq-harness) under `.agents/skills/`.
This hub owns **org and domain context**, not those workflow skills.

## How other repos consume this hub

In a product repo’s `AGENTS.md` (or Cursor rules), add a short pointer:

```markdown
## Org context

For chauhaidang / XQ org map, domains, and shared conventions, see
https://github.com/chauhaidang/xq-context-hub
(CONTEXT-MAP.md → domains/<area>/CONTEXT.md).
```

There is no sync CLI in v1 — open this repo as a workspace or follow the
pointer when cross-repo context is needed.

## Contributing

See [`docs/contributing-context.md`](docs/contributing-context.md).
