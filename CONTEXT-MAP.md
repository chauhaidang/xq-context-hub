# Context Map

Index of org contexts for coding agents. Pick a row, then load only that
domain’s `CONTEXT.md`.

| Area | When to use | Domain context | Primary repos |
| --- | --- | --- | --- |
| Org / cross-cutting | Naming, packages, shared rules, “what repos exist?” | [`org/overview.md`](org/overview.md), [`org/catalogue.md`](org/catalogue.md), [`org/conventions.md`](org/conventions.md) | `xq-context-hub` |
| Fitness | Workouts, fitness app CQRS services, mobile clients for fitness | [`domains/fitness/CONTEXT.md`](domains/fitness/CONTEXT.md) | `xq-fitness-app`, `xq-fitness-write`, `xq-fitness-read`, `xq-fitness-db`, `xq-fitness-gate-keeper`, `xq-mobile-app`, `xq-android-app` |
| Harness / tooling | Test libraries, module runner, stubs, agent CLI box, published `@chauhaidang/xq-harness-*` | [`domains/harness/CONTEXT.md`](domains/harness/CONTEXT.md) | `xq-harness`, `xq-versastack`, `xq-test-infra`, `xq-stubby`, `xq-stub-server`, `xq-toolbox` (legacy) |
| Platform | Platform runtime, contracts, plugins, SDKs, shared kits | [`domains/platform/CONTEXT.md`](domains/platform/CONTEXT.md) | `xq-platform`, `xq-platform-node`, `xq-contracts`, `xq-plugins`, `xq-sdk-node`, `xq-js-common-kit`, `xq-kit-common` |

## Related but not first-class domains yet

These repos exist under `chauhaidang` but do not yet have a dedicated
`domains/*/CONTEXT.md`. Map them via catalogue + nearest domain, or propose a
new domain with the `add-domain-context` skill:

- Test / QA services: `xq-e2e`, `xq-services-test`, `xq-ms-test-plan`, `xq-records`
- Mobile shells: `xq-mobile`, `xq-obj-mgmt`
- Experiments / forks: `grpc-mock`, `poc-android-native-tdd`, `SeleniumJava`, etc.

## Loading rule

```text
task → CONTEXT-MAP row → domain CONTEXT.md (+ org/conventions if coding)
         ↘ do not load sibling domains unless the task crosses them
```
