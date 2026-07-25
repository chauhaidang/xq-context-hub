# Repo catalogue — chauhaidang

One-line roles for agents. Prefer [`CONTEXT-MAP.md`](../CONTEXT-MAP.md) to
choose a domain before opening product code.

## Context and agent tooling

| Repo | Role |
| --- | --- |
| `xq-context-hub` | Org AI context home (this repo) |
| `xq-versastack` | CLI tools box for AI agents |
| `xq-harness` | Polyglot testing monorepo; `@chauhaidang/xq-harness-*` packages; agent skills |

## Fitness

| Repo | Role |
| --- | --- |
| `xq-fitness-app` | Fitness application surface |
| `xq-fitness-write` | Fitness write-side service |
| `xq-fitness-read` | Fitness read-side service |
| `xq-fitness-db` | Fitness database / persistence |
| `xq-fitness-gate-keeper` | Fitness gate / access boundary |
| `xq-mobile-app` | Mobile fitness (or shared mobile) app |
| `xq-android-app` | Android client |

## Platform and shared kits

| Repo | Role |
| --- | --- |
| `xq-platform` | XQ Platform |
| `xq-platform-node` | Node platform runtime |
| `xq-contracts` | Shared contracts |
| `xq-plugins` | Plugins and platform dependencies |
| `xq-sdk-node` | Node SDK |
| `xq-js-common-kit` | JavaScript common kit |
| `xq-kit-common` | Shared repeated utilities |
| `xq-obj-mgmt` | Object management |

## Test, stub, and QA infra

| Repo | Role |
| --- | --- |
| `xq-test-infra` | CLI to spin up test environments |
| `xq-e2e` | End-to-end tests |
| `xq-services-test` | Services e2e setup and runs |
| `xq-ms-test-plan` | Test plan service (requirements, cases, reports) |
| `xq-stubby` | Centralized stub server |
| `xq-stub-server` | Stub framework on Camouflage |
| `xq-records` | Records (supporting / data) |
| `grpc-mock` | gRPC mock server via protobuf reflection |

## Legacy / broader tooling

| Repo | Role |
| --- | --- |
| `xq-toolbox` | Legacy monorepo of tools to develop XQ apps |
| `xq-toolings` | Additional tooling |
| `xq-mobile` | Mobile-related repo |

## Profile and experiments

| Repo | Role |
| --- | --- |
| `chauhaidang` | Org / profile repo |
| `poc-android-native-tdd` | Android native TDD POC |
| `SeleniumJava` | Selenium Java experiments |
| `spring-boot-starter` | Spring Boot starter experiments |
| `golang` | Go experiments |
| `react-native-navigation` | RN navigation fork/work |
| `i18n` | WebdriverIO docs translation files |

## Package naming note

- **Harness lineage** (preferred for new installs): `@chauhaidang/xq-harness-*`
- **Legacy toolbox lineage**: shorter `@chauhaidang/xq-*` names without
  `harness-` — still on the registry; do not confuse the two lines
