# Prototype B — Documented empty `modules/` + single template

**Idea:** Same language-agnostic `templates/module/` as A, plus a **committed** `modules/` directory that documents how to add a module. No product module code this wave.

## Concrete file tree (after Phase 1 wave)

```text
xq-versastack/
├── AGENTS.md
├── CONSUMER_CONTEXT.md
├── README.md                      # shows modules/ + templates/module/
├── LICENSE
├── .gitignore
├── docs/
│   └── research/
│       ├── xq-scout-cli.md
│       └── xq-ios-act-cli.md
├── modules/
│   ├── .gitkeep                   # keep empty dir in git
│   └── README.md                  # “How to add a module” (copy template, CI caller, verify)
├── templates/
│   └── module/
│       ├── README.md              # ## Verify → ./scripts/ci.sh
│       ├── Makefile               # optional: make ci → ./scripts/ci.sh
│       ├── .gitignore
│       ├── scripts/
│       │   └── ci.sh              # stub verify entry
│       └── skills/
│           └── _example/
│               └── SKILL.md
├── scripts/                       # optional root helpers — listing only, no build orchestration
│   └── changed-modules.sh         # lists changed modules/* paths; does NOT build
└── .github/
    └── workflows/
        ├── module-ci.yml          # reusable workflow
        └── repo-meta.yml          # docs/templates/.github only
# Still NO modules/<product>/ this wave
# Still NO root package.json / workspace / scripts/module runner
```

### `modules/README.md` (required content)

Document, in short form:

1. **Copy:** `cp -R templates/module modules/<kebab-name>`
2. **Customize:** language toolchain, README, replace `scripts/ci.sh`, rename `skills/_example`
3. **Verify locally:** `cd modules/<name> && ./scripts/ci.sh`
4. **CI:** add a thin path-filtered caller workflow that calls `module-ci.yml` with `module`, `setup` (`node`|`swift`|`none`), and a **gate** job so required checks stay green when untouched
5. **Consumer:** add a row to root `CONSUMER_CONTEXT.md` when ready to consume
6. **Do not:** register the module in any root workspace or invent a central runner

### Template contents (outline)

Same as Prototype A:

| File | Role |
| --- | --- |
| `templates/module/README.md` | Module identity + Verify section |
| `templates/module/scripts/ci.sh` | Canonical CI/verify entry (stub until real module) |
| `templates/module/Makefile` | Optional `make ci` → `./scripts/ci.sh` |
| `templates/module/skills/_example/SKILL.md` | Skill location convention |
| `templates/module/.gitignore` | Common ignore stubs for Node/Swift/local artifacts |

**`scripts/ci.sh` stub outline** — identical contract to A (language body filled per module after copy).

### Where agent skills live

| Scope | Path |
| --- | --- |
| Shipped module | `modules/<name>/skills/<skill>/SKILL.md` |
| Template stub | `templates/module/skills/_example/SKILL.md` |
| How-to pointer | `modules/README.md` (points at template + per-module skills) |
| Repo root | **Never** for product skills |

### What NOT to put at root

Same anti-list as A, plus:

- Do not put “starter” product sources under `modules/` just to fill the directory
- Do not add a root `Makefile` that loops `modules/*` and builds all

Root may have **optional** `scripts/changed-modules.sh` (path listing only).

## Agent workflow (this wave and later)

**This wave (foundation):**

1. Read `AGENTS.md` → see “modules live under `modules/`”
2. Read `modules/README.md` → learn add-module path
3. Touch only template / root docs / CI (per Work Contract ownership)

**Later (first real module, e.g. scout or ios-act):**

1. Copy `templates/module` → `modules/xq-scout-cli` (or ios-act)
2. Fill Node or Swift toolchain **inside that directory only**
3. Implement real `scripts/ci.sh`; keep skill under `modules/.../skills/`
4. Devops adds caller + gate for that path prefix
5. Update consumer table

## Pros

- Satisfies plan acceptance: **`modules/` exists** with documented add-module layout
- Agents immediately see the destination directory; fewer “where do modules go?” failures
- Still zero product skeleton — respects maintainer decision
- Single `templates/module/` keeps Work Contract and ownership globs simple (`templates/**`, `modules/README.md` only)
- First real module PR is smaller (directory already present)

## Cons

- Empty `modules/` can look unfinished to casual browsers (mitigated by `modules/README.md`)
- Slightly more files than A (`.gitkeep` + README)
- Polyglot details still live in docs/comments inside one template (not separate Node/Swift trees)

## Fit vs constraints

| Constraint | Fit |
| --- | --- |
| No skeleton this wave | Strong |
| Template + docs + CI only | Strong |
| Independent modules | Strong |
| Plan acceptance: `modules/` exists | Strong |
| Work Contract `templates/module/` | Strong (unchanged) |
