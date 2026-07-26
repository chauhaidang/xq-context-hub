# Consumer context — <repo-name>

Hub-facing context for agents working from
[`xq-context-hub`](https://github.com/chauhaidang/xq-context-hub).

This file is the **minimum** context surface the hub expects. Prefer this name
for hub consumers; `AGENTS.md` may also satisfy the hub audit when present.

## Identity

| Field | Value |
| --- | --- |
| Repo | `<repo-name>` |
| Org | `chauhaidang` |
| Domain | `fitness` \| `harness` \| `platform` |
| Default branch | `main` |
| Hub catalogue | see `xq-context-hub` `org/catalogue.md` |

## Purpose

One short paragraph: what this repository owns.

## Boundary

**Owns:**

- …

**Does not own:**

- …

## Stack

- Language / runtime: …
- Key frameworks: …
- Packages published (if any): …

## Agent entry

- Local agent instructions: `AGENTS.md` (if present)
- Domain glossary (hub): `xq-context-hub/domains/<domain>/CONTEXT.md`
- Org conventions (hub): `xq-context-hub/org/conventions.md`

## Verification

Commands agents should run before claiming done:

```bash
# e.g. npm test / make ci / ./scripts/module ci <name>
```

## Hub pointer

Multi-repo plans and fan-out are orchestrated from
https://github.com/chauhaidang/xq-context-hub  
(`CONTEXT-MAP.md` → `domains/<domain>/CONTEXT.md` → this checkout).
