# Plan: <title>

- **ID**: `<NNN>-<slug>`
- **Hub issue**: _(progress tracker)_
- **Domains**: _(from CONTEXT-MAP.md)_
- **Status**: drafting | ready | in_progress | done

## Goal

One paragraph: what success looks like.

## Non-goals

- …

## Target repos

| Order | Repo | Branch | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | | feat/… | dev+test+devops | |
| 2 | | feat/… | dev+test+devops | |

## Acceptance criteria

- [ ] …
- [ ] …

## Work Contract — <repo>

<!-- Repeat per repo. Required before parallel wave. -->

**Branch:** `feat/<slug>`  
**Goal:** …

### Interfaces / seams

- …

### File ownership

| Role | Owns (paths / globs) | Must not touch |
| --- | --- | --- |
| dev | | |
| test | | |
| devops | | |

### Acceptance

- [ ] …

### Snap commands

```bash
# e.g. npm test / make ci
```

## Work packages

### WP0 — contract (optional design)

- **Role**: design
- **Engineer**: `engineer-in-design`
- **Done when**: Work Contract above is complete

### Parallel wave — same branch

| Role | Engineer | Package | Ownership |
| --- | --- | --- | --- |
| dev | `engineer-in-dev` | | |
| test | `engineer-in-test` | | |
| devops | `engineer-in-devops` | | |

### After snap

| Role | Engineer | Package |
| --- | --- | --- |
| review | `engineer-in-review` | review branch → one PR |

## Notes / decisions

- …

## Links

- Hub issue: _
- Domain context: _
