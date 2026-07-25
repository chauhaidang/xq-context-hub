# Plan: <title>

- **ID**: `<NNN>-<slug>`
- **Hub issue**: _(progress tracker)_
- **Domains**: _(from CONTEXT-MAP.md)_
- **Status**: drafting | ready | in_progress | done

## Goal

One paragraph: what success looks like.

## Non-goals

- …

## Before / After

| Aspect | Before | After |
| --- | --- | --- |
| Behavior | … | … |
| Surfaces (API / CLI / UI / files) | … | … |
| Evidence | … | … |

## Test approach

- **Layers**: unit / component / integration / e2e / static (pick what applies)
- **Seams**: what test asserts against while/before dev lands (from Work Contract)
- **Fixtures / fakes**: …
- **Environments**: local snap vs CI / disposable runners
- **Out of scope for this plan**: …

## Test coverage

- [ ] Happy path: …
- [ ] Failure / negative: …
- [ ] Edge / boundary: …
- [ ] Regression for the Before behavior that must not return
- [ ] Evidence artifact: TSR (`**/tsr/` JUnit + markdown report) or equivalent snap proof

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
# Prefer commands that emit or refresh TSR under the module's tsr/ path when applicable
```

## Work packages

### WP0 — contract (optional design)

- **Role**: design
- **Engineer**: `engineer-in-design`
- **Done when**: Work Contract above is complete; Before/After + Test approach +
  Test coverage in this plan are filled enough for the parallel wave

### Parallel wave — same branch

| Role | Engineer | Package | Ownership |
| --- | --- | --- | --- |
| dev | `engineer-in-dev` | | |
| test | `engineer-in-test` | | |
| devops | `engineer-in-devops` | | |

### After snap

| Role | Engineer | Package |
| --- | --- | --- |
| review | `engineer-in-review` | review branch vs contract + acceptance; verify **TSR** (or snap-equivalent evidence) → one PR |

## Notes / decisions

- …

## Links

- Hub issue: _
- Domain context: _
