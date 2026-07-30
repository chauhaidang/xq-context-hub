# Plan: Versastacks module test best practices

- **ID**: `003-versastacks-test-best-practices`
- **Hub issue**: https://github.com/chauhaidang/xq-context-hub/issues/12
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastacks` only
- **Status**: ready

## Goal

Give every `xq-versastacks` module a **clear, module-owned test bar**. **Unit + functional (e2e) is sufficient** for the required bar. Define what **TSR** evidence a PR / review must leave behind — without introducing a shared test runner, reusable CI framework, or cross-module orchestrator.

Success means: new modules and engineer-in-test waves can follow one documented contract; `xq-scout-kit` and `xq-ios-act-cli` either already meet unit+e2e or have explicit, closed gaps; hub review can judge evidence the same way across modules.

## Terminology

| Term in this plan | Meaning |
| --- | --- |
| **Unit** | In-process tests of library/helpers/contracts (mocks/fakes OK) |
| **Functional** | **E2E** — real shipped entrypoint through the real runtime the module claims to support (not mock transport as the only “functional” proof) |
| **E2E environment** | Module-chosen disposable runtime (e.g. iOS **Simulator** + DeviceKit for `xq-ios-act-cli`; real Scout install for scout-kit). Physical device / paid host auth is not a separate required tier if sim/local e2e covers the contract |

## Non-goals

- A root `./scripts/module`, matrix, or reusable `module-ci.yml`
- One language, framework, or required script name across modules
- A shared org-wide e2e harness (each module owns its e2e command and runner needs)
- Requiring a **physical** iOS device when Simulator e2e already proves the CLI contract
- Replacing or centralizing `xq-harness` test libraries
- Rewriting scout-kit’s suite into a copy-paste template that other modules must clone

## Before / After

| Aspect | Before | After |
| --- | --- | --- |
| Behavior | Modules verify independently; scout-kit has strong deterministic + some real-Scout paths; ios-act-cli is mostly **unit** (`swift test` + mocks), little/no DeviceKit e2e in CI; hub expects TSR but versastacks only documents commands + CI ownership | Explicit contract: required **unit + functional(e2e)**; each module documents and runs both; TSR names both layers |
| Surfaces | `docs/module-verification.md`, `docs/module-ci.md`, per-module tests/tsr, `ci-<name>.yml` | Add `docs/module-testing.md`; pointers from verification / CI / `AGENTS.md` / `modules/README.md`; module READMEs document unit cmd + e2e cmd + runner prerequisites |
| Evidence | Mixed richness; ios-act TSR is unit-shaped | TSR reports unit and e2e results (e2e may be skip-with-reason only when runner prerequisites are unavailable — must not claim pass) |

## Test approach

**Decision (locked):** **unit + functional is sufficient**, and **functional means e2e** (user clarification 2026-07-30).

- **Required layers:**
  1. **Unit** — in-process; fakes/mocks OK; fast; always on PR CI when the module’s toolchain can run
  2. **Functional (= e2e)** — run the **real CLI / skill entrypoint** against the **real dependency stack** the module ships for (happy path minimum; negative e2e when practical)
- **E2E expectations by module (intent):**
  - `xq-ios-act-cli`: e2e = `xq-ios-act` verbs with **DeviceKit up** on **Simulator** (install/start/status + at least one map/tap-style loop path). Physical device optional, not required by this plan.
  - `xq-scout-kit`: e2e = installed skill / real Scout path the module already models (`--real-scout` or equivalent documented command), not fakes-only as the sole functional proof
- **Mocks-only CLI process tests** are useful **unit/helpers**, not a substitute for the e2e bar
- **Static / contract** checks may sit inside unit or e2e suites; not a third mandatory tier
- **Seams**: README documents `unit` and `e2e` commands; CI invokes what the runner can support; TSR under `modules/<name>/tsr/`
- **Environments**: local snap runs unit + e2e when the host can; CI runs unit always and e2e when the workflow provides the runtime (macOS + sim for ios-act, etc.)
- **Out of scope for this plan**: shared e2e infra across modules; physical-device-only gates

## Test coverage

- [ ] Happy path: unit green for each shipped module
- [ ] Happy path: e2e green for each shipped module on a documented disposable runtime (or explicit blocker if CI cannot host it yet — tracked on the module README + issue)
- [ ] Failure / negative: unit and/or e2e negative coverage as appropriate to the entrypoint
- [ ] Regression: no shared runner / reusable module CI / root matrix
- [ ] Evidence artifact: TSR refreshes from documented commands; summary distinguishes **unit** vs **functional(e2e)**

## Target repos

| Order | Repo | Branch | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | `xq-versastacks` | `feat/versastacks-test-best-practices` | design (optional) → parallel `dev+test+devops` | Checkout: `checkouts/xq-versastacks` (local alias today: `checkouts/xq-versastack` → same remote). Only delivery unit. |

## Acceptance criteria

- [ ] `docs/module-testing.md` defines: **unit + functional(e2e) sufficient**; functional **= e2e**; mocks ≠ e2e; TSR fields; per-module CI ownership; anti-patterns (shared runner, calling mock-only tests “e2e”)
- [ ] `docs/module-verification.md` and `docs/module-ci.md` link to the testing contract
- [ ] Root pointers (`AGENTS.md`, `modules/README.md`, README / CONSUMER_CONTEXT as needed) mention the contract
- [ ] Both shipped modules audited for **unit + e2e**; gaps closed or explicitly waived with rationale + follow-up (primary gap: `xq-ios-act-cli` DeviceKit/Simulator e2e)
- [ ] Documented verify commands refresh TSR; path-scoped CI invokes unit always and e2e when runner supports it
- [ ] Hub issue checklist reflects wave → snap → review → one PR

## Work Contract — xq-versastacks

**Branch:** `feat/versastacks-test-best-practices`  
**Goal:** Land the module testing contract (**unit + functional(e2e)**) and bring shipped modules up to that bar without centralizing verification.

### Interfaces / seams

- **Contract doc**: `docs/module-testing.md` (new) — normative for agents and review; must state **functional = e2e**
- **Existing contracts**: `docs/module-verification.md`, `docs/module-ci.md` — keep command/CI ownership; testing doc owns unit vs e2e policy
- **Reference / gap:**
  - `xq-scout-kit` — strong unit/deterministic + emerging real-Scout e2e (`--real-scout`); align naming to unit vs functional(e2e) in TSR/docs
  - `xq-ios-act-cli` — unit exists; **add Simulator + DeviceKit e2e** (or README waiver + tracked follow-up if blocked on CI images)
- **E2E seam (CLI modules):** real binary + real DeviceKit (sim); not mock `Transport` alone
- **TSR minimum:**
  - `modules/<name>/tsr/summary.md` — pass/fail/skip counts, toolchain, commit/time, **unit vs functional(e2e)** coverage statement, per-case or per-suite table
  - `modules/<name>/tsr/junit.xml` (or named equivalent)
  - If e2e cannot run on a given host, **skip with reason** — never mark e2e pass when not executed
- **CI seam:** per-module `ci-<name>.yml` owns setup (incl. sim/DeviceKit prerequisites for e2e when enabled); no reusable module CI framework

### File ownership

| Role | Owns (paths / globs) | Must not touch |
| --- | --- | --- |
| design | Plan/contract refinements in hub only (if still needed) | Product code under `modules/**` |
| dev | `docs/module-testing.md`, pointer edits in `docs/module-verification.md`, `docs/module-ci.md`, `AGENTS.md`, `README.md`, `modules/README.md`, `CONSUMER_CONTEXT.md` (docs only) | Module test implementations; workflow YAML beyond doc cross-links |
| test | `modules/xq-scout-kit/tests/**`, `modules/xq-scout-kit/tsr/**`, `modules/xq-scout-kit/testbed/**`, `modules/xq-ios-act-cli/**/Tests/**`, `modules/xq-ios-act-cli/scripts/**`, `modules/xq-ios-act-cli/tsr/**`, module README testing sections — **incl. e2e scripts/cases** | Root CI framework; unrelated feature freelancing |
| devops | `.github/workflows/ci-xq-scout-kit.yml`, `.github/workflows/ci-xq-ios-act-cli.yml` — wire unit + e2e (or skip-with-reason); `docs/module-ci.md` evidence notes | Shared reusable workflow |

### Acceptance

- [ ] Testing contract merged on the feature branch and linked from verification + CI docs
- [ ] Audit notes: scout-kit vs ios-act-cli vs **unit + e2e** bar
- [ ] Gap fixes landed under test ownership **or** explicit README waiver per gap
- [ ] Snap commands below green (e2e skip-with-reason allowed only if documented as blocked)
- [ ] No new root runner / reusable module CI / matrix

### Snap commands

```bash
cd checkouts/xq-versastacks   # or checkouts/xq-versastack if that is the synced path

test -f docs/module-testing.md
rg -n 'module-testing|functional|e2e' docs/module-testing.md docs/module-verification.md docs/module-ci.md

# Unit (always)
cd modules/xq-scout-kit && bash tests/run-all.sh && test -s tsr/summary.md && test -s tsr/junit.xml
cd ../xq-ios-act-cli && bash scripts/run-swift.sh && test -s tsr/summary.md

# E2E — exact commands to be named in each module README by the wave
# (ios-act: Simulator + DeviceKit path; scout: documented real-Scout / e2e command)
```

## Work packages

### WP0 — contract (optional design)

- **Role**: design
- **Engineer**: `engineer-in-design`
- **Done when**: Work Contract above is complete enough for the parallel wave. **Waive WP0** if root accepts this plan as-is; spawn design only if e2e runtime choices (sim vs device, CI hosting) are disputed.

### Parallel wave — same branch (`feat/versastacks-test-best-practices`)

| Role | Engineer | Package | Ownership |
| --- | --- | --- | --- |
| dev | `engineer-in-dev` | WP1 — `docs/module-testing.md` stating functional=e2e + pointers | docs + root markdown pointers |
| test | `engineer-in-test` | WP2 — audit unit+e2e; add ios-act Simulator/DeviceKit e2e (or waive); align scout TSR naming; TSR | module tests / e2e scripts / tsr / README testing sections |
| devops | `engineer-in-devops` | WP3 — CI runs unit + e2e (or honest skip); runner prerequisites | per-module workflow YAML + `docs/module-ci.md` |

### After snap

| Role | Engineer | Package |
| --- | --- | --- |
| review | `engineer-in-review` | WP4 — review vs contract; **unit + e2e** evidence in TSR → one PR to `xq-versastacks` |

## Notes / decisions

- **Required bar (locked):** **unit + functional**, with **functional = e2e** (clarified 2026-07-30). Earlier “functional = CLI against fakes” interpretation is **withdrawn**.
- **Simulator is enough** for ios-act e2e unless the module README explicitly requires device.
- **Independence invariant:** each module owns CI/CD and its e2e command/runtime. Best practices are a **contract document**, not a shared implementation.
- **Hub checkout name:** `org/links.yaml` uses `xq-versastacks`; some machines still have `checkouts/xq-versastack` remoted to that repo — snap commands accept either path.
- Plan `002` merge-conflict markers resolved on this hub branch as hygiene (prefer `xq-versastacks` naming).

## Links

- Hub issue: https://github.com/chauhaidang/xq-context-hub/issues/12
- Domain context: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
- Related plans: [`001-versastack-fast-delivery`](../001-versastack-fast-delivery/PLAN.md), [`002-xq-ios-act-cli`](../002-xq-ios-act-cli/PLAN.md)
- Existing contracts in product repo: `docs/module-verification.md`, `docs/module-ci.md`
