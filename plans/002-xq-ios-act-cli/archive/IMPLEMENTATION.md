# Implementation status — xq-ios-act-cli

- **Versastack PR**: https://github.com/chauhaidang/xq-versastack/pull/8
- **Branch**: `xq/xq-ios-act-cli-f8f1`
- **As of**: 2026-07-29

## Shipped (versastack)

| Area | Status |
| --- | --- |
| Swift CLI (`xq-ios-act`) | ✅ ArgumentParser, all v1 verbs |
| `IosAct` library | ✅ transport, map/refs, devicekit lifecycle |
| Devicekit install (sim) | ✅ fetch → `simctl install` |
| Devicekit install (device) | ✅ fetch unsigned IPA → Swift resign → `devicectl install` |
| Devicekit start (sim) | ✅ `simctl launch` + health poll |
| Devicekit start (device) | ✅ `xcodebuild test-without-building` + health poll |
| Tests | ✅ `swift test` (10 tests), mock transport + contract fixtures |
| CI | ✅ macOS-only (`scripts/run-swift.sh`) |

## Deviations from original design

| Design (locked at plan time) | As built |
| --- | --- |
| Dual client: Python primary + Swift optional | **Swift-only** in versastack; Python POC removed |
| Real device start via go-ios tunnel + `runwda` | **Native `xcodebuild`** against installed runner (unsigned IPA + resign) |
| `iproxy` / libimobiledevice port forward | **Not used** — Xcode-only environment |
| Linux CI (Python unit tests) | **Removed** with Python client |
| Module name `XqIosAct` | Renamed to **`IosAct`** (community-style naming) |

## Layout (versastack)

```
modules/xq-ios-act-cli/
  swift/                    # CLI + IosAct library
  scripts/devicekit/
    fetch-release.sh        # pinned devicekit-ios artifacts
    install-sim.sh
    install-device.sh
  contract/                 # golden JSON envelopes
  scripts/run-swift.sh
  scripts/run-all.sh
```

## Real device flow (as built)

```bash
# Install: unsigned IPA from devicekit-ios release → resign in Swift → devicectl
xq-ios-act devicekit install \
  --device <UDID> \
  --provisioning-profile ~/path/to/profile.mobileprovision

# Start: xcodebuild launches DeviceKitUITests/testRunAutomation on device
xq-ios-act devicekit start --device <UDID>
```

Prerequisites: plug in + trust device, Xcode 15+, development provisioning profile.

## Follow-on

- WP2: agent skill
- WP3: live DeviceKit CI gate (`XQ_IOS_ACT_LIVE=1`)
- `ensure_runtime()` auto-start on RPC verbs (partial — status/start exist; full auto-start TBD)
- Hub/design doc refresh if Python client is revived elsewhere for Android path
