# Plan: Versastacks module test best practices

- **ID**: `003-versastacks-test-best-practices`
- **Hub issue**: https://github.com/chauhaidang/xq-context-hub/issues/12
- **Domains**: harness (`domains/harness/CONTEXT.md`) — `xq-versastacks` only
- **Status**: ready

## Goal

Give every `xq-versastacks` module a **clear, module-owned test bar**: what layers to cover, how to keep PR CI deterministic, when live/capability suites are allowed, and what **TSR** evidence a PR / review / release must leave behind — without introducing a shared test runner, reusable CI framework, or cross-module orchestrator.

Success means: new modules and engineer-in-test waves can follow one documented contract; `xq-scout-kit` and `xq-ios-act-cli` either already meet it or have explicit, closed gaps; hub review can judge evidence the same way across modules.

## Non-goals

- A root `./scripts/module`, matrix, or reusable `module-ci.yml`
- One language, framework, or required script name across modules
- Requiring live DeviceKit / live Cursor / authenticated `gh skill` on every PR
- Replacing or centralizing `xq-harness` test libraries
- Rewriting scout-kit’s suite into a copy-paste template that other modules must clone

## Before / After

| Aspect | Before | After |
| --- | --- | --- |
| Behavior | Modules verify independently; scout-kit has a rich layered suite + TSR; ios-act-cli has thinner `swift test` + brief TSR; hub process expects TSR but versastacks only documents *commands* (`module-verification.md`) and *CI ownership* (`module-ci.md`) | Same independence, plus an explicit **module testing contract** (layers, determinism, capability gates, TSR shape, release vs PR) that every shipped module documents and meets |
| Surfaces | `docs/module-verification.md`, `docs/module-ci.md`, per-module `tests/` / `tsr/`, path-scoped `ci-<name>.yml` | Add `docs/module-testing.md`; pointer updates from verification / CI / `AGENTS.md` / `modules/README.md`; module READMEs cite their local verify + evidence paths |
| Evidence | scout-kit: `tsr/summary.md` + `junit.xml` with layers/skips; ios-act-cli: shorter `tsr/summary.md` + junit; no repo-wide “what good looks like” | Contract defines minimum TSR fields; both shipped modules produce compliant evidence from their documented local commands; PR checklist can cite the contract |

## Test approach

- **Layers** (module may rename, but must map):
  1. **Static / contract** — schema, skill tree, pinned versions, forbidden layout
  2. **Unit / fake** — no network, no paid hosts, no developer machine secrets
  3. **Integration (disposable)** — optional; isolated real deps when explicitly invoked
  4. **Live / capability** — authenticated or host-bound; **skip by default** on PR CI; gate behind env flags / `workflow_dispatch` / release tags
- **Seams**: document commands in module README; CI invokes the same commands; TSR written under `modules/<name>/tsr/`
- **Fixtures / fakes**: prefer in-module fakes (scout-kit pattern); never require sibling modules
- **Environments**: local snap = module’s deterministic suite; CI = same; live only when the module’s release/debt policy says so
- **Out of scope for this plan**: building new product features inside modules beyond closing test/TSR contract gaps

## Test coverage

- [ ] Happy path: deterministic suite green for each shipped module via documented command
- [ ] Failure / negative: contract states that failing cases must appear in TSR (not silent skip)
- [ ] Edge / boundary: capability-labeled cases may `skip` with reason; live-not-run must not claim pass
- [ ] Regression: no shared runner / reusable module CI / root matrix introduced
- [ ] Evidence artifact: each shipped module refreshes `tsr/summary.md` + machine-readable junit (or equivalent named in README) from the same command CI runs

## Target repos

| Order | Repo | Branch | Wave roles | Notes |
| --- | --- | --- | --- | --- |
| 1 | `xq-versastacks` | `feat/versastacks-test-best-practices` | design (optional) → parallel `dev+test+devops` | Checkout: `checkouts/xq-versastacks` (local alias today: `checkouts/xq-versastack` → same remote). Only delivery unit. |

## Acceptance criteria

- [ ] `docs/module-testing.md` exists and defines: layers, determinism default, capability/live policy, TSR minimum fields, PR vs release expectations, anti-patterns (shared runner, fake green)
- [ ] `docs/module-verification.md` and `docs/module-ci.md` link to the testing contract; wording stays “per-module owns CI/CD”
- [ ] Root agent/consumer pointers (`AGENTS.md`, `modules/README.md`, and README or CONSUMER_CONTEXT as needed) mention the testing contract for new modules
- [ ] Both shipped modules (`xq-scout-kit`, `xq-ios-act-cli`) are audited against the contract; gaps closed or explicitly waived in the module README with rationale
- [ ] Documented module verify commands refresh TSR; path-scoped CI still invokes those same commands (no new shared workflow)
- [ ] Hub issue checklist reflects wave → snap → review → one PR

## Work Contract — xq-versastacks

**Branch:** `feat/versastacks-test-best-practices`  
**Goal:** Land the module testing best-practices contract and bring shipped modules up to that bar without centralizing verification.

### Interfaces / seams

