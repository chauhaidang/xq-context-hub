# Prototype A — Minimal template only

**Idea:** Ship `templates/module/` + root context/CI docs. Do **not** commit a `modules/` directory until the first real product module lands (follow-on plan).

## Concrete file tree (after Phase 1 wave)

```text
xq-versastack/
├── AGENTS.md                      # work inside modules/<name>/ when it exists
├── CONSUMER_CONTEXT.md            # how to load one module; point at modules/ when shipped
├── README.md                      # layout intent + “copy template → modules/<name>”
├── LICENSE
├── .gitignore
├── docs/
│   └── research/                  # research-only (scout, ios-act) — NOT modules
│       ├── xq-scout-cli.md
│       └── xq-ios-act-cli.md
├── templates/
│   └── module/                    # sole scaffold (language-agnostic contract)
│       ├── README.md              # includes ## Verify → ./scripts/ci.sh
│       ├── Makefile               # optional: `ci:` → ./scripts/ci.sh
│       ├── .gitignore             # stub ignores (node_modules, .build, etc.)
│       ├── scripts/
│       │   └── ci.sh              # canonical verify entry (stub: echo + exit 0)
│       └── skills/
│           └── _example/
│               └── SKILL.md       # placeholder; rename when copying
└── .github/
    └── workflows/
        ├── module-ci.yml          # reusable: inputs module, setup, command
        └── repo-meta.yml          # path filter: AGENTS/README/CONSUMER/.github/templates
# NO modules/ directory in git yet
# NO per-module caller workflows until first module exists
```

### Template contents (outline)

**`templates/module/README.md`**

- What this module does (fill-in)
- How to work: `cd` here; use only this directory’s toolchain
- **Verify:** `./scripts/ci.sh` (or `make ci`)
- Skills: load `skills/<name>/SKILL.md` for agents using this CLI
- Consumer note: orchestrators load root `CONSUMER_CONTEXT.md` then this module’s skill/README

**`templates/module/scripts/ci.sh`** (stub outline)

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Replace with module-local lint/test/build.
# Language examples (pick one when copying):
#   Node:  npm ci && npm test
#   Swift: swift test
echo "ci: stub OK for $(basename "$PWD")"
```

**`templates/module/Makefile`** (optional)

```make
.PHONY: ci
ci:
	./scripts/ci.sh
```

### Where agent skills live

| Scope | Path |
| --- | --- |
| Per module (required pattern) | `modules/<name>/skills/<skill>/SKILL.md` after copy |
| Template stub only | `templates/module/skills/_example/SKILL.md` |
| Repo root | **Never** — no root `.agents/` / `skills/` for product modules |

### What NOT to put at root

- `package.json`, `Package.swift`, workspace / `pnpm-workspace`, `Cargo.toml`
- `./scripts/module`, `modules.yaml`, monorepo `make ci` that builds everything
- Product CLI sources, vendored upstream engines
- Shared “org” glossaries (belong in `xq-context-hub`)

## Agent workflow (add a module later)

1. Read root `AGENTS.md` + `README.md`
2. `cp -R templates/module modules/<name>`
3. Rename skill stub; fill README; replace `scripts/ci.sh` body
4. Add path-filtered caller workflow + gate (devops pattern) when the module is real
5. `cd modules/<name> && ./scripts/ci.sh`
6. Update `CONSUMER_CONTEXT.md` table when the module is consumable

## Pros

- Smallest Phase 1 footprint; no empty-dir / placeholder module noise
- Forces “modules appear when real” — aligns with no-skeleton decision
- Single template matches Work Contract path `templates/module/`

## Cons

- Acceptance wording (“`modules/` exists”) is weaker until first follow-on module
- Agents/humans may hunt for `modules/` and assume the repo is incomplete or broken
- First module PR must also create `modules/` + first caller workflow (slightly fatter first landing)

## Fit vs constraints

| Constraint | Fit |
| --- | --- |
| No skeleton this wave | Strong |
| Template + docs + CI only | Strong |
| Independent modules | Strong |
| Plan acceptance: `modules/` exists | Weak (deferred) |
