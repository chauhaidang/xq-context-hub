# Shared conventions — chauhaidang / XQ

Org-wide rules for coding agents. Product repos may add stricter local
`AGENTS.md` rules; when they conflict on implementation detail, prefer the
product repo. Prefer this file for package naming, secrets, and cross-repo
etiquette.

## Always

- Confirm working directory before destructive or wide-ranging commands
- Match existing patterns in the target repo; keep diffs minimal
- Use `@chauhaidang` for published packages; configure GitHub Packages auth via
  `NODE_AUTH_TOKEN` / `.npmrc` (never commit the token)
- Prefer **harness-lineage** package names (`@chauhaidang/xq-harness-*`) for new
  work from `xq-harness`
- Use domain glossary terms from this hub’s `domains/*/CONTEXT.md` (or the
  product’s local `CONTEXT.md` when present)
- Run the verification commands documented in the target repo before claiming
  done

## Ask first

- Commits, pushes, and pull requests
- Publishing packages or cutting releases
- Renaming public APIs, package scopes, or module registry entries
- Creating new org domains in this hub that invent product vocabulary

## Never

- Commit secrets, `.env` contents, private keys, or live tokens
- Confuse harness packages with legacy toolbox short names
- Dump this entire hub into context; load via `CONTEXT-MAP.md` only
- Silently override an existing ADR in a product repo

## Agent skills locations

| Kind | Where |
| --- | --- |
| Org / domain context skills | This repo: `.agents/skills/` |
| Engineering workflow skills | `xq-harness`: `.agents/skills/` (grill-with-docs, wayfinder, triage, …) |

## Commits and git

Follow the user’s git rules for the session. Default: do not commit or push
unless explicitly asked.
