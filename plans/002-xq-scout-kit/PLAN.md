# Plan: xq-scout-kit

- **ID**: `002-xq-scout-kit`
- **Hub issue**: https://github.com/chauhaidang/xq-context-hub/issues/4
- **Delivery PR**: https://github.com/chauhaidang/xq-versastack/pull/5
- **Release tech debt**: https://github.com/chauhaidang/xq-versastack/issues/4
- **Domain**: harness
- **Status**: `release_prep` — delivery PR
  https://github.com/chauhaidang/xq-versastack/pull/5 **MERGED** 2026-07-26.
  Product branch tip `40d1225` (`40d122564e337075cbdc661efb17fa8a07fe095d`);
  main merge commit `be95b11` (`be95b11f65e9134b76f85d2709098982744df375`).
  Refactor/snap/CI/WP4 and the exact v0.1.0 Cursor waiver implementation are on
  that tip. Remaining: authenticated real `gh skill install` E2E, then publish
  `xq-scout-kit-v0.1.0`. Cursor WP0b/live remains waived for that exact version
  only; [xq-versastack#4](https://github.com/chauhaidang/xq-versastack/issues/4)
  stays open. Deterministic, real-Scout, GitHub CLI validation, and
  authenticated real-install requirements are not waived.

## Final refactor delivery evidence

- Merged delivery tip: `40d1225`
  (`40d122564e337075cbdc661efb17fa8a07fe095d`) on `xq/scout-kit`.
- Main merge commit: `be95b11`
  (`be95b11f65e9134b76f85d2709098982744df375`) — current `origin/main`.
- Prior integration refactor tip (ancestor): `9122b10`
  (`9122b1099c37fd7623e4d6c47426f75cb985ceae`).
- Post-`9122b10` waiver commits on the merged tip: `50eab7d`, `f955a65`,
  `0943e65`, `40d1225` (exact v0.1.0 Cursor waiver + require install before
  waiver).
- WP1: `2982031`.
- WP2: `fcd4f32`, `b21b223`, `ca2eb9f`, and `7afcb14`.
- WP3: `93cca62`, `69e969d`, and `faa1d73`.
- Consumer product is self-contained under `skills/xq-scout/**`; the custom
  `.xq/scout` payload, tar contract, and packager are removed.
- Refactor TSR: local deterministic `11 passed / 0 failed / 2 skipped`;
  isolated real Scout `12 passed / 0 failed / 2 skipped`.
- `gh skill publish modules/xq-scout-kit --dry-run` passes.
- PR CI run
  [30202584726](https://github.com/chauhaidang/xq-versastack/actions/runs/30202584726)
  is green at exact tip `40d1225`: `deterministic candidate` passed. The
  `real gh skill install capability` job passed by executing its public-PR
  capability-skip label; its authenticated install steps were skipped, so this
  is not real-install evidence. `real Scout and live Cursor` was skipped.
- Final WP4/delta review through `9122b10` found no findings; PR #5 was
  approved and **merged**. Maintainer permits only the v0.1.0 release to
  proceed with WP0b/live Cursor explicitly skipped and deferred to
  `xq-versastack#4`; it does not convert the skipped evidence into a pass.

## Maintainer decision / new contract

`xq-scout-kit` is distributed as one self-contained Agent Skill through the
GitHub CLI `gh skill` commands. The complete consumer product is exactly the
`modules/xq-scout-kit/skills/xq-scout/` tree:

```text
modules/xq-scout-kit/skills/xq-scout/
  SKILL.md
  references/**
  SCOUT_VERSION
  KIT_VERSION
  scout.json.example
  xq-scout-kit.json.example
  scripts/
    setup.sh
    verify.sh
  templates/
    scenarios/**
```

`gh skill publish modules/xq-scout-kit --dry-run` discovers and validates that
tree against the Agent Skills specification. Publication uses:

```bash
gh skill publish modules/xq-scout-kit --tag "xq-scout-kit-v<semver>"
```

WP3 must validate the installed GitHub CLI's current `gh skill publish --help`
and dry-run behavior before relying on the explicit tag form. CI must pin or
enforce a documented minimum GitHub CLI version that supports `gh skill`; it
must fail clearly rather than silently use another packaging path.

Consumers install with:

```bash
gh skill install OWNER/REPO xq-scout --agent cursor
```

For Cursor project installation the resulting product lives at
`.agents/skills/xq-scout/**`. Other supported hosts use the path selected by
`gh skill`. GitHub CLI installs the complete skill directory and tracks its
provenance. Product instructions and scripts therefore derive the skill root
from their own installed location and never depend on the caller's current
directory or on a particular host path.

There is no separate consumer payload, custom tar contract, internal payload
manifest, archive checksum contract, or custom packager. The GitHub Release
created by `gh skill publish` is the distribution source.

## Goal

Ship `xq-scout-kit` from `xq-versastack` as a natively publishable and
installable Agent Skill for the upstream `@testerarmy/scout` CLI. One installed
skill directory provides Agent instructions, references, exact-version global
Scout setup, deterministic verification, configuration examples, and scenario
templates. Consumer repositories continue to own their Scout configuration,
kit policy, and executable behavioral scenarios.

The module must support:

- spec-valid publication validation with `gh skill publish ... --dry-run`;
- installation and provenance tracking through `gh skill install`;
- host-location-independent setup and verification scripts;
- deterministic local simulation of the complete installed skill directory;
- authenticated/networked install E2E where CI permits;
- exact skill-tree identity and evidence binding; and
- the existing safe Author, Verify, optional Discover, scenario, and report
  behavior.

## Non-goals

- Implementing, reimplementing, vendoring, or wrapping Scout.
- Hiding upstream commands behind an XQ command.
- Shipping an XQ CLI, daemon, service, UI, npm package, custom installer, or
  custom release archive.
- Maintaining compatibility with the unreleased former split consumer layout.
- Depending on Cursor's project path in product logic; it may appear only in
  installation/documentation examples and host-specific tests.
- Making fuzz or exploratory testing the default merge gate.
- Supporting non-shell scenarios in v1.
- Running against external demonstration or production APIs.
- Adding a root runner, reusable/shared workflow, or repository-wide
  changed-module orchestrator.
- Sharing CI/release implementation with another module.
- Automatically enabling mutations or accepting destructive test data.

## Migration

No consumer release has been published, so there is no backward-compatibility
obligation for the former `.xq/scout` layout. Implementation must remove that
payload and all operational references to it. No migration shim, dual install,
fallback lookup, deprecation period, or upgrade test for that layout is
required. The only remaining mention of `.xq/scout` after implementation should
be historical migration documentation explicitly stating that it is
unsupported and absent.

## Before / After

| Aspect | Before refactor | After refactor |
| --- | --- | --- |
| Consumer product | Skill instructions and runtime resources are sibling source trees mapped by custom packaging into two consumer roots. | One spec-valid `skills/xq-scout/` directory contains every installed resource. |
| Installation | A custom archive is unpacked at repository root. | `gh skill install OWNER/REPO xq-scout --agent <host>` installs the complete directory and records provenance. |
| Runtime location | Scripts and templates assume a separately mapped consumer payload. | Scripts resolve `SCOUT_VERSION`, examples, references, and templates relative to their own skill root; `--repo` identifies only the consumer repository. |
| Distribution | A custom deterministic tar, manifest, and SHA-256 sidecar are produced. | `gh skill publish` validates the Agent Skill and creates the GitHub Release. |
| Candidate identity | Evidence is bound to archive and internal-manifest digests. | Evidence is bound to commit, published/installed skill-tree SHA, source skill-tree SHA, model, and agent versions. |
| Tests | Archive modes, paths, deterministic bytes, extraction, manifest, checksum, and root mapping are tested. | Agent Skills validation, complete-tree simulation, location independence, provenance/frontmatter tolerance, source/installed tree identity, and optional real install are tested. |
| Behavior | Setup, verify, scenarios, safety policy, testbed, and Scout integration exist. | Those behavioral contracts remain unchanged, with path references adapted to the installed skill root. |
| Delivery state | WP1–WP3 were treated as implementation-complete. | WP1–WP3, snap, CI, WP4, and v0.1.0 waiver are merged via PR #5 at tip `40d1225` / main `be95b11`; release-prep (trusted install + publish) remains. |

## Source and consumer interface

### Source tree

```text
modules/xq-scout-kit/
  README.md
  skills/
    xq-scout/
      SKILL.md
      references/
        scenario-authoring.md
        safety-and-configuration.md
        ci-and-troubleshooting.md
        scout-compatibility.md
      SCOUT_VERSION
      KIT_VERSION
      scout.json.example
      xq-scout-kit.json.example
      scripts/
        setup.sh
        verify.sh
      templates/
        scenarios/
          _lib.sh
          01-smoke.sh
          90-mutation-opt-in.sh.example
  fixtures/
    openapi.yaml
    server.mjs
    scenarios/**
  tests/
    fakes/**
    run-all.sh
    run-static.sh
    test-setup.sh
    test-verify.sh
    test-fixture.sh
    test-installed-skill.sh
    test-gh-skill.sh
  testbed/
    README.md
    consumer-template/**
    tasks/**
    rubrics/**
    run-cursor-eval.mjs
    evaluate.mjs
    redact-evidence.mjs
    import-live-evidence.mjs
    tests/**
    .cursor/cli.json
    evidence/.gitignore
  tsr/
    .gitignore
    summary.md
    junit.xml
```

Only `skills/xq-scout/**` is consumer product. Fixtures, tests, testbed,
generated evidence, and TSR are module source/Actions artifacts and are not
installed as part of the skill or attached as additional custom distribution
payloads.

`KIT_VERSION` contains the release semver without a `v` prefix.
`SCOUT_VERSION` contains one exact upstream package/CLI version. Both are
single-line validated files inside the skill tree. There is no second,
module-root version source.

### Installed interface

The stable script interface is:

```text
<installed-skill>/scripts/setup.sh
<installed-skill>/scripts/verify.sh --repo <consumer-root>
```

`setup.sh` locates `SCOUT_VERSION` from its own script path. `verify.sh` locates
the same file from its own script path and roots product operations at the
explicit `--repo` value. The skill's instructions use relative links for
references, examples, templates, and scripts and explain that the host resolves
the installed skill root. They must not encode a fixed host install directory.

`verify.sh --repo <root>` is the documented interface. It accepts no arbitrary
pass-through arguments. If an omitted `--repo` remains supported for
convenience, it may use the current Git root, but all skill instructions,
tests, and CI invoke the explicit form.

The consumer owns and the skill never overwrites:

```text
<consumer-root>/scout.json
<consumer-root>/xq-scout-kit.json
<consumer-root>/scenarios/scout/
  _lib.sh
  [0-9][0-9]-*.sh
```

Installation or reinstallation may replace only files owned by the installed
skill/provenance mechanism. Copying examples or templates into product-owned
paths is an explicit consumer or agent action, never an install side effect.

### Configuration and verification behavior

Root `scout.json` remains upstream-only Scout configuration. For selected Scout
`0.3.0`, it uses only the compatibility-validated `spec`, `baseUrl`, `headers`,
`authProfiles`, and `policy` fields. It contains no kit report policy.

Root `xq-scout-kit.json` remains product-owned, secret-free workflow policy:

```json
{
  "report": {
    "minCoverage": 75,
    "severityThreshold": "high"
  },
  "completenessSweep": {
    "path": "/health"
  }
}
```

Validation remains strict before state deletion or Scout invocation: no unknown
keys, integer coverage from 0 through 100, a compatibility-validated severity,
and a required concrete leading-slash safe GET path without path parameters.
The kit fixes sweep method to GET, maximum requests to one, and auth probes off.
`/health` is a fixture/example path, not a universal default.

Every verify run:

1. resolves the exact expected Scout version from its skill root;
2. validates the consumer root and both product-owned config files;
3. removes only `<consumer-root>/.scout/`;
4. runs `scout init --json` from the consumer root;
5. runs executable numbered scenarios in bytewise filename order;
6. runs the one-request, GET-only, no-auth-probes sweep; and
7. runs the policy-gated `scout report --ci` command and propagates failures.

It does not install Scout, alter product-owned files, enable mutations, run
`scout agent init`, or become a general command proxy.

### Setup behavior

Setup remains exact global Scout:

- non-interactive Bash;
- Node `>=22.12.0` and npm required before mutation;
- exact target read from adjacent `SCOUT_VERSION`;
- current npm package and callable CLI versions checked;
- `current=` and `target=` printed before replacement;
- a complete match is an idempotent no-op;
- mismatch is visibly replaced with the exact global package version; and
- package and CLI identity are rechecked before success.

Global state mutation is accepted for one active consumer environment and
disposable CI runners. Local deterministic tests fake process boundaries and
never alter a developer's global installation.

### Skill modes

- **Author (default):** inspect product API/config/scenarios, adapt a template
  from the installed skill into `scenarios/scout/`, use direct Scout calls with
  process-failing assertions, and run installed verify with `--repo`.
- **Verify:** run installed setup when provisioning, then installed verify;
  report failures exactly and never weaken assertions or gates.
- **Discover (optional):** use bounded direct upstream discovery/fuzz/sweep
  only when authorized, then promote durable behavior into a reviewed scenario.

The skill never instructs agents to run `scout agent init`, because that would
create a competing skill contract.

## Product-owned versus skill-owned

| Owner | Settings and files |
| --- | --- |
| Installed skill | Exact Scout and kit versions; setup/version checks; strict policy schema; fixed verify sequence; references; examples; templates; scenario conventions; assertion helper behavior; safe sweep limits; default mutation-off guidance |
| Consumer product | Root `scout.json`; root `xq-scout-kit.json`; `scenarios/scout/**`; API spec/base URL; methods/paths; auth profile names and environment references; runtime credentials; report thresholds; safe sweep path; explicit mutation authorization; synthetic namespace and cleanup |
| Module/Actions only | Fixtures, deterministic tests, GitHub CLI validation, testbed, redacted evidence, and TSR artifacts |

Secrets are never accepted in scenarios, examples, arguments likely to be
logged, fixtures, or Git. Mutation opt-in remains product-owned but must satisfy
skill-owned authorization, synthetic-data, and cleanup invariants.

## Test approach

### Layers

- **Static/spec:** shell syntax, metadata, frontmatter, relative links, complete
  resource containment, executable expectations, no wrapper, no split payload,
  and no operational legacy-layout references.
- **Unit/component:** fake `PATH`/npm/Scout setup cases; strict policy parsing;
  verify ordering, state deletion, exact Scout commands, and failures.
- **Fixture integration:** dependency-free local API, positive and negative
  scenarios, capture/reuse, deterministic reruns, and mutation cleanup.
- **Installed-tree simulation:** copy the exact source skill directory to
  arbitrary temporary host paths, optionally apply representative
  provenance/frontmatter changes, invoke its scripts from unrelated current
  directories, and prove product-owned files are unchanged.
- **GitHub CLI validation:** use a pinned or minimum-supported `gh`; run
  `gh skill publish modules/xq-scout-kit --dry-run` on PRs without publishing;
  validate accepted tag behavior from the current CLI before release.
- **Consumer E2E:** where authentication and network policy permit, install
  with `gh skill install` into a disposable agent host and run the installed
  scripts. Deterministic filesystem simulation remains the local/offline
  equivalent and is always required.
- **Behavioral:** preserve the Cursor Agent CLI testbed's three one-attempt
  cases, restrictive policy, redaction, process cleanup, causal skill-read
  rubric, and test-owned evidence import.

### Installed skill identity

The candidate is the exact source skill tree plus its tree SHA, not a custom
archive. Tests record the source tree SHA, the filesystem-simulated installed
tree SHA, and the actual published/installed tree SHA as distinct named values.
WP2 must define the tree algorithm and inventory precisely enough to reproduce
each value and fail on an unexplained missing, added, or changed file.

Deterministic simulation copies the source tree exactly, so its source and
installed tree SHAs must match. A real `gh skill` installation may add
documented provenance files or augment frontmatter; its SHA therefore need not
equal the source SHA. Tests record the complete resulting installed tree and
its SHA, classify the documented host additions, and prove all source-owned
content remains present and semantically intact. They do not hash-normalize
away installed changes. Required `name: xq-scout`, trigger-oriented
description, relative resources, and Agent Skills parsing must remain valid.

Live evidence records candidate commit SHA, source skill-tree SHA,
published/installed skill-tree SHA, model, Cursor Agent version, GitHub CLI
version, rubric results, and artifact IDs. Archive and manifest digests are not
part of the schema.

### Coverage

- [x] Exact-version setup happy, replacement, idempotent, prerequisite,
      install-failure, and post-install mismatch paths pass through fakes.
- [x] Verify covers missing/malformed config, unknown policy, coverage
      boundaries, severity validation, unsafe sweep path, no scenarios,
      non-executable scenarios, ordered execution, failed scenario/sweep/report,
      and caller paths containing spaces.
- [x] Two fixture runs are deterministic after deleting only `.scout/`.
- [x] Product `scout.json`, `xq-scout-kit.json`, and scenarios remain
      byte-identical across skill installation simulation and script runs.
- [x] Every skill-relative reference/resource resolves inside the skill tree;
      no direct upstream command is replaced by an XQ wrapper.
- [x] Simulation works from at least two unrelated host paths and current
      directories, including a path containing spaces.
- [x] Host-added provenance/frontmatter is accepted only where allowed; required
      skill identity and parsing continue to pass.
- [x] Source and exact simulated-installed tree SHAs match.
- [ ] Authenticated real-install source and installed SHAs are separately
      recorded with documented host deltas.
- [x] `gh skill publish modules/xq-scout-kit --dry-run` passes with no release
      side effect on PR CI.
- [ ] Authenticated/networked CI, where available, installs with
      `gh skill install`, verifies provenance, and exercises installed scripts.
- [x] Real Scout integration runs only on disposable runners/containers.
- [x] Mutation remains disabled by default; authorized fixture mutation uses
      namespaced synthetic data and cleans up after success/failure where
      practicable.
- [x] TSR summary/JUnit are refreshed, non-empty, and distinguish deterministic,
      real-Scout, gh-skill install, and live Cursor layers.
- [x] No custom package-release implementation, archive, checksum, internal
      manifest, archive mode/path/determinism test, or safe-extraction contract
      remains.

### Preserved behavioral and security coverage

- [ ] **Deferred for v0.1.0 only — [xq-versastack#4](https://github.com/chauhaidang/xq-versastack/issues/4):**
      record `agent --version`; prove automatic skill discovery/read behavior;
      canary isolation from tool subprocesses; remote-Git-write, WebFetch,
      external MCP, and shell-network denial; localhost/workspace positive
      controls; print-mode writes; NDJSON and non-JSON failure capture; and
      process-group timeout/cleanup.
- [ ] **Deferred for v0.1.0 only:** stream-redact prompt, NDJSON, stdout,
      stderr, diff, and rubric inputs; recursively scan all persistent outputs;
      quarantine/delete everything uploadable on redaction or leak failure; and
      never persist the API key or raw transcript.
- [ ] **Behavioral Author:** create a numbered GET scenario in the product path,
      use a process-failing direct Scout assertion, run installed verify, and
      invoke neither an XQ CLI nor `scout agent init`.
- [ ] **Behavioral Verify failure:** diagnose a deliberately wrong expectation
      honestly without deleting or weakening the assertion or gates.
- [ ] **Behavioral mutation safety:** reject unauthorized mutation and require
      explicit authorization, a synthetic namespace, and cleanup.
- [ ] Provisional Cursor Chat/subagent observations remain separately labeled,
      exploratory, and non-gating. They do not satisfy host discovery,
      credential isolation, egress, stream, cleanup, or exact-commit gates.
- [ ] Live evidence import rejects missing fields, stale commit, wrong source
      tree, wrong installed tree, and missing/failed rubrics, then merges exactly
      the three required cases into freshly generated TSR.

## Acceptance and gates

### PR / merge gate

PR #5 may continue and merge for the `xq-scout-kit-v0.1.0` delivery when:

- [x] WP1, WP2, and WP3 refactor slices are integrated without ownership
      collision.
- [x] The complete consumer product is one valid `skills/xq-scout/` tree.
- [x] Static, fake, fixture, installed-tree, no-overwrite, and canonical-tree
      checks pass in deterministic CI; isolated real-Scout checks pass.
- [x] PR CI passes `gh skill publish modules/xq-scout-kit --dry-run` and proves
      it did not publish.
- [x] Module README and skill instructions document `gh skill` install,
      host-resolved root usage, setup, verify, config, and tests.
- [x] No custom consumer payload, packager, archive contract, checksum,
      internal manifest, or corresponding stale tests/workflow logic remains.
- [x] CI remains module-owned/path-scoped and uses no shared workflow.
- [x] Fresh TSR reports and preserved evidence are reviewed.
- [x] WP4 completes a defect-first review from the previous candidate through
      the final refactor tip and explicitly records absent authenticated Cursor
      evidence as release-only debt.

Authenticated Cursor Agent CLI evidence is not a PR, review, or merge gate.
The maintainer's v0.1.0-only decision therefore permits approval and merge
without WP0b/live Cursor evidence. That evidence remains skipped/deferred, not
passed.

### Release gate

The maintainer explicitly waives only the authenticated Cursor WP0b/live
evidence gate for exactly `xq-scout-kit-v0.1.0`, accepting the risk tracked by
[xq-versastack#4](https://github.com/chauhaidang/xq-versastack/issues/4).
PR/merge and release may proceed for that exact version and tag while the issue
remains open. Before publication:

- [ ] All PR/merge criteria pass at the release commit.
- [ ] The release workflow validates
      `xq-scout-kit-v<semver>` against skill `KIT_VERSION`.
- [ ] Deterministic/spec checks, isolated real-Scout checks, GitHub CLI skill
      validation, and authenticated real `gh skill install` validation all pass
      for the release candidate.
- [ ] The workflow validates current CLI support for the accepted `--tag` form
      and invokes `gh skill publish modules/xq-scout-kit --tag ...`.
- [ ] The publishing job has only the permissions required to create the
      GitHub Release; PR validation has no publishing permissions.
- [ ] Immutable-release guidance is enforced: do not republish/mutate an
      existing release tag; create a new version/tag for changed content.
- [ ] The workflow's waiver branch is selected only when both the validated
      `KIT_VERSION` is the literal `0.1.0` and the validated tag is the literal
      `xq-scout-kit-v0.1.0`; otherwise exact authenticated WP0b/live Cursor
      evidence must pass all security, discovery/read, behavioral, cleanup,
      leak, and exact-binding gates.
- [ ] The v0.1.0 TSR and release summary label WP0b/live Cursor as
      `skipped/deferred` (never passed), state the maintainer-accepted risk, and
      include https://github.com/chauhaidang/xq-versastack/issues/4.
- [ ] Evidence/TSR binding still matches commit + source skill-tree SHA +
      actual installed skill-tree SHA + model/agent versions for every
      executed layer and does not fabricate fields for the skipped Cursor
      layer.

The workflow must fail closed for every other `KIT_VERSION` or tag, including
`0.1.1` and all later releases. The waiver must be encoded as the exact
version-and-tag conjunction above: no workflow input, boolean, environment
flag, label, or generic bypass may activate it. Subsequent releases require
either resolution of debt #4 with passing evidence or a new explicit,
version-scoped maintainer decision implemented by an authorized plan and
workflow code change. This v0.1.0 decision is not inheritable.

### Removed requirements

The following old requirements are deleted, not deferred:

- custom consumer tar creation and root extraction;
- `release/package-release.mjs`;
- split installation into a skill path plus a second runtime payload;
- internal `MANIFEST.sha256`;
- archive SHA-256 sidecar and archive/manifest evidence binding;
- deterministic tar/gzip bytes, metadata, owner/group, path, and mode allowlists;
- malicious archive and safe-extraction specimens;
- archive fresh-install/upgrade and source-to-payload remapping tests;
- custom release assets published beside the GitHub Release; and
- reconstruction of an archive to validate live evidence.

Source/testbed evidence and TSR remain short-lived Actions artifacts only. They
are not consumer distribution and are not added to the `gh skill` release.

## CI and release contract

- CI workflow: `.github/workflows/ci-xq-scout-kit.yml`.
- Release workflow: `.github/workflows/release-xq-scout-kit.yml`.
- Release tag: `xq-scout-kit-v<semver>`.
- Distribution command: `gh skill publish modules/xq-scout-kit`.
- Installation command under test:
  `gh skill install OWNER/REPO xq-scout --agent cursor`.

PR CI is path-scoped, credential-free with respect to Cursor, and
non-publishing. It provisions a pinned or minimum-supported GitHub CLI, confirms
`gh skill` exists, runs the module deterministic suite, performs filesystem
installation simulation, and runs `gh skill publish ... --dry-run`.

Because install E2E can require authentication/network access, CI treats it as
an explicit capability:

- authenticated/networked trusted CI must exercise the real install path and
  record GitHub CLI version, destination, provenance, and canonical installed
  tree SHA;
- fork/offline/local runs use the deterministic exact-tree simulation and do
  not falsely claim real-install coverage; and
- lack of network/authentication does not permit a custom packaging fallback.

Post-snap dispatch preserves exact global Scout integration and the Cursor
testbed. It creates one disposable consumer repository per case, installs or
simulates the candidate skill tree according to the recorded layer, applies
restrictive Cursor policy, starts the local fixture, and runs each case once.
The testbed remains test-owned, Node-built-in-only, fail-closed, and specific to
the three xq-scout tasks.

The release workflow reruns required deterministic/spec/real-Scout checks and
the authenticated real `gh skill install` validation, verifies tag/version
agreement, refuses an existing immutable tag/release, and publishes only
through `gh skill publish`. It imports exact-bound live Cursor evidence unless
the literal `KIT_VERSION=0.1.0` and tag `xq-scout-kit-v0.1.0` conjunction
selects the one-release waiver. Under that waiver it emits skipped/deferred
Cursor results and the accepted-risk issue URL in TSR/release summary; it never
emits a Cursor pass. Any other version/tag without passing live evidence fails
closed. It does not hand-create release archives or upload TSR/testbed
artifacts as release assets. Actions may retain eligible TSR and redacted
evidence for a short documented period; a leak/redaction failure uploads
nothing.

## Evidence contract

Keep the existing TSR, WP0 Scout evidence, Cursor testbed security design,
provisional Chat observations, and review history. Change only candidate and
distribution identity:

```text
candidateCommitSHA
sourceSkillTreeSHA
publishedOrInstalledSkillTreeSHA
kitVersion
scoutVersion
ghVersion
agentVersion
model
sessionId (when available)
three mandatory rubric results
artifact IDs
timestamps/duration
process cleanup result
redaction/leak-scan result
```

The test-owned importer validates this schema and exact values. It must reject
archive/manifest fields as obsolete rather than continuing to rely on them.
Where publication has not occurred, deterministic CI records the simulated
installed tree SHA and labels it as simulation; it must not label that value a
published tree. Release evidence requires the actual installed tree identity
available from the authenticated `gh skill` flow. For v0.1.0, absent Cursor
fields remain explicitly skipped/deferred under the version-scoped waiver;
they are not synthesized or represented as passing.

Current historical evidence remains:

- WP0 selected Scout `0.3.0` at commits `4d4a8ee` and `98a153c`;
- previous deterministic TSR: `10 passed / 0 failed / 1 skipped`;
- previous isolated real-Scout TSR: `11 passed / 0 failed / 0 skipped`;
- provisional Chat runs: `7/7`, `7/7`, and `8/8`;
- interim review: no findings; and
- previous review candidate: `dcb378d`.

Those results prove the prior behavior only. They must be retained in review
history but cannot prove the refactored distribution. The completed refactor at
`9122b10` adds local deterministic TSR `11/0/2`, isolated real-Scout TSR
`12/0/2`, green dry-run CI, and a no-findings WP4 delta review.

## File ownership

Ownership is path-exact and disjoint. A role stops on an interface mismatch
rather than editing another role's slice.

| Role | Owns | Must not touch |
| --- | --- | --- |
| dev / `engineer-in-dev` | `modules/xq-scout-kit/README.md`; `modules/xq-scout-kit/skills/**`; removal of superseded module-root `VERSION`, `SCOUT_VERSION`, `scout.json.example`, `xq-scout-kit.json.example`, `scripts/**`, and `templates/**`; `README.md`; `CONSUMER_CONTEXT.md`; `modules/README.md`; `docs/research/xq-scout-cli.md` | fixtures, tests, testbed, TSR, release tooling, workflows |
| test / `engineer-in-test` | `modules/xq-scout-kit/fixtures/**`; `modules/xq-scout-kit/tests/**`; `modules/xq-scout-kit/testbed/**`; `modules/xq-scout-kit/tsr/**` | skill/runtime implementation, docs/pointers, workflows |
| devops / `engineer-in-devops` | `.github/workflows/ci-xq-scout-kit.yml`; `.github/workflows/release-xq-scout-kit.yml`; deletion of the formerly devops-owned `modules/xq-scout-kit/release/package-release.mjs` and now-empty `release/` directory | skill/runtime/docs, fixtures, tests, testbed, authored TSR |
| review / `engineer-in-review` | read-only WP4 findings and recommendation | implementation files |

Dev owns moving all consumer runtime resources into the skill tree and making
paths location-independent. Test owns canonical tree-hash rules, installation
simulation, gh-skill/E2E assertions, evidence schema/import changes, and TSR.
Devops owns GitHub CLI provisioning, dry-run validation, authenticated install
transport (required for release), and `gh skill publish` release invocation.
Devops may invoke
test-owned commands and upload eligible artifacts but may not reimplement their
schema or hashing.

No package manifest or lockfile is planned. If an unavoidable new dependency is
proposed, stop and revise ownership/CI before adding it.

## Work packages and waves

### WP0 — bounded Scout compatibility validation (complete)

- **Owner:** dev / `engineer-in-dev`.
- **Evidence:** commits `4d4a8ee` and `98a153c`.
- **Result:** selected Scout `0.3.0`; validated exact setup identity,
  upstream-only config, direct assertion failure, capture/reuse, mutation-off
  behavior, one-request GET sweep, report thresholds/exit status, and
  deterministic reset of only consumer `.scout/`.
- **Refactor effect:** none. Preserve `scout-compatibility.md`, move the exact
  version file into the self-contained skill, and keep behavior unchanged.

### WP0b — Cursor Agent CLI compatibility tracer (v0.1.0-only waiver; debt open)

- **Owner:** test / `engineer-in-test`.
- **Tracker:** https://github.com/chauhaidang/xq-versastack/issues/4
- **Sequence when debt is resolved:** authenticate; pass host safety/discovery
  probes; install the exact candidate skill through the validated path; run
  three one-attempt cases; import exact-bound evidence; then satisfy the gate
  for subsequent publication.
- **Preserved gates:** automatic discovery/read causality, unique behavior
  fingerprint, API-key/canary isolation, separate egress/write denials,
  localhost/workspace positive controls, print-mode and stream capture,
  fail-closed redaction/leak scan, process-group TERM/KILL cleanup, no retries,
  and no policy weakening.
- **Updated binding:** commit + source skill-tree SHA + published/installed
  skill-tree SHA + model/agent versions. No archive or manifest fields.
- **Delivery rule:** absence remains accepted residual risk for WP4 and PR
  merge. By explicit maintainer decision it does not block exactly
  `xq-scout-kit-v0.1.0`, but must remain reported as skipped/deferred and linked
  to the open tracker. It blocks every subsequent release until resolved or
  replaced by a new explicit version-scoped maintainer decision and authorized
  plan/workflow code change.

### Refactor wave — WP1/WP2/WP3 complete

All three roles completed their disjoint slices from the same `xq/scout-kit`
line underlying PR #5 and integrated them at `9122b10`.

| Package | Owner | Exact work |
| --- | --- | --- |
| WP1 — self-contained product (complete: `2982031`) | dev | Moved `SCOUT_VERSION`, kit version, examples, scripts, templates, and references under `skills/xq-scout/`; renamed the consumer version source to `KIT_VERSION`; made scripts and skill links root-relative; updated docs/install examples; removed operational legacy-layout references; preserved Scout behavior and product ownership. |
| WP2 — distribution/tests/evidence (complete: `fcd4f32`, `b21b223`, `ca2eb9f`, `7afcb14`) | test | Replaced archive/remapping/mode/checksum tests with Agent Skills validation, complete-tree simulation, arbitrary-host-path execution, no-overwrite checks, provenance/frontmatter tolerance, canonical source/installed tree hashing, and authenticated install E2E hooks; updated testbed seeds/evaluator/import schema from archive/manifest binding to source/published-installed tree binding; refreshed TSR while preserving security and provisional evidence history. |
| WP3 — gh-skill CI/release (complete: `93cca62`, `69e969d`, `faa1d73`) | devops | Deleted the custom packager; provisioned/enforced a GitHub CLI version with `gh skill`; added credential-free PR `publish --dry-run`; added capability-gated real `gh skill install` E2E without fallback packaging; validated current accepted tag behavior in workflow logic; configured release publication only with `gh skill publish --tag`; enforced tag/`KIT_VERSION`, least permissions, immutable release guidance, and the release debt gate. |

Cross-slice interface:

1. WP1 provides the exact self-contained source tree and stable script CLI.
2. WP2 treats that tree as the candidate, defines canonical hashing, and
   provides commands/work products consumed by workflows.
3. WP3 invokes WP2 commands and official GitHub CLI commands; it does not
   create an alternate candidate.

### Integration snap (complete: `9122b10`)

- [x] Merge the three owned slices into one branch tip.
- [x] Confirm the source tree exactly matches the locked layout.
- [x] Run deterministic tests and inspect fresh TSR summary/JUnit.
- [x] Confirm real-Scout integration remains green on a disposable runner.
- [x] Confirm PR validation runs official `gh skill publish ... --dry-run`.
- [x] Confirm CI labels unavailable real-install capability accurately. Run
  authenticated real install E2E when trusted authentication/network is
  available; run 30200285908 skipped those install steps.
- [x] Confirm no custom package/release archive or split consumer payload remains.
- [x] Search implementation/docs/workflows/tests for operational legacy-layout
  references; retain only explicit historical migration text.
- [x] Confirm evidence schema contains tree identities and no archive/manifest
  bindings.
- [x] Record authenticated Cursor evidence as absent and link debt #4.
- [x] Do not update the linked issue or PR from this plan task; implementation
  delivery may update tracking only when separately authorized.

### WP4 — review complete; delivery PR merged

WP4 performed a defect-first review from prior candidate `dcb378d` through
refactor tip `9122b10`, then waiver commits landed through `40d1225`. PR #5
merged to main as `be95b11`.

WP4 explicitly states:

- whether PR #5 is merge-ready;
- that prior archive-based evidence is superseded;
- that provisional Chat does not satisfy WP0b;
- that authenticated live Cursor evidence is absent unless newly produced; and
- that, at review time, release remained blocked by debt #4 even if merge was
  recommended.

The final defect-first/delta review through `9122b10` found no findings.
Archive-based evidence is superseded. Authenticated real-install and live
Cursor evidence remain absent on public PR CI; provisional Chat evidence does
not satisfy WP0b. The maintainer decision waives only the live Cursor/WP0b gate
for v0.1.0; real-install evidence remains required and debt #4 remains open.
PR #5 is merged; release-prep is next.

## Snap commands

Run from the `xq-versastack` checkout. Local commands do not alter global npm
state and do not publish:

```bash
cd modules/xq-scout-kit
test_status=0
bash tests/run-all.sh || test_status=$?
test -s tsr/summary.md
test -s tsr/junit.xml
grep -Eq '<testsuites|<testsuite' tsr/junit.xml
sed -n '1,240p' tsr/summary.md
test "$test_status" -eq 0
cd ../..
gh skill publish modules/xq-scout-kit --dry-run
git status --short
```

The final `git status` check is part of proving that dry-run did not create a
release-side-effect file in the checkout; remote non-publication is also
verified from workflow permissions/logs. `tests/run-all.sh` owns static,
setup/verify fakes, fixture, installed-tree simulation, tree hashing, testbed
unit tests, and TSR refresh.

Real global Scout and real `gh skill install` checks run only in disposable,
appropriately authenticated/networked CI. A disposable local container may
reproduce real Scout:

```bash
docker run --rm -v "$PWD:/work:ro" -w /tmp node:22.12-bookworm \
  bash -lc 'cp -R /work module && cd module && bash tests/run-all.sh --real-scout'
```

Before release, the release workflow records and validates:

```bash
gh --version
gh skill publish --help
gh skill publish modules/xq-scout-kit \
  --tag "xq-scout-kit-v$(< modules/xq-scout-kit/skills/xq-scout/KIT_VERSION)"
```

The final command is publication and must never be run by local snap or PR CI.

## Tracking checklist

```markdown
## xq-scout-kit delivery

- [x] Create `xq/scout-kit` from the agreed base
- [x] WP0: Scout 0.3.0 selected and compatibility evidence committed at `4d4a8ee` + `98a153c`
- [x] Prior implementation candidate `dcb378d` and review history retained
- [x] Prior deterministic TSR 10/0/1 and isolated real-Scout TSR 11/0/0 recorded
- [x] Provisional Cursor Chat 7/7, 7/7, 8/8 retained as exploratory/non-gating
- [x] Interim review recorded no findings
- [x] WP1 `2982031`: self-contained `skills/xq-scout/` product and location-independent paths
- [x] WP2 `fcd4f32`, `b21b223`, `ca2eb9f`, `7afcb14`: gh-skill/spec/install simulation tests and tree-bound evidence contract
- [x] WP3 `93cca62`, `69e969d`, `faa1d73`: custom packager removed; module-owned gh-skill CI/release
- [x] Remove split consumer payload and operational legacy-layout references
- [x] Remove archive/manifest/checksum/deterministic-extraction requirements and tests
- [x] Integration `9122b10`: refactor slices snapped; later tip `40d1225` carries v0.1.0 waiver
- [x] Snap: local deterministic TSR 11/0/2 and isolated real-Scout TSR 12/0/2
- [x] PR CI run 30202584726: exact-tip `40d1225` deterministic candidate and `gh skill publish` dry-run green without publication
- [x] CI capability reporting: `real gh skill install capability` job passed by labeling the public-PR skip
- [ ] Trusted CI: real `gh skill install` E2E green where authentication/network permits
- [x] Deterministic tree binding: commit + source tree SHA + simulated-installed tree SHA
- [ ] Deferred v0.1.0 Cursor live binding: actual installed tree SHA +
      model/agent versions (skipped, not passed)
- [ ] Deferred v0.1.0 debt #4: authenticated WP0b host/security tracer (skipped, not passed)
- [ ] Deferred v0.1.0 debt #4: exact candidate three-case Cursor evaluation/import (skipped, not passed)
- [x] WP4 final/delta review through `9122b10`: no findings; approve PR #5
- [x] Maintainer decision: accept missing WP0b/live Cursor risk for exactly `xq-scout-kit-v0.1.0`; keep xq-versastack#4 open
- [x] Merge xq-versastack PR #5 (tip `40d1225` → main `be95b11`)
- [x] Encode fail-closed literal v0.1.0/version-tag waiver with no generic input or boolean bypass (`40d1225`)
- [ ] Require debt #4 resolution or a new explicit version-scoped maintainer decision/code change for v0.1.1+
- [ ] Authenticated real `gh skill install` E2E green with provenance and actual installed-tree SHA
- [ ] Validate current `gh skill publish --tag` behavior and tag/`KIT_VERSION` agreement at release
- [ ] v0.1.0 TSR/release summary states accepted risk, skipped/deferred Cursor layer, and issue #4 URL
- [ ] Publish immutable `xq-scout-kit-v0.1.0` through `gh skill publish`
```

## Current next steps

1. On `main` at `be95b11` (contains tip `40d1225`), run trusted authenticated
   `gh skill install` E2E via
   `workflow_dispatch` on `.github/workflows/ci-xq-scout-kit.yml` with
   `trusted_gh_install=true` (do **not** set `post_snap_live` for v0.1.0).
   Record provenance + installed-tree SHA. Public PR skip runs do not count.
2. Confirm `modules/xq-scout-kit/skills/xq-scout/KIT_VERSION` is literal
   `0.1.0`, then create and push immutable tag `xq-scout-kit-v0.1.0` on the
   release commit (`be95b11` / `main`). That triggers
   `.github/workflows/release-xq-scout-kit.yml`, which re-runs install/real-Scout
   gates, applies the exact v0.1.0 Cursor waiver, and publishes via
   `gh skill publish`.
3. Keep debt #4 open. For v0.1.1 or any later release, resolve it or obtain a
   new explicit version-scoped maintainer decision and authorized plan/workflow
   code change.

## Work Contract — release-prep (xq-versastack)

**Repo:** `xq-versastack`  
**Branch / ref:** `main` @ `be95b11` (includes product tip `40d1225`) — no new feature branch unless a fix is required  
**Hub issue:** https://github.com/chauhaidang/xq-context-hub/issues/4  
**Goal:** Prove authenticated exact-SHA `gh skill install`, then publish immutable `xq-scout-kit-v0.1.0`. No product code changes unless CI fails.

### Ownership

| Role | Owns | Must not touch |
| --- | --- | --- |
| devops / `engineer-in-devops` | Trigger/monitor `ci-xq-scout-kit.yml` (`trusted_gh_install=true`); tag `xq-scout-kit-v0.1.0`; monitor `release-xq-scout-kit.yml`; confirm `gh skill publish` / release exists | Skill/runtime product files; Cursor WP0b unless separately authorized |
| test / `engineer-in-test` (as needed) | Interpret install-result / tree-SHA artifacts; confirm TSR/release summary labels Cursor as skipped/deferred + debt URL | Workflow edits; publishing |

### Acceptance

- [ ] Trusted `workflow_dispatch` with `trusted_gh_install=true` succeeds on release candidate SHA (or equivalent evidence from release verify job)
- [ ] Install result records candidate commit + source skill-tree SHA + distinct installed skill-tree SHA + kit/scout/gh versions
- [ ] Tag `xq-scout-kit-v0.1.0` matches `KIT_VERSION=0.1.0` and points at intended release commit
- [ ] Release workflow green; GitHub Release / skill published only via `gh skill publish`
- [ ] Cursor layer labeled skipped/deferred with https://github.com/chauhaidang/xq-versastack/issues/4 (never passed)
- [ ] No republish/mutation of an existing tag

### Snap / verify commands (local preflight; does not publish)

```bash
cd checkouts/xq-versastack
git fetch origin main
git checkout --detach origin/main   # be95b11
test "$(tr -d '\r\n' < modules/xq-scout-kit/skills/xq-scout/KIT_VERSION)" = "0.1.0"
cd modules/xq-scout-kit && bash tests/run-all.sh
gh skill publish modules/xq-scout-kit --dry-run
```

### Trusted CI + publish (root / devops; remote)

```bash
# 1) Authenticated install E2E on main (blocker)
gh workflow run ci-xq-scout-kit.yml \
  --repo chauhaidang/xq-versastack \
  --ref main \
  -f trusted_gh_install=true \
  -f post_snap_live=false
gh run watch --repo chauhaidang/xq-versastack   # await success; collect install artifacts

# 2) Immutable tag → release workflow publishes
git tag -a xq-scout-kit-v0.1.0 be95b11f65e9134b76f85d2709098982744df375 \
  -m "xq-scout-kit v0.1.0"
git push origin refs/tags/xq-scout-kit-v0.1.0
gh run list --repo chauhaidang/xq-versastack --workflow=release-xq-scout-kit.yml --limit 3
gh release view xq-scout-kit-v0.1.0 --repo chauhaidang/xq-versastack
```

**Secrets / vars for this package:** none beyond default `GITHUB_TOKEN` for install/publish.  
**Do not** set `post_snap_live=true` or require `CURSOR_API_KEY` / `CURSOR_*` vars for v0.1.0 (waived; those are debt #4).

## Notes / decisions

- Product/module name remains `xq-scout-kit`; upstream Scout remains the CLI.
- The official GitHub CLI Agent Skills flow is the sole distribution path.
- The complete consumer product is one Agent Skill directory.
- Cursor's project installation path is an example, not a runtime assumption.
- GitHub CLI provenance/frontmatter additions are host metadata and must not
  break parsing; they do not permit mutation of required product content.
- Setup still manages one exact global Scout version as an explicit trade-off.
- Shell scenarios remain the only v1 scenario format.
- Product scenarios/config are never installed or overwritten by the skill.
- The local fixture remains dependency-free and is not a product.
- No custom package manifest/lockfile is needed for the Node-built-in harness.
- TSR and redacted testbed evidence remain Actions artifacts, never release
  distribution assets.
- Cursor Agent CLI remains the behavioral reference host and its strict
  discovery/security contract is unchanged.
- The maintainer accepts missing authenticated Cursor WP0b/live evidence only
  for `xq-scout-kit-v0.1.0`; the skipped layer is never a pass and debt #4 stays
  open.
- The v0.1.0 waiver is a literal version-and-tag exception, not a reusable
  mechanism. No input/boolean bypass is permitted, and v0.1.1+ fails closed
  absent debt resolution or a new explicit version-scoped decision/code
  change.
- No released consumer exists, so compatibility scaffolding for the abandoned
  split layout would add risk without protecting a user.
- Plan status is `release_prep`; WP1–WP3, integration snap, exact-tip PR CI,
  WP4, v0.1.0 waiver encoding, and PR #5 merge are complete. Trusted
  authenticated real-install evidence and immutable `xq-scout-kit-v0.1.0`
  publication are next.
- Open questions: none. Current `gh skill` tag syntax is an implementation
  validation item, not a design question or permission to invent a fallback.

## Links

- Hub issue: https://github.com/chauhaidang/xq-context-hub/issues/4
- Delivery PR: https://github.com/chauhaidang/xq-versastack/pull/5
- Release tech debt / deferred WP0b:
  https://github.com/chauhaidang/xq-versastack/issues/4
- Domain context: `domains/harness/CONTEXT.md`
- Parallel process: `docs/agents/parallel-wave.md`
- Module policy: `checkouts/xq-versastack/modules/README.md`
- Module CI: `checkouts/xq-versastack/docs/module-ci.md`
- Module verification:
  `checkouts/xq-versastack/docs/module-verification.md`
- Prior research:
  `checkouts/xq-versastack/docs/research/xq-scout-cli.md`
