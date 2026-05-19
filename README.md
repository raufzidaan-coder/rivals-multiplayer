# Rivals — Monorepo

This directory hosts **two independent projects** that happen to share the "Rivals" name and live alongside each other:

| | Roblox FPS Game | Express Browser Game |
|---|---|---|
| **Runtime** | Roblox Studio (Luau) | Node.js (JavaScript) |
| **Sync tool** | Rojo → `localhost:34872` | n/a |
| **Port** | Studio (no port) | `localhost:3001` |
| **Code lives in** | `src/`, `tools/`, `types/` | `server.js`, `public/`, `package.json` |
| **Run with** | `tools\rojo.exe serve` + Studio | `npm install && npm start` |

They share `node_modules/`, the workspace `.git`, and the `roblox-scripts/` legacy folder, but otherwise have no runtime overlap. Most days you'll be working on one or the other, not both.

---

## 1. Roblox FPS Game

A multiplayer FPS for Roblox, managed by **Rojo** so you can edit `.luau` files in any editor and have them sync into Roblox Studio in real time.

### One-time setup (per machine)

1. **Install the Rojo Studio plugin** — drag `tools\Rojo-Plugin.rbxm` into a running Studio window. Or copy it into Studio's plugins folder (Studio → **Plugins → Plugins Folder**, restart Studio).
2. **(Optional) Add `tools\` to your user PATH** — so bare `rojo serve` works in any terminal. The bundled binary is `tools\rojo.exe` (v7.6.1).
3. **Roblox Studio MCP plugin** — already installed at `%LOCALAPPDATA%\Roblox\Plugins\RobloxStudioMCP.rbxmx`. See `MCP_SETUP.md` if you need to reinstall or troubleshoot.
4. **One Studio toggle** — Studio → **File → Game Settings → Security → Allow HTTP Requests** must be on (required for the MCP plugin handshake).

### Daily workflow

```powershell
# In one terminal, from this directory:
.\tools\rojo.exe serve
# → "Rojo server listening on localhost:34872"
```

In Studio:
1. Open any place (or `rivals.rbxlx` from this folder).
2. Click the **Rojo** plugin button → **Connect** → accept incoming sync.
3. Edit any `.luau` file → save → Studio updates within ~1 s.

Rojo is **one-way** (disk → Studio). Studio-side changes are not written back to disk; always edit on disk.

### Build the in-game arena (first run only)

After connecting, open Studio's Command Bar (View → Command Bar, or **Ctrl+9**) and run:

```lua
local MapSystem = require(game:GetService("ReplicatedStorage"):WaitForChild("MapSystem"))
MapSystem.new():CreateArena()
```

Save the place (Ctrl+S) and the arena persists. Use `:CreateWarehouse()` or `:CreateDowntown()` for the other maps.

### Build a place file from disk (no Studio required)

```powershell
.\tools\rojo.exe build default.project.json -o rivals.rbxlx
```

`rivals.rbxlx` is gitignored — regenerate as needed.

### Project layout

```
src/
├── server/                    -> ServerScriptService
│   ├── Server.server.luau     (main server entrypoint)
│   └── LobbyPads.luau         (pad-based matchmaking)
├── client/                    -> StarterPlayer.StarterPlayerScripts
│   └── Client.client.luau     (main client entrypoint)
└── shared/                    -> ReplicatedStorage
    ├── RivalsCore.luau        (movement, combat, weapons, abilities)
    ├── MapSystem.luau         (arena / warehouse / downtown builders)
    └── Settings.luau          (keybinds, sensitivity, crosshair, UI)

