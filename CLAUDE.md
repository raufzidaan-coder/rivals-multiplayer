# Rivals - Claude Context

This working directory hosts **two projects side-by-side**:

1. **Roblox FPS game** (managed by Rojo — local `.luau` files sync into Roblox Studio).
2. **Express/Socket.io browser game** (`server.js` + `public/`) — unrelated to the Roblox project, kept here for convenience. Don't conflate the two.

When the user mentions "the game," "Studio," "Rojo," or any `.luau` work, it's the Roblox project. When they mention "the server," "Socket.io," "node," or browser play, it's the Express side.

## Project Layout

```
rivals-multiplayer/
├── src/                           # ROBLOX project (Rojo-managed)
│   ├── server/                    -> ServerScriptService
│   │   ├── Server.server.luau     (Script - main server entrypoint)
│   │   └── LobbyPads.luau         (ModuleScript - pad-based matchmaking)
│   ├── client/                    -> StarterPlayer.StarterPlayerScripts
│   │   └── Client.client.luau     (LocalScript - main client entrypoint)
│   └── shared/                    -> ReplicatedStorage
│       ├── RivalsCore.luau        (ModuleScript - shared systems library)
│       ├── MapSystem.luau         (ModuleScript - map generation)
│       └── Settings.luau          (ModuleScript - player settings + UI)
├── default.project.json           (Rojo project mapping)
├── tools/
│   ├── rojo.exe                   (Rojo CLI, bundled)
│   └── Rojo-Plugin.rbxm           (Studio plugin to install once)
├── types/
│   ├── globalTypes.d.luau         (Roblox API type definitions)
│   └── roblox-api-docs.json       (Full API dump for reference)
│
├── server.js                      # EXPRESS browser game (Node)
├── package.json                   (npm config — `npm start` runs server.js)
├── public/                        (HTML5 canvas client)
├── users.json                     (file-based user store)
├── roblox-scripts/                (LOOSE .lua files — pre-Rojo experiments, not synced)
└── docs/                          (Express game docs)
```

The Roblox and Express projects share this directory but are otherwise independent — different runtimes, different ports (Rojo 34872, MCP 58741, Express 3001), different file types (`.luau` vs `.js`).

## File Naming Conventions (Rojo)

- `Foo.server.luau` → becomes a **Script** named `Foo`
- `Foo.client.luau` → becomes a **LocalScript** named `Foo`
- `Foo.luau` → becomes a **ModuleScript** named `Foo`
- `init.server.luau` inside `Foo/` → makes the folder become a **Script** named `Foo`

## Folder → Roblox Service Mapping

| Local folder | Roblox service |
|---|---|
| `src/shared/` | `ReplicatedStorage` |
| `src/server/` | `ServerScriptService` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts` |

## Module Require Paths

Server / client scripts access shared modules at `ReplicatedStorage`:
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))
local MapSystem  = require(ReplicatedStorage:WaitForChild("MapSystem"))
local Settings   = require(ReplicatedStorage:WaitForChild("Settings"))
```

Server-only siblings (e.g., `LobbyPads`) use:
```lua
local LobbyPads = require(script.Parent:WaitForChild("LobbyPads"))
```

## One-Time Setup

These are done once per machine.

### 1. Install the Rojo Studio plugin
Either drag `tools/Rojo-Plugin.rbxm` into a running Studio window, or copy it into Studio's plugins folder (Studio → **Plugins → Plugins Folder**, drop the `.rbxm` in, restart Studio).

