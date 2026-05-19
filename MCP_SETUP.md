# MCP Setup — Connect Claude Code Directly to Roblox Studio

## ✅ Status: INSTALLED & CONNECTED

**Active MCP server:** `boshyxd/robloxstudio-mcp` v2.6.0 (**69 tools** — verified via real MCP handshake)
**Studio plugin:** v2.6.0 (pinned to match server — newer v2.7.0 plugin replaced to avoid mismatch)

- `claude mcp list` shows: `robloxstudio: ✓ Connected`
- Studio plugin installed at `%LOCALAPPDATA%\Roblox\Plugins\RobloxStudioMCP.rbxmx`
- Project config: `.mcp.json` (shared with anyone who clones this folder)
- User config: also added to `~/.claude.json` (works outside this folder too)
- MCP server listens on `localhost:58741` (modern) and `:3002` (legacy)

---

## How It's Wired (`.mcp.json`)

The project-scoped `.mcp.json` in this folder registers the server. It was created with:

```powershell
claude mcp add robloxstudio --transport stdio --scope project -- npx -y robloxstudio-mcp@latest
```

Anyone who clones the folder picks it up automatically — no per-machine re-registration needed.

---

## What This Means

Once you reopen Studio:
- I (Claude in any future session inside this project) can directly **read your Workspace**, **edit scripts**, **run code in the Command Bar**, **read Output errors**, **take screenshots**, and **start/stop play tests**
- No more "what's in Output?" loops

## Final Step You Need To Do (one time, in Studio)

The Studio plugin needs permission to make HTTP requests (so it can talk to the MCP server). When you open Studio:

1. Open any place (your existing one, or `rivals.rbxlx` from this folder)
2. Studio will pop up: **"Plugin wants to make HTTP requests — Allow?"** → click **Allow**
3. Look for the new **MCP Plugin** button in the toolbar (it shows connection status)
4. If it says "Disconnected," click it once to connect to the MCP server

That's it. From then on, ask me anything in a Claude Code session opened inside `C:\Users\admin\rivals-multiplayer\` and I can act on Studio directly.

---

## How to Verify Connection

In a terminal:
```powershell
claude mcp list
```
You should see:
```
robloxstudio: npx -y robloxstudio-mcp@latest - ✓ Connected
```

To see which tools the MCP server exposes:
```powershell
claude mcp get robloxstudio
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `claude mcp list` says ✗ Failed | Restart Claude Code. The MCP only registers on startup. |
| Studio plugin won't connect | In Studio: **File → Game Settings → Security → Allow HTTP Requests** = on |
| Port already in use | Close any other Node processes (`taskkill /IM node.exe /F` — careful!) |
| First-run slow | `npx -y` downloads ~10MB the first time; subsequent runs are cached |
| MCP shows up but does nothing | The Studio plugin must be loaded AND connected. Click it in Studio's plugin toolbar. |

---

## How to Remove (if you change your mind)

```powershell
# Remove from Claude Code
claude mcp remove robloxstudio -s project   # removes .mcp.json entry
claude mcp remove robloxstudio -s user      # removes user-config entry

# Remove the Studio plugin
del "$env:LOCALAPPDATA\Roblox\Plugins\RobloxStudioMCP.rbxmx"
```

---

## Alternative Options (Not Used, FYI)

### Option A — Roblox Studio Built-in MCP (April 2026)
If your Studio version has it: Assistant icon → Manage MCP Servers → Quick Connect → Claude Code. Doesn't require an external plugin. Use this instead if it's available — switching is easy.

### Option B — Bidirectional Sync (weppy)
`hope1026/weppy-roblox-mcp` adds two-way file sync. Install with their bundled installer. Edit `.mcp.json` to swap the `command`/`args` for theirs.

---

## What Tools the MCP Exposes (boshyxd v2.6.0, 69 tools)

Categories:
- **Scripts** — read, write, search across the DataModel
- **Instances** — create, get/set properties, parent, delete, traverse hierarchy
- **Workspace** — inspect Parts, Models, Cameras
- **Bulk operations** — change properties on many instances at once
- **Runtime** — execute Luau in Command Bar, start/stop play test
- **Console** — read Studio Output messages
- **Screenshots** — capture viewport
- **Architecture analysis** — get full project tree, summarize structure

This is more than enough to let me debug, refactor, and extend your Rivals game without you having to copy/paste anything.
