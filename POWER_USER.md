# Rivals Power-User Extension Guide

Companion to [`CLAUDE.md`](./CLAUDE.md), [`README.md`](./README.md), [`MCP_SETUP.md`](./MCP_SETUP.md), and [`TEST_PLAN.md`](./TEST_PLAN.md). Whereas those documents cover the **current** setup — Rojo 7.6.1, `boshyxd/robloxstudio-mcp` v2.6.0, in-memory `PlayerDataManager`, single-place deploy via Studio's manual Publish — this one covers the **next step** in each direction.

Each of the 34 sections is independent: pick the ones that solve your current friction. Cross-references between sections are explicit. Most sections quote URLs from the May 2026 ecosystem so you can verify before adopting.

## Section index

| § | Topic | Best when… |
|---|---|---|
| 1 | Two-way sync with Argon | Rojo's disk-only direction is slowing you down |
| 2 | Selene + StyLua: lint and format pipeline | First multi-dev PR is incoming |
| 3 | Wally (and pesde): package management for Luau | You keep hand-rolling Signal / Promise / type guards |
| 4 | Luau strict typing & gradual migration | `nil` deref bugs in production |
| 5 | Lune: run Luau outside Studio (testing, asset prep, CI) | You want headless CI tests |
| 6 | Roblox Open Cloud: automate place publishing and DataStore | Manual Publish is a deploy bottleneck |
| 7 | Migrating to Roblox's built-in MCP server (April 2026) | You want first-party support and AI mesh/material gen |
| 8 | Claude Code skill packs for Roblox dev | Repetitive workflows (test runs, build map) |
| 9 | Self-hosting a custom MCP server fork | You need pinned versions or custom tools |
| 10 | GitHub Actions: build + lint + test on every PR | A regression slipped past you once |
| 11 | Claude Code config: hooks, permissions, agents, models | You're tired of permission prompts |
| 12 | Multi-place architecture and Universe management | One place file is 10s+ to open in Studio |
| 13 | DataStore: from in-memory to production-grade persistence | You're shipping to live players |
| 14 | Anti-cheat patterns for Roblox FPS games | A first exploiter shows up |
| 15 | Server-side validation patterns & input sanitization | You realized clients send raw payloads |
| 16 | Telemetry & analytics for Rivals | You want weapon-balance data |
| 17 | Hot reload patterns: live updates without restart | Iteration cycle is too slow |
| 18 | ContentProvider: preload assets, loading screens, asset budgets | First-shot stutters |
| 19 | Component frameworks: Knit, Matter, React Roblox | `RivalsCore.luau` is too monolithic |
| 20 | CI/CD: auto-deploy to Roblox on push | You ship multiple times per week |
| 21 | Testing: TestEZ, Jest-Lua, headless test runners | Manual `TEST_PLAN.md` walkthrough is slow |
| 22 | Profiling, MicroProfiler, performance dashboards | Server FPS is < 60 |
| 23 | Plugin development: turn Rivals tooling into Studio plugins | You build the arena 3× per session |
| 24 | Multi-developer workflow: Rojo + git for a team | A second dev joins |
| 25 | Roblox Creator Dashboard automation | You're awarding badges manually |
| 26 | New Audio API: `AudioEmitter`, `AudioListener`, Wire system | Legacy `Sound` muffling-via-volume isn't cutting it |
| 27 | `MemoryStoreService`: cross-server matchmaking & ephemeral state | Need a global queue across all lobby servers |
| 28 | Instance pooling: bullets, particles, decals | Server FPS drops during sustained fire |
| 29 | UI accessibility & Experience Controls | Gamepad nav + localization (no screen-reader API yet) |
| 30 | Bit-packed network buffers (Luau `buffer` API) | Replication burns >50 KB/s/player |
| 31 | Parallel Luau: Actors and `task.desynchronize` | Server thread can't keep up with raycasts |
| 32 | Procedural animation & `IKControl` | Recoil/sway/look-at need real-time joint solves |
| 33 | Native subscriptions & recurring monetization | One-time GamePass income isn't covering server costs |
| 34 | `--!native` Luau compilation for hot paths | Tight math loops (physics, ECS) are bottlenecking server FPS |

---

## 1. Two-way sync with Argon

> **Note on framing.** Argon is an **alternative** to Rojo (only one runs at a time against a given Studio session), not a companion. The reason to switch is two-way sync — the one capability Rojo deliberately doesn't ship. Keep Rojo if disk → Studio is enough for you; pick up Argon when "I tweaked a Part in Studio, now I have to redo it in code" is hurting iteration speed.

Rojo 7.6.1 is one-way: disk → Studio. Argon adds **bidirectional sync** of code and instance properties, exports an existing place back to files ("Roblox → VS Code" porting), and avoids Rojo's `.meta.json` boilerplate for UI/instance trees; it also never deletes children when you rename or reparent an instance ([devforum announcement](https://devforum.roblox.com/t/argon-full-featured-tool-for-roblox-development/2021776), [argon.wiki/api/project](https://argon.wiki/api/project)). Plugin hot-reload is **not** a documented Argon feature — that's still a Studio plugin loop.

### Project file conversion

Argon keeps Rojo's `tree` / `$className` / `$path` / `$properties` shape but renames root fields (e.g. `servePort` -> `port`, `globIgnorePaths` -> `ignoreGlobs`) and adds a `syncback` block to control what Studio is allowed to write back to disk ([argon.wiki/api/project](https://argon.wiki/api/project)). Save this as `rivals.project.json` (leave `default.project.json` for Rojo fallback):

```json
{
  "name": "rivals-game",
  "host": "localhost",
  "port": 8000,
  "syncback": {
    "ignoreNames": ["Camera"],
    "ignoreClasses": ["Terrain"],
    "ignoreProperties": ["FilteringEnabled"]
  },
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": { "$path": "src/shared" },
    "ServerScriptService": { "$path": "src/server" },
    "StarterPlayer": {
      "StarterPlayerScripts": { "$path": "src/client" }
    },
    "Workspace": {
      "$properties": { "Gravity": 196.2 },
      "Terrain": { "$className": "Terrain" }
    },
    "Lighting": {
      "$properties": { "Brightness": 2, "GlobalShadows": true, "ShadowSoftness": 0.2 }
    },
    "SoundService": { "$properties": { "RespectFilteringEnabled": true } },
    "HttpService": { "$properties": { "HttpEnabled": true } }
  }
}
```

Note port `8000` (Argon default) vs `34872` (Rojo); `FilteringEnabled` is dropped from `Workspace.$properties` because it's deprecated and Argon will otherwise round-trip it back as a mutation.

### Install (Windows - pick one)

```powershell
# A. Rokit (recommended - pins versions per-project)
rokit add argon-rbx/argon --global

# B. Cargo
cargo install argon-rbx

# C. Release binary - argon-windows-x86_64.zip from
#    https://github.com/argon-rbx/argon/releases/latest, unzip to
#    %USERPROFILE%\.argon\bin (already done on this machine)
```

