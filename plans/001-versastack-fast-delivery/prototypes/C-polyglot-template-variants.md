# Prototype C — Polyglot template variants

**Idea:** Because research targets diverge (**Node** `xq-scout-cli` vs **Swift** `xq-ios-act-cli`), ship language-specific scaffolds instead of (or in addition to) one agnostic template.

Two shapes are considered; pick one if C wins.

## Variant C1 — Sibling templates (preferred if choosing C)

```text
xq-versastack/
├── AGENTS.md
├── CONSUMER_CONTEXT.md
├── README.md
├── LICENSE
├── .gitignore
├── docs/research/…
├── modules/
│   ├── .gitkeep
│   └── README.md                  # “pick templates/module-node or module-swift”
├── templates/
│   ├── module-node/
│   │   ├── README.md
│   │   ├── package.json           # minimal stub: name, scripts.test, engines.node
│   │   ├── Makefile               # optional make ci
│   │   ├── .gitignore
│   │   ├── scripts/ci.sh          # npm ci && npm test (or npm run ci)
│   │   └── skills/_example/SKILL.md
│   └── module-swift/
│       ├── README.md
│       ├── Package.swift          # executable + test target stubs
│       ├── Makefile
│       ├── .gitignore
│       ├── Sources/ModuleName/main.swift   # hello stub OR empty Sources/.gitkeep
│       ├── Tests/…                # optional minimal test
│       ├── scripts/ci.sh          # swift test
│       └── skills/_example/SKILL.md
└── .github/workflows/
    ├── module-ci.yml              # setup: node | swift | none
    └── repo-meta.yml
```

## Variant C2 — Single template with language folders

```text
templates/module/
├── README.md                      # “copy whole tree, delete the language you don’t use”
├── scripts/ci.sh                  # detects Package.swift vs package.json OR requires edit
├── Makefile
├── skills/_example/SKILL.md
├── node/                          # package.json + node .gitignore fragments
└── swift/                         # Package.swift + Sources stub
```

**Avoid C2** unless strongly desired: copy-then-delete is error-prone for agents; `scripts/ci.sh` becomes a mini-router (smells like a root runner living inside the template).

## Concrete trees — skills and root anti-patterns

### Skills

| Scope | Path |
| --- | --- |
| Node module after copy | `modules/<name>/skills/<skill>/SKILL.md` |
| Swift module after copy | same pattern under that module |
| Template stubs | `templates/module-node/skills/_example/…` and `templates/module-swift/skills/_example/…` |
| Root | **Never** |

### What NOT to put at root

Identical to A/B. Additionally for C:

- Do **not** add a root “template picker” CLI
- Do **not** share a root `node_modules` or Swift workspace across modules
- Language stubs stay **inside** `templates/module-*` only until copied

## Agent workflow

1. Read `modules/README.md` → choose `module-node` or `module-swift`
2. `cp -R templates/module-node modules/xq-scout-cli` (example)
3. Rename package/module identifiers; flesh `scripts/ci.sh` if needed
4. Wire CI caller with matching `setup: node` or `setup: swift`
5. Verify only inside `modules/<name>/`

## Pros

- Matches polyglot research reality with less blank-page work per first module
- `scripts/ci.sh` can be realistic on day one of each language track
- Clearer devops defaults (`setup` input aligns with which template was copied)

## Cons

- **Over-scope for this wave:** still no real modules; two templates to keep in sync with CI stubs and docs
- Work Contract currently names **`templates/module/`** — C requires contract + ownership glob updates (`templates/module-node/**`, etc.)
- Risk of “almost a skeleton”: Swift `Sources/` or Node `package.json` stubs invite drive-by product code
- Diverges from maintainer “template + docs + CI foundation only” if stubs grow teeth
- Dev/test/devops ownership thrash: who owns which language stub?

## Fit vs constraints

| Constraint | Fit |
| --- | --- |
| No skeleton this wave | Medium (stubs can become accidental skeletons) |
| Template + docs + CI only | Medium–weak (more surface) |
| Independent modules | Strong |
| Plan acceptance | Strong if `modules/` documented (combine with B’s empty dir) |
| Current Work Contract path | Weak (needs rewrite) |

## When C becomes worth it

Defer C until a follow-on plan that lands the **first** Node or Swift module, then extract a second language template from the shipped module (template-from-reality) rather than inventing both up front.
