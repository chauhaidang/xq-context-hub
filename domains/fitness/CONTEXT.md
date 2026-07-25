# Fitness domain context

## Purpose

Fitness is an XQ product area with CQRS-style services and client apps.
Callers and agents should treat write, read, persistence, and gate-keeping as
separate boundaries unless a task explicitly spans them.

## Boundary

Fitness owns:

- write-side command handling (`xq-fitness-write`)
- read-side queries / projections (`xq-fitness-read`)
- fitness persistence (`xq-fitness-db`)
- access / gate decisions at the fitness edge (`xq-fitness-gate-keeper`)
- fitness-facing application and mobile clients (`xq-fitness-app`,
  `xq-mobile-app`, `xq-android-app` when used for fitness)

Fitness does not own:

- shared platform runtime or contracts (see platform domain)
- harness test libraries or stub servers (see harness domain)
- org-wide package naming rules (see `org/conventions.md`)

## Glossary

### Write side

The command / mutation path for fitness state. Prefer **write side** or
`xq-fitness-write`, not *backend* alone when the distinction matters.

### Read side

The query / projection path for fitness state. Prefer **read side** or
`xq-fitness-read`.

### Gate keeper

The fitness access boundary that admits or rejects calls before deeper
services. Prefer **gate keeper** / `xq-fitness-gate-keeper`, not *auth service*
unless the product repo’s own docs use that term.

### Fitness DB

Persistence for fitness data (`xq-fitness-db`). Prefer **fitness DB**, not
*the database*, when multiple DBs exist in a workspace.

### Fitness app

Application surface for fitness users (`xq-fitness-app`). Mobile clients may
sit in separate repos; name the repo explicitly when the task is client-only.

## Related repos

| Repo | Role in this domain |
| --- | --- |
| `xq-fitness-app` | App surface |
| `xq-fitness-write` | Write side |
| `xq-fitness-read` | Read side |
| `xq-fitness-db` | Persistence |
| `xq-fitness-gate-keeper` | Gate / access |
| `xq-mobile-app` | Mobile client |
| `xq-android-app` | Android client |

## Notes for agents

- Prefer opening the specific service repo for the task (write vs read vs gate)
  rather than assuming a single monolith
- Local `CONTEXT.md` / ADRs inside a fitness repo win for implementation detail
- Cross-cutting platform contracts belong in the platform domain