tools/    rojo.exe + Rojo-Plugin.rbxm
types/    luau-lsp type stubs (globalTypes.d.luau, roblox-api-docs.json)
```

Full architecture, conventions, and the `RivalsCore` / `MapSystem` / `LobbyPads` / `Settings` API surface live in **`CLAUDE.md`**.

### Pre-applied bug fixes

Ten fixes were already applied to the source vs. the original Rivals scripts (see `CLAUDE.md` for the authoritative list). Highlights:
- `Server.server.luau` — `self:Lobby:LeaveQueue` (colon syntax) → `self.Lobby:LeaveQueue`
- `Client.client.luau` and `Server.server.luau` — `script.Parent:WaitForChild("RivalsCore")` → `ReplicatedStorage:WaitForChild("RivalsCore")`
- `LobbyPads.luau` — `Instance.new("TouchTransducer", Part)` (fake class — crash) → `Part.Touched:Connect(...)` with a Humanoid+Player check
- `Server.server.luau` — `PlayerDataManager` is now a cached singleton on the server (was being re-`.new()`-ed every callsite, leaking state)
- `Server.server.luau` — `SetupRemoteListeners` now fires once on Start instead of once per player join (was registering duplicate handlers)
- `Server.server.luau` — `PlayerRemoving` now clears `self.Players[Player]` to avoid a memory leak
- `Server.server.luau` — `KillFeed:FireAllClients` now only fires during an active match
- `MapSystem.luau` — `LoadMap` now validates the target map exists before deleting the current one
- `Client.client.luau` — removed dead-local Primary/Secondary/Melee/Utility assignments

Re-apply all of these if you ever re-paste the originals.

### Working with Claude Code

The `.claude/`, `.mcp.json`, and `CLAUDE.md` files in this directory configure Claude Code automatically. Opening a Claude Code session here gives you:
- Pre-approved tool permissions for Rojo, stylua, selene, and reads/writes under `src/`.
- A connected `robloxstudio` MCP server (so Claude can read Workspace, edit scripts, run Luau in Studio, read Output, and take screenshots without you copy-pasting).
- Access to **15 MCP servers** total when this README was last refreshed — `robloxstudio` for this project, plus 14 account-level servers (GitHub, Google Calendar, Excalidraw, PubMed, Scholar Gateway, Granted, Tango, LangChain Docs, LunarCrush, MoSPI, PDF Viewer, Google Drive, Google Compute Engine, claude-in-chrome). Verify your own count with `claude mcp list`.

See `MCP_SETUP.md` for the connection model and troubleshooting. After restarting Claude Code from this directory, tick through `TEST_PLAN.md` to confirm every capability (Rojo sync, all 69 MCP tools of `robloxstudio`, Express side, etc.) is working.

---

## 2. Rivals Multiplayer — Express Browser Game

A fast-paced multiplayer browser game built with **Express** and **Socket.io**. Real-time combat, room-based matchmaking, a weapon system, basic user progression.

### Tech stack
- **Backend:** Node.js + Express.js
- **Real-time:** Socket.io
- **Frontend:** HTML5 Canvas + vanilla JS
- **Storage:** `users.json` (file-based)

### Run it

```powershell
npm install
npm start
```

Then open `http://localhost:3001`.

### Gameplay
1. Create an account (username + password).
2. Join or create a room (up to 10 players per room).
3. Pick primary and secondary weapons.
4. Battle. Earn XP, level up.

### Weapon system
Assault Rifle, Shotgun, Sniper, SMG, Handgun, Exogun, plus melee (Fists, Knife). Each has distinct damage, fire rate, ammo, projectile speed.

### Socket.io events

**Client → Server:** `register`, `login`, `join_room`, `player_move`, `shoot`, `select_weapon`
**Server → Client:** `player_joined`, `player_moved`, `hit`, `room_state`, `game_over`

### Layout (Express side only)

```
server.js              Express server + Socket.io handlers
package.json           npm scripts and deps (express, socket.io)
public/index.html      HTML5 canvas client
users.json             user account store
docs/                  hero image + landing page
roblox-scripts/        loose .lua files from an earlier experiment (not used)
```

### Future work (Express)
- Database (Mongo / Postgres) replacing `users.json`
- Persistent profiles + ranked matchmaking
- Spectator mode, clan/team system, anti-cheat

---

## Repository conventions

- **`.gitignore`** covers both Node (`node_modules/`, `.env`) and Rojo (`*.rbxl`, `*.rbxlx`, `*.rbxm` except `tools/*.rbxm`, `sourcemap.json`).
- **VS Code tasks** (`.vscode/tasks.json`) — `Rojo: Serve (live sync)`, `Rojo: Build place`, `Rojo: Sourcemap (regenerate)`.
- **Formatting / linting** — `stylua.toml` (4 spaces, double quotes, 120 col) and `selene.toml` (`std = "roblox"`).
- **luau-lsp** is pre-configured via `.vscode/settings.json` to consume `types/globalTypes.d.luau` and the regenerable `sourcemap.json`.

## Author

Created by **raufzidaan-coder**.

## License

MIT.