### 2. Install the Roblox Studio MCP plugin
Already done — `RobloxStudioMCP.rbxmx` lives in `%LOCALAPPDATA%\Roblox\Plugins\` (v2.6.0). See `MCP_SETUP.md` for the full handshake checklist (Studio → **File → Game Settings → Security → Allow HTTP Requests** must be on).

### 3. Bundled CLIs
`tools/rojo.exe` is the bundled Rojo binary; no separate install required. If you want it on PATH (so bare `rojo serve` works in any terminal), add `C:\Users\admin\rivals-multiplayer\tools` to your user PATH. Otherwise always invoke as `tools\rojo.exe …`.

## Daily Workflow

1. **Start Rojo sync** — `tools\rojo.exe serve` from this directory (or use the VS Code task **Rojo: Serve (live sync)**). Watches files; serves on `localhost:34872`.
2. **Connect Studio** — Studio's Rojo plugin → **Connect** → accept incoming sync.
3. **Edit `.luau` files on disk** — Studio updates within ~1s.
4. **Rojo is one-way** — Studio-side changes are NOT written back to disk. Treat disk as the source of truth.
5. **Build the in-game arena** (once per place save) — in Studio Command Bar (Ctrl+9):
   ```lua
   local MapSystem = require(game:GetService("ReplicatedStorage"):WaitForChild("MapSystem"))
   MapSystem.new():CreateArena()
   ```
   Save the place (Ctrl+S) — the arena persists. To use a different map, swap `:CreateArena()` for `:CreateWarehouse()` or `:CreateDowntown()`.

## Building a Place File

Produce a `.rbxlx` without Studio:
```
tools\rojo.exe build default.project.json -o rivals.rbxlx
```
Open the built place in Studio:
```
tools\rojo.exe build default.project.json -o rivals.rbxlx; start rivals.rbxlx
```
The `.rbxlx` is gitignored — rebuild on demand.

## Pre-Applied Bug Fixes

The source in `src/` has these fixes already applied versus the original Rivals scripts:

1. `Server.server.luau` — `self:Lobby:LeaveQueue(Player)` (invalid colon syntax) → `self.Lobby:LeaveQueue(Player)`
2. `Client.client.luau` — `script.Parent:WaitForChild("RivalsCore")` (wrong location) → `ReplicatedStorage:WaitForChild("RivalsCore")`
3. `Server.server.luau` — `script.Parent:WaitForChild("RivalsCore")` (same wrong location as #2, server side) → `ReplicatedStorage:WaitForChild("RivalsCore")`
4. `LobbyPads.luau` — `Instance.new("TouchTransducer", Part)` (not a real Roblox class — runtime crash) → `Part.Touched:Connect(function(otherPart) ... end)` with a Humanoid+Player check
5. `Server.server.luau` — multiple `RivalsCore.PlayerDataManager.new():GetData(Player)` calls each created a fresh in-memory store, leaking data between callsites → single `self.DataManager = RivalsCore.PlayerDataManager.new()` cached in `Server.new()` and reused everywhere
6. `Server.server.luau` — `SetupRemoteListeners(Player)` was called from `OnPlayerJoined`, so every player join added another `OnServerEvent` handler to every RemoteEvent → moved into `Server:Start()` so it runs once
7. `Server.server.luau` — `PlayerRemoving` only called `Lobby:LeaveQueue`, never cleared `self.Players[Player]` → added `self.Players[Player] = nil` to close the memory leak
8. `Server.server.luau` — `KillFeed:FireAllClients` fired on every death (even in lobby) → moved inside the active-match branch so it only fires during a round
9. `MapSystem.luau` — `LoadMap` deleted `CurrentMap` before checking the requested map exists, leaving the place mapless if the target was unregistered → validate first, delete second, return a boolean
10. `Client.client.luau` — `Loadout` declared `Primary`, `Secondary`, `Melee`, `Utility` locals that were never used → removed
11. `RivalsCore.luau` — `ClientController:SetupInput` referenced `Enum.InputState.Begin` (×12); `InputState` is not a top-level Roblox Enum → `Enum.UserInputState.Begin`. Without this fix, every WASD / Sprint / ADS / Fire / Reload bind threw "InputState is not a valid member of Enum" and the entire ContextActionService chain crashed silently.
12. `RivalsCore.luau` — `ClientController:SetupInput` bound `Enum.KeyCode.MouseButton1` / `MouseButton2` (×2); mouse buttons live under `UserInputType`, not `KeyCode` → `Enum.UserInputType.MouseButton1/2`. Without this fix, Fire and ADS binds errored on every Initialize.
13. `Settings.luau` — module ended with `return Settings, SettingsUI` (two return values); Roblox ModuleScripts must return a single value or `require()` warns "Module code did not return exactly one value" and the second value is silently dropped → `Settings.UI = SettingsUI; return Settings`. SettingsUI is now reachable as `Settings.UI`.
14. `Client.client.luau` — `game:GetService("StarterPlayerScripts")` (StarterPlayerScripts is a child of StarterPlayer, not a top-level service — `:GetService` would error). Local was also unused → line removed.
15. `LobbyPads.luau` — `Enum.MeshType.Box` (not a real enum value) → `Enum.MeshType.Brick`. Caused pad mesh creation to error at runtime.
16. `Settings.luau` — default keybinds `ADS = Enum.KeyCode.MouseButton2` and `Fire = Enum.KeyCode.MouseButton1` (same family of bug as #12 — mouse buttons live on `UserInputType`, not `KeyCode`) → switched to `Enum.UserInputType.MouseButton{1,2}`. Without this fix, any code reading `Settings.Data.PC.Keybinds.Fire` / `.ADS` to bind would error.
17. `RivalsCore.luau` — `ClientController:Update` had duplicate if/elseif branches: `if Fire and not ADS then Fire() ... elseif ADS and Fire then Fire() ... end` — both branches identical → collapsed to a single `if Fire then ...` (the ADS state is consumed by `WeaponSystem:Fire()` internally via `self.State.IsADS`, no need to gate at the caller).

If you ever re-paste the originals on top, re-apply all of these.

### Discovered via `test.rbxlx` + selene

Fixes 11-13 were surfaced by the runtime test suite in `test.rbxlx` (see `tests/README.md`) — the harness caught them when spec assertions failed.
Fixes 14-17 were surfaced by `tools/selene.exe src/` (4 of 5 `incorrect_standard_library_use` errors plus 1 `if_same_then_else`). Re-run `tools/selene.exe src/` after any source change — current baseline is **0 errors, 52 warnings**.

## Roblox Conventions to Follow

- **Always use `task.wait()` and `task.spawn()`** — never the deprecated `wait()` or `spawn()`
- **Server-validate everything from the client** — never trust input over RemoteEvents
- **Place RemoteEvents in ReplicatedStorage** so both server and client can access them
- **Use `:GetService()` not `game.ServiceName`** for service access — more robust
- **Use `:WaitForChild()` from the client side** — replication isn't instant
- **Anchor parts before parenting** to avoid them falling
- **`PrimaryPart` must be set** before using `PivotTo` on a Model
- **LocalScripts only run** in `StarterPlayerScripts`, `StarterCharacterScripts`, `StarterPack`, or `PlayerGui`
- **ModuleScripts return a single value** — usually a table

## Known Game Systems

### `RivalsCore` (shared) exposes:
- `CONFIG` — game config (movement speeds, combat constants, etc.)
- `MovementSystem` — sprint, slide, wall-run, double-jump
- `CombatSystem` — damage, headshots, hitreg
- `WeaponSystem` — weapon definitions
- `AbilitySystem` — special abilities **(referenced in docs but NOT implemented in code; the `UseAbility` RemoteEvent is created but has no server handler and no client keybind. Treat as a TODO, not a feature.)**
- `LobbySystem` — queue management (also referenced as "MatchmakingSystem" in older docs)
- `GameModeManager` — round flow
- `PlayerDataManager` — leaderstats, persistence
- `ClientController` — main client-side coordinator

### `MapSystem` (shared) exposes:
- `MapSystem.new()` returns a builder
- `:CreateArena()` — main arena with cover/platforms
- `:CreateWarehouse()` — warehouse map
- `:CreateDowntown()` — urban map
- `:DeleteMap(name)` / `:LoadMap(name)`

### `LobbyPads` (server) exposes:
- `PadSystem.new()` returns a controller
- `:CreatePad(name, color, position, queueType, teamSize)`
- `:SetupDefaultPads()` creates 1v1, 2v2, 5v5, Special, Shooting Range pads

### `Settings` (shared) exposes:
- `Settings` table (default keybinds, sensitivities, crosshair, etc.)
- `SettingsUI.new(Player)` — in-game settings menu

## How to Build the Map In-Studio Manually

In Studio Command Bar (View → Command Bar, or Ctrl+9):
```lua
local MapSystem = require(game:GetService("ReplicatedStorage"):WaitForChild("MapSystem"))
local maps = MapSystem.new()
maps:CreateArena()
```

## Common Pitfalls

- If `require` says "module experienced an error while loading," scroll up in Output for the real error. The first cached error is opaque.
- Studio doesn't reload ModuleScripts inside the same play session — restart the test to pick up changes.
- `SpawnLocation`'s circular decal must be deleted to make spawns truly invisible (`Transparency = 1` alone is not enough).
- If colors look weird in the editor (e.g., everything red), check for an unclosed `"` or `--[[` higher in the file.

## Working with Claude Code

This folder ships with four files that configure / exercise Claude Code automatically:

- `CLAUDE.md` (this file) — project context loaded into every Claude Code session opened here.
- `.claude/settings.json` — pre-approved tool permissions (Rojo, stylua, selene, Read/Edit/Write on `src/**`) and MCP allowlist.
- `.mcp.json` — registers the `robloxstudio` MCP server (auto-started via `npx -y robloxstudio-mcp@latest`). See `MCP_SETUP.md` for the full handshake checklist and troubleshooting table.
- `TEST_PLAN.md` — tick-through smoke-test checklist for every capability available from this dir (Rojo sync, all 69 MCP tools, Express side, skills, other MCPs). Run it after restarts and after any tooling change.

When the MCP server is connected, Claude can read Workspace, edit scripts, run Luau in Studio's Command Bar, read Output, and take screenshots — no copy/paste loop.

## Express Browser Game (other half of this directory)

`server.js`, `package.json`, `public/`, and `users.json` are a separate Express + Socket.io browser game project. Unrelated to the Roblox code. To run it: `npm install` then `npm start` → `http://localhost:3001`. See `README.md` for that side's gameplay and API. Don't mix the two in the same task.
