# Benchmark: Vibium CLI patterns → xq-ios-act-cli

- **Source**: [VibiumDev/vibium](https://github.com/VibiumDev/vibium) (`clicker/` Go binary)
- **Role**: engineer-in-design research (planning only)
- **Relates to**: [`DESIGN.md`](DESIGN.md)

## What Vibium is

Agent-native **browser** automation CLI (Selenium/Appium lineage). ~80+ flat verbs, shipped as a **single Go binary** (~10MB) with:

- CLI + **daemon** + **MCP server** + **client libraries** (JS/Python/Java)
- WebDriver **BiDi** to Chrome
- Agent Skill (`skills/vibe-check/SKILL.md`) as the primary agent contract

## Tech stack (Vibium)

| Layer | Choice |
| --- | --- |
| Language | **Go 1.21+** |
| CLI framework | **[spf13/cobra](https://github.com/spf13/cobra)** |
| WebSocket | gorilla/websocket |
| Binary | Single static binary, cross-compiled |
| Distribution | `npm install -g vibium` bundles binary; PyPI/Maven same |
| Build | Makefile orchestrates Go + JS/Python/Java clients |

## Architecture (the important part)

```text
Agent / human
    │  bash: vibium map && vibium click @e1
    │  MCP:  tools/call browser_click
    ▼
┌─────────────────────────────────────┐
│  vibium CLI (thin, one file/cmd)     │  cobra commands → daemonCall()
└──────────────┬──────────────────────┘
               │ JSON-RPC newline / unix socket
               ▼
┌─────────────────────────────────────┐
│  vibium daemon (long-lived)          │  auto-starts on first command
│  router → tools/call → handlers      │  holds browser session
└──────────────┬──────────────────────┘
               │ WebDriver BiDi WS
               ▼
           Chrome
```

### Key structural choices

1. **Daemon-first** — Browser launch is expensive; daemon stays up between CLI invocations. CLI processes are **ephemeral thin clients**.

2. **Uniform dispatch** — Almost every command is ~15 lines:

   ```go
   result, err := daemonCall("browser_map", toolArgs)
   printResult(result)
   ```

   Tool names (`browser_click`, `browser_map`, …) are the internal API; CLI verbs are the agent API.

3. **One file per command** — `map.go`, `click.go`, `eval.go` each export `newMapCmd()` registered in `main.go`.

4. **Three agent surfaces, one engine**:
   - **CLI** (bash / skill)
   - **MCP** (`vibium mcp` — same handlers as CLI)
   - **Pipe** (`vibium pipe` — for embedded client libraries)

5. **Agent skill is the contract** — `SKILL.md` is a full command reference + workflows (map → act → diff), not a thin pointer.

## CLI UX patterns (copy-worthy)

### Core agent loop: map → ref → act → diff

```bash
vibium go https://example.com
vibium map                    # → @e1, @e2, …
vibium click @e1
vibium diff map               # what changed?
```

Refs are **stable within a page state**; agents re-map after navigation/DOM changes. Skill documents this explicitly.

### Flat verbs, not deep nesting

`vibium click`, `vibium map`, `vibium screenshot` — not `vibium browser element click`.

### Escape hatch

`vibium eval` / `vibium eval --stdin` — arbitrary JS when no wrapper exists.

### Global flags

| Flag | Purpose |
| --- | --- |
| `--json` (opt-in) | `{"ok":true,"result":"..."}` / `{"ok":false,"error":"..."}` |
| `--headless` | Runtime mode |
| `-v` | Debug logging |

Human mode (no `--json`) prints plain text only.

**Our deviation:** JSON **by default**; `--pretty` for human text (agent-first).

### Optional navigate-then-act

`vibium click https://example.com "a"` — URL + selector in one command.

### Auto-start with actionable failure

If daemon socket missing → auto-spawn daemon → retry. Agents never manage browser lifecycle manually.

### Output envelope (simple)

```json
{"ok": true, "result": "..."}
{"ok": false, "error": "..."}
```

Human mode prints plain text only.

## Mapping to xq-ios-act-cli

| Vibium | Our world | Recommendation |
| --- | --- | --- |
| Chrome + chromedriver | **DeviceKit** XCUITest server (already long-lived) | Do **not** build our own daemon in v1 — DeviceKit **is** the server |
| vibium daemon | DeviceKit @ `127.0.0.1:12004` | CLI connects over WS JSON-RPC per command (or pooled connection later) |
| `daemonCall("browser_*")` | `kitCall("device.io.tap", params)` | Single internal dispatch helper; thin command files |
| `map` + `@e1` refs | `device.dump.ui` (accessibility tree) | **Add `map` command** — client assigns `@refs` to tree nodes; cache last map locally |
| `diff map` | Compare UI dumps | **Add `diff map`** — agent verify loop after tap/type |
| `eval` | `rpc --method …` | Keep `rpc` as escape hatch; consider alias `eval` only if we add JS-like surface (probably not) |
| Flat verbs | Nested `device/io/apps` | **Prefer flat verbs** in v1: `map`, `tap`, `screenshot`, `dump`, `launch` |
| MCP server | Out of scope v1 | Skill-first (like Vibium), MCP later if needed |
| `pipe` mode | N/A v1 | Future: stdin JSON-RPC to DeviceKit for Swift lib consumers |
| npm global binary | `swift build` / future brew | Document install; versastack module ships source + skill |
| Auto-start daemon | DeviceKit must be started separately | `health` + **actionable error** that prints how to start DeviceKit (not auto-launch v1) |

## Revised architecture (informed by Vibium)

```text
Agent / skill
    │  xq-ios-act map && xq-ios-act tap @e3
    ▼
┌──────────────────────────────────────────┐
│  xq-ios-act CLI (thin commands)           │
│  map/tap/screenshot/rpc → kitCall()       │
│  optional: ~/.xq-ios-act/last-map.json    │  ← client-side ref cache (Vibium-like)
└──────────────┬───────────────────────────┘
               │ WebSocket JSON-RPC
               ▼
┌──────────────────────────────────────────┐
│  DeviceKit (external, already a daemon)   │
└──────────────────────────────────────────┘
```

**Session state we own (Vibium-inspired):** last UI map + ref table on disk, invalidated on act commands that change UI (document ref lifecycle in skill).

## Revised v1 command surface (Vibium-shaped)

Flat verbs first; group only for `daemon`-like ops if we add them later:

```text
xq-ios-act [--pretty] [--base-url URL] [--timeout SEC]

  health
  map [--out PATH]              # dump UI + assign @refs (core loop)
  diff map                      # compare to last map
  tap @eN | --x N --y N
  type TEXT | @eN TEXT
  screenshot [-o PATH]
  launch --bundle-id ID
  foreground
  dump                          # raw device.dump.ui JSON
  rpc --method M [--params JSON]  # escape hatch
```

Drop deep `device/io/apps` nesting for v1 — matches how agents learn Vibium.

## Tech stack — still Swift, different CLI shape

| Decision | Before Vibium review | After |
| --- | --- | --- |
| Language | Swift 5.9 | **Unchanged** — DeviceKit/iOS alignment |
| CLI framework | ArgumentParser | **Unchanged** — but adopt **one-file-per-command** layout |
| Transport | WS JSON-RPC | **Unchanged** |
| Session | One-shot per command | **Add local map/ref cache** (file); optional WS pool in v1.1 |
| Command tree | Nested `device/io/apps` | **Flat verbs** + `rpc` escape hatch |
| Agent contract | README | **Skill with map→act→diff workflow** (WP2, Vibium-shaped) |

Go is attractive for Vibium because they **own** the engine and ship one binary everywhere. We **don't** own DeviceKit and already committed to Swift in research — no reason to switch.

## Design deltas to apply to DESIGN.md

1. Add **`map`** and **`diff map`** as v1 commands (not v1.1).
2. Switch command tree from nested groups to **flat verbs**.
3. Add **local ref cache** seam (`MapStore` protocol, file-backed default).
4. Document **core agent workflow** in skill: `health` → `map` → `tap @eN` → `diff map`.
5. Internal pattern: every command → `kitCall(method, params)` → `printEnvelope`.

## Open question for product-lead / user

Adopt Vibium's **flat verb + map/@ref** model as the primary agent UX (recommended), or keep nested `device/io/apps` + coordinates-only?

---

## Synthesis: Vibium + MobileCLI → xq-ios-act

**Locked direction** (see [`DESIGN.md`](DESIGN.md) § Hybrid architecture):

| Concern | Owner | Mechanism |
| --- | --- | --- |
| Agent verbs & ref loop | **Vibium** | `map`, `tap @eN`, `diff map`, `MapStore`, skill-first |
| Thin command files | **Vibium** | `kitCall()` ≈ `daemonCall()`; ~15 lines per verb |
| Auto-start runtime | **Vibium pattern** | `ensure_runtime()` before RPC |
| Install signed runner | **MobileCLI pattern** | `devicekit install` ≈ `agent install` + `ResignIPA` |
| Launch runner + forward | **MobileCLI pattern** | `devicekit start` ≈ `StartAgent` |
| Talk to DeviceKit | **DeviceKit native** | **WS `/ws`** JSON-RPC (MobileCLI uses HTTP `/rpc` — we skip that) |
| Mac proxy server | **Neither** | No `:12000` MobileCLI server; direct to `:12004` |

**Agent session (bash):**

```bash
xq-ios-act devicekit install --sim          # once (MobileCLI agent install)
xq-ios-act launch --bundle-id com.example.app
xq-ios-act map && xq-ios-act tap @e3 && xq-ios-act diff map   # Vibium loop
# ensure_runtime() calls devicekit start on first map if server down
```
