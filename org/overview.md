# Org overview — chauhaidang / XQ

## Who

**chauhaidang** is the GitHub org and npm scope for **XQ** products and
tooling. Published packages use the `@chauhaidang` scope on GitHub Packages.

## What XQ is

XQ is a family of products and platforms:

- **Fitness** — CQRS-style fitness services and clients (write / read / DB /
  gate-keeper / apps)
- **Platform** — shared platform runtime, contracts, plugins, and SDKs that
  future XQ products build on
- **Harness** — polyglot testing libraries, module runner, stubs, MCP test
  tooling, and agent-oriented CLI tooling

## Context home

This repository (`xq-context-hub`) is the **org-level AI context home**: maps,
glossaries, and conventions agents should load on demand. Product
implementation detail lives in each product repo; keep this hub lean and
org-scoped.

## Related hubs (not this repo)

| Repo | Role |
| --- | --- |
| [`xq-harness`](https://github.com/chauhaidang/xq-harness) | Testing monorepo, published harness packages, engineering agent skills |
| [`xq-versastack`](https://github.com/chauhaidang/xq-versastack) | Box of CLI tools for AI agents |
| [`xq-toolbox`](https://github.com/chauhaidang/xq-toolbox) | Legacy monorepo of XQ application tools (prefer harness-lineage packages for new work) |

## Registry

```ini
@chauhaidang:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}
```

Token needs `read:packages` (and `write:packages` only when publishing).