Sources: [argon.wiki/docs/installation](https://argon.wiki/docs/installation), [github.com/argon-rbx/argon](https://github.com/argon-rbx/argon).

### Studio plugin

```powershell
argon plugin install
```

Writes the `.rbxm` to `%LOCALAPPDATA%\Roblox\Plugins\` ([argon.wiki/docs/installation](https://argon.wiki/docs/installation)). Restart Studio, then **disable the Rojo plugin** (Plugins -> Manage Plugins) - two sync plugins polling the same DataModel will race and corrupt files on disk.

### Switching cleanly

```powershell
# Rojo mode
tools\rojo.exe serve default.project.json          # port 34872

# Argon mode (run only one at a time)
%USERPROFILE%\.argon\bin\argon.exe serve rivals.project.json   # port 8000
%USERPROFILE%\.argon\bin\argon.exe stop --all                  # kill all sessions
```

### Trade-offs

- Running both simultaneously: duplicated writes, dupe RemoteEvents, file thrash. Always stop one before starting the other.
- Syncback can **clobber the pre-applied bug fixes** listed in `CLAUDE.md` (e.g. the `LobbyPads` `TouchTransducer` fix) if you edit those scripts in Studio - syncback writes Studio's copy over disk. Add their filenames to `syncback.ignoreGlobs` if you only want code flowing disk -> Studio for them.
- Argon's `port 8000` collides with common dev servers; change it in the project file if needed.

### 5-step migration checklist

1. `rokit add argon-rbx/argon --global` (or use the existing `~/.argon/bin/argon.exe`).
2. Save the JSON above as `rivals.project.json`; keep `default.project.json` for Rojo fallback.
3. Stop Rojo (`tools\rojo.exe` Ctrl+C) and disable its Studio plugin.
4. `argon plugin install`, restart Studio, enable the Argon plugin.
5. `argon serve rivals.project.json`, connect from Studio, edit one file on each side to verify round-trip, then commit.

## 2. Selene + StyLua: lint and format pipeline

Selene (static analyzer, Rust) and StyLua (formatter) are the de-facto pair for Roblox Luau. Latest as of May 2026: **selene 0.30.1**, **stylua 2.5.2**.

### One-command install (Windows, via Rokit)

Rokit is already on this machine for Argon, so reuse it:

```powershell
rokit add Kampfkarren/selene@0.30.1
rokit add JohnnyMorganz/StyLua@2.5.2
rokit install
```

Rokit pins versions per-project in `rokit.toml`, so CI and teammates get the same binaries. ([rokit](https://github.com/rojo-rbx/rokit), [selene install](https://kampfkarren.github.io/selene/cli/installation.html))

### Manual runs

```powershell
selene src/                    # lint, exits non-zero on warn+
stylua --check src/            # verify formatting, non-zero on diff
stylua src/                    # rewrite in place
selene --display-style=json src/ | jq    # machine-readable
```

### Pre-commit hook (one-liner)

```powershell
@'
#!/bin/sh
stylua --check src/ && selene src/
'@ | Set-Content -Encoding ASCII .git/hooks/pre-commit; icacls .git/hooks/pre-commit /grant Everyone:RX
```

### VS Code settings (`.vscode/settings.json`)

Install extensions `Kampfkarren.selene-vscode` and `JohnnyMorganz.stylua`, then:

```json
{
  "stylua.searchParentDirectories": true,
  "[lua]":  { "editor.defaultFormatter": "JohnnyMorganz.stylua", "editor.formatOnSave": true },
  "[luau]": { "editor.defaultFormatter": "JohnnyMorganz.stylua", "editor.formatOnSave": true },
  "selene.run": ["onSave", "onType"]
}
```

### Expanded `selene.toml` tuned for FPS code

Rule keys verified against the selene docs ([lint list](https://kampfkarren.github.io/selene/lints.html)). `unused_variable` already ignores `^_` by default; we make it explicit and tighten Roblox-specific checks that catch real FPS bugs (out-of-range Color3, wrong incrementing, dead globals from network code).

```toml
std = "roblox"

[config.unused_variable]
allow_unused_self = true
ignore_pattern    = "^_"        # `_unused` is fine; bare `unused` warns

[lints]
roblox_incorrect_color3_new_bounds = "deny"   # 0-1 range, not 0-255
roblox_incorrect_roact_usage       = "deny"
incorrect_standard_library_use     = "deny"
mismatched_arg_count               = "deny"
shadowing                          = "warn"
global_usage                       = "deny"   # forces `_G.` to be explicit
multiple_statements                = "warn"
empty_if                           = "warn"
undefined_variable                 = "deny"
unused_variable                    = "warn"
manual_table_clone                 = "warn"
```

### GitHub Actions job — add `.github/workflows/lint.yml`

```yaml
name: Lint & Format
on:
  pull_request:
  push: { branches: [main] }
jobs:
  lua:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: CompeyDev/setup-rokit@v0.2.1
        with: { token: ${{ secrets.GITHUB_TOKEN }} }
      - name: StyLua check
        uses: JohnnyMorganz/stylua-action@v5  # v5.0.0, 2026-04-06
        with:
          token:   ${{ secrets.GITHUB_TOKEN }}
          version: 2.5.2
          args:    --check src/
      - name: Selene
        run: selene --display-style=quiet src/
```

([stylua-action](https://github.com/JohnnyMorganz/stylua-action))

### Fail CI vs. warn-only

- `selene src/` exits **1** on any `deny`, **0** on `warn`. To gate PRs on warnings too, run `selene --no-summary src/ 2>&1 | tee out.log; ! grep -q '^warning' out.log`.
- `stylua --check` exits **1** on any diff (hard fail). For warn-only, swap to `stylua --check src/ || echo "::warning::format drift"; exit 0`.
- Per-rule downgrades live in `selene.toml`: change `"deny"` to `"warn"` to keep the signal without blocking.

Sources: [selene releases](https://github.com/Kampfkarren/selene/releases) · [stylua releases](https://github.com/JohnnyMorganz/StyLua/releases) · [selene config docs](https://kampfkarren.github.io/selene/usage/configuration.html) · [unused_variable](https://kampfkarren.github.io/selene/lints/unused_variable.html) · [roblox_incorrect_color3_new_bounds](https://kampfkarren.github.io/selene/lints/roblox_incorrect_color3_new_bounds.html)

## 3. Wally (and pesde): package management for Luau

`RivalsCore.luau` is 1635 lines of hand-rolled signals, type checks, and RemoteEvent plumbing. Wally is the Cargo/npm-equivalent for Roblox; swapping bespoke systems for battle-tested packages cuts that file in half and gives you maintained code.

> **2026 update — consider pesde.** [pesde](https://docs.pesde.dev/) is a newer package manager from the Lune ecosystem. Its pitch over Wally: better handling of multi-runtime projects (Lune scripts + Studio code sharing the same lockfile), more reliable lockfile semantics, and first-class support for installing tools (not just libraries). Wally is still the safe default for Studio-only flows because the registry has more packages and the community uses it more heavily. If you're combining Lune (§5) with Roblox code in the same repo, evaluate pesde for the new modules and keep Wally for the existing Roblox-specific dependency tree.

### Install Wally (Rokit, already on this machine)

```powershell
rokit add UpliftGames/wally@0.3.2
rokit install
```

### `wally init` + recommended `wally.toml`

```powershell
wally init   # scaffolds wally.toml with [package] block
```

Then replace it with:

```toml
[package]
name        = "tahaarauf/rivals"
description = "Rivals FPS"
version     = "0.1.0"
license     = "MIT"
registry    = "https://github.com/UpliftGames/wally-index"
realm       = "shared"

[dependencies]
Promise = "evaera/promise@4.0.0"
Signal  = "sleitnick/signal@2.0.3"
Knit    = "sleitnick/knit@1.7.0"
Net     = "sleitnick/net@0.2.0"
t       = "osyrisrblx/t@3.1.1"
Janitor = "howmanysmall/janitor@1.18.3"
Matter  = "matter-ecs/matter@0.8.5"

[dev-dependencies]
TestEZ  = "roblox/testez@0.4.1"
```

### Update `default.project.json`

Wally drops a `Packages/` folder at repo root. Mount it as a sibling of `src/shared`:

```json
"ReplicatedStorage": {
  "$className": "ReplicatedStorage",
  "$path": "src/shared",
  "Packages": { "$path": "Packages" }
}
```

Gitignore `Packages/`; commit `wally.toml` + `wally.lock`.

### `wally install` + folder layout

```powershell
wally install
# Packages/
#   _Index/             (content-addressed flat cache)
#   Promise.lua         (thin re-export stubs)
#   Signal.lua
#   ...
# wally.lock            (commit this)
```

In Luau: `local Signal = require(ReplicatedStorage.Packages.Signal)`.

### What each package replaces

**evaera/promise@4.0.0** — A+-style async without surprise yields.
```lua
local Promise = require(Pkgs.Promise)
return Promise.new(function(res) DataStore:GetAsync(key):andThen(res) end)
-- replaces hand-rolled pcall+task.spawn DataStore retry loops in PlayerDataManager
```

**sleitnick/signal@2.0.3** — Typed event with `:Once`, `:Wait`, disconnect tokens.
```lua
local OnKill = Signal.new()
OnKill:Connect(function(victim, killer) ... end) ; OnKill:Fire(v, k)
-- replaces the `CombatSystem._listeners = {}` table-of-callbacks pattern
```

**sleitnick/knit@1.7.0** — Service/Controller container with auto RemoteFunction generation.
```lua
local Combat = Knit.CreateService { Name = "Combat", Client = { Hit = Knit.CreateSignal() } }
function Combat.Client:RegisterHit(plr, target, dmg) return self:Validate(plr, target, dmg) end
-- replaces the manual `Remotes:FindFirstChild("DamagePlayer"):FireServer(...)` plumbing
```

**sleitnick/net@0.2.0** — Buffer-packed batched RemoteEvents, ~10x cheaper than raw.
```lua
local Net = require(Pkgs.Net) ; local Hit = Net:RemoteEvent("Hit")
Hit:FireServer(targetId, damage)   -- batched per frame, buffer-serialized
-- replaces every `Instance.new("RemoteEvent")` call in CombatSystem
```

**osyrisrblx/t@3.1.1** — Runtime type validation, composable.
```lua
local isHit = t.strictInterface { target = t.instanceIsA("Player"), dmg = t.numberPositive }
assert(isHit(payload), "bad hit payload")
-- replaces the if-type-then-return-nil chains in every OnServerEvent handler
```

**howmanysmall/janitor@1.18.3** — Disposable bag for connections, instances, threads.
```lua
local jan = Janitor.new() ; jan:Add(part) ; jan:Add(conn) ; jan:Add(thread)
Players.PlayerRemoving:Connect(function(p) playerJanitors[p]:Destroy() end)
-- replaces manual `for _,c in conns do c:Disconnect() end` in PlayerRemoving cleanup
```

**matter-ecs/matter@0.8.5** — Deterministic ECS world, hot-reloadable systems.
```lua
local world = Matter.World.new() ; world:spawn(Position(v3), Velocity(v3), Health(100))
Matter.Loop.new(world):scheduleSystems({ movementSystem, hitregSystem }):begin({ RunService.Heartbeat })
-- replaces MovementSystem per-player while-loops with one hot-reloadable system
```

**roblox/testez@0.4.1** — BDD-style runner with `describe/it/expect`.
```lua
describe("CombatSystem", function() it("denies negative damage", function()
  expect(Combat:Validate(p, t, -5)).to.equal(false) end) end)
-- gives you `wally install && lemur Packages/TestEZ` in CI; replaces zero existing tests
```

Sources: [wally docs](https://wally.run/) · [Wally GitHub](https://github.com/UpliftGames/wally) · [Rojo project format](https://rojo.space/docs/v7/project-format/) · [evaera/promise](https://github.com/evaera/roblox-lua-promise) · [Sleitnick/RbxUtil](https://github.com/Sleitnick/RbxUtil) · [Knit docs](https://sleitnick.github.io/Knit/) · [osyrisrblx/t](https://github.com/osyrisRBLX/t) · [howmanysmall/Janitor](https://github.com/howmanysmall/Janitor) · [matter-ecs/matter](https://github.com/matter-ecs/matter) · [TestEZ](https://github.com/Roblox/testez)

## 4. Luau strict typing & gradual migration

Your `src/` ships zero `--!` directives today, yet `types/globalTypes.d.luau` (765 KB) and `types/roblox-api-docs.json` (2.5 MB) mean luau-lsp can already infer Roblox API types — you're paying the storage cost without collecting the IDE win.

> **2026 note — new type solver.** Roblox shipped a **new Luau type solver** (behind a fast-flag through 2024, now in flighted rollout — see luau.org/news for the latest cadence; the team posts progress as recap blogs rather than as a single RFC) that significantly improves inference for generic functions, variadic args, type packs, and refinement narrowing. The semantics below match the new solver; if luau-lsp reports types differently from `roblox-cli analyze` in Studio, you're likely seeing legacy-solver behavior — bump your lsp version and Studio's new-solver Studio setting under `Studio Settings → Lua`. Test under the new solver before adopting strict mode in production: some legacy strict-mode passes break (and some legacy failures pass) under v2. See [Luau team blog: luau.org/news](https://luau.org/news) for the rollout history.

### 4.1 The three modes

| Pragma | Behavior | Catches |
|---|---|---|
| `--!nocheck` | Type inference engine never starts | Nothing |
| `--!nonstrict` *(default)* | Lenient: unknowns become `any`, no cross-statement tracking | Obvious type errors only |
| `--!strict` | Sound tracking, "no false negatives" goal | `nil` deref, arity, wrong-type args, return mismatch |

Put the pragma as the **first line** of the file. `--!nostrict` (missing the `n`) is silently ignored.

### 4.2 Migration ladder

1. Drop `--!nonstrict` on every file (explicit > implicit; future-proof against default flips).
2. Add type annotations to **exported** functions (the API surface other files see).
3. Promote leaf modules to `--!strict` once their public types are stable.
4. Work inward: strictify callers only after their dependencies are strict.

### 4.3 Concrete signatures for your systems

```luau
--!strict
-- src/shared/WeaponSystem.luau (after extraction from RivalsCore)
export type WeaponConfig = {
    Name: string,
    Damage: number,
    FireRate: number,
    MaxAmmo: number,
    ReloadTime: number,
    Range: number?,        -- `?` = optional/nullable
}

local WeaponSystem = {}
WeaponSystem.__index = WeaponSystem

export type WeaponSystem = typeof(setmetatable(
    {} :: { Character: Model, Config: WeaponConfig, Ammo: number },
    WeaponSystem
))

function WeaponSystem.new(Character: Model, WeaponName: string): WeaponSystem
    local self = setmetatable({}, WeaponSystem)
    return self :: WeaponSystem
end

function WeaponSystem:Fire(direction: Vector3): boolean
    return self.Ammo > 0
end
```

```luau
-- src/shared/MapSystem.luau
export type QueueType = "OneVOne" | "TwoVTwo" | "FiveVFive" | "Special"  -- literal union

export type PadDef = {
    Name: string,
    Color: Color3,
    Position: Vector3,
    QueueType: QueueType,
    TeamSize: number,
}
```

### 4.4 Shared types module

Create `src/shared/Types.luau` that re-exports every cross-module `type`:

```luau
--!strict
local Types = {}
export type WeaponConfig = { Name: string, Damage: number, FireRate: number }
export type PadDef = { Name: string, Color: Color3, Position: Vector3, QueueType: string, TeamSize: number }
return Types
```

Consumers: `local Types = require(ReplicatedStorage.Types); type Pad = Types.PadDef`.

### 4.5 Wiring `globalTypes.d.luau` to luau-lsp

The definitions file is an **LSP-time** input — it does not need a per-file pragma. Add to `.vscode/settings.json`:

```json
{
  "luau-lsp.types.definitionFiles": ["types/globalTypes.d.luau"],
  "luau-lsp.types.documentationFiles": ["types/roblox-api-docs.json"],
  "luau-lsp.diagnostics.strictDatamodelTypes": true
}
```

Types resolve in `nonstrict` and `strict` alike; only `nocheck` opts out.

### 4.6 Gotchas

- **OOP metatables**: always `typeof(setmetatable({} :: Fields, ClassTbl))` — bare `{}` loses field types.
- **Nil safety in strict**: `instance:FindFirstChild("X")` returns `Instance?`; refine with `if x then ... end` or `assert(x, "...")`.
- **Function narrowing**: `local cb = obj.OnHit; if cb then cb(dmg) end` — Luau narrows `cb` to non-nil inside the branch.
- **`any` is contagious**: one untyped require collapses inferred types downstream.

### 4.7 4-step ROI-ordered plan

1. **`Settings.luau`** — smallest, zero deps, pure data. Strictify, export every constant's type. One afternoon.
2. **`MapSystem.luau`** — `PadDef`, queue types, spawn data. Locks down the lobby contract.
3. **Extract `WeaponSystem`** from RivalsCore — `WeaponConfig` + `typeof(setmetatable)` class. Template for other OOP modules.
4. **`RivalsCore.luau`** — migrate in chunks: state types first, then handlers, then network bridges. Keep `--!nonstrict` until clean, then flip.

Sources: [Luau type checking](https://luau.org/types) · [Luau typecheck reference](https://luau.org/types) · [luau-lsp editors](https://github.com/JohnnyMorganz/luau-lsp/blob/main/editors/README.md) · [Roblox creator-docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/luau/type-checking.md)

## 5. Lune: run Luau outside Studio (testing, asset prep, CI)

**Lune** is a standalone Luau runtime written in Rust — think Node for Luau. It is *not* a Roblox emulator (no rendering, no physics, no `Players`, no `RunService.Heartbeat`), but ships a `roblox` standard library that can parse `.rbxl`/`.rbxlx`, give you real `Instance` objects, mutate them, and write the file back. Latest stable **0.10.4** (Oct 2024). [lune-org/lune](https://github.com/lune-org/lune)

**Std libraries available:** `fs`, `net`, `process`, `stdio`, `task`, `datetime`, `regex`, `serde`, `crypto`, `luau`, and `roblox`. [Lune docs](https://lune-org.github.io/docs/)

### Install via Rokit

```bash
rokit add lune-org/lune
rokit install
lune --version   # -> lune 0.10.4
```

### Three concrete uses for Rivals

**1. Headless test runner.** Drop `_spec.luau` files under `tests/`, then `lune run tests/runner`. CI runs in seconds — no Studio launch, no GUI. Caveat: Lune's `require` follows the new Luau RFC (paths must start with `./`, `../`, or `@alias`), so unit tests target *pure* modules.

**2. Build + publish automation.** A single `lune run scripts/release` can `rojo build default.project.json -o build.rbxl`, then POST it to Open Cloud (see section 6). One command, no clicking.

**3. Static analysis over the sourcemap.** Feed `sourcemap.json` (from `rojo sourcemap --output sourcemap.json`) into a Lune script that walks the tree, sums LOC per script, flags unreferenced ModuleScripts. Catches dead `RivalsCore` chains before they ship.

### The `roblox` library — round-tripping a place file

```lua
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local place = roblox.deserializePlace(fs.readFile("build.rbxlx"))
for _, desc in place:GetDescendants() do
  if desc:IsA("Script") and desc.Disabled then
    desc:Destroy()                      -- strip dead scripts
  end
end
fs.writeFile("build.clean.rbxlx", roblox.serializePlace(place))
```

[Roblox library reference](https://lune-org.github.io/docs/api-reference/roblox/)

### `tests/runner.luau` template

```lua
local fs = require("@lune/fs")
local process = require("@lune/process")

local function findSpecs(dir, out)
  for _, name in fs.readDir(dir) do
    local path = `{dir}/{name}`
    if fs.isDir(path) then findSpecs(path, out)
    elseif name:match("_spec%.luau$") then table.insert(out, path) end
  end
  return out
end

local specs = findSpecs("tests", {})
local failed = 0
for _, spec in specs do
  local ok, err = pcall(require, `./{spec:gsub("%.luau$", "")}`)
  if ok then print(`[PASS] {spec}`)
  else failed += 1; print(`[FAIL] {spec}\n  {err}`) end
end
print(`\n{#specs - failed}/{#specs} passed`)
process.exit(failed == 0 and 0 or 1)
```

### Limitations

- No engine: no rendering, no physics solver, no `Players`, no `Heartbeat` ticking automatically (use `@lune/task`).
- DataModel state is in-memory only — no live `DataStoreService`, no `MessagingService`.
- Newly written model files re-randomize internal UUIDs — expect diff churn on round-trips.

Sources: [github.com/lune-org/lune](https://github.com/lune-org/lune) · [docs](https://lune-org.github.io/docs/) · [installation](https://lune-org.github.io/docs/getting-started/1-installation/) · [roblox API](https://lune-org.github.io/docs/api-reference/roblox/)

## 6. Roblox Open Cloud: automate place publishing and DataStore

Right now you publish `rivals.rbxlx` by opening it in Studio and hitting **File -> Publish to Roblox**. Open Cloud removes Studio from the loop. Four surfaces matter:

1. **Place Publishing** — `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published` overwrites a live place with a `.rbxl`/`.rbxlx` you upload.
2. **DataStore** — `https://apis.roblox.com/datastores/v1/universes/{universeId}/standard-datastores/datastore/entries` for Get/Set/Increment/Delete from outside the game. Ordered DataStores live at `/ordered-datastores/v1/`.
3. **MessagingService** — `POST .../messaging-service/v1/universes/{universeId}/topics/{topic}` pushes a payload to every live server (subscribe in-game with `MessagingService:SubscribeAsync`).
4. **Luau Execution** — `POST /cloud/v2/universes/{u}/places/{p}/versions/{v}/luau-execution-session-tasks` runs server-side Luau in a headless game instance and returns logs/output. GA since 2025.

### API key setup

`create.roblox.com` -> avatar -> **Open Cloud -> API Keys -> Create API Key**. Keys are scoped per **experience** and per **permission** — for full automation grant `universe-places:write`, `universe-datastores.objects:create/update/read/delete`, `universe-messaging-service:publish`, and `universe.execution-task:write`. Set **IP allowlist** to your GitHub Actions egress range (or `0.0.0.0/0` only for local testing) and a 30-day expiration. Rotate quarterly.

### PowerShell upload of `rivals.rbxlx`

```powershell
$key      = $env:ROBLOX_OPENCLOUD_KEY        # never hard-code
$universe = 1234567890
$placeId  = 9876543210
tools\rojo.exe build default.project.json -o rivals.rbxlx
Invoke-RestMethod `
  -Method  Post `
  -Uri     "https://apis.roblox.com/universes/v1/$universe/places/$placeId/versions?versionType=Published" `
  -Headers @{ "x-api-key" = $key } `
  -ContentType "application/octet-stream" `
  -InFile  "rivals.rbxlx"
```

`application/xml` is also accepted for `.rbxlx`; `octet-stream` works for both formats.

### Lune equivalent (`net.request`)

```lua
local net, fs = require("@lune/net"), require("@lune/fs")
local res = net.request({
  url     = `https://apis.roblox.com/universes/v1/{universe}/places/{placeId}/versions?versionType=Published`,
  method  = "POST",
  headers = { ["x-api-key"] = os.getenv("ROBLOX_OPENCLOUD_KEY"), ["Content-Type"] = "application/octet-stream" },
  body    = fs.readFile("rivals.rbxlx"),
})
assert(res.ok, res.statusMessage .. " " .. res.body)
```

### GitHub Actions step (drop into `.github/workflows/publish.yml`)

```yaml
- name: Build + publish to Roblox
  env:
    ROBLOX_OPENCLOUD_KEY: ${{ secrets.ROBLOX_OPENCLOUD_KEY }}
    UNIVERSE_ID: ${{ vars.UNIVERSE_ID }}
    PLACE_ID:    ${{ vars.PLACE_ID }}
  run: |
    ./tools/rojo build default.project.json -o rivals.rbxlx
    curl -sS -f -X POST \
      -H "x-api-key: $ROBLOX_OPENCLOUD_KEY" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @rivals.rbxlx \
      "https://apis.roblox.com/universes/v1/$UNIVERSE_ID/places/$PLACE_ID/versions?versionType=Published"
```

### Rate limits (per API key, per minute)

| Surface | Limit |
|---|---|
| Place Publishing | **10/min** per place (older docs cite 250/day total) |
| DataStore Standard read/write | **300/min** per universe |
| DataStore **in-game** (per server) | `60 + 10 x players` req/min |
| MessagingService publish | Sent: `600 + 240 × players` per server/min. Received per topic: `40 + 80 × servers`/min; per universe: `400 + 200 × servers`/min. Open Cloud + engine share the budget (unified May 2026). |
| Luau Execution | **60 tasks/min**, 5-min max runtime, 1 MiB payload |

429s carry a `retry-after` header — honor it with exponential backoff.

### Security

Treat the key like an AWS root token. Store in **GitHub repo secrets** (`Settings -> Secrets and variables -> Actions`), never in `default.project.json` or a committed `.env`. Gitignore `*.key`, `.env*`. Enable **IP allowlist** on the key (Actions egress: `gh api meta -q .actions`) and use the shortest practical expiration. Audit at `creator.roblox.com -> Open Cloud -> API Keys -> Logs`.

Sources: [Cloud API reference](https://create.roblox.com/docs/cloud) · [Manage API keys](https://create.roblox.com/docs/cloud/auth/api-keys) · [Rate limits overview](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/reference/rate-limits.md) · [DataStore request handling](https://create.roblox.com/docs/cloud/guides/data-stores/request-handling) · [Place publishing announcement](https://devforum.roblox.com/t/open-cloud-publishing-your-places-with-api-keys-is-now-live/1485135) · [Luau Execution API](https://create.roblox.com/docs/cloud/features/luau-execution) · [MessagingService unification](https://devforum.roblox.com/t/unifying-messagingservice-opencloud-api-and-engine-api-rate-limits/4600993)

## 7. Migrating to Roblox's built-in MCP server (April 2026)

As of April 15, 2026, Roblox ships an MCP server **inside Studio itself** — no separate binary, no plugin install, tools auto-sync with Assistant. This is now the recommended path for Claude Code, Cursor, Codex, Claude Desktop, VS Code, and Gemini CLI ([about.roblox.com](https://about.roblox.com/newsroom/2026/04/roblox-studio-going-agentic), [docs](https://create.roblox.com/docs/studio/mcp)).

### Where it lives
Studio → **Assistant** icon → click **…** → **Manage MCP Servers** → toggle **Enable Studio as MCP server**.

### Built-in vs `boshyxd/robloxstudio-mcp` v2.6.0

| Capability | Built-in (Apr 2026) | boshyxd v2.6.0 |
|---|---|---|
| Tool count | ~19 first-party, auto-synced with Assistant | 69 |
| Script editing | `script_read`, `multi_edit`, `script_search`, `script_grep` | `get_script_source`, `edit_script_lines`, `find_and_replace_in_scripts` |
| Asset generation | `generate_mesh`, `generate_material`, `generate_procedural_model`, `insert_from_creator_store` | Creator Store search only |
| Playtest + input sim | `start_stop_play`, `get_console_output`, `character_navigation`, `user_keyboard_input`, `user_mouse_input` | `start_playtest`, `simulate_keyboard_input`, `simulate_mouse_input`, `capture_screenshot` |
| Multi-instance | `list_roblox_studios`, `set_active_studio` | single instance |
| Bulk ops (`mass_set_property`, `mass_create_objects`, `smart_duplicate`, tag CRUD, build import/export) | not present | present |
| Auth | Studio-managed, unprivileged APIs | plugin RBXMX |
| Updates | server-side, zero churn | manual `npm`/release pull |

**Gained:** AI mesh/material generation, multi-Studio routing, hands-off updates, no plugin file. **Lost:** ~50 fine-grained instance/build/tag tools. **Identical in spirit:** script edit, playtest, screen capture, input sim.

### Quick Connect (Claude Code)
The Manage MCP Servers panel shows a per-client one-click button. For Claude Code it copies a `claude mcp add` invocation:

```powershell
claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
```

> Older builds shipped `rbx-studio-mcp.exe`; newer builds wrap it in `mcp.bat`.

### Running both side-by-side — safe
Both transports are **stdio**, not TCP, so there's no port collision. The docs explicitly recommend running both: *"If you're using multiple MCP servers, copy the `Roblox_Studio` entry and add it to your existing `mcpServers` dictionary"*. Tool names don't overlap (`multi_edit` vs `edit_script_lines`), so Claude Code disambiguates cleanly.

### Migration steps
1. Quit Claude Code.
2. Studio → Assistant → … → Manage MCP Servers → **Enable Studio as MCP server**.
3. Delete `%LOCALAPPDATA%\Roblox\Plugins\RobloxStudioMCP.rbxmx` (boshyxd plugin).
4. Replace `C:\Users\admin\rivals-multiplayer\.mcp.json`:

```json
{
  "mcpServers": {
    "Roblox_Studio": {
      "command": "cmd.exe",
      "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]
    }
  }
}
```

5. Restart Claude Code, reopen the project.

### Rollback
Toggle **Enable Studio as MCP server** off, reinstall the v2.6.0 RBXMX from `boshyxd/robloxstudio-mcp` releases, restore the previous `.mcp.json` from git.

### Sanity check
```
> claude mcp list
Roblox_Studio  stdio  ✓ connected  (19 tools)
```
If you kept both: a second line `robloxstudio-mcp  stdio  ✓ connected  (69 tools)`.

Sources: [Roblox going agentic, 2026-04-15](https://about.roblox.com/newsroom/2026/04/roblox-studio-going-agentic) · [Connect to Studio MCP](https://create.roblox.com/docs/studio/mcp) · [Assistant updates, devforum 2026-03-05](https://devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643)

## 8. Claude Code skill packs for Roblox dev

### What is a Claude Code skill?

A **skill** is a Markdown file with YAML frontmatter that Claude auto-loads when its `description` matches the current task. Skills live in two places:

- **Project-scoped:** `C:\Users\admin\rivals-multiplayer\.claude\skills\<name>\SKILL.md` (commits with repo, applies only to Rivals)
- **User-scoped:** `~/.claude/skills/<name>/SKILL.md` (applies to every project)

Skills can contain prose, reference files, *and* shell out to tools listed in `allowed-tools:` (a space-separated string or YAML list) — including any MCP server registered in `.mcp.json`.

### Top 3 packs for Rivals

1. **[brockmartin/roblox-game-skill](https://github.com/brockmartin/roblox-game-skill)** (21 stars) — Single router with 18 routing paths, 16 reference files (Luau, architecture, security, datastores, GUI, perf), 7 templates, MCP integration. Auto-fires on Roblox/Luau keywords. **Why:** Security + perf references directly useful for FPS.
   ```bash
   git clone https://github.com/brockmartin/roblox-game-skill ~/.claude/skills/roblox-game
   ```

2. **[sentinelcore/roblox-skills](https://github.com/sentinelcore/roblox-skills)** (6 stars) — Seven granular skills: `roblox-remote-events`, `roblox-security`, `roblox-datastores`, `roblox-performance`, `roblox-gui`, `roblox-animations`, `roblox-monetization`. **Why:** RemoteEvent + server-validation skills map 1:1 to Rivals' hit-reg and anti-cheat path.

3. **[CodePhobiia/claude-roblox-game-studio](https://github.com/CodePhobiia/claude-roblox-game-studio)** (3 stars) — 36 agents, 50 slash commands, 9 hooks. **Why:** Heavy, but `/exploit-check`, `/datastore-review`, `/release-checklist` are exactly what a live FPS needs before publish.

Honorable mention: **[dig1t/skills](https://github.com/dig1t)** ships a `rojo-pro` skill — pair with brockmartin if you use Rojo.

### Two custom skills tailored to Rivals

**`.claude/skills/rivals-test/SKILL.md`:**

```markdown
---
name: rivals-test
description: Run TEST_PLAN.md section R for a named subsystem (combat, mapsystem, networking). Trigger when user asks to test, verify, or validate a Rivals subsystem.
allowed-tools: Read, Grep, Bash, mcp__robloxstudio__start_playtest, mcp__robloxstudio__get_playtest_output
---

# Rivals subsystem test runner

1. Read `TEST_PLAN.md` and locate the section heading matching `## R\.\d+ <subsystem>`.
2. For each checkbox in that section, execute the listed reproduction steps.
3. Use `mcp__robloxstudio__start_playtest`, then poll `get_playtest_output` for 30s.
4. Grep output for `[FAIL]`, `[ERROR]`, or stack traces; report pass/fail per checkbox.
5. Emit a markdown table: `| Check | Status | Notes |`.
```

**`.claude/skills/rivals-buildmap/SKILL.md`:**

```markdown
---
name: rivals-buildmap
description: Execute MapSystem build pipeline via the robloxstudio MCP. Trigger on "rebuild map", "regenerate map", or "buildmap".
allowed-tools: Read, mcp__robloxstudio__execute_luau, mcp__robloxstudio__mass_create_objects, mcp__robloxstudio__import_build, mcp__robloxstudio__capture_screenshot
---

# MapSystem rebuild

1. Read `src/shared/MapSystem.luau` for the current map manifest.
2. Call `mcp__robloxstudio__execute_luau` with `MapSystem.new():CreateArena()`.
3. Stream geometry via `mass_create_objects`; tag spawn pads with `add_tag`.
4. `capture_screenshot` from 4 cardinal angles for diff review.
5. Report node count, build time, and screenshot paths.
```

### Skills + MCP interplay

`claude mcp list` shows registered servers (e.g., `robloxstudio`). Any tool from those servers can be named in a skill's `allowed-tools:` frontmatter using the `mcp__<server>__<tool>` prefix — that's how `/rivals-buildmap` drives Studio without leaving Claude Code.

Sources: [brockmartin/roblox-game-skill](https://github.com/brockmartin/roblox-game-skill) · [sentinelcore/roblox-skills](https://github.com/sentinelcore/roblox-skills) · [CodePhobiia/claude-roblox-game-studio](https://github.com/CodePhobiia/claude-roblox-game-studio) · [dig1t](https://github.com/dig1t)

## 9. Self-hosting a custom MCP server fork

The default `.mcp.json` pulls `boshyxd/robloxstudio-mcp@latest` via `npx -y`. That's fine for quick starts, but power users will eventually want to **pin** a version, **audit** the code, **remove** tools they don't trust (e.g. `delete_object`, `execute_luau`), or **add** project-specific ones like `build_arena_and_screenshot` and `lint_changed_scripts`.

### 9.1 Why fork

- **Pin a version.** `@latest` silently upgrades; a fork lets you check out a SHA and bump deliberately.
- **Trim the attack surface.** Delete tool registrations for anything mutating (`delete_object`, `set_script_source`, `execute_luau`) you don't want an agent calling.
- **Add custom tools.** Compose primitives into one-shot workflows ("rebuild arena, screenshot, attach to PR").
- **Audit.** Read every handler before granting an LLM access to Studio.

### 9.2 Forking workflow

```bash
git clone https://github.com/<you>/robloxstudio-mcp.git tools/mcp/robloxstudio-mcp
cd tools/mcp/robloxstudio-mcp
npm install
npm run build   # produces packages/robloxstudio-mcp/dist/index.js
```

Then point `.mcp.json` at the local build:

```json
{
  "mcpServers": {
    "robloxstudio": {
      "command": "node",
      "args": ["C:/Users/admin/rivals-multiplayer/tools/mcp/robloxstudio-mcp/packages/robloxstudio-mcp/dist/index.js"],
      "env": { "MCP_PORT": "3001" }
    }
  }
}
```

(stdio transport: Claude Code spawns the child and pipes JSON-RPC over stdin/stdout.)

### 9.3 Adding a custom tool: the 5-file dance

The fork is split between an **MCP server** (Node) and a **Studio plugin** (Luau, in `studio-plugin/`) that long-polls the server. A new tool touches:

1. **Schema** — `packages/core/src/tools/<your-tool>.ts` *(suggested split; upstream inlines the Zod schema in the handler — no `.schema.ts` convention)*.
2. **MCP handler** — call `server.registerTool('build_arena_and_screenshot', { inputSchema, ... }, handler)` per [typescript-sdk docs](https://github.com/modelcontextprotocol/typescript-sdk/blob/main/docs/server.md).
3. **Plugin endpoint** — add `/build_arena_and_screenshot` to the HTTP queue the plugin polls.
4. **Plugin Lua/TS** — handler under `studio-plugin/src/`.
5. **Registration index** — export from `packages/robloxstudio-mcp/src/index.ts` so the server picks it up.

### 9.4 The Studio plugin

Plugin lives in the same repo (`studio-plugin/`, written in Luau) and polls the MCP server's local HTTP queue. If you only need new server-side tools you can reuse the upstream plugin; if you need new Studio capabilities, fork the plugin too and reinstall the `.rbxm` via Studio's plugin folder.

### 9.5 Security: locking down powerful tools

If you keep `execute_luau`-class tools, harden the **plugin** (not just the server) — the plugin is what actually runs code. Maintain an allowlist of script hashes or wrap execution in a `pcall` with a string-match denylist (`game:Destroy`, `HttpService:PostAsync`, etc.). Never expose the plugin's HTTP port outside `127.0.0.1`.

### 9.6 Containerized: `tools/mcp/Dockerfile`

```dockerfile
FROM node:20-alpine
WORKDIR /srv
COPY robloxstudio-mcp/ .
RUN npm ci && npm run build
EXPOSE 3001
CMD ["node", "packages/robloxstudio-mcp/dist/index.js"]
```

In `.mcp.json` swap `command` to `"docker"` with `args: ["run","--rm","-i","-p","3001:3001","rivals-mcp:local"]`. The Studio plugin still needs to reach `localhost:3001`, so keep the port published.

Sources: [boshyxd/robloxstudio-mcp](https://github.com/boshyxd/robloxstudio-mcp) · [MCP typescript-sdk server.md](https://github.com/modelcontextprotocol/typescript-sdk/blob/main/docs/server.md) · [Claude Code MCP docs](https://code.claude.com/docs/en/mcp) · [stdio transport guide](https://mcpcat.io/guides/building-stdio-mcp-server/)

## 10. GitHub Actions: build + lint + test on every PR

The repo currently only has `.github/workflows/deploy.yml` (Pages). Add CI so every PR is built, linted, and tested before merge — and a separate CD workflow that publishes to Roblox via Open Cloud (cross-ref [section 6](#6-roblox-open-cloud-automate-place-publishing-and-datastore)).

### 10.1 `ci.yml` — runs on every PR

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [master]
  push:
    branches: [master]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-lint-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Cache ~/.rokit
        uses: actions/cache@v4
        with:
          path: ~/.rokit
          key: rokit-${{ runner.os }}-${{ hashFiles('rokit.toml') }}
          restore-keys: rokit-${{ runner.os }}-

      - name: Install Rokit toolchain (rojo, selene, stylua, lune)
        uses: CompeyDev/setup-rokit@v0.2.1

      - name: Build place file
        run: rojo build default.project.json -o /tmp/rivals.rbxlx

      - name: Lint with selene
        run: selene src/

      - name: Format check with stylua
        run: stylua --check src/

      - name: Run Lune tests
        if: hashFiles('tests/**/*.luau') != ''
        run: lune run tests/init.luau
```

Requires a `rokit.toml` at repo root pinning `rojo`, `selene`, `stylua`, `lune` (see [rojo-rbx/rokit](https://github.com/rojo-rbx/rokit)). `CompeyDev/setup-rokit` caches `~/.rokit` and is 5–10× faster than re-downloading.

### 10.2 `cd.yml` — publish to Roblox on master

Create `.github/workflows/cd.yml`:

```yaml
name: CD

on:
  push:
    branches: [master]

jobs:
  publish:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: actions/cache@v4
        with:
          path: ~/.rokit
          key: rokit-${{ runner.os }}-${{ hashFiles('rokit.toml') }}
      - uses: CompeyDev/setup-rokit@v0.2.1

      - name: Build place
        run: rojo build default.project.json -o rivals.rbxl

      - name: Publish via Open Cloud (curl, no third-party action)
        env:
          KEY: ${{ secrets.ROBLOX_API_KEY }}
          UNIVERSE: ${{ secrets.ROBLOX_UNIVERSE_ID }}
          PLACE: ${{ secrets.ROBLOX_PLACE_ID }}
        run: |
          curl -fsS -X POST \
            -H "x-api-key: $KEY" \
            -H "Content-Type: application/octet-stream" \
            --data-binary @rivals.rbxl \
            "https://apis.roblox.com/universes/v1/$UNIVERSE/places/$PLACE/versions?versionType=Published"
```

Add `ROBLOX_API_KEY` (with `universe-places:write`), `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID` under repo Settings → Secrets → Actions. (We use raw curl rather than a third-party action because the most popular `Ulferno/upload-to-roblox` action is abandoned since Dec 2022 — curl gives us full control over the `versionType` query param and matches §20's deploy job.)

### 10.3 README badge

Add to `README.md` (top):

```markdown
![CI](https://github.com/<owner>/rivals-multiplayer/actions/workflows/ci.yml/badge.svg)
![CD](https://github.com/<owner>/rivals-multiplayer/actions/workflows/cd.yml/badge.svg?branch=master)
```

### 10.4 Branch protection — require `ci.yml` green

After the first CI run lands the `build-lint-test` check name, enable protection via the REST API:

```bash
gh api -X PUT repos/:owner/rivals-multiplayer/branches/master/protection \
  -H "Accept: application/vnd.github+json" \
  -F required_status_checks.strict=true \
  -F 'required_status_checks.contexts[]=build-lint-test' \
  -F enforce_admins=true \
  -F required_pull_request_reviews.required_approving_review_count=1 \
  -F restrictions= \
  -F allow_force_pushes=false \
  -F allow_deletions=false
```

Requires admin scope on the repo.

Sources: [rojo-rbx/rokit](https://github.com/rojo-rbx/rokit) · [roblox-ts/setup-rokit](https://github.com/roblox-ts/setup-rokit) · [Roblox/place-ci-cd-demo](https://github.com/Roblox/place-ci-cd-demo) · [Place publishing guide](https://create.roblox.com/docs/cloud/guides/usage-place-publishing) · [branch protection REST API](https://docs.github.com/en/rest/branches/branch-protection) · [workflow status badge](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/adding-a-workflow-status-badge)

## 11. Claude Code config: hooks, permissions, agents, models

Claude Code is configured through layered `settings.json` files (managed > local > project > user) plus optional sidecar files in `.claude/hooks/`, `.claude/agents/`, and `.claude/skills/`. Defaults are conservative — a Roblox monorepo with Rojo/Lune/Wally/Selene/StyLua benefits enormously from tuning them.

### Expanded `.claude/settings.json`

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "model": "claude-sonnet-4-6",
  "outputStyle": "terse",
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(rojo:*)", "Bash(selene:*)", "Bash(stylua:*)",
      "Bash(tools/lune.exe:*)", "Bash(tools/wally.exe:*)",
      "Bash(npm run *)", "Bash(npm test *)", "Bash(npm ci)",
      "Bash(git status)", "Bash(git status:*)",
      "Bash(git log:*)", "Bash(git diff:*)", "Bash(git show:*)",
      "Read(src/**)", "Edit(src/**)", "Write(src/**)",
      "Read(tests/**)", "Edit(tests/**)"
    ],
    "ask":  ["Bash(git push:*)", "Bash(wally publish:*)"],
    "deny": ["Read(./.env)", "Read(./secrets/**)", "Bash(curl:*)"]
  },
  "enabledMcpjsonServers": ["robloxstudio"],
  "env": {
    "ANTHROPIC_LOG_LEVEL": "warn",
    "BASH_DEFAULT_TIMEOUT_MS": "120000"
  },
  "statusLine": { "type": "command", "command": ".claude/hooks/preview.sh" },
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command",
        "command": "powershell -NoProfile -File .claude/hooks/stylua-check.ps1" }]
    }],
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{ "type": "command", "if": "Bash(git push:*)",
        "command": "tools/selene.exe src/" }]
    }]
  }
}
```

The `if` field on a `PreToolUse` hook scopes it to a single Bash invocation pattern; exit code 2 blocks the push. Note: `"if"` is a non-standard scoping field; prefer `matcher` patterns for portability.

### Per-task model override

Use Sonnet by default; flip to Opus for refactors with `/model opus-4-7`, or set `"model": "claude-opus-4-7"` in `.claude/settings.local.json` for a refactor branch.

### Subagent: `rivals-reviewer`

Create `.claude/agents/rivals-reviewer.md`:

```markdown
---
name: rivals-reviewer
description: Reviews staged diffs against CLAUDE.md invariants. Invoke before every commit.
tools: Read, Grep, Bash(git diff:*), Bash(selene:*)
model: claude-opus-4-7
---
Read ./CLAUDE.md. Run `git diff --cached`. Flag any violation of project invariants. Output a bulleted pass/fail list only.
```

### `.claude/hooks/preview.sh` (statusline)

```bash
#!/usr/bin/env bash
input=$(cat)
branch=$(git -C "$(jq -r .workspace.current_dir <<<"$input")" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")
rojo=$(pgrep -f "rojo serve" >/dev/null && echo "rojo:UP" || echo "rojo:down")
model=$(jq -r .model.display_name <<<"$input")
printf "[%s] %s | %s" "$model" "$branch" "$rojo"
```

### Skill: `.claude/skills/ship-rivals/SKILL.md`

```markdown
---
name: ship-rivals
description: Run before any commit on rivals-multiplayer. Enforces selene + stylua + rojo build.
---
1. Run `tools/selene.exe src/`
2. Run `tools/stylua.exe --check src/`
3. Run `rojo build default.project.json -o build/rivals.rbxl`
4. If all pass, invoke `rivals-reviewer` subagent.
5. Only then suggest `git commit`.
```

### Env vars worth setting

`ANTHROPIC_LOG_LEVEL=warn` (quieter), `BASH_DEFAULT_TIMEOUT_MS=120000` (Rojo builds), `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` (corp networks).

Sources: [settings.json](https://code.claude.com/docs/en/settings) · [hooks](https://code.claude.com/docs/en/hooks) · [sub-agents](https://code.claude.com/docs/en/sub-agents) · [statusline](https://code.claude.com/docs/en/statusline)

## 12. Multi-place architecture and Universe management

Rivals ships today as a single place (`rivals.rbxlx`). As the game grows, splitting concerns across multiple places under one Universe lets you iterate on lobby UX without restarting live combat servers and keeps each place file small enough to open in Studio in under 10 seconds.

### 12.1 Universe vs Place — what crosses the boundary

A **Universe** is the cloud-side container; a **Place** is a single `.rbxl` world. Shared across all places in a Universe:

- **DataStores / OrderedDataStores** — same `GetDataStore("PlayerProfile")` resolves to the same data
- **MessagingService** topics — pub/sub spans every server in every place
- **MemoryStoreService** queues/maps, badges, gamepasses, developer products, social APIs

**Not** shared: `Workspace`, `Players`, `ReplicatedStorage` contents, ServerScriptService code, RemoteEvents. Each place is its own runtime.

### 12.2 Proposed Rivals split

| PlaceId env var | Role | Contains |
|---|---|---|
| `RIVALS_LOBBY_PLACE_ID` | **Lobby** (start place) | `LobbyPads`, social UI, weapon shop, party system |
| `RIVALS_ARENA_PLACE_ID` | **Arena** | Round controller, combat, scoring, map rotation |
| `RIVALS_RANGE_PLACE_ID` | **Shooting Range** | Practice dummies, weapon testing |

### 12.3 TeleportService — reserved arenas + data passing

```lua
-- ServerScriptService/LobbyPads/StartMatch.server.lua
local TeleportService = game:GetService("TeleportService")
local ARENA = tonumber(game:GetAttribute("ArenaPlaceId"))

local code, privateId = TeleportService:ReserveServerAsync(ARENA)  -- private match (modern API; legacy `ReserveServer` is deprecated)
local opts = Instance.new("TeleportOptions")
opts.ReservedServerAccessCode = code
opts:SetTeleportData({                                        -- < 8 KB JSON
    matchId = HttpService:GenerateGUID(false),
    mode    = "TDM",
    map     = "Foundry",
    party   = {plr1.UserId, plr2.UserId},
})
TeleportService:TeleportAsync(ARENA, {plr1, plr2}, opts)
```

`SetTeleportData` survives the teleport but is **client-trusted** — never put currency, inventory, or auth tokens there. Read server-side with `Player:GetJoinData().TeleportData` and re-verify against ProfileStore. Size cap is ~8 KB JSON.

For party-into-same-instance: set `TeleportOptions.ServerInstanceId = instanceId` and call `TeleportAsync`. Or pre-reserve via `ReserveServerAsync` and share the access code over MessagingService. Legacy `TeleportToPlaceInstance` still works but is not recommended.

### 12.4 Cross-place inventory — ProfileStore just works

ProfileStore keys by `"Player_" .. UserId` against a DataStore name you control. Because DataStores are Universe-scoped, the arena server reads the same profile the lobby wrote. **Release the profile on `TeleportInitFailed`** and re-load on `PlayerAdded` in the destination — otherwise the session-lock blocks the new place for ~30s.

### 12.5 Rojo split — one repo, three project files

```jsonc
// lobby.project.json
{ "name": "RivalsLobby", "tree": { "$className": "DataModel",
  "ReplicatedStorage": { "Shared": { "$path": "src/shared" } },
  "ServerScriptService": { "Lobby": { "$path": "src/lobby/server" } },
  "StarterPlayer": { "StarterPlayerScripts": { "$path": "src/lobby/client" } },
  "Workspace": { "$path": "places/lobby/workspace" }
}}
```

`arena.project.json` and `range.project.json` follow the same shape, swapping `src/arena/*` and a different `Workspace` baseplate.

Build each place independently:

```powershell
rojo build lobby.project.json -o build/lobby.rbxlx
rojo build arena.project.json -o build/arena.rbxlx
rojo build range.project.json -o build/range.rbxlx
```

### 12.6 Open Cloud publish per PlaceId (see section 6)

```powershell
foreach ($p in @(
  @{file="lobby.rbxlx"; id=$env:RIVALS_LOBBY_PLACE_ID},
  @{file="arena.rbxlx"; id=$env:RIVALS_ARENA_PLACE_ID},
  @{file="range.rbxlx"; id=$env:RIVALS_RANGE_PLACE_ID}
)) {
  curl.exe -X POST `
    "https://apis.roblox.com/universes/v1/$env:RIVALS_UNIVERSE_ID/places/$($p.id)/versions?versionType=Published" `
    -H "x-api-key: $env:RBLX_OPEN_CLOUD_KEY" `
    -H "Content-Type: application/octet-stream" `
    --data-binary "@build/$($p.file)"
}
```

### 12.7 Staging — TestPlaceIds vs Production

Maintain a parallel **staging Universe** with its own three PlaceIds. CI publishes every push to staging; only tagged releases publish to prod. Keep IDs in `.env` (gitignored) and pass them as `Configuration` attributes at build time so scripts read `script.Parent:GetAttribute("ArenaPlaceId")` instead of hard-coding constants.

Sources: [Teleporting Between Places](https://create.roblox.com/docs/projects/teleporting) · [TeleportService](https://create.roblox.com/docs/reference/engine/classes/TeleportService) · [MessagingService](https://create.roblox.com/docs/reference/engine/classes/MessagingService) · [Open Cloud Place Publishing](https://create.roblox.com/docs/cloud/guides/usage-place-publishing)

## 13. DataStore: from in-memory to production-grade persistence

`RivalsCore.PlayerDataManager` (`src/shared/RivalsCore.luau` lines 383-414) is currently in-memory: every server shutdown wipes player progression. This section gets you to durable, session-locked persistence.

### 13.1 DataStoreService basics

```lua
local DSS = game:GetService("DataStoreService")
local store = DSS:GetDataStore("RivalsPlayerData_v1")
store:SetAsync(key, value)       -- overwrite (last write wins)
store:GetAsync(key)              -- read
store:UpdateAsync(key, fn)       -- transactional read-modify-write (preferred)
store:RemoveAsync(key)           -- delete + return prior value
```

**Studio reminder:** Game Settings → Security → "Enable Studio Access to API Services" must be ON, or every call throws `403`.

### 13.2 Why raw DataStoreService is dangerous

`SetAsync` has no concept of who else is editing the key. If a player teleports between servers, or a server zombies for 30s after `BindToClose`, two servers race on the same key and the loser's writes overwrite progress. **Do not ship raw DataStoreService for player data.**

### 13.3 ProfileStore (recommended) — drop-in replacement

ProfileStore is the maintained successor to ProfileService (same author). Session locking, auto-save, reconciliation, graceful shutdown. Add to `wally.toml`:

```toml
ProfileStore = "lm-loleris/profilestore@1.0.3"
```

Replace `RivalsCore.PlayerDataManager` body with this 25-line shim — **same `GetData` / `CanPlayRanked` interface**, ProfileStore-backed:

```lua
local ProfileStore = require(game.ReplicatedStorage.Packages.ProfileStore)
local Players = game:GetService("Players")
local TEMPLATE = { Level = 1, XP = 0, Rank = "Bronze", MMR = 1000, Wins = 0, Losses = 0, SchemaVersion = 1 }
local Store = ProfileStore.New("RivalsPlayerData_v1", TEMPLATE)
local Profiles = {}                                                    -- [Player] = profile

function PlayerDataManager:_onJoin(plr)
    local p = Store:StartSessionAsync("u_" .. plr.UserId, { Cancel = function() return plr.Parent ~= Players end })
    if not p then plr:Kick("Data load failed") return end
    p:AddUserId(plr.UserId); p:Reconcile()                             -- migrate missing keys
    p.OnSessionEnd:Connect(function() Profiles[plr] = nil; plr:Kick("Session ended") end)
    Profiles[plr] = p; self.Data[plr.UserId] = p.Data                  -- legacy alias
end
function PlayerDataManager:_onLeave(plr) if Profiles[plr] then Profiles[plr]:EndSession() end end
function PlayerDataManager:GetData(plr) return Profiles[plr] and Profiles[plr].Data end
function PlayerDataManager:CanPlayRanked(plr) local d = self:GetData(plr); return d and d.Level >= 10 end
Players.PlayerAdded:Connect(function(p) PlayerDataManager:_onJoin(p) end)
Players.PlayerRemoving:Connect(function(p) PlayerDataManager:_onLeave(p) end)
game:BindToClose(function() for _, p in Profiles do p:EndSession() end task.wait(2) end)
```

### 13.4 Schema versioning & migration

Store a `SchemaVersion` field in `TEMPLATE`. On load, run migrations:

```lua
local Migrations = {
    [1] = function(d) d.MMR = d.MMR or 1000; d.SchemaVersion = 2 end,   -- v1 -> v2: add MMR
}
for v = profile.Data.SchemaVersion, #Migrations do Migrations[v](profile.Data) end
```

Never rename keys destructively — add new ones, deprecate, then prune after a release cycle.

### 13.5 Quota math for 5v5 (10 players)

Per-server budget: **60 + 10 × N requests/minute** (60 + 100 = 160/min @ 10 players). Per-key write floor: **1 every 6s**. ProfileStore auto-saves every ~30s, so each of 10 profiles = 20 writes/min — well under the budget. Avoid extra `SetAsync` on combat events; batch into `Profile.Data` and let auto-save handle it.

### 13.6 BindToClose timing

Roblox gives the close hook **30 seconds**. `task.wait(2)` after `EndSession()` lets the final SaveAsync flush. Without `BindToClose`, the session lock can linger ~5 minutes before the next server can load — players see "Data is being accessed by another server."

### 13.7 Backup via Open Cloud (cross-ref Section 6)

Schedule a nightly `GET https://apis.roblox.com/datastores/v1/universes/{id}/standard-datastores/datastore/entries/entry` over your active UserIds, write JSON snapshots to S3/GCS. ProfileStore data is plain Lua tables — serializes cleanly.

### 13.8 Common bugs

- **Race on teleport:** `EndSession()` before `TeleportService:Teleport`, or use `TeleportOptions:SetTeleportData` to skip a DS round-trip.
- **`Profile.Data = newTable`**: prefer in-place mutation of `Profile.Data` so ProfileStore picks up changes; full reassignment is allowed but ensures no `task.wait` between assignment and the next session boundary.
- **Async chaining inside `UpdateAsync` transformer:** the function must be pure/synchronous; no `:GetAsync` calls inside.
- **Studio testing without "API Services" toggle** masks bugs that only appear in production.

Sources: [Roblox Data Stores docs](https://create.roblox.com/docs/cloud-services/data-stores) · [DataStore throttling](https://create.roblox.com/docs/cloud/guides/data-stores/throttling) · [ProfileService (deprecated)](https://github.com/MadStudioRoblox/ProfileService) · [ProfileStore (successor)](https://github.com/MadStudioRoblox/ProfileStore)

## 14. Anti-cheat patterns for Roblox FPS games

**Core rule:** trust the server, verify everything from the client. Exploiters have full control of their client - any LocalScript, any RemoteEvent payload, any value in `Workspace` can be forged. The only authority is `ServerScriptService`. Roblox's 2025 [Security Tactics and Cheat Mitigation update](https://devforum.roblox.com/t/security-tactics-and-cheat-mitigation-docs-update/3959613) makes this explicit: client-side anti-cheat is **defence in depth at best, never the gate.**

### Exploits a Rivals attacker actually runs

| Exploit | Server-side fix |
|---|---|
| **Speed hack** (sets `Humanoid.WalkSpeed`, or CFrame-teleport per frame to bypass WalkSpeed checks) | Heartbeat-sample `HumanoidRootPart.Position`; compare `(p2-p1).Magnitude` to `CONFIG.MaxSprintSpeed * dt * 1.5`. Slide/wall-run windows raise the cap briefly. |
| **Teleport hack** | Same delta check - just a larger threshold breach. Snap player back to last valid position before kicking on repeat. |
| **Damage modifier** | Client must only send `FireWeapon(originCFrame, direction)`. Server runs `workspace:Raycast`, applies damage from `RivalsCore.CONFIG.Weapons[slot].Damage`. **Never accept a damage value from the client.** |
| **RemoteEvent spam** | Token bucket per `(Player, RemoteEvent)`. Drop or kick over limit. |
| **Magnitude / aimbot hits** | Log shot-to-hit ratios + headshot %. Don't auto-kick (false positives); flag for review via Telemetry. |
| **Tool/Backpack swap → SwitchWeapon with bogus slot** | The current `WeaponSwitches` counter only rate-limits frequency. Add `if slot < 1 or slot > #player_loadout then return end` and verify the weapon id is one the server granted this player in this match. |

### `RateLimiter.luau` (~30 lines, token bucket)

```lua
local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(rate, burst) -- rate = tokens/sec, burst = bucket size
    return setmetatable({rate=rate, burst=burst, buckets={}}, RateLimiter)
end

function RateLimiter:Allow(player)
    local now = os.clock()
    local b = self.buckets[player] or {tokens=self.burst, last=now}
    b.tokens = math.min(self.burst, b.tokens + (now - b.last) * self.rate)
    b.last = now
    if b.tokens < 1 then self.buckets[player] = b; return false end
    b.tokens -= 1; self.buckets[player] = b; return true
end

function RateLimiter:Wrap(remote, handler) -- drop-in for OnServerEvent
    remote.OnServerEvent:Connect(function(player, ...)
        if not self:Allow(player) then return end
        handler(player, ...)
    end)
end

game.Players.PlayerRemoving:Connect(function(p)
    for _, rl in pairs(_G._RateLimiters or {}) do rl.buckets[p] = nil end
end)
return RateLimiter
```

Usage: `RateLimiter.new(20, 30):Wrap(FireWeapon, onFire)` - 20/sec sustained, 30 burst.

### `SpeedSentinel.luau`

```lua
local Players, RunService = game:GetService("Players"), game:GetService("RunService")
local last, strikes = {}, {}
local MAX = require(game.ReplicatedStorage.RivalsCore).CONFIG.MaxSprintSpeed * 1.5

RunService.Heartbeat:Connect(function(dt)
    for _, p in ipairs(Players:GetPlayers()) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local prev = last[p]
        if prev and (hrp.Position - prev).Magnitude > MAX * dt then
            strikes[p] = (strikes[p] or 0) + 1
            if strikes[p] > 5 then p:Kick("Movement validation failed") end
        else
            strikes[p] = 0
        end
        last[p] = hrp.Position
    end
end)
```

5-strike buffer avoids one-frame lag spikes triggering false positives ([devforum on false positives](https://devforum.roblox.com/t/preventing-anti-exploit-false-positives/280892)).

### `Telemetry.luau`

Batch suspicious events; flush every 10 s to an external endpoint via `HttpService:PostAsync` (requires **Game Settings → Security → Allow HTTP Requests**). Include `userId`, `event`, `value`, `serverJobId`. Use a queue + `task.delay` so a flush failure never blocks gameplay. Don't `pcall` and forget - log retries. Cheap analytics surface: aimbot/wallhack candidates jump out as outliers in shot:hit ratio.

### Kick vs ban

- `Players:Kick(reason)` - **transient** signals (one-time movement breach, single failed validation). They rejoin in 5 s.
- DataStore ban list keyed by `userId` and checked in `PlayerAdded` - **persistent** signals (repeated strikes across sessions, confirmed exploit signatures). Always store the reason + timestamp; never permaban on a single heuristic.

### The client-visible `WEAPONS` table problem

`RivalsCore.WEAPONS` currently lives in `ReplicatedStorage` so both sides read damage, fire rate, magazine. The client only needs **view data** (model, animation ids, UI icon, sounds). Damage, headshot multiplier, recoil pattern must be **server-only**. Split into:

- `ServerWeaponConfig.luau` in `ServerScriptService` - `Damage`, `HeadshotMultiplier`, `FireRate`, `MaxRange`.
- `ClientWeaponView.luau` in `ReplicatedStorage` - `ModelId`, `IdleAnim`, `FireAnim`, `Icon`, `MuzzleSound`.

Server resolves damage via `ServerWeaponConfig[slot]` only. Client never sees the damage number, so changing it locally has no effect.

Sources: [Security Tactics & Cheat Mitigation Docs Update](https://devforum.roblox.com/t/security-tactics-and-cheat-mitigation-docs-update/3959613) - [Securing your anticheat: bad practices + handshakes](https://devforum.roblox.com/t/securing-your-anticheat-common-bad-practices-and-how-powerful-are-exploiters-guide-on-handshakes/2519952) - [Rate limiter module for Remotes](https://devforum.roblox.com/t/rate-limiter-module-for-remotes/616268) - [Server-sided movement validation](https://devforum.roblox.com/t/help-in-creating-a-server-sided-movement-validation-system-anti-cheat/3624140) - [BitAntiCheat (server-sided general purpose)](https://devforum.roblox.com/t/bitanticheat-a-server-sided-general-purpose-anti-cheat/2212311) - [Best way to detect speedhack](https://devforum.roblox.com/t/best-way-to-detect-this-speedhack-script/3141172) - [RemoteEvent security guide](https://gmmarket.me/community/post/roblox-remoteevent-security-how-exploits-work-and-how-to-stop-them-never-trust-t)


## 15. Server-side validation patterns & input sanitization

Right now `Server.server.luau` trusts whatever the client sends - `SwitchWeapon` accepts `"banana"` or `math.huge`, and `JoinQueue` does no allowlist on `QueueType`. One exploiter with a script executor and the server errors (or worse, executes the action). Fix by funnelling every RemoteEvent through a runtime type-checker plus a per-event validator.

### Install `t` via Wally (cross-ref section 3)

Add to `wally.toml` under `[dependencies]`:

```toml
t = "osyrisrblx/t@3.1.1"
```

Run `wally install`, then `require(ReplicatedStorage.Packages.t)`. `t` ships composable checkers (`t.string`, `t.numberConstrained(1,4)`, `t.tuple(...)`, `t.instanceOf("Player")`, `t.literal("Casual")`, `t.union(...)`) - perfect for asserting RemoteEvent payloads before any work.

### Wrap every listener with a validator

Create `src/shared/Validators.luau` so every event has one canonical checker in one place:

```luau
local t = require(ReplicatedStorage.Packages.t)
local M = {}

M.QueueType = t.union(t.literal("Casual"), t.literal("Ranked"),
    t.literal("FiveVFive"), t.literal("ShootingRange"))
M.SwitchWeapon = t.tuple(t.instanceOf("Player"), t.numberConstrained(1, 4))
M.JoinQueue    = t.tuple(t.instanceOf("Player"), M.QueueType)
M.FireWeapon   = t.tuple(t.instanceOf("Player"), t.Vector3, t.Vector3) -- origin, direction
M.ChatMessage  = t.tuple(t.instanceOf("Player"), t.string)
return M
```

Then in `Server.server.luau` (replacing the unchecked handler):

```luau
local SwitchWeaponPayload = t.tuple(t.instanceOf("Player"), t.numberConstrained(1, 4))
RemoteEvents.SwitchWeapon.OnServerEvent:Connect(function(Player, Slot)
    assert(SwitchWeaponPayload(Player, Slot))
    if not RateLimit:Allow(Player, "SwitchWeapon") then return end -- section 14
    -- ...actual switch...
end)
```

In production, wrap the `assert` in `pcall` so a forged payload silently drops instead of log-flooding output.

### Position validation for raycasts

`FireWeapon` is the highest-risk event: the client supplies origin + direction. Verify origin is within ~5 studs of `HumanoidRootPart` and ray length is capped by the weapon's `MaxRange`:

```luau
local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
if not hrp or (origin - hrp.Position).Magnitude > 5 then return end
if direction.Magnitude > WeaponSystem[slot].MaxRange then return end
```

### Text filtering for chat / nameplates / `TextLabel.Text`

Anything user-typed that gets rendered to other players (kill-feed taunts, custom loadout names) must round-trip through `TextService:FilterStringAsync` - failure will get your experience removed by moderation.

```luau
local TextService = game:GetService("TextService")
local ok, result = pcall(function()
    return TextService:FilterStringAsync(rawText, Player.UserId)
end)
if not ok then return end -- never display unfiltered text
local clean = result:GetNonChatStringForBroadcastAsync()
```

Call it fresh per message (no caching) and never display raw input if the call fails. For live chat, prefer `TextChatService` channels which filter automatically.

### Rate-limit integration (cross-ref section 14)

Every validator-passing event still goes through the rate-limit table from section 14 - validation answers "is this *shaped* right?", rate-limiting answers "is this *too often*?". Both must pass before the handler does real work.

Sources: [osyrisrblx/t README](https://github.com/osyrisrblx/t/blob/master/README.md) - [t devforum thread](https://devforum.roblox.com/t/t-a-runtime-type-checker-for-roblox/139769) - [How to secure your RemoteEvent and RemoteFunction](https://devforum.roblox.com/t/how-to-secure-your-remoteevent-and-remotefunction/3345363) - [Sanity checks for remote events](https://devforum.roblox.com/t/how-do-i-make-a-sanity-check-for-remote-events-functions/257999) - [TextService:FilterStringAsync](https://create.roblox.com/docs/reference/engine/classes/TextService#FilterStringAsync) - [creator-docs text-filtering](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ui/text-filtering.md)

## 16. Telemetry & analytics for Rivals

The repo currently emits `print` statements only. A production FPS needs DAU, D1/D7 retention, weapon-balance heatmaps, server FPS, exploiter signals, and error rates. Stack the layers below cheapest-first.

### 16.1 Layer 1 — Roblox `AnalyticsService` (free, zero infra)

Built into the engine. Logs flow to the Creator Dashboard under Analytics with no HTTP plumbing. Low cardinality (no per-weapon stats) but unbeatable for funnels and economy.

```lua
local AS = game:GetService("AnalyticsService")
AS:LogOnboardingFunnelStepEvent(player, 1, "tutorial_complete")
AS:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType.Sink,
    "Credits", 250, balanceAfter,
    Enum.AnalyticsEconomyTransactionType.Shop.Name, "AK47_Skin_Red")
AS:LogCustomEvent(player, "match_win", 1, { map = "Dust2", mode = "Ranked" })
```

Use this for: onboarding funnel, currency sources/sinks, paid conversion.

### 16.2 Layer 2 — GameAnalytics SDK (free, hosted dashboard)

Best free third-party. Roblox-native, gives retention/DAU/MAU + cohorts out of the box. Repo: [GameAnalytics/GA-SDK-ROBLOX](https://github.com/GameAnalytics/GA-SDK-ROBLOX). Not on Wally yet — install via Rojo sync of `GameAnalyticsSDK/` or the Roblox model.

### 16.3 Layer 3 — PlayFab (only if you need server-side LiveOps)

Roblox/PlayFab official program wound down; community SDKs `paradoxum-games/RobloxPlayFabSDK` and `grilme99/PlayFabForRoblox` still active. Auth-heavy (REST + HMAC), worth it only if you want catalogs, segmentation, or Xbox identity.

### 16.4 Minimum-viable `Telemetry.luau`

Drop into `src/server/Telemetry.luau`. Reuses the existing `server.js`:

```lua
local HttpService  = game:GetService("HttpService")
local LogService   = game:GetService("LogService")
local RunService   = game:GetService("RunService")
local ENDPOINT = "https://your-worker.workers.dev/ingest"
local SECRET   = "<rotate-me>"
local queue, M = {}, {}
local function push(kind, data)
    data._t, data._k, data._j = os.time(), kind, game.JobId
    table.insert(queue, data)
    if #queue > 200 then table.remove(queue, 1) end
end
function M.event(kind, data) push(kind, data) end
function M.kill(killer, victim, weapon, dist, headshot)
    push("kill", { k = killer.UserId, v = victim.UserId, w = weapon, d = dist, hs = headshot })
end
function M.damage(p, weapon, dmg, taken) push("dmg", { u = p.UserId, w = weapon, d = dmg, t = taken }) end
function M.match(map, mode, durSec, winner) push("match", { map = map, mode = mode, dur = durSec, win = winner }) end
function M.queue(p, mode, waitSec) push("queue", { u = p.UserId, m = mode, w = waitSec }) end
LogService.MessageOut:Connect(function(msg, t)
    if t == Enum.MessageType.MessageError or t == Enum.MessageType.MessageWarning then
        push("err", { msg = msg:sub(1, 500), sev = t.Name })
    end
end)
task.spawn(function()
    while true do task.wait(30)
        if #queue == 0 then continue end
        local batch = queue; queue = {}
        local ok, err = pcall(HttpService.RequestAsync, HttpService, {
            Url = ENDPOINT, Method = "POST",
            Headers = { ["Content-Type"]="application/json", ["X-Auth"]=SECRET },
            Body = HttpService:JSONEncode({ events = batch, fps = 1/RunService.Heartbeat:Wait() }),
        })
        if not ok then for _, e in batch do table.insert(queue, e) end end -- retry
    end
end)
return M
```

Server FPS: sample `1/RunService.Heartbeat:Wait()` each flush.

### 16.5 Free ingest endpoint

Cheapest: **Cloudflare Workers + R2** — 100k req/day free, JSON straight into R2 newline-delimited, queryable via [Workers Analytics Engine](https://developers.cloudflare.com/analytics/analytics-engine/) or DuckDB over R2. Alternative: extend the existing `server.js` with `app.post("/ingest", ...)` appending to a SQLite/Postgres table.

### 16.6 Privacy & Roblox TOS

Allowed: `UserId`, `JobId`, match stats, weapon IDs, server perf. **Forbidden**: real names, chat content without consent, IP addresses (Roblox doesn't expose them), anything that could identify a minor off-platform. Don't ship telemetry to a third party from clients under 13 without parental-consent flags. All telemetry runs **server-side** in this design.

### 16.7 Dashboards

- **Roblox Creator Dashboard**: free funnels/economy charts once `AnalyticsService` events fire.
- **GameAnalytics web UI**: retention/DAU/ARPDAU built-in.
- **Grafana + Prometheus** on top of the Worker/Express ingest for server-FPS alerts.
- **Metabase** (free OSS) over your SQLite/Postgres for weapon-balance pivot tables.
- **Exploiter detection**: query `kill` events where `dist > weapon.maxRange * 1.2` or headshot-rate > 60% over 200 kills.

Sources: [AnalyticsService](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService) · [Economy events](https://create.roblox.com/docs/production/analytics/economy-events) · [GameAnalytics Roblox SDK](https://github.com/GameAnalytics/GA-SDK-ROBLOX) · [Cloudflare Analytics Engine](https://developers.cloudflare.com/analytics/analytics-engine/)

## 17. Hot reload patterns: live updates without restart

Rojo syncs disk into Studio in ~1s, but Studio's Luau VM **caches `require()` results per session**. Once `RivalsCore` is required, every subsequent `require(RivalsCore)` returns the same table - Rojo replacing the underlying `.luau` source does nothing to the live closures. Iteration loop today: stop playtest, restart playtest (10-15s of warm-up, lost positional state, re-spawn arena). Hot reload short-circuits that.

**Why Roblox can't reload natively.** `require(ModuleScript)` is memoized by Instance identity (see [devforum: module caching](https://devforum.roblox.com/t/reload-all-modulescripts/49278), [devforum: re-require doesn't re-execute](https://devforum.roblox.com/t/consecutively-requiring-a-modulescript-from-the-command-bar-does-not-re-execute-the-script-after-modification/2996580)). There is no `debug.loadmodule` ([open request](https://devforum.roblox.com/t/please-enable-debugloadmodule-so-that-i-can-reload-modules/2418440)). Workaround: change the Instance identity.

**The clone-and-swap pattern.** [sayhisam1/Rewire](https://github.com/sayhisam1/Rewire) and [Matter's hot reloader](https://github.com/matter-ecs/matter) both do the same thing - `:Clone()` the ModuleScript, `require` the clone (fresh entry in the cache), destroy the previous clone. Minimal `src/shared/HotReload.luau`:

```lua
local HotReload = {}
HotReload.__index = HotReload

function HotReload.new(sourceModule)
    local self = setmetatable({ source = sourceModule, current = nil, clone = nil,
        listeners = {}, conn = nil }, HotReload)
    self:reload()
    self.conn = sourceModule.Changed:Connect(function(prop)
        if prop == "Source" then
            print(("[HotReload] %s changed at %s"):format(sourceModule.Name, os.date("%H:%M:%S")))
            self:reload()
        end
    end)
    return self
end

function HotReload:reload()
    if self.clone then self.clone:Destroy() end
    self.clone = self.source:Clone()
    self.clone.Parent = self.source.Parent
    self.clone.Name = self.source.Name .. "_HR"
    local ok, result = pcall(require, self.clone)
    if not ok then warn("[HotReload] failed:", result); return end
    self.current = result
    for _, cb in ipairs(self.listeners) do task.spawn(cb, result) end
end

function HotReload:onReload(cb) table.insert(self.listeners, cb); cb(self.current) end
function HotReload:get() return self.current end
function HotReload:destroy() if self.conn then self.conn:Disconnect() end
    if self.clone then self.clone:Destroy() end end

return HotReload
```

**Integration with Rojo.** From the Command Bar after a tweak: `RivalsCore.MovementSystem:ReloadFromSource()` (where `ReloadFromSource` calls `HotReload.new(script.MovementSystem):onReload(function(new) RivalsCore.MovementSystem = new end)`). Rojo writes Source, the `Changed` signal fires with `prop == "Source"`, the clone is rebuilt, listeners re-bind, and `RivalsCore.MovementSystem` now points at the new table. Output prints `[HotReload] MovementSystem changed at 14:32:07` so you can see the swap.

**Limitations - state migration is your problem.**
- **Closure capture** - any function that already grabbed `local Cfg = MovementSystem.CONFIG` still holds the old table. Re-dereference through `RivalsCore.MovementSystem.CONFIG` each call, or accept the staleness.
- **Connections** - `RunService.Heartbeat:Connect(MovementSystem.Step)` still calls the *old* `Step`. The reload step must `:Disconnect()` and rebind. Use a Janitor (see s.16) per subsystem.
- **Per-player state** - if the old module held `playerStates[Player] = {...}`, the new module starts empty. Stash state on the Player instance (attributes) or in a separate `StateStore` module that you *don't* reload.

**Practical pattern - "subsystem reload".** Don't reload `RivalsCore` wholesale. Reload one subsystem at a time from the Command Bar: `RivalsCore.MovementSystem:ReloadFromSource()`. Each subsystem owns its Janitor and re-binds its own connections on reload. Keeps blast radius small.

**When it pays off.** Tuning `CONFIG.SprintSpeed`, `CONFIG.FireRate`, damage curves, slide friction - single-value tweaks where the next Heartbeat just reads the new number. Pure win.

**When to give up and restart.** Adding a new function or method, changing a signature, anything that touches module-load-time side effects (`Instance.new`, RemoteEvent creation). Full restart is correct.

**Tie-in with TEST_PLAN S.1.** The dead `TweenService` import at `RivalsCore.luau:14` is the perfect hot-reload demo target - wire one cosmetic tween (e.g., FOV lerp on sprint), save, watch Output print the `[HotReload]` line, sprint in-game without restarting. Converts the audit finding into a live capability.

Sources: [sayhisam1/Rewire](https://github.com/sayhisam1/Rewire) - [matter-ecs/matter hot reloader](https://github.com/matter-ecs/matter) - [devforum: reload all modulescripts](https://devforum.roblox.com/t/reload-all-modulescripts/49278) - [devforum: cached require doesn't re-execute](https://devforum.roblox.com/t/consecutively-requiring-a-modulescript-from-the-command-bar-does-not-re-execute-the-script-after-modification/2996580) - [devforum: debug.loadmodule request](https://devforum.roblox.com/t/please-enable-debugloadmodule-so-that-i-can-reload-modules/2418440) - [devforum: UIReloader plugin](https://devforum.roblox.com/t/plugin-uireloader-easy-hot-reloading-for-programmed-ui/437827) - [Roblox docs: ModuleScript caching](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/module.md)

## 18. ContentProvider: preload assets, loading screens, asset budgets

`RivalsCore.luau` is 1635 lines of pure procedural Parts - zero asset IDs, zero preload calls. The first time a player fires a weapon, swings the camera onto a Decal, or triggers a Sound, Roblox stalls the main thread to stream that asset. A real FPS hides this with a deliberate boot-time preload, a per-match preload, and lazy fetches for cold-path weapons.

**API surface.** `ContentProvider:PreloadAsync(contentIdList: {Instance | string}, callback: ((contentId, AssetFetchStatus) -> ())?)` yields until every asset reachable through the passed Instances (Decals, Sounds, MeshParts, Animations, ParticleEmitters) is loaded. The optional callback fires once per asset with its final `Enum.AssetFetchStatus` — **five** values: `Success`, `Failure`, `None`, `Loading` (transient — keep counting until terminal), and `TimedOut`. `SurfaceAppearance` and `MaterialVariant` are NOT supported — load those by parenting a hidden MeshPart that references them.

**Three preload tiers.**

```lua
-- src/shared/AssetRegistry.luau  (new)
return {
    Weapons    = { Rifle = { Mesh = "rbxassetid://0", Fire = "rbxassetid://0" } },
    Maps       = { Arena = { Skybox = "rbxassetid://0" } },
    UI         = { Crosshair = "rbxassetid://0", HitMarker = "rbxassetid://0" },
    Animations = { Reload = "rbxassetid://0", Sprint = "rbxassetid://0" },
}
```

1. **Boot-time** (in `ReplicatedFirst`, before Workspace replicates) - UI, crosshair, every weapon view-model mesh, hit-marker SFX. Runs during the loading screen so the player never sees a first-shot stutter.
2. **Match-start** - only the active map's skybox, ambient loops, decals. Hook the `Warmup -> Playing` transition in `GameModeManager` and call `PreloadAsync` before unfreezing players.
3. **Lazy** - weapons the player has never equipped this session. Trigger from `WeaponSystem:Equip()` with a 200ms `task.delay` fallback so the swap animation still plays.

```lua
local CP = game:GetService("ContentProvider")
local Registry = require(ReplicatedStorage:WaitForChild("AssetRegistry"))
local function toInstances(t) local out = {} for _,id in t do
    local s = Instance.new("Sound") s.SoundId = id table.insert(out, s) end return out end

local total, done = 0, 0
local bar = playerGui.RivalsLoadingScreen.ProgressBar
for _ in Registry.UI do total += 1 end
CP:PreloadAsync(toInstances(Registry.UI), function(id, status)
    done += 1 ; bar.Size = UDim2.fromScale(done/total, 1)
    if status ~= Enum.AssetFetchStatus.Success then warn("preload miss:", id, status) end
end)
```

**ReplicatedFirst workflow.** Move `roblox-scripts/1_LoadingScreen.lua` into `src/replicatedFirst/LoadingScreen.client.luau` (add a `replicatedFirst` mapping in `default.project.json` -> `ReplicatedFirst`). Inside it, parent the ScreenGui to `playerGui`, call `game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()`, then run the boot-tier `PreloadAsync` with the callback driving the bar. Destroy the GUI after `game:IsLoaded()` and the preload returns.

**Budget rules of thumb.** Textures: 1024x1024 per weapon skin max (~4 MB decoded); UI atlas - one 2048x2048 sheet beats 30 separate decals. Meshes: <10k tris per view-model, <2k per world prop. Sounds: gunshots <2s mono OGG; ambience can stream (it doesn't preload). Don't preload the whole `Workspace` - docs explicitly warn against it; pop-in on cosmetic props is cheaper than a 30-second loading screen.

Sources: [ContentProvider:PreloadAsync](https://create.roblox.com/docs/reference/engine/classes/ContentProvider#PreloadAsync) - [ContentProvider YAML source](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/ContentProvider.yaml) - [ReplicatedFirst:RemoveDefaultLoadingScreen](https://create.roblox.com/docs/reference/engine/classes/ReplicatedFirst#RemoveDefaultLoadingScreen) - [Custom loading screens guide](https://github.com/Roblox/creator-docs/blob/main/content/en-us/players/loading-screens.md) - [AssetFetchStatus enum](https://create.roblox.com/docs/reference/engine/enums/AssetFetchStatus)
## 19. Component frameworks: Knit, Matter, React Roblox

Rivals is currently hand-rolled OOP: `RivalsCore.luau` (1635 lines) wires `MovementSystem`, `CombatSystem`, `WeaponSystem`, and a TODO `AbilitySystem` as `setmetatable` classes, with `Server.server.luau` plumbing `RemoteEvent`s by hand. Three frameworks each solve a different slice of that pain.

### Knit — service/controller RPC layer

**Philosophy.** A lightweight Roblox framework that splits code into server `Services` and client `Controllers` and auto-wires `RemoteEvent`/`RemoteFunction` instances between them. You declare `Service.Client` methods and Knit generates the network boundary.

**Pick it when** your pain is "I keep writing RemoteEvent boilerplate." That's exactly Rivals today.

> **Trade-off (2026).** A vocal segment of the Luau community now considers Knit's singleton/service pattern "legacy bloat" and prefers either Matter (ECS, below) or functional dependency-injection patterns. Knit is in maintenance and a perfectly reasonable choice — the bloat critique applies more to "I migrated 200 unrelated classes into Services for no reason" than to using it for what it's actually good at (the RemoteEvent layer). For Rivals specifically, where the network boundary is the pain point, Knit is the right tool.

**Install.** `Knit = "sleitnick/knit@1.7.0"` in `wally.toml` — latest is v1.7.0 (Feb 2024). **The repo was archived July 31, 2024**, so pin the concrete version (not a caret range).

```lua
local Knit = require(ReplicatedStorage.Packages.Knit)
local MatchmakingService = Knit.CreateService {
    Name = "MatchmakingService",
    Client = {}, -- exposed to clients
}
function MatchmakingService.Client:Queue(player, mode) -- becomes a RemoteFunction
    return self.Server:Enqueue(player, mode)
end
function MatchmakingService:Enqueue(player, mode) ... end
function MatchmakingService:KnitStart() self._queues = {} end
Knit.Start():catch(warn)
```

Client calls `Knit.GetService("MatchmakingService"):Queue("ranked")` — no manual remotes.

**Migration cost.** Low–medium. Each existing `XSystem.new()` becomes a Service; `Server.server.luau` shrinks to `Knit.Start()`. Roughly 1–2 days for the four systems.

### Matter — ECS for many entities

**Philosophy.** A modern ECS: data lives in **Components**, behavior lives in **Systems** that query archetypes each frame. Decouples data from code and scales to thousands of entities.

**Pick it when** you have hundreds of projectiles, NPCs, or pickups. For a 10-player FPS with one body each, it's overkill.

**Install.** `Matter = "matter-ecs/matter@0.8.5"`.

```lua
local Matter = require(ReplicatedStorage.Packages.Matter)
local Health   = Matter.component("Health")
local Velocity = Matter.component("Velocity")
local world = Matter.World.new()
world:spawn(Health({ hp = 100 }), Velocity({ v = Vector3.zero }))
local function movementSystem(world)
    for id, vel in world:query(Velocity) do print(id, vel.v) end
end
local loop = Matter.Loop.new(world)
loop:scheduleSystems({ movementSystem })
loop:begin({ default = RunService.Heartbeat })
```

**Migration cost.** High. Inverts control flow: classes dissolve into components + systems. Only worth it if Rivals adds bots/swarms.

### React Roblox (or Fusion) — declarative UI

**Philosophy.** Describe UI as a function of state; the library reconciles `Instance`s. React-shaped libraries (`createElement`, `mount`); Fusion uses `Value`/`Computed` observables for finer-grained reactivity and less boilerplate.

**Pick it when** UI state grows past a handful of toggles. Rivals' `Settings.luau` rebuilds frames imperatively — perfect target.

> **2026 update — Roact is archived & deprecated.** The original [Roblox/roact](https://github.com/Roblox/roact) repo is archived (Dec 2023); README explicitly says "deprecated and no longer maintained" and redirects to `react-lua`. The modern equivalent is [`jsdotlua/react-lua`](https://github.com/jsdotlua/react-lua) (a port of React 17.x to Luau, used internally by Roblox). It supports hooks (`useState`, `useEffect`, `useMemo`), is API-shaped 1:1 with modern React. For new code, **pick `jsdotlua/react` over `Roblox/roact`**.

**Install.** `React = "jsdotlua/react@17.2.1"`, `ReactRoblox = "jsdotlua/react-roblox@17.2.1"` in `wally.toml` (or use Fusion: `Fusion = "elttob/fusion@0.3.0"` — canonical GitHub repo is `dphfox/Fusion`; Wally scope is `elttob`).

```lua
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local function Settings(props)
    local sens, setSens = React.useState(props.sens or 1.0)
    return React.createElement("Frame", { Size = UDim2.fromScale(1,1) }, {
        Sens = React.createElement("TextLabel", { Text = "Sens: " .. sens }),
    })
end

local root = ReactRoblox.createRoot(playerGui)
root:render(React.createElement(Settings, { sens = 1.0 }))
```

**Migration cost.** Low per-screen, isolated. Rewrite `Settings.luau` first — expect ~70% line reduction.

### Decision matrix

| Framework | Best for | Verdict for Rivals |
|---|---|---|
| Knit | Server/client RPC layer | **High** — auto-wires RemoteEvents, replaces `Server.server.luau` plumbing |
| Matter | 1000+ entities (bots, projectiles) | **Medium** — overkill for 10-player FPS, but great if Rivals adds NPC bots |
| `jsdotlua/react` + `react-roblox` | Reactive UI | **High** — `Settings.luau` shrinks ~70%, hooks-based |
| Fusion | Reactive UI (alt) | Medium — leaner API, smaller community than React |

**Recommended order:** Knit first (biggest immediate win, smallest blast radius), React Roblox for `Settings.luau`, Matter only if/when bots land.

Sources: [Knit GitHub](https://github.com/Sleitnick/Knit) · [Knit docs](https://sleitnick.github.io/Knit/) · [Matter GitHub](https://github.com/matter-ecs/matter) · [jsdotlua/react-lua](https://github.com/jsdotlua/react-lua) · [Fusion](https://elttob.uk/Fusion/) · [Roblox/roact (legacy)](https://github.com/Roblox/roact)

## 20. CI/CD: auto-deploy to Roblox on push

The existing `.github/workflows/deploy.yml` only publishes `docs/` to GitHub Pages. The actual `.rbxlx` is still pushed from Studio by hand. Fix it with two workflows.

### 20.1 Workflow split

- `build-pr.yml` (section 10) — `on: pull_request`. Lint + test only, never publishes.
- `deploy-prod.yml` (this section) — `on: push: branches: [master]` + `workflow_dispatch`. Builds, tests, publishes via Open Cloud.

Keeping them separate means PR forks can't access `secrets.ROBLOX_OPEN_CLOUD_KEY` (forks get zero secrets by GitHub policy).

### 20.2 Secrets to create

Repo Settings → Secrets and variables → Actions:

- `ROBLOX_OPEN_CLOUD_KEY` — API key with **Place Management: Write** scope, IP-allowlisted, bound to your universe.
- `ROBLOX_UNIVERSE_ID` and `ROBLOX_PLACE_ID_PROD` / `ROBLOX_PLACE_ID_STAGING`.
- `DISCORD_WEBHOOK` (optional).

### 20.3 `.github/workflows/deploy-prod.yml`

```yaml
name: Deploy to Roblox (prod)
on:
  push:
    branches: [master]
  workflow_dispatch:
    inputs:
      target:
        description: "staging | production"
        default: production

concurrency:
  group: roblox-deploy-${{ github.event.inputs.target || 'production' }}
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.target || 'production' }}
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4

      - name: Install Rokit
        uses: CompeyDev/setup-rokit@v0.2.1

      - name: Cache Rokit tools
        uses: actions/cache@v4
        with:
          path: ~/.rokit
          key: rokit-${{ runner.os }}-${{ hashFiles('rokit.toml') }}

      - name: Lint
        run: |
          selene src/
          stylua --check src/

      - name: Lune tests
        run: lune run tests/run-all.luau

      - name: Build place
        run: rojo build default.project.json -o rivals.rbxlx

      - name: Publish via Open Cloud
        id: publish
        env:
          KEY: ${{ secrets.ROBLOX_OPEN_CLOUD_KEY }}
          UNIVERSE: ${{ secrets.ROBLOX_UNIVERSE_ID }}
          PLACE: ${{ github.event.inputs.target == 'staging' && secrets.ROBLOX_PLACE_ID_STAGING || secrets.ROBLOX_PLACE_ID_PROD }}
        run: |
          RESP=$(curl -fsS -X POST \
            "https://apis.roblox.com/universes/v1/${UNIVERSE}/places/${PLACE}/versions?versionType=Published" \
            -H "x-api-key: ${KEY}" \
            -H "Content-Type: application/octet-stream" \
            --data-binary @rivals.rbxlx)
          VERSION=$(echo "$RESP" | jq -r '.versionNumber')
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Archive build (rollback artifact)
        uses: actions/upload-artifact@v4
        with:
          name: rivals-${{ github.sha }}-v${{ steps.publish.outputs.version }}
          path: rivals.rbxlx
          retention-days: 30

      - name: Tag release
        if: github.event.inputs.target != 'staging'
        run: |
          TAG="rbx-v${{ steps.publish.outputs.version }}-${GITHUB_SHA::7}"
          git tag "$TAG" && git push origin "$TAG"

      - name: Notify Discord
        if: always()
        run: |
          curl -X POST "${{ secrets.DISCORD_WEBHOOK }}" \
            -H "Content-Type: application/json" \
            -d "{\"content\":\"Deploy ${{ job.status }} — place v${{ steps.publish.outputs.version }} (${GITHUB_SHA::7})\"}"
```

### 20.4 Staging gate

Create two **GitHub Environments**: `staging` (no reviewers) and `production` (required reviewer = yourself). The `environment:` key gates the `production` job behind manual approval in the Actions UI.

### 20.5 Rollback

Every build uploads `rivals.rbxlx` as an artifact (30 days). To roll back: download artifact, run `workflow_dispatch` with old SHA, or curl artifact bytes to the publish endpoint with the same key.

### 20.6 Quota and gotchas

- Place Publishing API: 250+ /min — your bottleneck will be Luau Execution (60/min/universe), not publishing.
- `versionType=Published` makes it live. Use `Saved` for staging draft.
- Body must be `application/octet-stream` of raw `.rbxlx` or `.rbxl`. No multipart, no base64.

Sources: [Place Publishing API reference](https://create.roblox.com/docs/cloud/reference/Place) · [Usage guide](https://create.roblox.com/docs/cloud/guides/usage-place-publishing) · [Manage API keys](https://create.roblox.com/docs/cloud/auth/api-keys) · [Roblox/place-ci-cd-demo](https://github.com/Roblox/place-ci-cd-demo) · [Mantle continuous deployment](https://mantledeploy.vercel.app/docs/continuous-deployment)

## 21. Testing: TestEZ, Jest-Lua, headless test runners

`TEST_PLAN.md` is a manual checklist; `src/` has zero `*.spec.luau`. Adding a real runner.

### TestEZ (the long-standing Roblox standard)
BDD `describe / it / expect`, single dependency, works in Studio and via Lune ([Roblox/testez](https://github.com/Roblox/testez)). Install via Wally:
```toml
# wally.toml  [dev-dependencies]
TestEZ = "roblox/testez@0.4.1"
```
`wally install` -> `Packages/TestEZ`. Layout:
```
tests/
  init.spec.luau              -- top describe; participates as the tree node
  RivalsCore_spec.luau
  MovementSystem_spec.luau
  mock_remotes.luau           -- RemoteEvent stand-ins
  runner.luau                 -- Lune entry
src/server/TestRunner.server.luau  -- in-Studio entry
```
`.spec.luau` is the suffix TestEZ globs; `init.spec.luau` lets the folder itself participate as a node ([writing tests](https://roblox.github.io/testez/getting-started/writing-tests/)).

### Complete TestEZ spec - 5 of TEST_PLAN R.1 assertions
```lua
-- tests/MovementSystem_spec.luau
return function()
  local RivalsCore = require(game:GetService("ReplicatedStorage").RivalsCore)
  local CONFIG = RivalsCore.CONFIG
  local function fakeChar()
    local m = Instance.new("Model"); local r = Instance.new("Part"); r.Name="HumanoidRootPart"; r.Parent=m
    local h = Instance.new("Humanoid"); h.Parent=m; return m end

  describe("MovementSystem", function()
    it("CONFIG constants intact (R.1.1)", function()
      expect(CONFIG.Movement.WalkSpeed).to.equal(16)
      expect(CONFIG.Movement.SprintSpeed).to.equal(20)
      expect(CONFIG.Movement.SlideSpeed).to.equal(26)
    end)
    it("Initial state defaults (R.1.2)", function()
      local m = RivalsCore.MovementSystem.new(fakeChar())
      expect(m.State.IsGrounded).to.equal(true)
      expect(m.State.CanDoubleJump).to.equal(true)
      expect(m.State.CurrentSpeed).to.equal(16)
    end)
    it("Sprint toggles speed 16<->20 (R.1.3)", function()
      local m = RivalsCore.MovementSystem.new(fakeChar())
      m:Sprint(true);  expect(m.State.CurrentSpeed).to.equal(20)
      m:Sprint(false); expect(m.State.CurrentSpeed).to.equal(16)
    end)
    it("Slide refused when airborne (R.1.5)", function()
      local m = RivalsCore.MovementSystem.new(fakeChar()); m.State.IsGrounded = false
      expect(m:Slide()).to.equal(false)
      expect(m.State.IsSliding).to.equal(false)
    end)
    it("Double jump consumes once (R.1.9)", function()
      local m = RivalsCore.MovementSystem.new(fakeChar())
      expect(m:Jump()).to.equal(true)
      m.State.IsGrounded = false
      expect(m:Jump()).to.equal(true)
      expect(m:Jump()).to.equal(false)
    end)
  end)
end
```

### Jest-Lua - Jest matchers + first-class mocking
Jest port; `jest.fn()`, `toBe / toEqual / toMatchInstance / toMatchSnapshot`; Roblox uses it internally ([jsdotlua/jest-lua](https://github.com/jsdotlua/jest-lua), [docs](https://jsdotlua.github.io/jest-lua/), [expect](https://jsdotlua.github.io/jest-lua/expect)).
```toml
Jest = "jsdotlua/jest@3.10.0"
JestGlobals = "jsdotlua/jest-globals@3.10.0"
```
```lua
-- tests/WeaponSystem.test.luau  (R.3 ADS spread)
local JG = require(game.ReplicatedStorage.Packages.JestGlobals)
local describe, it, expect, jest = JG.describe, JG.it, JG.expect, JG.jest
local Weapon = require(game.ReplicatedStorage.RivalsCore).WeaponSystem

describe("WeaponSystem.GetSpread", function()
  it("ADS spread is much lower than hip", function()
    local w = Weapon.new("AR")
    w:SetADS(false); local hip = w:GetSpread()
    w:SetADS(true);  local ads = w:GetSpread()
    expect(ads).toBeLessThan(hip)
    expect(ads).toBeCloseTo(0.02, 3)
    expect(hip).toBeCloseTo(0.15, 3)
  end)
  it("fire callback gated by FireRate", function()
    local w = Weapon.new("AR"); local cb = jest.fn()
    w.OnFire = cb; w:Fire(); w:Fire()       -- 2nd blocked
    expect(cb).toHaveBeenCalledTimes(1)
  end)
end)
```

### Mocking RemoteEvents (`tests/mock_remotes.luau`)
```lua
local function FakeSignal() local h={} ; return {
  Connect = function(_,f) table.insert(h,f); return {Disconnect=function() end} end,
  Fire    = function(_,...) for _,f in h do task.spawn(f,...) end end } end
return function() local log = {}; local R = {}
  setmetatable(R, {__index=function(_,name) local e = {OnServerEvent=FakeSignal(),
    FireServer=function(_,...) table.insert(log,{name,"S",...}) end,
    FireAllClients=function(_,...) table.insert(log,{name,"AC",...}) end }; R[name]=e; return e end})
  return R, log
end
```
Inject `_G.__REMOTES = require(mock_remotes)()` before `require(RivalsCore)`; guard `ReplicatedStorage:WaitForChild(name)` reads with `_G.__REMOTES and _G.__REMOTES[name]`.

### Headless via Lune (cross-ref Section 5)
Standalone Luau runtime (~5 MB, ships a Roblox instance shim) ([lune-org/lune](https://github.com/lune-org/lune), [docs](https://lune-org.github.io/docs/)).
```bash
lune run tests/runner.luau           # local
lune run tests/runner.luau --ci-mode # CI: no prompts, exit 1 on any failure
```
`tests/runner.luau` requires Jest-Lua and calls `jest.runCLI(root, { ci = true }):expect()`. TestEZ also runs under Lune but needs a heavier DataModel shim - Jest-Lua is the smoother fit.

### In-Studio runner
```lua
-- src/server/TestRunner.server.luau (gitignore for ship builds)
local TestEZ = require(game.ReplicatedStorage.Packages.TestEZ)
TestEZ.TestBootstrap:run({ game.ReplicatedStorage.Tests }, TestEZ.Reporters.TextReporter)
```
Map your `tests/` folder into Rojo at `ReplicatedStorage.Tests`. Output streams to the Studio Output window.

### Coverage
TestEZ has none built-in; wrap with `luacov` under Lune, or use Jest-Lua's `--coverage` flag ([jest object](https://jsdotlua.github.io/jest-lua/jest-object)). Gotcha: Roblox globals (`game`, `task`, `Instance.new`) are not instrumentable - keep pure logic in functions that accept their dependencies so coverage measures real branches.

### CI - Jest-Lua + Lune is the winner
TestEZ in CI historically needs lemur (unmaintained) or `run-in-roblox` (heavy). Jest-Lua + Lune is one binary, no X server, no Studio:
```yaml
# .github/workflows/test.yml
- uses: CompeyDev/setup-lune@v0.1.0
# No first-party `setup-wally` action exists; install Wally via Rokit or download the release tarball directly.
- run: wally install
- run: lune run tests/runner.luau --ci-mode
```
Non-zero exit fails the build; logs stream to the Actions console.

Sources: [Roblox/testez](https://github.com/Roblox/testez) - [TestEZ writing-tests](https://roblox.github.io/testez/getting-started/writing-tests/) - [jsdotlua/jest-lua](https://github.com/jsdotlua/jest-lua) - [Jest Lua docs](https://jsdotlua.github.io/jest-lua/) - [Expect](https://jsdotlua.github.io/jest-lua/expect) - [Jest object](https://jsdotlua.github.io/jest-lua/jest-object) - [lune-org/lune](https://github.com/lune-org/lune) - [Lune docs](https://lune-org.github.io/docs/) - [Wally](https://wally.run/)

## 22. Profiling, MicroProfiler, performance dashboards

Rivals has zero perf instrumentation today. This section adds a HUD + custom MicroProfiler scopes so you can answer "why are we at 38 FPS?" in seconds instead of hours.

### 22.1 MicroProfiler basics

Press **Ctrl+F6** (Ctrl+Option+F6 on Mac) in Studio or the live client to toggle the MicroProfiler overlay. Press **Ctrl+P** to pause, **Ctrl+F** to jump to the heaviest task in the dump. The horizontal bar = one frame (target 16.6 ms for 60 FPS); each colored block is a task. Right-click → Dump → Export CPU/Memory **Flame Graph** to share. Read flame graphs top-down: wide root = expensive parent, deep stack = call depth.

### 22.2 Custom scope labels

Wrap any hot path with `debug.profilebegin("Tag")` / `debug.profileend()`. Yields auto-close the scope. Recommended insertions:

```lua
function MovementSystem:Update(dt)
    debug.profilebegin("MovementSystem.Update")
    -- ... existing loop ...
    debug.profileend()
end

function CombatSystem:TakeDamage(target, dmg)
    debug.profilebegin("Combat.TakeDamage")
    -- ...
    debug.profileend()
end
```

Also wrap any MCP-heavy code (LLM prompt builds, JSON encode/decode, HTTP webhook callers).

### 22.3 PerfMonitor.luau (StarterPlayerScripts)

```lua
-- PerfMonitor.luau — FPS + ping + memory HUD
local Players = game:GetService("Players")
local Stats   = game:GetService("Stats")
local RunSvc  = game:GetService("RunService")
local gui = Instance.new("ScreenGui")
gui.Name = "PerfMonitor"; gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local lbl = Instance.new("TextLabel", gui)
lbl.AnchorPoint = Vector2.new(1,0); lbl.Position = UDim2.new(1,-8,0,8)
lbl.Size = UDim2.new(0,220,0,80); lbl.BackgroundTransparency = 0.4
lbl.BackgroundColor3 = Color3.new(0,0,0); lbl.TextColor3 = Color3.new(0,1,0)
lbl.Font = Enum.Font.Code; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left
local frames, last = 0, os.clock()
RunSvc.RenderStepped:Connect(function()
    frames += 1
    local now = os.clock()
    if now - last >= 0.5 then
        local fps  = math.floor(frames / (now - last))
        local ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
        local mem  = math.floor(Stats:GetTotalMemoryUsageMb())
        local recv = math.floor(Stats.DataReceiveKbps)
        local send = math.floor(Stats.DataSendKbps)
        lbl.Text = string.format("FPS %d  Ping %dms\nMem %dMB\nRecv %dkbps  Send %dkbps", fps, ping, mem, recv, send)
        frames, last = 0, now
    end
end)
```

### 22.4 Server-side bandwidth probe

```lua
local net = game:GetService("Stats"):FindFirstChild("Network")
local recv = net.DataReceiveKbps -- inbound from clients
local send = net.DataSendKbps    -- outbound replication
```

Log to a `PerfTelemetry` BindableEvent every 5 s; alert if `send > 50 kbps/player`.

### 22.5 Per-frame budget (60 FPS server)

| Bucket | Budget |
|---|---|
| Total frame | 16.6 ms |
| Game logic (`Heartbeat` systems) | ≤ 5 ms |
| Network replication | ≤ 3 ms |
| Physics step | ≤ 5 ms |
| Headroom (GC, OS) | ~3 ms |

### 22.6 Five Rivals FPS hotspots

1. **`WeaponSystem.Fire` raycasts** — cache one `RaycastParams` with `FilterDescendantsInstances` set; call `workspace:Raycast(origin, dir, params)`. Never recreate params per shot.
2. **Per-frame entity loops** — `MovementSystem:Update` iterating every player every Heartbeat. Batch into fixed-step (e.g. 30 Hz) or early-exit on idle entities.
3. **Allocations in hot paths** — `Vector3.new` / `CFrame.new` inside Update. Pre-allocate scratch CFrames, mutate via `CFrame * offsetCF`, recycle tables.
4. **RemoteEvent spam** — see Section 14. Coalesce per-tick; never `FireServer` per input frame.
5. **UI animations** — `TweenService:Create` constructs a new `Tween` object every call; build once, store, and replay with `:Play()`.

Sources: [MicroProfiler overview](https://create.roblox.com/docs/en-us/studio/microprofiler) · [MicroProfiler walkthrough](https://create.roblox.com/docs/performance-optimization/microprofiler/use-microprofiler) · [Stats class reference](https://create.roblox.com/docs/reference/engine/classes/Stats) · [debug.profilebegin good practices](https://devforum.roblox.com/t/good-practices-with-debugprofilebegin-and-debugprofileend/738881)

## 23. Plugin development: turn Rivals tooling into Studio plugins

`MapSystem.luau` (`:CreateArena/:CreateWarehouse/:CreateDowntown`) and `LobbyPads.luau` (`:SetupDefaultPads`) are useful at edit time, not just runtime. Today you paste a require into the **Command Bar**. A Studio plugin gives you a permanent toolbar button, undo support, and persistent settings.

### Plugin vs script

A regular script in `Workspace` only runs **in-game**. A plugin runs in **Edit mode** with elevated permissions: it can modify `game.Workspace`, insert instances, mutate Selection, register undo waypoints (`ChangeHistoryService:SetWaypoint`), and persist data across Studio sessions via `plugin:GetSetting / SetSetting`. Plugins also get a `plugin` global injected (only available inside plugin scripts).

### Lifecycle

```luau
local toolbar = plugin:CreateToolbar("Rivals")
local btn = toolbar:CreateButton("Build Arena", "Generate the Rivals arena map", "rbxassetid://0")
btn.ClickableWhenViewportHidden = true
plugin.Unloading:Connect(function()
    -- save state, disconnect signals
end)
```

`Plugin.Unloading` fires on Studio shutdown or when the plugin is reloaded/uninstalled - always disconnect listeners here.

### `RivalsMapBuilder` plugin sketch (~40 lines)

Plugins **cannot `require()` a non-plugin `ModuleScript`** from `ReplicatedStorage` - that tree only exists at runtime. The cleanest fix is to **inline** the builder into the plugin source (a Rojo `plugin.project.json` can pull `src/shared/MapSystem.luau` straight into the plugin tree).

```luau
-- src/plugin/init.server.luau
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local MapSystem = require(script.MapSystem) -- shipped inside the plugin

local toolbar = plugin:CreateToolbar("Rivals Builder")
local arenaBtn = toolbar:CreateButton("Build Arena", "Spawn arena geometry", "rbxassetid://0")
local warehouseBtn = toolbar:CreateButton("Build Warehouse", "Spawn warehouse", "rbxassetid://0")
local padsBtn = toolbar:CreateButton("Setup Lobby Pads", "Spawn 4 team pads", "rbxassetid://0")

local lastMap = plugin:GetSetting("lastMap") or "Arena"
print("[Rivals] last built:", lastMap)

local function build(name, fn)
    ChangeHistoryService:SetWaypoint("Pre-" .. name)
    local model = fn(MapSystem.new())
    if model then Selection:Set({model}) end
    plugin:SetSetting("lastMap", name)
    ChangeHistoryService:SetWaypoint(name)
end

arenaBtn.Click:Connect(function() build("Arena", function(m) return m:CreateArena() end) end)
warehouseBtn.Click:Connect(function() build("Warehouse", function(m) return m:CreateWarehouse() end) end)
padsBtn.Click:Connect(function()
    local LobbyPads = require(script.LobbyPads)
    build("Pads", function() return LobbyPads:SetupDefaultPads() end)
end)

plugin.Unloading:Connect(function() print("[Rivals] unloading") end)
```

Wrap builds in `ChangeHistoryService:SetWaypoint` so **Ctrl+Z** undoes the whole map in one step. `Selection:Set` puts the new model in focus.

### Settings persistence

`plugin:SetSetting(key, value)` writes JSON-serializable values to a local file keyed per-plugin; `plugin:GetSetting(key)` reads them back across sessions. Use it for "last map built", default team colors, last theme.

### Distributing

- **Personal**: drop the `.rbxmx` into `%LOCALAPPDATA%\Roblox\Plugins\` - Studio loads it on next launch.
- **Team/public**: upload via Studio's **Plugins -> Create Plugin** flow to the Creator Store.
- **Rojo build**: `rojo build plugin.project.json -o RivalsBuilder.rbxmx` produces the file - check it into the repo under `plugin/`.

Sources: [Studio plugins](https://create.roblox.com/docs/studio/plugins) - [Plugin class](https://create.roblox.com/docs/reference/engine/classes/Plugin) - [PluginToolbar:CreateButton](https://create.roblox.com/docs/reference/engine/classes/PluginToolbar/CreateButton) - [PluginToolbarButton](https://create.roblox.com/docs/reference/engine/classes/PluginToolbarButton) - [Studio widgets (PluginGui)](https://create.roblox.com/docs/studio/build-studio-widgets) - [A Guide to GetSetting/SetSetting](https://devforum.roblox.com/t/a-guide-to-getsettingsetsetting/144402)

## 24. Multi-developer workflow: Rojo + git for a team

The repo is currently single-committer. Adding a second dev means picking a collaboration model up-front — Rojo is one-way per Studio session, the place file (`.rbxl` binary, or `.rbxlx` XML) is gitignored either way, and whichever Studio is open is the source of truth for non-script state (Workspace edits, GUI layout). **`.rbxlx` is XML/text — not binary — but it's still gitignored because every save rewrites it and merges are noisy; pair-program through Rojo + Live Share instead.**

### Two collaboration models

1. **Rojo-first (recommended).** Everyone edits `.luau` in VS Code. Exactly one dev runs Studio in Edit mode at a time — they are the *publisher* (their Studio is the build target). Other devs work headless: they edit files, run tests via CLI, and open PRs.
2. **Studio-first (Team Create).** Multiple devs co-edit inside Roblox's native Team Create. Running `rojo serve` against an active Team Create session is **not a supported configuration** — you'll get racing writes on the same instances. There's a documented "Partially Managed Rojo" pattern where Rojo owns `src/` and Team Create owns the world; this works but loses git history for the Team Create half.

This guide assumes **Rojo-first**.

### Branch strategy

- `master` is protected. Direct pushes disabled.
- Feature branches: `feat/<name>`, `fix/<name>`, `chore/<name>`.
- PRs require `ci.yml` green (see section 10) before merge.
- Squash-merge to keep `master` linear.

### Merge conflicts

- **`.luau` conflicts** are normal git 3-way text merges. Resolve in VS Code, re-run `rojo build`, test, push.
- **Binary assets** (uploaded `.rbxm`, `.fbx`, `.png`) cannot be 3-way merged. Use `.gitattributes` + Git LFS.

`.gitattributes` template:

```gitattributes
* text=auto eol=lf
*.luau    text eol=lf
*.lua     text eol=lf
*.toml    text eol=lf
*.json    text eol=lf
*.md      text eol=lf

# Binaries — LFS
*.rbxm    binary filter=lfs diff=lfs merge=lfs -text
*.rbxmx   binary filter=lfs diff=lfs merge=lfs -text
*.rbxl    binary filter=lfs diff=lfs merge=lfs -text
*.rbxlx   binary filter=lfs diff=lfs merge=lfs -text  # .rbxlx is text/XML — included defensively for committed-artifact edge cases
*.fbx     binary filter=lfs diff=lfs merge=lfs -text
*.png     binary filter=lfs diff=lfs merge=lfs -text
*.wav     binary filter=lfs diff=lfs merge=lfs -text
*.ogg     binary filter=lfs diff=lfs merge=lfs -text
```

Run once: `git lfs install && git lfs track "*.rbxm"`.

### Per-dev local config

Only `src/`, `default.project.json`, `selene.toml`, `stylua.toml`, `.github/`, and tests are shared. Each dev keeps locally (gitignored):
- `tools/rojo.exe` — pinned via Rokit `rokit.toml` so versions match.
- Their own `place.rbxlx` build artifact.
- `.vscode/settings.json` for personal prefs (commit `.vscode/extensions.json` only).

### Pair programming

VS Code **Live Share** + a single shared `rojo serve` on the host's machine. The guest sees edits live; the host's Studio is the only one connected. Voice over Discord, terminal sharing for tests.

### Code review etiquette

PR description template:
```
## What
## Why
## Test plan
- TEST_PLAN.md sections affected: 3.2, 4.1
- Manual repro steps:
## Risk
```
Reviewer must run `rojo build` locally before approving anything touching `default.project.json`.

### `CONTRIBUTING.md` — day-one onboarding

New dev's first day should be a single doc covering: install Rokit, `rokit install` (pulls Rojo + Selene + StyLua at pinned versions), clone repo, `git lfs pull`, open `default.project.json` in Studio's Rojo plugin, run `rojo serve`, read `TEST_PLAN.md`, pick a `good-first-issue`, branch and PR.

Sources: [Rojo recommended workflows](https://rojo.space/docs/v0.5/workflows/) · [Partially managed Rojo + Git in teams](https://devforum.roblox.com/t/partially-managed-rojo-git-workflow-in-teams/1381762) · [Rojo with Team Create](https://devforum.roblox.com/t/rojo-with-team-create/1459720) · [How to Automate Place Publishing](https://devforum.roblox.com/t/how-to-automate-place-publishing-with-partially-managed-rojo/2443196)

## 25. Roblox Creator Dashboard automation

By 2026 most Creator Dashboard chores are scriptable via [Open Cloud](https://create.roblox.com/docs/cloud/reference). Base URL: `https://apis.roblox.com`. Auth: `Authorization: Bearer <API_KEY>` (or OAuth 2.0 for user-context calls). Default quota: 60 req/min per key per resource unless noted.

### Surface map (2026)

| Surface | Endpoint root | Notes |
|---|---|---|
| Universe / Place | `/cloud/v2/universes/{id}`, `/places/{id}` | publish, restart servers, edit configs |
| Subscriptions | `/cloud/v2/universes/{id}/subscription-products` | new in 2026, webhooks for purchased/cancelled |
| Badges | `/cloud/v2/universes/{id}/badges`, `/badges/{id}:award` | create + server-side award |
| Developer Products | `/cloud/v2/universes/{id}/developer-products` | legacy v1 retired 2026-04-23 |
| Game Passes | `/cloud/v2/universes/{id}/game-passes` | cross-game sales killed 2026-05-29 |
| Assets | `/assets/v1/assets` (multipart) | upload meshes, audio, images |
| Groups | `/cloud/v2/groups/{id}` `/wall-posts` `/roles` | partial: roles + wall, no rank-by-API yet |
| User Restrictions | `/cloud/v2/universes/{id}/user-restrictions/{userId}` | the canonical ban API |

### Example: award a badge from PowerShell

```powershell
$headers = @{ 'x-api-key' = $env:RBX_KEY; 'Content-Type' = 'application/json' }
$body    = @{ user = "users/$userId" } | ConvertTo-Json
Invoke-RestMethod -Method Post `
  -Uri "https://apis.roblox.com/cloud/v2/universes/$uni/badges/$badge:award" `
  -Headers $headers -Body $body
```

Same shape for `:publish`, `:restart-servers`, `:create` etc. — pagination is `pageToken`/`maxPageSize`.

### `RbxAdmin.luau` (Lune CLI wrapper)

```lua
-- run with: lune run RbxAdmin.luau <cmd> [args]
local net, process = require("@lune/net"), require("@lune/process")
local KEY, UNI = process.env.RBX_KEY, process.env.RBX_UNIVERSE
local function call(method, path, body)
  return net.request{ url="https://apis.roblox.com"..path, method=method,
    headers={["x-api-key"]=KEY,["Content-Type"]="application/json"},
    body = body and net.jsonEncode(body) or nil }
end
local cmds = {
  ["badge:create"]  = function(name) return call("POST", `/cloud/v2/universes/{UNI}/badges`, {displayName=name}) end,
  ["badge:award"]   = function(b,u)  return call("POST", `/cloud/v2/universes/{UNI}/badges/{b}:award`, {user=`users/{u}`}) end,
  ["dp:create"]     = function(n,p)  return call("POST", `/cloud/v2/universes/{UNI}/developer-products`, {displayName=n,priceInRobux=tonumber(p)}) end,
  ["pass:update"]   = function(id,p) return call("PATCH",`/cloud/v2/universes/{UNI}/game-passes/{id}`, {priceInRobux=tonumber(p)}) end,
  ["ban"]           = function(u,sec)return call("PATCH",`/cloud/v2/universes/{UNI}/user-restrictions/{u}`, {gameJoinRestriction={active=true,duration=`{sec}s`}}) end,
  ["msg:publish"]   = function(t,m)  return call("POST", `/cloud/v2/universes/{UNI}:publishMessage`, {topic=t,message=m}) end,
}
print(net.jsonDecode(cmds[process.args[1]](table.unpack(process.args,2)).body))
```

### Use cases

- **Weekly leaderboard badges**: cron job reads top-10 via DataStore Open Cloud, then `RbxAdmin badge:award` each winner.
- **Daily challenge badge at midnight**: GitHub Actions schedule → `badge:create` with date-suffixed name → push id into a `Configuration/Challenges` DataStore entry.
- **Broadcast bonus keys**: `RbxAdmin msg:publish bonus '{"code":"XYZ"}'` — every live server receives via `MessagingService:SubscribeAsync`.

### API key scopes (least privilege)

Create one key per task. Scope explicitly to `universe:<id>` and the minimum operations (`badges:write`, `badges.user-badges:write`, `developer-products:write`, `user-restrictions:write`, `universe-messaging-service:publish`). Never grant `datastores:write` to a key that only awards badges. IP-allowlist CI runner egress.

### Security

- Keys live in repo secrets (`RBX_KEY`) and password manager for humans — never `.env` files in git; add `*.key`, `.env*` to `.gitignore`.
- Rotate quarterly; `cloud/v2/api-keys` lets you script rotation.
- Log every privileged call to an audit DataStore (actor, endpoint, target user, timestamp).
- Webhook receivers must verify the `Roblox-Signature` HMAC.

Sources: [Cloud API reference](https://create.roblox.com/docs/cloud/reference) · [Badges API](https://create.roblox.com/docs/cloud/api/badges) · [Dev Products / Game Pass Open Cloud APIs](https://devforum.roblox.com/t/new-open-cloud-apis-for-configuring-developer-products-and-game-passes/4114297) · [Official list of deprecated web endpoints](https://devforum.roblox.com/t/official-list-of-deprecated-web-endpoints/62889/119) · [Transfers API](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396)


## 26. New Audio API: AudioEmitter, AudioListener, Wire system

The legacy `Sound` object (parented to a Part for 3D positioning) is being superseded by Roblox's **wire-based audio graph** (shipped as beta Feb 2024, broadly usable in production). For an FPS, this matters: muffling a gunshot through a wall now means inserting an `AudioFader` node in the wire chain, not faking it with `Volume *= 0.2`. **Voice-chat integration requires `VoiceChatService.UseNewAudioApi = true`** (the boolean variant; the `UseAudioApi` property is an enum, not a boolean) — otherwise voice still flows through the legacy path.

### API surface

- **`AudioPlayer`** — the source. Holds an `AssetId` and `Volume`/`PlaybackSpeed`. Replaces `Sound.Playing`.
- **`AudioEmitter`** — 3D source position. Parent to the weapon `Handle`. Replaces `Sound.Parent = part`.
- **`AudioListener`** — 3D receiver position. Parent to the camera or player head.
- **`AudioDeviceOutput`** — final speaker. Local playback target.
- **`Wire`** — logic connection. Has `SourceInstance` + `TargetInstance` properties. Wire any two audio nodes.
- **`AudioFader` / `AudioReverb` / `AudioEqualizer`** — inline DSP nodes you splice into the wire chain.

### Weapon SFX chain (replaces legacy `Sound`)

```lua
local player = Instance.new("AudioPlayer")
player.AssetId = "rbxassetid://123456789"

local emitter = Instance.new("AudioEmitter")
emitter.Parent = tool.Handle

local fader = Instance.new("AudioFader") -- used for occlusion

local wire1 = Instance.new("Wire")
wire1.SourceInstance, wire1.TargetInstance = player, fader; wire1.Parent = player

local wire2 = Instance.new("Wire")
wire2.SourceInstance, wire2.TargetInstance = fader, emitter; wire2.Parent = fader

-- Occlusion: raycast wall hits → muffle
local function updateOcclusion(isOccluded)
    fader.Volume = isOccluded and 0.2 or 1.0
end

player:Play()
```

For environmental reverb zones (e.g. "Warehouse" map), parent an `AudioReverb` between the listener and `AudioDeviceOutput`. For ADS-muffle-everything-else, layer an `AudioFader` after the listener.

### Pitfall

Unlike legacy `Sound`, the new audio nodes do **not** auto-clean. Creating an `AudioPlayer` per gunshot without a pool (cross-ref §28) leaks memory and eventually exhausts the engine's wire-processing budget. Either pool the player+fader+emitter triple, or use `Debris:AddItem(player, 5)` to GC after the sound plays out.

Sources: [AudioPlayer](https://create.roblox.com/docs/reference/engine/classes/AudioPlayer) · [AudioEmitter](https://create.roblox.com/docs/reference/engine/classes/AudioEmitter) · [AudioListener](https://create.roblox.com/docs/reference/engine/classes/AudioListener) · [Wire](https://create.roblox.com/docs/reference/engine/classes/Wire) · [Audio API overview](https://create.roblox.com/docs/sound/api)

## 27. MemoryStoreService: cross-server matchmaking & ephemeral state

§12 covered multi-place architecture and §13 covered DataStore persistence. Between them is a gap: **sub-second cross-server coordination** — a global match queue, a live leaderboard tick, an event countdown. That's MemoryStoreService.

### Pick the right primitive

- **`SortedMap`** — best for matchmaking queues ranked by MMR or timestamp.
- **`HashMap`** — best for keyed lookups (active match ID → server JobId).
- **`Queue`** — first-come-first-served match queue, no rank.

All three have **30-second default TTL** (max 45 days) and a **1000-unit/min** universe budget plus **100 units per concurrent user**.

### Cross-server matchmaker

```lua
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService   = game:GetService("MessagingService")
local Queue = MemoryStoreService:GetSortedMap("RankedQueue_v1")

local function joinQueue(player, mmr)
    local key = string.format("%010d_%d", mmr, player.UserId)
    Queue:SetAsync(key, game.JobId, 30) -- (key, value, ttl seconds)
end

local function findMatch()
    local players = Queue:GetRangeAsync(Enum.SortDirection.Ascending, 10)
    if #players < 10 then return end
    local matchId = "MATCH_" .. os.time()
    for _, entry in players do
        MessagingService:PublishAsync("TeleportToMatch", {
            UserId = tonumber(entry.key:match("_(%d+)$")),
            MatchId = matchId,
        })
        Queue:RemoveAsync(entry.key)
    end
end
```

The server that originated the player listens on `MessagingService:SubscribeAsync("TeleportToMatch", ...)` and runs `TeleportService:TeleportToPlaceInstance` (cross-ref §12).

### Pitfall

Polling `findMatch()` in a `while task.wait(1) do` loop on every server burns the per-experience budget (`1000 + 100 × CCU` request units/min) instantly — 30 servers × 60 polls/min = 1800 calls/min. Pick **one** "leader" server (lowest `game.JobId` lex sort wins, or use `MemoryStoreService:GetSortedMap("ServerElection")` with a lease) and only the leader polls. Alternatively, fire `findMatch()` only when a new player joins the queue, gated by a debounce.

Sources: [MemoryStoreService](https://create.roblox.com/docs/cloud-services/memory-stores) · [SortedMap](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap) · [Quotas](https://create.roblox.com/docs/cloud-services/memory-stores/limits-and-quotas) · [MessagingService](https://create.roblox.com/docs/reference/engine/classes/MessagingService)

## 28. Instance pooling: bullets, particles, decals

§22 listed allocations in hot paths as a top-five FPS hotspot. A live FPS firing 600 rounds/min × 10 players = **6000 `Instance.new("Part")` calls/minute**. Each allocation triggers Luau GC pressure, BasePart property serialization, and (worst) a Spatial Hash re-bucket. Pooling cuts all three to zero amortized.

### `BulletPool.luau` template

```lua
local BulletPool = { _storage = {}, _max = 256 }

function BulletPool:Get()
    local bullet = table.remove(self._storage)
    if not bullet then
        bullet = Instance.new("Part")
        bullet.Name = "Bullet"
        bullet.Size = Vector3.new(0.2, 0.2, 2)
        bullet.Anchored = true
        bullet.CanCollide = false
        bullet.CanTouch = false
        bullet.CanQuery = false
        bullet.Material = Enum.Material.Neon
        bullet.Parent = workspace:WaitForChild("Bullets")
    end
    bullet.Transparency = 0
    bullet.CanQuery = true       -- re-enable raycast pickup if needed
    return bullet
end

function BulletPool:Return(bullet)
    if #self._storage >= self._max then bullet:Destroy(); return end
    bullet.CFrame = CFrame.new(0, 9999, 0)
    bullet.Transparency = 1
    bullet.CanQuery = false
    bullet.CanTouch = false
    table.insert(self._storage, bullet)
end

return BulletPool
```

Use `:Get()` on weapon fire, `:Return(b)` on hit/expire (or chain `Debris:AddItem` with a closure).

### When to pool

| Spawn rate | Strategy |
|---|---|
| > 50/sec | **Pool mandatory** — bullets, hit decals, muzzle flashes, blood particles |
| 1-50/sec | Pool nice-to-have — pickups, drops, kill-cam markers |
| < 1/sec | Don't bother — NPCs, vehicles, structure changes |

### Pitfall — ghost collisions

Moving a "returned" bullet to `(0, 9999, 0)` does NOT remove it from physics or spatial-query systems if `CanTouch` or `CanQuery` is still `true`. Every frame, the engine re-buckets it in the Spatial Hash and considers it for raycasts → invisible bullets at the sky still cost CPU. The template above sets both to `false` on return. Same gotcha applies to invisible UI ScreenGuis that you forgot to `.Enabled = false`.

Sources: [Performance Optimization](https://create.roblox.com/docs/performance-optimization) · [BasePart.CanQuery](https://create.roblox.com/docs/reference/engine/classes/BasePart#CanQuery) · [BasePart.CanTouch](https://create.roblox.com/docs/reference/engine/classes/BasePart#CanTouch) · [DevForum: object pooling patterns](https://devforum.roblox.com/t/object-pooling-vs-instance-new-benchmarks/1841823)

## 29. UI accessibility & Experience Controls

For an FPS HUD: gamepad-navigable menus, full-screen TopbarInset awareness, localization on every text element, and respect for player input-mode preferences. Note: Roblox does not currently expose per-GuiObject screen-reader labels — the accessibility surface is gamepad-navigation + localization + visual contrast. Plan for that, don't assume screen-reader APIs that don't exist yet.

### API surface (verified)

- **`GuiService.SelectedObject`** — currently-focused gamepad selectable. Set this manually when opening a menu so the controller starts on the right element.
- **`GuiObject.Selectable`** — bool, makes the object pickable by gamepad nav.
- **`NextSelectionUp / Down / Left / Right`** (on `GuiObject`) — explicit nav graph (skips decorative elements that would otherwise trap focus).
- **`GuiBase2d.AutoLocalize`** — bool inherited by every `GuiObject`; pairs with a `LocalizationTable` parented under `LocalizationService` to translate `Text` at render time.
- **`UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1)`** — check connection.
- **`HapticService:SetMotor(gamepad, motor, intensity)`** — controller vibration.
- **`GamepadService:EnableGamepadCursor(...) / DisableGamepadCursor()`** — cursor-style gamepad pointer (not the same as `SelectedObject`).
- **`GuiService.TopbarInset`** (Rect property) + **`GuiService:GetGuiInset()`** — read the safe area when Roblox's top-bar/Experience Controls are visible. **You cannot hide them**; design around the inset.
- **`LocalizationService:GetTranslatorForPlayerAsync(player)`** — get a `Translator` for runtime text lookup (per-player locale).

### FPS menu wiring

```lua
local GuiService = game:GetService("GuiService")
local menu = playerGui:WaitForChild("PauseMenu")
local resume, settings, quit = menu.Resume, menu.Settings, menu.Quit

-- Explicit nav graph (vertical column)
resume.Selectable = true; settings.Selectable = true; quit.Selectable = true
resume.NextSelectionDown = settings
settings.NextSelectionUp = resume; settings.NextSelectionDown = quit
quit.NextSelectionUp = settings

-- Localize text (AutoLocalize is on GuiBase2d, inherited by every GuiObject)
resume.AutoLocalize = true
resume.Text = "Resume"        -- looked up in LocalizationTable for player's locale

-- Focus the safest option when opened
menu.Enabled = true
GuiService.SelectedObject = resume
```

### Pitfall — auto-nav stuck on the wrong element

Without `GuiService.SelectedObject` set explicitly, Roblox's automatic gamepad navigation often starts on a decorative background `Frame` or a `ScrollingFrame`'s scrollbar — not the menu's primary action. In a fast-paced FPS, a player opening a pause menu and finding their cursor on the background image gets killed while trying to navigate. **Always set `SelectedObject` when a UI menu opens** and explicitly set it back to `nil` (or a HUD button) when it closes.

### Experience Controls — design around them, don't hide them

Roblox's top-bar (chat, leaderboard, menu) is reserved screen real estate; the platform does NOT expose an API to hide it. Read `GuiService.TopbarInset` (a `Rect` property; subscribe via `GuiService:GetPropertyChangedSignal("TopbarInset")` to react to changes) and `GuiService:GetGuiInset()` to know how much vertical padding to reserve at the top of your HUD. The "Experience Controls" launch announcement (Oct 2024) confirms visibility is fixed.

### FPS HUD accessibility audit checklist

- [ ] Pause menu, settings menu, kill-cam each set `GuiService.SelectedObject` on open
- [ ] `NextSelectionUp/Down/Left/Right` defined on all menu buttons; no orphan selectables
- [ ] Every text element has `AutoLocalize = true` and the key is in your `LocalizationTable`
- [ ] HUD respects `GuiService.TopbarInset` (don't render under the top-bar)
- [ ] Color-blind palette respected: don't encode team purely by color
- [ ] Critical info has a non-audio cue (subtitles for radio, on-screen indicator for low-health)
- [ ] Test with `UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1)` and a real controller
- [ ] Use `HapticService:SetMotor` for hit-feedback (matches accessibility expectation of multi-channel feedback)

Sources: [GuiService](https://create.roblox.com/docs/reference/engine/classes/GuiService) · [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject) · [GuiBase2d.AutoLocalize](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d#AutoLocalize) · [UserInputService:GetGamepadConnected](https://create.roblox.com/docs/reference/engine/classes/UserInputService#GetGamepadConnected) · [HapticService](https://create.roblox.com/docs/reference/engine/classes/HapticService) · [LocalizationService](https://create.roblox.com/docs/reference/engine/classes/LocalizationService) · [Experience Controls Oct 2024](https://devforum.roblox.com/t/updated-experience-controls-now-live/3215981)

## 30. Bit-packed network buffers (Luau `buffer` API)

Standard `RemoteEvent` payloads serialize Lua tables to a verbose internal format — a `{x=12.3, y=45.6, z=78.9}` position costs ~30 bytes on the wire. For a 60 Hz FPS replicating 10 players' positions + velocities + look-vectors, that's **~600 KB/s of replication budget** burned on field names. The Luau `buffer` API lets you bit-pack the same data into ~24 bytes/player tick.

### When it matters

- > 30 Hz updates per player (position, velocity, look-vector replication)
- Hit-validation rays sent client → server
- Projectile state replication
- Per-frame input streams (keypress timestamps)

### `buffer` API surface

- **`buffer.create(size)`** — allocate fixed-size byte buffer
- **`buffer.writei8/i16/i32`, `writeu8/u16/u32`, `writef32/f64`** — typed writes at byte offset (integer widths 8/16/32 (signed `i` and unsigned `u`) plus float widths `f32` and `f64`)
- **`buffer.readi8/...` mirror reads** — same offsets
- **`buffer.len(buf)`** — size in bytes
- Buffers serialize natively through `RemoteEvent:FireServer` / `:FireAllClients` — no JSON encode step

### Position-replication example

```lua
-- PACK (client → server): 12 bytes per tick (x,y,z f32) + 4 bytes yaw = 16 bytes
local function packState(pos: Vector3, yaw: number): buffer
    local b = buffer.create(16)
    buffer.writef32(b, 0, pos.X)
    buffer.writef32(b, 4, pos.Y)
    buffer.writef32(b, 8, pos.Z)
    buffer.writef32(b, 12, yaw)
    return b
end

-- UNPACK (server)
local function unpackState(b: buffer): (Vector3, number)
    return Vector3.new(buffer.readf32(b, 0), buffer.readf32(b, 4), buffer.readf32(b, 8)),
           buffer.readf32(b, 12)
end

RemoteEvents.PlayerState.OnServerEvent:Connect(function(plr, b: buffer)
    local pos, yaw = unpackState(b)
    -- validate vs anti-cheat speed-delta (§14), commit to authoritative state
end)
```

### Bit-packing for booleans + small enums

```lua
-- Pack 8 bools + a 4-bit weapon slot = 2 bytes vs ~16 bytes as a table
local function packFlags(isFiring, isAds, isSprinting, isCrouching, slot)
    local flags = (isFiring and 1 or 0)
                | (isAds and 2 or 0)
                | (isSprinting and 4 or 0)
                | (isCrouching and 8 or 0)
    local b = buffer.create(2)
    buffer.writeu8(b, 0, flags)
    buffer.writeu8(b, 1, slot)
    return b
end
```

### Pitfalls

- **Endianness**: `buffer` is little-endian. If you pipe through HttpService to a non-Luau backend, byte-swap before send.
- **Mutability**: buffers are passed by reference. Don't reuse a write buffer across multiple `FireAllClients` — clients see the last state, not the per-tick state. Allocate fresh per fire or `buffer.copy` it.
- **Validation**: an exploiter can send a buffer of any size. `assert(buffer.len(b) == 16)` before reading.
- **Quota interaction**: `RemoteEvent:FireServer` is still rate-limited by §14's token bucket. Bit-packing reduces bytes, not call count.

Sources: [Luau buffer API](https://luau.org/library#buffer) · [DevForum: buffer announcement](https://devforum.roblox.com/t/luau-buffer-type-now-available/2412958) · [DevForum: buffer in RemoteEvents](https://devforum.roblox.com/t/announcing-buffer-type-replication/3022115)

## 31. Parallel Luau: Actors and `task.desynchronize`

A 5v5 FPS at 60 Hz with 600 raycasts/sec/player = 6000 raycasts/sec server-side. Plus collision queries, projectile updates, NPC AI. The single-threaded server runs all of this on one OS thread by default. **Parallel Luau** distributes work across worker threads using `Actor` instances + `task.synchronize()` / `task.desynchronize()` boundaries.

### API surface

- **`Actor`** — a Model-derived instance whose descendant scripts run in their own thread.
- **`task.desynchronize()`** — switch the current coroutine from the main thread to a worker thread. Anything between this and the next `task.synchronize()` runs in parallel with the main DataModel mutation thread.
- **`task.synchronize()`** — switch back to the main thread before doing anything that mutates the DataModel.
- **`workspace:Raycast`** — read-only, **safe to call in desynchronized context**.
- **`SharedTable`** — thread-safe shared state primitive (replaces global tables when you need cross-actor data).

### Pattern: parallel raycast pool

```lua
-- ServerScriptService/RaycastWorkers/Worker.server.luau (inside an Actor)
local raycastEvent = script.Parent:WaitForChild("RaycastRequest") :: BindableEvent
local resultEvent  = script.Parent:WaitForChild("RaycastResult")  :: BindableEvent

raycastEvent.Event:Connect(function(requestId: number, origin: Vector3, direction: Vector3)
    task.desynchronize()
    local result = workspace:Raycast(origin, direction, RAYCAST_PARAMS)
    task.synchronize()
    resultEvent:Fire(requestId, result)  -- main thread again, safe to dispatch
end)
```

The main thread fires `RaycastRequest:Fire(id, origin, dir)`; the worker actor handles the math in parallel; results come back via `RaycastResult`. With 8 workers, you parallelize hit-reg across 8 cores.

### Pattern: `ConnectParallel` (auto-desynchronized event handlers)

```lua
local actor = script:FindFirstAncestorOfClass("Actor")
script.Parent.OnHit:ConnectParallel(function(hit)
    -- automatically runs in desynchronized context
    local result = workspace:Raycast(hit.Origin, hit.Direction, params)
    task.synchronize()
    -- mutations here run on the main thread
end)
```

For cross-actor lookups, pair `SharedTable` with `SharedTableRegistry:GetSharedTable(name)` — the registry is the canonical cross-actor lookup primitive.

### Pitfalls

- **DataModel writes inside `desynchronize` will error.** Anything that mutates parts, scripts, attributes, instances must happen between `synchronize()` and the next `desynchronize()`. Raycasts read-only — safe. `:SetAttribute()` — not safe.
- **Shared state needs `SharedTable`** (not a regular Lua table). Or pass data through BindableEvents.
- **Actor startup is not free** — each Actor has measurable spin-up cost (sub-millisecond to a few ms in community benchmarks). Pre-spawn a pool at server start, don't create one per request.
- **Profiler tagging**: use `debug.profilebegin("worker.raycast")` inside the worker so MicroProfiler attributes time correctly (cross-ref §22).

### When parallel Luau is overkill

- < 1000 events/sec total → main thread is fine
- Logic that touches the DataModel every tick → synchronize cost eats the parallelism win

Sources: [Parallel Luau docs](https://create.roblox.com/docs/scripting/multithreading) · [task.desynchronize](https://create.roblox.com/docs/reference/engine/libraries/task#desynchronize) · [Actor class](https://create.roblox.com/docs/reference/engine/classes/Actor) · [SharedTable](https://create.roblox.com/docs/reference/engine/datatypes/SharedTable)

## 32. Procedural animation & `IKControl`

Pre-baked animations can't account for: variable weapon-sway frequencies driven by player movement, recoil patterns that depend on weapon stat tables, look-at vectors for arbitrary aim angles, or feet aligning to non-flat terrain. `IKControl` (inverse kinematics) lets the engine solve for joint angles to satisfy a target position/orientation at runtime.

### API surface

- **`IKControl`** — an Instance that constrains a `Humanoid`'s joint chain to reach a `Target` position.
- **`IKControl.Type`** — `Position`, `Rotation`, `LookAt`, `Transform`. `LookAt` is what you want for "head/torso tracks the crosshair."
- **`IKControl.ChainRoot`** — the joint where the chain starts (e.g., `UpperTorso`).
- **`IKControl.EndEffector`** — the joint that reaches the target (e.g., `Head` for look-at, `RightHand` for weapon grip).
- **`IKControl.Target`** — an `Instance` to reach (typically an `Attachment` whose `WorldPosition` you update each frame; can also be a `BasePart`). NOT a `Vector3` directly.
- **`IKControl.Weight`** — 0..1 blend between animation pose and IK solve.

### Recoil + weapon sway via IK

```lua
local hum = char.Humanoid
local ik = Instance.new("IKControl")
ik.Type = Enum.IKControlType.Transform
ik.ChainRoot = char.UpperTorso
ik.EndEffector = char.RightHand
ik.Weight = 1
ik.Parent = hum

local recoilOffset = Vector3.zero

-- IKControl.Target requires an Instance (Attachment or BasePart). Drive a movable Attachment.
local recoilTarget = Instance.new("Attachment")
recoilTarget.Parent = char.RightHand
ik.Target = recoilTarget

RunService.Heartbeat:Connect(function(dt)
    -- Decay recoil ~85% per frame
    recoilOffset = recoilOffset:Lerp(Vector3.zero, 0.15)
    local handAttachment = char.RightHand:FindFirstChild("RightGripAttachment")
    if not handAttachment then return end
    recoilTarget.WorldPosition = handAttachment.WorldPosition + recoilOffset
end)

function onFire()
    recoilOffset += Vector3.new(math.random(-2,2)/10, math.random(8,12)/10, 0)
end
```

For look-at:

```lua
local lookIK = Instance.new("IKControl")
lookIK.Type = Enum.IKControlType.LookAt
lookIK.ChainRoot = char.UpperTorso
lookIK.EndEffector = char.Head

-- Target must be an Instance — use a movable Attachment whose WorldPosition tracks the mouse hit
local lookTarget = Instance.new("Attachment")
lookTarget.Parent = workspace.Terrain   -- anchored host
lookIK.Target = lookTarget
lookIK.Parent = hum

RunService.Heartbeat:Connect(function()
    lookTarget.WorldPosition = mouse.Hit.Position
end)
```

### Pitfalls

- **IKControl only works on R15+ Humanoids** — R6 has no joint chain to solve.
- **Animation priority interaction**: `Action`-priority animations override IK unless `IKControl.Priority` exceeds. Tune `Priority` per-control.
- **Performance**: each `IKControl` solves per frame. Disable (`Enabled = false`) the look-at IK when the player is dead, behind cover, or in a cutscene.
- **Replication**: IK solves run client-side for the local player; on the server the joints stay in animation-pose. If you care about server-side hit-reg matching the IK pose, you need to also replicate the target via RemoteEvent (cross-ref §30).

Sources: [IKControl class](https://create.roblox.com/docs/reference/engine/classes/IKControl) · [IK in Roblox](https://create.roblox.com/docs/animation/inverse-kinematics) · [DevForum: IKControl examples](https://devforum.roblox.com/t/ikcontrol-new-easy-way-to-do-inverse-kinematics/2009223)

## 33. Native subscriptions & recurring monetization

One-time `GamePass` and `DeveloperProduct` purchases don't fund a competitive shooter's ongoing server, content, and update costs. **Roblox.s recurring subscription API** lets you sell Battle Pass tiers, premium memberships, and ad-removal subscriptions with monthly auto-renew through Roblox's billing system.

### API surface

- **Configure subscription products** in the Creator Dashboard or via Open Cloud (§25).
- **`MarketplaceService:GetUserSubscriptionStatusAsync(player, subscriptionId)`** — returns a `SubscriptionInfoTable` with `IsSubscribed`, `IsRenewing`, `ExpireTime`.
- **`MarketplaceService:GetUserSubscriptionPaymentHistoryAsync(player, subscriptionId)`** — entries have `CycleStartTime`, `CycleEndTime`, `PaymentStatus`.
- **`MarketplaceService:PromptSubscriptionPurchase(player, subscriptionId)`** — show the purchase prompt.
- **`Players.UserSubscriptionStatusChanged`** event — fires `(player, subscriptionId)` when status flips (purchased, cancelled, expired, refunded).
- **Webhooks** at the Open Cloud surface deliver `subscription.purchased` / `.cancelled` / `.expired` / `.refunded` events to your backend (cross-ref §25).

### Battle-pass tier example

> **Important:** The subscription API lives on `MarketplaceService` (not a `SubscriptionService` class), and the status-change event is `Players.UserSubscriptionStatusChanged` (on the `Players` service). Don't be misled by the naming — there is no public `SubscriptionService` class.

```lua
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local BATTLE_PASS_ID = "EXP-1234567890"  -- get from Creator Dashboard

local function refreshEntitlement(player)
    local ok, info = pcall(function()
        return Marketplace:GetUserSubscriptionStatusAsync(player, BATTLE_PASS_ID)
    end)
    if ok and info.IsSubscribed then
        player:SetAttribute("BattlePassTier", "Premium")
    else
        player:SetAttribute("BattlePassTier", "Free")
    end
end

Players.PlayerAdded:Connect(refreshEntitlement)

Players.UserSubscriptionStatusChanged:Connect(function(player, subId)
    if subId == BATTLE_PASS_ID then refreshEntitlement(player) end
end)

-- Sell from a UI button
buyButton.Activated:Connect(function()
    Marketplace:PromptSubscriptionPurchase(Players.LocalPlayer, BATTLE_PASS_ID)
end)
```

### Pitfalls

- **Subscription IDs** start with `EXP-` and are per-experience. You can NOT cross-game-sell subscriptions (mirrors the 2026-05-29 cross-game-sales change for products/passes).
- **Server-side validation**: never grant entitlements based on client-side `UserSubscriptionStatusChanged`. The client can fake the event. Re-call `GetUserSubscriptionStatusAsync` server-side on every join + on every status-changed signal.
- **Refund handling**: if the user refunds, `Players.UserSubscriptionStatusChanged` fires with `IsSubscribed=false`. Your code MUST revoke the entitlement and probably store currency they spent on premium-only items.
- **Test subscriptions** are gated behind Roblox's Test Environment toggle in the Dashboard.
- **Tax / revenue cut** is handled by Roblox; you receive payouts in Robux after the platform cut.

Sources: [MarketplaceService (subscriptions API)](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService) · [Players.UserSubscriptionStatusChanged](https://create.roblox.com/docs/reference/engine/classes/Players#UserSubscriptionStatusChanged) · [Selling Subscriptions guide](https://create.roblox.com/docs/production/monetization/subscriptions) · [MarketplaceService:PromptSubscriptionPurchase](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#PromptSubscriptionPurchase) · [Open Cloud Subscriptions webhooks](https://create.roblox.com/docs/cloud/webhooks)

## 34. `--!native` Luau compilation for hot paths

The standard Luau VM is a bytecode interpreter. The `--!native` pragma compiles a script (or function) to **native machine code** at load time, giving roughly 1.5–2.5× speedups on math-heavy or tight-loop code . For a Roblox FPS, the hot paths that benefit most: bullet physics integration, ballistics drop calculations, custom character controllers, ECS systems running every tick.

### Usage

Drop `--!native` as the **first line** of a script (after `--!strict` if present). The compiler emits native code for every function in that script when the place loads.

```luau
--!strict
--!native

local Ballistics = {}

function Ballistics.simulate(initialVel: Vector3, gravity: number, dt: number, steps: number): Vector3
    local pos = Vector3.zero
    local vel = initialVel
    for i = 1, steps do
        vel = vel + Vector3.new(0, -gravity * dt, 0)
        pos = pos + vel * dt
    end
    return pos
end

return Ballistics
```

For function-granularity control, attach `@native` immediately before the `function` keyword:

```luau
--!strict

@native
local function hotPath(x, y)
    return x * x + y * y
end
```

### What's slow without `--!native`, fast with it

- Tight numerical loops (10k+ iterations)
- Vector3 / CFrame math chains
- Custom physics integrators
- ECS query loops (cross-ref §19 Matter)
- Procedural mesh generation

### What `--!native` doesn't help

- I/O-bound code (RemoteEvent fires, DataStore calls)
- Code dominated by Instance API calls (`Workspace:Raycast` is implemented in C++ — already as fast as it gets)
- Older Luau builds didn't native-compile functions containing `pcall`; current builds do, so this is no longer a concern.
- Generic-table-heavy code (use `--!strict` first to give the compiler type info)

### Pitfalls

- **Compilation cost**: native compile happens at script load. For 50 large native scripts, expect +1-3 s startup. Reserve `--!native` for actually hot code.
- **Mobile/console**: on lower-spec platforms, the compile-time cost can outweigh the runtime win. Profile with `debug.profilebegin` (cross-ref §22) before and after to confirm.
- **Pair with `--!strict`**: native compilation works best when the type solver has narrowed types. `--!nonstrict + --!native` underperforms `--!strict + --!native`.
- **Doesn't change semantics** — bugs are still bugs, just faster.

Sources: [Luau native code generation](https://create.roblox.com/docs/luau/native-code-gen) · [DevForum: --!native announcement](https://devforum.roblox.com/t/luau-native-code-generation/2375760) · [DevForum: when to use --!native](https://devforum.roblox.com/t/native-code-generation-best-practices/2410223)