- **Contract doc**: `docs/module-testing.md` (new) — normative for agents and review
- **Existing contracts**: `docs/module-verification.md` (commands), `docs/module-ci.md` (workflow ownership) — remain authoritative for their scopes; testing doc owns layers/evidence policy
- **Reference implementations** (patterns to extract, not to force):
  - `modules/xq-scout-kit/tests/run-all.sh` + `tsr/` — layered cases, skips with reasons, junit + summary
  - `modules/xq-ios-act-cli/scripts/run-swift.sh` + `tsr/` — Swift Testing / XCTest evidence path
- **TSR minimum** (normative target for the doc):
  - `modules/<name>/tsr/summary.md` — pass/fail/skip counts, toolchain, commit/time, coverage statement, per-case or per-suite table
  - `modules/<name>/tsr/junit.xml` (or clearly named equivalent already produced by the toolchain)
  - Skips must carry a reason; live suites must not be reported as pass when not run
- **CI seam**: each `.github/workflows/ci-<name>.yml` continues to own setup + call module commands; this plan does **not** add reusable workflows

### File ownership

| Role | Owns (paths / globs) | Must not touch |
| --- | --- | --- |
| design | Plan/contract refinements in hub only (if still needed); advisory comments on versastacks docs shape | Product code under `modules/**` |
| dev | `docs/module-testing.md`, pointer edits in `docs/module-verification.md`, `docs/module-ci.md`, `AGENTS.md`, `README.md`, `modules/README.md`, `CONSUMER_CONTEXT.md` (docs only) | Module test implementations; workflow YAML logic beyond doc cross-links |
| test | `modules/xq-scout-kit/tests/**`, `modules/xq-scout-kit/tsr/**`, `modules/xq-scout-kit/testbed/tests/**`, `modules/xq-ios-act-cli/**/Tests/**`, `modules/xq-ios-act-cli/scripts/**`, `modules/xq-ios-act-cli/tsr/**`, module README **Testing / verification** sections | Root CI framework; unrelated feature freelancing |
| devops | `.github/workflows/ci-xq-scout-kit.yml`, `.github/workflows/ci-xq-ios-act-cli.yml` only as needed so CI runs evidence-producing commands; `docs/module-ci.md` evidence bullets | Shared reusable workflow; `release-*.yml` behavior changes unless required for TSR honesty |

### Acceptance

- [ ] Testing contract merged on the feature branch and linked from verification + CI docs
- [ ] Audit notes (in PR body or hub issue comment): scout-kit vs ios-act-cli vs contract
- [ ] Gap fixes landed under test ownership **or** explicit README waiver per gap
- [ ] Snap commands below green
- [ ] No new root runner / reusable module CI / matrix

### Snap commands

```bash
cd checkouts/xq-versastacks   # or checkouts/xq-versastack if that is the synced path

test -f docs/module-testing.md
rg -n 'module-testing' docs/module-verification.md docs/module-ci.md AGENTS.md modules/README.md

# Per-module deterministic evidence (same commands CI should use)
cd modules/xq-scout-kit && bash tests/run-all.sh && test -s tsr/summary.md && test -s tsr/junit.xml
cd ../xq-ios-act-cli && bash scripts/run-swift.sh && test -s tsr/summary.md
```

## Work packages

### WP0 — contract (optional design)

- **Role**: design
- **Engineer**: `engineer-in-design`
- **Done when**: Work Contract above is complete enough for the parallel wave (product-lead filled QA sections). **Waive WP0** if root accepts this plan as-is; only spawn design if layer/TSR minimums are disputed.

### Parallel wave — same branch (`feat/versastacks-test-best-practices`)

| Role | Engineer | Package | Ownership |
| --- | --- | --- | --- |
| dev | `engineer-in-dev` | WP1 — write `docs/module-testing.md` + pointer updates | docs + root markdown pointers |
| test | `engineer-in-test` | WP2 — audit both modules; close TSR/layer gaps or document waivers | module tests / scripts / tsr / testing sections in module READMEs |
| devops | `engineer-in-devops` | WP3 — confirm CI invokes evidence commands; adjust workflow steps only if missing; keep path filters | per-module workflow YAML + `docs/module-ci.md` evidence notes |

### After snap

| Role | Engineer | Package |
| --- | --- | --- |
| review | `engineer-in-review` | WP4 — review branch vs contract + acceptance; verify refreshed **TSR** on both modules → one PR to `xq-versastacks` |

## Notes / decisions

- **Independence invariant (keep):** each module controls its own CI/CD and verification commands. Best practices are a **contract document**, not a shared implementation.
- **Scout-kit is the reference bar**, not the required harness. Swift modules may emit TSR via `swift test` + a thin summary writer; they need not adopt bash `run-all.sh`.
- **PR default = deterministic.** Live / authenticated cases stay capability-gated (scout-kit already models this).
- **Hub checkout name:** `org/links.yaml` uses `xq-versastacks`; some machines still have `checkouts/xq-versastack` remoted to that repo — snap commands accept either path.
- Plan `002` merge-conflict markers resolved on this hub branch as hygiene (prefer `xq-versastacks` naming).

## Links

- Hub issue: https://github.com/chauhaidang/xq-context-hub/issues/12
- Domain context: [`domains/harness/CONTEXT.md`](../../domains/harness/CONTEXT.md)
- Related plans: [`001-versastack-fast-delivery`](../001-versastack-fast-delivery/PLAN.md), [`002-xq-ios-act-cli`](../002-xq-ios-act-cli/PLAN.md)
- Existing contracts in product repo: `docs/module-verification.md`, `docs/module-ci.md`
