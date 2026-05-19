# Claude Code — Functionality Test Plan

Run these checks the first time you restart Claude Code from `C:\Users\admin\rivals-multiplayer\`. They cover the full surface of what this working directory should let you do: Rojo sync, Roblox Studio orchestration via MCP, source-code work on the FPS game, the Express browser game, Claude Code's own tools, and the other MCP servers connected to your account.

Each check is structured as **`[ ] Title — what to type / ask — what should happen`**. Tick them off as you go.

> **Convention:** "Ask Claude" means type the request in the Claude Code prompt. "Type" means run it in a terminal yourself.

---

## A. Session bootstrap

These confirm Claude Code launched correctly with the project context loaded.

- `[ ]` **Working directory** — Type `pwd` (or check the status line). Expect `C:\Users\admin\rivals-multiplayer`.
- `[ ]` **Empty husk cleared** — Type `Get-ChildItem C:\Users\admin\rivals-project -Force -ErrorAction SilentlyContinue | Measure-Object`. Expect `Count = 0` (the directory may or may not still exist depending on whether the prior session's bash shells released it — what matters is that it's empty).
- `[ ]` **CLAUDE.md loaded** — Ask Claude: *"What's in this project?"*. Expect a summary that mentions BOTH the Roblox FPS game and the Express browser game. If it only mentions one, CLAUDE.md didn't load.
- `[ ]` **MCP server health** — Type `claude mcp list`. Expect `robloxstudio: npx -y robloxstudio-mcp@latest - ✓ Connected`. Other servers (GitHub, etc.) may also appear.
- `[ ]` **Pre-approved permissions** — Ask Claude to run `tools\rojo.exe --version`. It should run **without** prompting for permission (the `.claude/settings.json` allowlist covers it).

---

## B. Rojo sync orchestration

- `[ ]` **Version** — Type `tools\rojo.exe --version`. Expect `Rojo 7.6.1`.
- `[ ]` **Project parses** — Ask Claude: *"Validate `default.project.json`."* Expect confirmation that the three `$path` entries (`src/shared`, `src/server`, `src/client`) all resolve.
- `[ ]` **Sourcemap regen** — Type `tools\rojo.exe sourcemap default.project.json --include-non-scripts --output sourcemap.json`. Expect `sourcemap.json` to be created/updated.
- `[ ]` **Place file build** — Type `tools\rojo.exe build default.project.json -o rivals.rbxlx`. Expect `Built project to rivals.rbxlx` and an ~88 KB file.
- `[ ]` **Serve (live sync)** — Type `tools\rojo.exe serve` in a dedicated terminal (or use VS Code task **Rojo: Serve (live sync)**). Expect `Rojo server listening on localhost:34872`.
- `[ ]` **Port listening** — In another terminal: `Get-NetTCPConnection -State Listen -LocalPort 34872`. Expect one entry.
- `[ ]` **Studio handshake** — In Studio, open the Rojo plugin → **Connect** → accept. Edit `src/shared/RivalsCore.luau` (add a `print("test")` near the top), save. Expect the change to appear in Studio's script editor within ~1 second.
- `[ ]` **One-way sync confirmation** — Change a script in Studio's editor. Confirm the change does NOT propagate back to disk (Rojo is one-way).

---

## C. Roblox Studio orchestration via MCP (boshyxd v2.6.0, 69 tools)

This is the headline capability. Studio must be open AND have the MCP plugin connected (toolbar button shows green/connected). Each test asks Claude to perform an action — the MCP tool is loaded on demand via `ToolSearch`.

### C.1 Inspect the running place

- `[ ]` **Place info** — Ask Claude: *"What place is open in Studio?"*. Expects MCP `get_place_info` → returns place name, gameId, jobId.
- `[ ]` **Service inventory** — Ask: *"List the services and their child counts."* Expects `get_services` → shows Workspace, ReplicatedStorage, ServerScriptService, StarterPlayer, etc.
- `[ ]` **DataModel tree** — Ask: *"Show me the project structure."* Expects `get_project_structure`.
- `[ ]` **Drill into ReplicatedStorage** — Ask: *"What modules are in ReplicatedStorage?"*. Expects `get_instance_children` → returns `MapSystem`, `RivalsCore`, `Settings`.
- `[ ]` **Read a script** — Ask: *"Show me lines 440–470 of RivalsCore."* Expects `get_script_source` with `startLine`/`endLine`.
- `[ ]` **Instance properties** — Ask: *"What are the properties of `game.Workspace.Terrain`?"* Expects `get_instance_properties`.
- `[ ]` **Class info** — Ask: *"What properties and events does the `Humanoid` class expose?"* Expects `get_class_info`.
- `[ ]` **All descendants** — Ask: *"List every descendant of `game.Workspace`."* Expects `get_descendants`.
- `[ ]` **Connected instances** — In Studio, select a Part with a `Weld` to another Part. Ask: *"What's physically connected to my selection?"* Expects `get_connected_instances`.
- `[ ]` **Compare two instances** — *Prerequisite:* run the **Create a part** and **Clone** items in C.2 first so there are two related Parts in Workspace. Then ask: *"Compare `TestProbe` and its clone, listing property differences."* Expects `compare_instances`.
- `[ ]` **Tags (list all)** — Ask: *"List CollectionService tags in the place."* Expects `get_tags`.

### C.2 Create / modify / delete instances

- `[ ]` **Create a part** — Ask: *"Make a 4×4×4 neon green anchored Part at (0, 100, 0) in Workspace called `TestProbe`."* Expects `create_object`.
- `[ ]` **Set property** — Ask: *"Change `TestProbe`'s material to Glass and transparency to 0.5."* Expects `set_property` (twice) or `set_properties`.
- `[ ]` **Clone** — Ask: *"Clone `TestProbe` and move the copy 10 studs along X."* Expects `clone_object` + `move_object`.
- `[ ]` **Rename** — Ask: *"Rename `TestProbe` to `TestProbe_Renamed`."* Expects `rename_object`.
- `[ ]` **Smart duplicate** — Ask: *"Use the `smart_duplicate` MCP tool to make 5 copies of `TestProbe_Renamed`, each offset +6 studs on Z from the previous."* Expects `smart_duplicate` (auto-handles offset and naming).
- `[ ]` **Mass duplicate** — Ask: *"Make 20 copies of `TestProbe_Renamed` in a 4×5 grid."* Expects `mass_duplicate`.
- `[ ]` **Mass create** — Ask: *"Create 10 anchored cubes at Y=200 in a row."* Expects `mass_create_objects`.
- `[ ]` **Bulk set property** — Ask: *"For every Part in Workspace, set Transparency to 0."* Expects `mass_set_property` (or `mass_get_property` first).
- `[ ]` **Delete (keep originals)** — Ask: *"Delete the smart-duplicate and mass-create children, but leave `TestProbe` and `TestProbe_Renamed` for the C.11 attribute/tag tests."* Expects `search_objects` + `delete_object`.

### C.3 Script editing (no copy-paste)

- `[ ]` **Edit a single script** — Ask: *"In `MapSystem`, find the `CreateArena` function and add a `print('arena built')` at the very end."* Expects `find_and_replace_in_scripts` or `edit_script_lines`.
- `[ ]` **Insert lines** — Ask: *"Insert a 10-line debug comment at the top of `Client.client.luau`."* Expects `insert_script_lines`.
- `[ ]` **Delete lines** — Ask: *"Remove that debug comment from `Client`."* Expects `delete_script_lines`.
- `[ ]` **Source replace** — Ask: *"Replace `Client.client.luau` with a known-good stub."* Expects `set_script_source`.
- `[ ]` **Full-script analysis** — Ask: *"Analyze `RivalsCore.luau` and tell me about the major systems."* Expects `get_script_analysis`.

### C.4 Runtime — execute Luau, read Output, run playtests

- `[ ]` **Execute Luau** — Ask: *"In Studio's Command Bar, require `MapSystem` and call `:CreateArena()`."* Expects `execute_luau`. The arena should appear in the viewport.
- `[ ]` **Read Output log** — Ask: *"What's in the Output panel right now?"*. Expects `get_output_log`.
- `[ ]` **Start a playtest** — Ask: *"Start a Play Solo session."* Expects `start_playtest`.
- `[ ]` **Read playtest output** — During the playtest: *"What's printing in playtest output?"*. Expects `get_playtest_output`.
- `[ ]` **Character navigation** — During playtest: *"Move my character forward 20 studs."* Expects `character_navigation`.
- `[ ]` **Stop playtest** — *"Stop the playtest."* Expects `stop_playtest`.

### C.5 Search & navigate

- `[ ]` **Find by property** — Ask: *"Find every BasePart in Workspace whose Material is `Neon`."* Expects `search_by_property`.
- `[ ]` **Find by name/class** — Ask: *"List every ModuleScript anywhere under `game`."* Expects `search_objects`.
- `[ ]` **Grep all scripts** — Ask: *"Find every reference to `MovementSystem` across the project."* Expects `grep_scripts` to span ReplicatedStorage and StarterPlayer scripts.
- `[ ]` **File-name search** — Ask: *"Use the `search_files` MCP tool to find every instance in the DataModel whose Name contains `Lobby`."* Expects `search_files` (it indexes by Name, not script content — `grep_scripts` is what you'd use for content search).
- `[ ]` **Material search** — Ask: *"What Roblox materials look like wood?"*. Expects `search_materials`.
- `[ ]` **Asset search** — Ask: *"Find free Roblox assault rifle assets."* Expects `search_assets`.

### C.6 Assets & library

> **Note:** `123456789` is a **placeholder asset ID** — it will not resolve to a real asset. Substitute any real free-to-use asset ID from the Roblox Creator Store (e.g. find one via the **Asset search** test below, or pick one you've previously favorited). The four asset-by-ID tests below all use the same ID, so swap once.

- `[ ]` **Insert asset by ID** — Ask: *"Insert asset 123456789 into Workspace."* Expects `insert_asset`.
- `[ ]` **Asset detail** — Ask: *"Show me details for asset 123456789."* Expects `get_asset_details`.
- `[ ]` **Asset thumbnail** — Ask: *"Show the thumbnail for asset 123456789."* Expects `get_asset_thumbnail`.
- `[ ]` **Preview asset** — Ask: *"Use `preview_asset` to render asset 123456789's hierarchy without inserting it."* Expects `preview_asset` (this differs from `get_asset_thumbnail`, which only returns the image).
- `[ ]` **List library** — Ask: *"Show what's currently in the Asset Library / Toolbox."* Expects `list_library`.
- `[ ]` **Upload decal** — Ask: *"Upload `docs/hero.png` as a decal called `RivalsHero`."* Expects `upload_decal`. (Requires Roblox creator credentials configured in Studio.)

### C.7 Builds / scenes (snapshot & restore)

- `[ ]` **Create build snapshot** — Ask: *"Save the current Workspace as a build called `pre-arena`."* Expects `create_build`.
- `[ ]` **List builds** — Ask: *"List saved builds."* Expects `get_file_tree` or `get_build`.
- `[ ]` **Export build** — Ask: *"Export the `pre-arena` build to disk."* Expects `export_build`.
- `[ ]` **Import build** — Ask: *"Re-import the `pre-arena` build into the current place."* Expects `import_build`.
- `[ ]` **Generate build** — Ask: *"Generate a minimal lobby scene as a build."* Expects `generate_build` (procedural).
- `[ ]` **Import scene** — Ask: *"Import `rivals.rbxlx` as a scene."* Expects `import_scene`.

### C.8 Selection, undo/redo, UI

- `[ ]` **Read selection** — In Studio, select a Part. Ask Claude: *"What's selected in Studio?"*. Expects `get_selection`.
- `[ ]` **Build UI tree** — Ask: *"Build a basic UI in StarterGui with a ScreenGui containing a centered Frame."* Expects `create_ui_tree`.
- `[ ]` **Undo** — Ask: *"Undo the last 3 Studio operations."* Expects `undo` ×3.
- `[ ]` **Redo** — Ask: *"Redo those 3 operations."* Expects `redo` ×3.

### C.9 Input simulation

- `[ ]` **Mouse click** — During a playtest, ask: *"Click at viewport (500, 400)."* Expects `simulate_mouse_input`.
- `[ ]` **Keyboard press** — During playtest: *"Press W for 2 seconds."* Expects `simulate_keyboard_input`.

### C.10 Screenshots

- `[ ]` **Capture viewport** — Ask: *"Take a screenshot of the Studio viewport."* Expects `capture_screenshot`. The image renders inline.

### C.11 Attributes & CollectionService tags

Per-instance metadata that doesn't show up in standard properties.

- `[ ]` **Set attribute** — On `TestProbe` (re-create it if you deleted it), ask: *"Set attribute `Spawned` = true."* Expects `set_attribute`.
- `[ ]` **Get attribute** — Ask: *"What's `TestProbe.Spawned`?"* Expects `get_attribute` → `true`.
- `[ ]` **Get all attributes** — Ask: *"List every attribute on `TestProbe`."* Expects `get_attributes`.
- `[ ]` **Delete attribute** — Ask: *"Remove the `Spawned` attribute from `TestProbe`."* Expects `delete_attribute`.
- `[ ]` **Bulk set attributes** — Ask: *"On every Part in Workspace, set attribute `Reviewed` = true and `Owner` = 'rivals'."* Expects `bulk_set_attributes`.
- `[ ]` **Add tag** — Ask: *"Tag `TestProbe` with `Probe`."* Expects `add_tag`.
- `[ ]` **Get tagged** — Ask: *"List every instance with the `Probe` tag."* Expects `get_tagged`.
- `[ ]` **Remove tag** — Ask: *"Untag `TestProbe` from `Probe`."* Expects `remove_tag`.

### C.12 Sanity smoke test (the always-pass)

A quick one-liner to confirm the whole MCP path is alive:
- `[ ]` Ask: *"Run `print('MCP alive')` in Studio."* Expects output `MCP alive` returned to Claude via `execute_luau` + `get_output_log`.

---

## D. Source-code editing (no Studio needed)

These exercise Claude Code's own file tools on the Roblox source.

- `[ ]` **Read** — Ask: *"Show me lines 1–50 of `src/shared/RivalsCore.luau`."* Uses `Read`.
- `[ ]` **Search** — Ask: *"Find every `task.delay(` call in `src/`."* Uses `Grep`. Expect 7 matches across `RivalsCore.luau` and `Server.server.luau`.
- `[ ]` **Glob** — Ask: *"List every `.luau` file in `src/`."* Uses `Glob`.
- `[ ]` **Targeted edit** — Ask: *"In `src/shared/Settings.luau`, change the default mouse sensitivity to 0.5."* Uses `Edit`.
- `[ ]` **Format** — Ask: *"Run stylua on `src/`."* Should run via the pre-approved `Bash(stylua:*)` permission.
- `[ ]` **Lint** — Ask: *"Run selene on `src/`."* Should run via pre-approved `Bash(selene:*)`.

---

## E. Express browser game side

The Roblox MCP is irrelevant here — this is just Node.

- `[ ]` **Deps installed** — Type `npm ls express socket.io`. Expect both present.
- `[ ]` **Start server** — Type `npm start`. Expect `RIVALS Server running on port 3001` (`server.js` defaults to `process.env.PORT || 3001`).
- `[ ]` **HTTP probe** — Type `curl http://localhost:3001`. Expect HTML from `public/index.html`. (The server binds to `process.env.PORT || 3001` per `server.js`.)
- `[ ]` **Open in browser** — Ask Claude: *"Open `http://localhost:3001` in Chrome and screenshot it."* Uses `claude-in-chrome` MCP (see section H).
- `[ ]` **Stop server** — `Ctrl+C` in the npm terminal, or `Get-Process node | Stop-Process`.

---

## F. Claude Code core capabilities

Stuff that's available in every session, not specific to this project.

- `[ ]` **Subagents (parallel)** — Ask: *"Spin up 3 Explore agents to audit `src/shared/`, `src/server/`, and `src/client/` in parallel."* Confirm 3 agents run concurrently.
- `[ ]` **Task tracking** — Ask: *"Use TaskCreate to plan a refactor of `LobbyPads` into 4 steps."* Confirm tasks appear and you can `TaskList`/`TaskUpdate`.
- `[ ]` **Plan mode** — Press `Shift+Tab` to enter plan mode; ask for a refactor plan. Confirm Claude proposes a plan without editing.
- `[ ]` **Background commands** — Ask: *"Run `tools\rojo.exe serve` in the background."* Confirm output streams to the background task file.
- `[ ]` **WebFetch** — Ask: *"Fetch the Rojo README from `https://github.com/rojo-rbx/rojo`."* Confirm content is returned.
- `[ ]` **WebSearch** — Ask: *"Search for recent Luau type-system changes."* Confirm results.
- `[ ]` **ScheduleWakeup / loop** — Ask: *"Loop /status every 10 minutes for the next hour."* (Optional — long-running.)

---

## G. Skills

Skills are reusable workflows. They appear when you type `/` or are triggered automatically.

- `[ ]` **`/init`** — In a different folder (NOT this one — it has CLAUDE.md already), run `/init`. Confirm Claude generates a fresh CLAUDE.md from the codebase.
- `[ ]` **`/review`** — Make a small change to `src/`, ask `/review`. Confirm Claude critiques the diff.
- `[ ]` **`/security-review`** — Ask `/security-review` on a branch. Confirm Claude inspects for vulns.
- `[ ]` **`/simplify`** — After making at least one `Edit` in `src/` (e.g., the sensitivity change from Section D), ask `/simplify` to look for cleanup opportunities. Skip if no uncommitted changes exist — the skill needs a diff to review.
- `[ ]` **`/fewer-permission-prompts`** — Run it; confirm it scans transcripts and proposes additions to `.claude/settings.json`.
- `[ ]` **`/update-config`** — Ask: *"Use `/update-config` to add an allowlist entry for `tools\selene.exe`."* Confirm the settings file updates.
- `[ ]` **`/claude-api`** — Only relevant if you're writing code that imports `anthropic` SDK; skip otherwise.

---

## H. Other connected MCP servers

These are tied to your Claude account, not the project. Each should be reachable from this session.

- `[ ]` **claude-in-chrome (browser automation)** — Ask: *"Open `http://localhost:3001` in a new Chrome tab and read the page text."* Confirms tabs_create + navigate + read_page work.
- `[ ]` **claude-in-chrome (screenshot)** — Ask: *"Screenshot the same tab."* Confirms screenshot tools.
- `[ ]` **GitHub** — Ask: *"List my open pull requests on `raufzidaan-coder/rivals-multiplayer`."* Confirms `mcp__…__list_pull_requests` works.
- `[ ]` **Google Calendar** — Ask: *"What's on my calendar today?"* Confirms list_events.
- `[ ]` **Excalidraw** — Ask: *"Sketch the lobby-pad system as a flowchart."* Confirms create_view + export_to_excalidraw.
- `[ ]` **PubMed / Scholar / LangChain Docs** — Only relevant if you're researching; smoke-test one.
- `[ ]` **Failing MCP servers** — Run `claude mcp list`. Some servers (`ChEMBL`, `bioRxiv`, `Clinical Trials`, `Candid`) were failing/unauthenticated at last check; confirm whether they recovered. Authenticate Candid via `mcp__claude_ai_Candid__authenticate` if you need it.

---

## I. Configuration sanity

- `[ ]` **`.mcp.json`** — Confirm `mcpServers.robloxstudio` entry exists.
- `[ ]` **`.claude/settings.json`** — Confirm `enabledMcpjsonServers: ["robloxstudio"]` and `enableAllProjectMcpServers: false`.
- `[ ]` **Permissions** — Confirm `permissions.allow` includes `Bash(tools/rojo.exe:*)`, `Bash(rojo:*)`, `Bash(selene:*)`, `Bash(stylua:*)`, `Read(src/**)`, `Read(types/**)`, `Edit(src/**)`, `Write(src/**)`.
- `[ ]` **`.vscode/tasks.json`** — Confirm Rojo: Serve, Build, Sourcemap tasks all visible.
- `[ ]` **`.vscode/settings.json`** — Confirm `luau-lsp.types.definitionFiles` references `types/globalTypes.d.luau`.
- `[ ]` **Argon parked** — `Get-NetTCPConnection -State Listen -LocalPort 8000 -ErrorAction SilentlyContinue`. Expect no output (Argon CLI exists at `~/.argon/bin/argon.exe` but should not be serving — project file is Rojo-format and Argon rejects it).
- `[ ]` **Git status** — `git status` (from this dir). Expect a clean tree or a known set of changes; not a `fatal: not a git repository` error.
- `[ ]` **Git remote sanity** — `git remote -v`. Expect `origin` to point at the GitHub repo (e.g. `raufzidaan-coder/rivals-multiplayer.git`).
- `[ ]` **Rojo ignores loose scripts** — Build the sourcemap (`tools\rojo.exe sourcemap default.project.json --output sourcemap.json`) and confirm `sourcemap.json` does NOT mention `roblox-scripts/` — those 7 loose `.lua` files are intentionally not part of the Rojo project.
- `[ ]` **Bash tool reachable** — Ask Claude: *"Use the Bash tool to run `pwd`."* Expect `/c/Users/admin/rivals-multiplayer`. (Confirms Bash is wired up alongside PowerShell.)
- `[ ]` **Formatter config present** — `Test-Path stylua.toml; Test-Path selene.toml`. Both `True`.

---

## J. End-to-end scenarios

These combine multiple capabilities and are the real test of whether the setup is usable.

### J.1 "Pretend I'm onboarding a teammate to the Roblox project"

- `[ ]` Ask Claude: *"Walk me through what this project does and how to start contributing."*
- Expect: a tour of CLAUDE.md content — One-Time Setup, Daily Workflow, file layout, Pre-Applied Bug Fixes.

### J.2 "Fix a bug end-to-end without leaving Claude Code"

- `[ ]` Pick a real or fake bug ("the lobby's matchmaking pads are spaced too closely — bump spacing from 15 to 25 studs").
- `[ ]` Ask: *"Find the relevant code, propose a fix, apply it, rebuild the place, and confirm the change is live in Studio."*
- Expect Claude to: `grep_scripts` for `CreatePad` in `LobbyPads` → `Read` the file → `Edit` the X coordinates → `tools\rojo.exe build` → `execute_luau` to verify, or use the live Rojo sync.

### J.3 "Add a new weapon"

- `[ ]` Ask: *"Add a new weapon called 'Railgun' with high damage, slow fire rate, and energy-effect projectile. Wire it into `WeaponSystem` in `RivalsCore` and the Settings menu."*
- Expect Claude to: explore `RivalsCore` for weapon definitions, propose schema, add code, verify with `execute_luau`.

### J.4 "Build the arena, screenshot it, and post to a GitHub issue"

- `[ ]` Ask: *"Build the arena in Studio, take a screenshot from above, and post the screenshot as a comment on the latest GitHub issue on this repo."*
- Expect: MCP `execute_luau` (build arena) → `capture_screenshot` → GitHub `add_issue_comment`. Tests three MCPs chained.

### J.5 "Restart everything cleanly"

- `[ ]` Ask: *"Stop Rojo, free the port, restart it, reconnect Studio."*
- Expect Claude to find PID, `Stop-Process`, `Bash` start Rojo background, verify with `Get-NetTCPConnection`.

---

## K. Known limitations / non-goals

For honesty, these are NOT expected to work — don't burn time testing them:

- **Two-way Rojo sync** — Rojo is one-way. Argon would do two-way; it's installed but disabled (project-file incompatibility).
- **`execute_luau` returning a Lua table directly** — table return values come back as opaque pointers. Use `print()` for structured output.
- **MCP plugin without Studio HTTP allowed** — Studio → File → Game Settings → Security → **Allow HTTP Requests** must stay on.
- **Editing `node_modules/`** — gitignored and rebuilt by `npm install`; never edit by hand.
- **Touching the empty `C:\Users\admin\rivals-project` husk** — it should be gone after restart; if it's still there, leave it.

---

## Triage if something fails

| Failing area | First thing to check |
|---|---|
| MCP says ✗ Connected | Restart Claude Code; the MCP only registers on startup |
| Studio plugin shows "Disconnected" | Studio → File → Game Settings → Security → Allow HTTP Requests = on; click MCP toolbar button |
| Rojo port 34872 busy | `Get-Process rojo \| Stop-Process`; restart |
| Permission prompt for something obviously safe | Edit `.claude/settings.json` (the `/update-config` skill helps) |
| `npm start` errors | `npm install` first; check `package.json` deps |
| Express port 3001 busy | `Get-NetTCPConnection -LocalPort 3001` → find PID → stop |
| `npx -y robloxstudio-mcp@latest` download fails | Network issue; check proxy / `npm cache clean --force` then retry `claude mcp list` |
| Studio crashes mid-playtest | Re-open Studio; reload the Rojo plugin (the MCP plugin auto-reconnects on next handshake) |
| `stylua` or `selene` not found | Install: `cargo install stylua` / `cargo install selene`, or use the VS Code extensions |
| `.claude/settings.json` parse error | Validate JSON; if recently edited, revert and re-apply via `/update-config` |

If a check fails and isn't in this triage table, capture: the exact command, the exact error, and `claude mcp list` output, then ask Claude to debug.

---

## L. Failure & recovery scenarios

The triage table above is reactive. This section is proactive: deliberately break each part of the stack, confirm the failure mode matches expectations, then verify the recovery path. Run these after any change to the tooling pipeline.

- `[ ]` **Rojo serve killed mid-edit** — Setup/Trigger: Start `tools\rojo.exe serve`, connect Studio, then `Get-Process rojo | Stop-Process` while editing `src/shared/RivalsCore.luau`. — Expected failure: Studio's Rojo plugin shows "Disconnected"; subsequent saves don't propagate; Studio script editor displays stale content. — Recovery: Restart `tools\rojo.exe serve`, in Studio click the Rojo plugin → **Connect** → accept.
- `[ ]` **MCP server process killed** — Setup/Trigger: Find the `npx robloxstudio-mcp` node PID via `Get-Process node`, `Stop-Process` it. — Expected failure: `claude mcp list` shows `robloxstudio: ... ✗ Failed to connect`; every MCP tool call errors. — Recovery: Restart Claude Code entirely (MCP servers only register on startup); re-verify with `claude mcp list`.
- `[ ]` **Studio crashes during playtest** — Setup/Trigger: Start a playtest with `TestProbe` in Workspace, then force-kill `RobloxStudioBeta.exe` via Task Manager. — Expected failure: Orphan `TestProbe` may persist in the unsaved place; MCP plugin connection drops. — Recovery: Re-open Studio, open the same place, the MCP plugin auto-reconnects on next handshake; delete orphaned `TestProbe` via `delete_object`.
- `[ ]` **HTTP Requests disabled in Studio** — Setup/Trigger: Studio → File → Game Settings → Security → toggle **Allow HTTP Requests** OFF mid-session. — Expected failure: MCP plugin loses its outbound channel; subsequent MCP tool calls time out or fail with HTTP errors. — Recovery: Re-enable **Allow HTTP Requests**, click the MCP toolbar button to re-handshake.
- `[ ]` **Rojo port 34872 occupied** — Setup/Trigger: Leave a stale `rojo serve` running, try to start a second one in another terminal. — Expected failure: New serve aborts with "address already in use" on `localhost:34872`. — Recovery: `Get-Process rojo | Stop-Process`, then re-run `tools\rojo.exe serve`; confirm with `Get-NetTCPConnection -State Listen -LocalPort 34872`.
- `[ ]` **MCP port 58741 occupied** — Setup/Trigger: Run `node -e "require('net').createServer().listen(58741)"` to squat the port, then restart Claude Code. — Expected failure: MCP server fails to bind; `claude mcp list` shows `✗`. — Recovery: Find the squatter (`Get-NetTCPConnection -LocalPort 58741`), kill it (`Stop-Process -Id <PID>`), restart Claude Code.
- `[ ]` **`npx -y robloxstudio-mcp` network failure** — Setup/Trigger: Disable network (or block npm registry via hosts file), restart Claude Code. — Expected failure: `npx` download fails; MCP unreachable; `claude mcp list` shows `✗`. — Recovery: Restore network, `npm cache clean --force`, retry `claude mcp list`; if still failing, manually `npx -y robloxstudio-mcp@latest` once to warm the cache.
- `[ ]` **Invalid edit breaks `RivalsCore` requires** — Setup/Trigger: Introduce a syntax error near the top of `src/shared/RivalsCore.luau` (e.g., unclosed string), save. — Expected failure: After Rojo sync, every `require(ReplicatedStorage.RivalsCore)` callsite errors with "module experienced an error while loading"; Server.server and Client.client both fail to initialize. — Recovery: Use `grep_scripts` for `require.*RivalsCore` to confirm scope, fix the syntax in the file on disk, save, let Rojo re-sync.
- `[ ]` **LobbySpawn part deleted** — Setup/Trigger: In Studio, delete the `LobbySpawn` Part (or any active SpawnLocation), start a playtest. — Expected failure: Players spawn at world origin / fall through map; no lobby pads reachable. — Recovery: Use `execute_luau` to re-create: `Instance.new("SpawnLocation", workspace)` anchored at the expected position; or import the `pre-arena` build snapshot from C.7.
- `[ ]` **Server.server.luau syntax error** — Setup/Trigger: Add `end end end` at the bottom of `src/server/Server.server.luau`, save, start a playtest. — Expected failure: Server script doesn't run; no Lobby, no matchmaking; clients connect but nothing initializes. — Recovery: `get_output_log` → grep for the parse error line number → fix the source file → save (Rojo re-syncs) → restart playtest.
- `[ ]` **MCP plugin file corrupted** — Setup/Trigger: Truncate `%LOCALAPPDATA%\Roblox\Plugins\RobloxStudioMCP.rbxmx` to 0 bytes, restart Studio. — Expected failure: MCP toolbar button missing; no plugin loads; MCP tool calls fail with no Studio-side responder. — Recovery: Reinstall the plugin file (re-download `RobloxStudioMCP.rbxmx` v2.6.0 to `%LOCALAPPDATA%\Roblox\Plugins\`), restart Studio, re-handshake.
- `[ ]` **API Services disabled mid-session** — Setup/Trigger: Studio → Game Settings → Security → toggle **Enable Studio Access to API Services** OFF, then trigger a `DataStoreService` call (e.g., `PlayerDataManager` save). — Expected failure: DataStore calls throw `403: Studio access to APIs is not allowed`; player persistence breaks. — Recovery: Re-enable API Services in Game Settings, restart the playtest to re-init `PlayerDataManager`.
- `[ ]` **Concurrent edits race on same script** — Setup/Trigger: Ask Claude to run two `edit_script_lines` operations on overlapping line ranges in `Settings.luau` in quick succession (or run two tool invocations from parallel agents). — Expected failure: Second edit lands against shifted line numbers; result is corrupted source — duplicated blocks, missing braces, or out-of-order code. — Recovery: Revert via Studio Undo or `set_script_source` with a known-good copy from disk; going forward, prefer `set_script_source` (whole-file atomic) over interleaved `edit_script_lines`/`insert_script_lines` when multiple changes are needed.
- `[ ]` **Sourcemap stale after rename** — Setup/Trigger: Rename `src/shared/Settings.luau` → `src/shared/SettingsV2.luau` without regenerating sourcemap. — Expected failure: Luau LSP shows "unknown module" red squiggles; `require` paths still pointing at old name fail at runtime. — Recovery: Re-run `tools\rojo.exe sourcemap default.project.json --include-non-scripts --output sourcemap.json`; update every `WaitForChild("Settings")` callsite.
- `[ ]` **`.claude/settings.json` JSON corrupted** — Setup/Trigger: Insert a trailing comma into `.claude/settings.json`, restart Claude Code. — Expected failure: Permissions allowlist fails to load; every `tools\rojo.exe` call prompts for permission again. — Recovery: Validate JSON (`Get-Content .claude\settings.json | ConvertFrom-Json`), fix the parse error, restart Claude Code; or revert via `git checkout .claude/settings.json`.

---

## M. Rojo edge-case sync tests

Extends section B. Run after the basic sync flow is healthy.

- `[ ]` **Nested folder + `init.luau`** — Create `src/shared/SubModule/init.luau` returning `{ ok = true }` plus a sibling `src/shared/SubModule/Helper.luau`. — Expects: `ReplicatedStorage.SubModule` shows as a **ModuleScript** (not Folder), `require(...SubModule).ok == true`, `Helper` appears as a child of `SubModule`.
- `[ ]` **Mid-serve rename propagation** — While Rojo is serving, rename `src/shared/Settings.luau` → `src/shared/SettingsRenamed.luau`. — Expects: `ReplicatedStorage.Settings` disappears within ~1s, `SettingsRenamed` appears with identical source. Revert after testing.
- `[ ]` **Mid-serve delete propagation** — Create `src/shared/Scratch.luau`, wait for it to appear, then delete it on disk. — Expects: instance appears then vanishes from `ReplicatedStorage` within ~1s. No orphan.
- `[ ]` **New plain `.luau` → ModuleScript** — Add `src/shared/Probe.luau` returning `42`. — Expects: `Probe` appears as ModuleScript; `require(...Probe) == 42`.
- `[ ]` **New `.server.luau` → Script** — Add `src/server/ProbeServer.server.luau` with `print('PS')`. — Expects: `ServerScriptService.ProbeServer` is a Script and prints on next playtest.
- `[ ]` **New `.client.luau` → LocalScript** — Add `src/client/ProbeClient.client.luau` with `print('PC')`. — Expects: `StarterPlayer.StarterPlayerScripts.ProbeClient` is a LocalScript.
- `[ ]` **Misplaced `.client.luau` in shared (foot-gun)** — Drop `src/shared/Stray.client.luau` and rebuild. — Expects: Rojo creates a `LocalScript` under `ReplicatedStorage.Stray`, but Roblox will never run it there. Document the foot-gun, then remove.
- `[ ]` **`.gitignore` vs Rojo glob** — Add `src/shared/Ignored.luau`, list it in `.gitignore`, run `tools\rojo.exe sourcemap default.project.json --output sourcemap.json`. — Expects: file IS included (Rojo does NOT respect `.gitignore` — uses its own `globIgnorePaths`).
- `[ ]` **`rojo build --watch`** — Run `tools\rojo.exe build default.project.json -o rivals.rbxlx --watch`, edit `src/shared/RivalsCore.luau`. — Expects: `rivals.rbxlx` mtime updates within ~1s of each save.
- `[ ]` **`rojo sourcemap --watch`** — Run `tools\rojo.exe sourcemap default.project.json --include-non-scripts --output sourcemap.json --watch`, add/remove a file. — Expects: `sourcemap.json` regenerates on every change.
- `[ ]` **`rojo plugin install` overwrites Studio plugin** — Back up `tools/Rojo-Plugin.rbxm`, run `tools\rojo.exe plugin install`. — Expects: Fresh `Rojo.rbxm` written to `%LOCALAPPDATA%\Roblox\Plugins\`. Does NOT touch `tools/Rojo-Plugin.rbxm` on disk.
- `[ ]` **Name-collision build error** — Add `src/shared/Settings/init.luau` while `src/shared/Settings.luau` still exists. Run `tools\rojo.exe build default.project.json -o conflict.rbxlx`. — Expects: build either fails with a collision error citing both sources OR silently picks the folder over the sibling .luau (Rojo 7.6.1 currently does the latter — flag this as undocumented behavior). Remove the folder to recover.
- `[ ]` **`rojo upload --asset-id` exists** — Run `tools\rojo.exe upload default.project.json --asset-id 0 --cookie_from_environment` (no valid cookie). — Expects: command exists, fails with auth/asset error (not "unknown subcommand").
- `[ ]` **Argon rejects this project** — Run `~/.argon/bin/argon.exe serve default.project.json`. — Expects: Argon errors because it requires its own schema. Confirms why the project stays Rojo-only.

---

## N. Express server deep tests

Extends section E with the actual Socket.io flows (`server.js` is a 922-line Socket.io game server, **not** a REST API — no `app.get/post` other than static serving).

- `[ ]` **Clean `npm install`** — Delete `node_modules`, run `npm install`. — Expects: completes without errors, `express` and `socket.io` both present.
- `[ ]` **Socket.io handshake endpoint** — `curl "http://localhost:3001/socket.io/?EIO=4&transport=polling"` — Expects: 200 with engine.io handshake JSON (`sid`, `upgrades:["websocket"]`).
- `[ ]` **WebSocket upgrade** — Open `http://localhost:3001` in Chrome, check DevTools Network → WS for `/socket.io/?EIO=4&transport=websocket` 101 Switching Protocols frame.
- `[ ]` **No REST `/api/*` endpoints** — `curl -i http://localhost:3001/api/users` — Expects: returns HTTP 404 (Express default — `server.js` does not implement a SPA catch-all). Confirms no accidental REST surface.
- `[ ]` **Register via Socket.io** — In browser console: `const s=io(); s.emit('register',{username:'test_'+Date.now(),password:'pw'},console.log)` — Expects: `{success:true, user:{level:1, keys:10, inventory:[AssaultRifle,Handgun,Fists,Grenade], tasks:[3 items]...}}`; `users.json` grows.
- `[ ]` **Duplicate-username rejection** — Emit `register` twice with same username. — Expects: second callback returns `{success:false, message:'Username taken'}`.
- `[ ]` **Login existing user** — Emit `login` with seed user `{username:'suiiiiiiib90', password:'67forlife'}`. — Expects: `{success:true, user:{...}}`; wrong password returns `Invalid credentials`.
- `[ ]` **`users.json` persistence across restart** — Register, restart server, login as same user. — Expects: login succeeds; `loadUsers()` migrates defaults for `tasks`, `xp`, `level`, `keys`.
- `[ ]` **Concurrent connections + rooms** — Open 3 tabs, log in as 3 users, one creates `1v1` room, others `getRooms` → join. — Expects: `roomUpdate` broadcasts; both joiners visible to creator.
- `[ ]` **Disconnect cleanup** — Close a tab with a player in a room. — Expects: server logs `Player disconnected`; `roomUpdate` to others without the player; empty rooms purged from `rooms` Map.
- `[ ]` **Static asset serving** — `curl -I http://localhost:3001/index.html` — Expects: 200, `Content-Type: text/html`.
- `[ ]` **CORS / cross-origin Socket.io** — Connect via `io('http://localhost:3001')` from `file:///...`. — Expects: connects if same-origin; cross-origin requires explicit `cors:` config.
- `[ ]` **Port-conflict handling** — Start `npm start` twice. — Expects: second instance logs `EADDRINUSE :::3001` and exits non-zero (no graceful retry).
- `[ ]` **Graceful Ctrl+C shutdown** — Press Ctrl+C while a client is connected. — Expects: process exits within ~1s; `users.json` not corrupted (synchronous `fs.writeFileSync`).
- `[ ]` **Buy weapon flow** — Logged in, emit `buyWeapon('SMG', cb)`. — Expects: deducts 5 keys, adds `SMG` to inventory, persists; second buy returns `Already owned`; insufficient keys returns `Not enough keys`.

> ⚠️ **Security note found by audit:** passwords in `users.json` are stored **plaintext**. Treat the file as a secret; never commit it.

---

## O. Git & CI/CD detail tests

Extends section I (which checks `git status` and remote). These exercise the actual deploy pipeline.

- `[ ]` **Working tree status** — Type: `cd C:\Users\admin\rivals-multiplayer; git status` — Expects: clean tree or only expected changes; on branch `master`.
- `[ ]` **Recent commit history** — `git log --oneline -10` — Expects: 10 commits with SHAs and messages.
- `[ ]` **Remote origin** — `git remote -v` — Expects: `origin` points at `raufzidaan-coder/rivals-multiplayer`; both fetch and push present.
- `[ ]` **Branch inventory** — `git branch -a` — Expects: local `master` plus `remotes/origin/master`.
- `[ ]` **Uncommitted diff** — `git diff` and `git diff --staged` — Expects: empty or expected hunks.
- `[ ]` **Deploy workflow YAML parses** — `gh workflow view deploy.yml` — Expects: parses without errors; valid `on`, `jobs`, `steps`.
- `[ ]` **Trigger limited to master push** — Inspect `on:` block. — Expects: only `push: branches: [master]`.
- `[ ]` **Uses peaceiris/actions-gh-pages@v3** — Expects: step references exactly that action with `github_token: ${{ secrets.GITHUB_TOKEN }}`.
- `[ ]` **publish_dir = `./docs`** — Confirm `with:` block.
- `[ ]` **Pages site live** — `curl -I https://raufzidaan-coder.github.io/rivals-multiplayer/` — Expects: HTTP 200 (or 301); last deploy run green in `gh run list --workflow=deploy.yml`.
- `[ ]` **Branch protection on master** — `gh api repos/raufzidaan-coder/rivals-multiplayer/branches/master/protection` — Expects: JSON object or 404 (matches owner intent).
- `[ ]` **`gh` CLI authenticated** — `gh auth status; gh pr list; gh issue list` — Expects: logged in as `raufzidaan-coder`, scopes `repo`+`workflow`.
- `[ ]` **Pre-commit hooks inactive** — List `.git/hooks/`. — Expects: only `.sample` files (no executable hooks).
- `[ ]` **`.gitignore` coverage** — Grep for `node_modules/`, `*.rbxlx`, `sourcemap.json`. — Expects: all three present; `git check-ignore` confirms.

---

## P. Cross-MCP integration scenarios

Multi-server chains. Don't run until the individual MCPs (section H) are smoke-tested.

- `[ ]` **Arena screenshot → GitHub issue** — Ask: "Build the arena, screenshot from above, then open a GitHub issue 'Arena visual baseline v1' on this repo with the screenshot attached." — Expects: `execute_luau` → `capture_screenshot` → `GitHub__issue_write`.
- `[ ]` **Lobby flow diagram to GitHub PR comment** — Ask: "Sketch LobbyPads as an Excalidraw flowchart, export it, attach as a comment on the latest open PR." — Expects: `grep_scripts` → `Excalidraw__create_view` → `Excalidraw__export_to_excalidraw` → `GitHub__add_comment_to_pending_review`.
- `[ ]` **Reaction-time research as repo doc** — Ask: "Find 3 PubMed papers on FPS reaction time, cross-check with Scholar Gateway, then write a `docs/research/reaction-time.md` in the repo summarizing implications for `CombatSystem`." — Expects: `PubMed__search_articles` → `Scholar_Gateway__semanticSearch` → `GitHub__create_or_update_file`.
- `[ ]` **Schedule a Rojo restart** — Ask: "If 9am tomorrow is free, schedule a 15-min 'Rojo serve + Studio handshake' calendar block." — Expects: `Calendar__list_events` → `Calendar__create_event`.
- `[ ]` **Express screenshot to GitHub PR** — Ask: "Open `http://localhost:3001` in Chrome, screenshot the landing page, post it as a comment on the latest open PR." — Expects: `chrome__tabs_create_mcp` → `chrome__navigate` → `chrome__capture_screenshot` → `GitHub__add_comment_to_pending_review`.
- `[ ]` **Top issue triaged and fixed** — Ask: "List open GitHub issues, pick the highest-priority one, find the code in `src/`, propose a fix, post the diff as a comment." — Expects: `GitHub__list_issues` → `grep_scripts` → `Read` → `GitHub__add_issue_comment`.
- `[ ]` **README MCP count refresh** — Ask: "Count the currently-connected MCPs and update the README on GitHub with the new number." — Expects: introspection → `GitHub__get_file_contents` → `GitHub__create_or_update_file`.
- `[ ]` **LangChain-backed ability AI** — Ask: "Search LangChain Docs for 'tool use streaming', then sketch an Excalidraw diagram of a Claude-driven enemy AbilitySystem using that pattern." — Expects: `LangChain_Docs__search_docs` → `query_docs_filesystem` → `Excalidraw__create_view`.
- `[ ]` **Grant pitch as repo doc** — Ask: "Find STEM/game-dev foundations on Granted, pick one, then write `docs/grants/<funder>-pitch.md` with a Rivals pitch tailored to their priorities." — Expects: `Granted__search_funders` → `Granted__get_funder` → `GitHub__create_or_update_file`.
- `[ ]` **Crypto-themed skin brief as repo doc** — Ask: "Pull top 3 trending crypto topics from LunarCrush, write `docs/skins/crypto-crash.md` proposing a 'Crypto Crash' weapon skin set themed after them." — Expects: `LunarCrush__list` → `LunarCrush__topic` → `GitHub__create_or_update_file`.
- `[ ]` **PDF design review attached to PR** — Ask: "List PDFs, read the Rivals design PDF, post a PR comment comparing its 'Combat' section to `RivalsCore.CombatSystem`." — Expects: `PDF_Viewer__list_pdfs` → `read_pdf_bytes` → `grep_scripts` → `GitHub__add_comment_to_pending_review`.
- `[ ]` **GCE playtest box + calendar block** — Ask: "Spin up a small GCE instance for stress testing, then schedule a 1-hour calendar block today titled 'Rivals load test' with the instance IP." — Expects: `GCE__list_machine_types` → `GCE__create_instance` → `GCE__get_instance_basic_info` → `Calendar__create_event`.
- `[ ]` **Tango onboarding linked from CLAUDE.md** — Ask: "Find a Tango walkthrough for 'Rojo Studio connect', then add a link to it in this repo's `CLAUDE.md` under Daily Workflow." — Expects: `Tango__search` → `Tango__get_details` → `Read` (CLAUDE.md) → `GitHub__create_or_update_file`.

---

## Q. Performance & stress

Localhost MCP baseline overhead is ~2-3s per call via the boshyxd Studio plugin (HTTP polling loop is single-threaded). The 20-40ms figure quoted in older boshyxd docs assumes WebSocket transport which this plugin does not currently use. Batch MCP work into single execute_luau payloads where possible to amortize. Record wall-clock per call.

- `[ ]` **Mass create 500 parts** — Ask: "Use `mass_create_objects` to spawn 500 Parts under `workspace.StressTest` at random positions in a 200-stud cube." — Expects: < 5s; all 500 present via `get_instance_children`.
- `[ ]` **Mass set property on 500 parts** — Ask: "Set Transparency=0.5 and Material=Neon on every Part under `workspace.StressTest`." — Expects: < 3s; single round-trip.
- `[ ]` **`get_descendants` on large tree** — Ask: "Call `get_descendants` on `game` after the 500-part arena exists; report payload size + count." — Expects: returns without truncation error; response < 2 MB; < 2s.
- `[ ]` **Rapid `execute_luau` burst** — Ask: "Run `execute_luau` 10 times back-to-back each printing `tick()`." — Expects: all 10 succeed, no rate-limit; total < 4s.
- `[ ]` **Output log overflow** — Ask: "Loop-print 1000 numbered lines, then `get_output_log`." — Expects: returns; document tail-truncation behavior and cap.
- `[ ]` **1 MB script transfer** — Ask: "`set_script_source` on `ServerScriptService.StressScript` with a 1 MB string of `-- pad` comments, then `get_script_source` and confirm length." — Expects: round-trip in < 10s; byte-exact.
- `[ ]` **First-call cold latency** — In a fresh session: time the first MCP call vs the second identical one. — Expects: first < 2s (ToolSearch + schema load); subsequent < 100ms overhead.
- `[ ]` **Screenshot leak check** — Ask: "Call `capture_screenshot` 60× with ~1s spacing; report Studio RAM before/after via `execute_luau collectgarbage('count')`." — Expects: < 50 MB net growth; no stall.
- `[ ]` **Bulk find_and_replace** — Ask: "`find_and_replace_in_scripts` across all 6 Rivals scripts: replace `print(` with `warn(`, then revert." — Expects: < 3s each pass; no file corruption.
- `[ ]` **8-NPC playtest framerate** — Ask: "`start_playtest`, spawn 8 NPC characters, run `character_navigation` on each, `capture_screenshot` every 2s for 20s; estimate FPS." — Expects: server FPS ≥ 30.
- `[ ]` **MCP HTTP round-trip floor** — Ask: "Run `get_services` 20× sequentially; report min/median/max latency." — Expects: median < 3s on localhost; p99 < 7s (boshyxd plugin polling loop). Test fails with the older < 50ms expectation; document the plugin bottleneck.
- `[ ]` **Concurrent tool calls** — Ask: "In one turn, issue `get_instance_children`, `get_services`, `get_output_log` in parallel; report whether they overlapped or serialized." — Expects: parallel dispatch from Claude; document if Studio plugin queues them (likely single-threaded).

---

## R. Game systems runtime — gameplay code

These probe whether the **game logic actually works at runtime**, not just whether MCP tools are reachable. Requires Studio open with the place loaded and a playtest started where indicated.

> ⚠️ **Audit findings surfaced by the agent sweep** (full summary at end of file): `AbilitySystem` documented but not implemented; `UseAbility` RemoteEvent never connected; `GameModeManager:GetSpawnCFrame` hardcodes spawn positions and ignores `MapSystem.Spawns`; `Server:SetupRemoteListeners` registers per-PlayerAdded causing duplicate handlers; `UpdateMatchState` never fired; `TweenService` imported but unused. The tests below reveal those gaps deliberately.

### R.1 Movement system (lines 450-572 of `RivalsCore.luau`)

- `[ ]` **CONFIG constants intact** — Ask: "Print `CONFIG.Movement.{WalkSpeed,SprintSpeed,SlideSpeed,JumpPower,DoubleJumpPower,WallRunSpeed,WallSlideSpeed}`." — Expects: `execute_luau`+`get_output_log` returns `16 20 26 20 24 22 8`.
- `[ ]` **Initial state defaults** — Ask: "Build MovementSystem on LocalPlayer.Character; print `State`." — Expects: `IsSprinting=false, IsSliding=false, CanDoubleJump=true, IsGrounded=true, CurrentSpeed=16, StrafeJumpMultiplier=1.0`.
- `[ ]` **Sprint toggles speed** — Ask: "Call `:Sprint(true)` then `:Sprint(false)`; print `CurrentSpeed`." — Expects: `20` then `16`.
- `[ ]` **Sprint suppressed during slide** — Ask: "Call `:Slide()` then `:Sprint(true)`; print `CurrentSpeed`." — Expects: `26` (slide speed preserved).
- `[ ]` **Slide refused when airborne** — Ask: "Set `IsGrounded=false`, call `:Slide()`; print return + state." — Expects: `false, false`.
- `[ ]` **Slide cooldown blocks rapid re-slide** — Ask: "Call `:Slide()`, immediately again." — Expects: second returns `false` (cooldown 0.5s).
- `[ ]` **Slide auto-stops after 0.5s** — Ask: "`:Slide()`, `task.wait(0.6)`, print state." — Expects: `IsSliding=false, CurrentSpeed=16` (or 20 if sprint persisted).
- `[ ]` **Slide-off-ledge restores correct speed** — Ask: "Sprint+Slide, set `IsGrounded=false` mid-slide, wait 0.6s; print speed." — Expects: `20` (StopSlide reads IsSprinting flag).
- `[ ]` **Double jump consumes once** — Ask: "Jump grounded, `IsGrounded=false`, Jump twice." — Expects: returns `true, true, false`; `CanDoubleJump=false`.
- `[ ]` **Ground rearms double jump** — Ask: "Exhaust double jump, set `IsGrounded=true`, jump." — Expects: `CanDoubleJump=true` after ground touch.
- `[ ]` **Weapon double-jump flag re-arms** — Ask: "`:SetWeaponDoubleJump(true)`, jump grounded; print `CanDoubleJump`." — Expects: `true` (HasWeaponDoubleJump branch).
- `[ ]` **Wall-slide caps fall speed** — Ask: "`IsWallSliding=true`, set RootPart Y velocity=-50, call `:Update(0.016)`; print Y." — Expects: `-8` (clamped to WallSlideSpeed).
- `[ ]` **StrafeJump multiplier caps at 1.5** — Ask: "Call `:StrafeJump()` 20× airborne; print multiplier; ground; `:Update(0.1)`; print again." — Expects: `1.5` then `1.0`.
- `[ ]` **Live sprint→slide→jump combo** — Ask: "Start playtest, hold Shift+W 1s, tap C (slide), then Space mid-slide; screenshot + output." — Expects: visible airborne arc, no errors.

### R.2 Combat system (lines 727-834 of `RivalsCore.luau`)

- `[ ]` **Body shot = base damage** — Ask: "Spawn dummy; `Combat:TakeDamage(25, attacker, torso)`; print Health." — Expects: Health=75, no headshot.
- `[ ]` **Headshot = base × 2.0** — Ask: "`TakeDamage(25, attacker, head)` where HitPart.Name='Head'." — Expects: ActualDamage=50, IsHeadshot=true, Health=50.
- `[ ]` **Armor absorbs 50%** — Ask: "`AddArmor(50)`, then `TakeDamage(40, nil, torso)`; print Health/Armor." — Expects: Armor=30, Health=80.
- `[ ]` **Armor caps at MaxArmor=50** — Ask: "`AddArmor(999)`; print Armor." — Expects: 50.
- `[ ]` **Humanoid.Died fires on lethal** — Ask: "Connect Died, `TakeDamage(150, attacker, torso)`." — Expects: Died fires; IsDead=true.
- `[ ]` **Overkill clamps to 0** — Ask: "TakeDamage(500) from full health." — Expects: Health=0, not negative.
- `[ ]` **Damage to dead returns 0** — Ask: "Kill, then TakeDamage again." — Expects: returns 0; no double Die.
- `[ ]` **Exactly 0 HP triggers Die once** — Ask: "From Health=25, TakeDamage(25); count Die invocations." — Expects: IsDead=true, counter=1.
- `[ ]` **Respawn after 3s** — Ask: "Kill at t=0; `task.wait(3.5)`; print Health/IsDead." — Expects: Health=100, IsDead=false.
- `[ ]` **Headshot via substring 'head'** — Ask: "Pass HitPart named 'UpperHead'." — Expects: headshot multiplier applied.
- `[ ]` **Burst damage accumulates** — Ask: "Loop `TakeDamage(10)` ×5 in one frame." — Expects: Health=50.
- `[ ]` **Fall damage disabled** — Ask: "Drop dummy from y=500." — Expects: no damage.
- `[ ]` **Self-damage Attacker==self** — Ask: "TakeDamage with attacker == victim; check Kills." — Expects: should NOT increment Kills — flag as bug if it does.
- `[ ]` **KillFeed RemoteEvent on Die** — Ask: "Listen on KillFeed, kill dummy; dump args." — Expects: `KillFeed:FireAllClients(Player)` reaches all clients (`Server.server.luau:183`).
- `[ ]` **Knockback decays to zero** — Ask: "`ApplyKnockback(50,0,0)`; `:Update(0.1)` loop." — Expects: `KnockbackVelocity == Vector3.new()` after ~2s.

### R.3 Weapons (`WeaponSystem` class `RivalsCore.luau:578-725`; WEAPONS table `RivalsCore.luau:68-377`)

Stats: AR (Dmg 15, FireRate 0.1, Mag 30/90, Reload 2.5), Handgun (Dmg 20, FireRate 0.2, Mag 12/48, Reload 1.8), Fists (Dmg 25, Melee, HasDoubleJump), Grenade (Utility). `CONFIG.Weapons.QuickSwitchMax = 2`.

- `[ ]` **AR damage = 15** — Build WeaponSystem; print WeaponData.Damage.
- `[ ]` **Handgun damage = 20** — Same with Handgun.
- `[ ]` **Fire rate gate** — `:Fire()` twice with no delay. — Expects: `true, false`.
- `[ ]` **Magazine decrements** — Fire once. — Expects: `29`.
- `[ ]` **Empty mag blocks fire** — Set Magazine=0; `:CanFire()`. — Expects: `false`.
- `[ ]` **Reload duration 2.5s** — `:Reload()`, wait 2.6s, print Magazine. — Expects: 30.
- `[ ]` **Reload skipped at full**. — Expects: `false`.
- `[ ]` **Slot 1/2/3/4 keyboard switch** — `simulate_keyboard_input` `1,2,3,4`. — Expects: cycles AR→Handgun→Fists→Grenade.
- `[ ]` **ADS reduces spread** — `:SetADS(true)`; compare `GetSpread()`. — Expects: ADS (0.02) << Hip (0.15).
- `[ ]` **Recoil on fire** — Print `RecoilOffset`. — Expects: nonzero magnitude.
- `[ ]` **Recoil decays 0.8×** — Two `:GetRecoil()` calls. — Expects: 2nd = 0.8× 1st.
- `[ ]` **Ammo persistence across switch** — Fire 5 on AR, switch to slot 2 then back; read Magazine. — Expects: 30 (flag potential bug since `EquipWeapon` reinstantiates).
- `[ ]` **QuickSwitchMax=2 per round** — Press `2,1,2,1,2`. — Expects: 3rd blocked.
- `[ ]` **Switch mid-reload cancels** — Fire 30, reload, at t=1s press `2` then `1`. — Expects: new WeaponSystem with full mag.
- `[ ]` **Switch mid-fire to Fists enables double-jump** — Hold LMB on AR, mid-burst press `3`. — Expects: `Movement:SetWeaponDoubleJump(true)` called.

### R.4 Abilities (⚠️ documented but **not implemented**)

These tests will FAIL by design — they surface the implementation gap.

- `[ ]` **AbilitySystem table exists** — Grep RivalsCore for `AbilitySystem`. — Expects: ≥1 defining match (currently **zero**).
- `[ ]` **UseAbility server handler** — Grep for `UseAbility.OnServerEvent`. — Expects: a `:Connect` handler (currently **missing**).
- `[ ]` **G key fires UseAbility from client** — `simulate_keyboard_input` G during playtest. — Expects: log entry (currently silent — no UIS binding).
- `[ ]` **Server receives payload** — `Events.UseAbility:FireServer('Grenade')`; read output. — Expects: handler logs receipt (currently silent).
- `[ ]` **Cooldown field per ability** — Dump WEAPONS table. — Expects: `Cooldown` field (currently absent).
- `[ ]` **Server-side cooldown enforcement** — Fire twice in 100ms. — Expects: 2nd rejected.
- `[ ]` **Visual effect spawns** — Trigger ability; list new Workspace children. — Expects: ParticleEmitter / effect Part within 1s.
- `[ ]` **Effect damages other players** — Spawn dummy; fire ability toward it. — Expects: Health decreases.
- `[ ]` **G binding matches `Settings.Keybinds.Utility`** — Read Client.client.luau. — Expects: UIS InputBegan branch present (currently absent).
- `[ ]` **F quick-melee independent of weapon** — Equip AR, press F. — Expects: melee damage without weapon switch.
- `[ ]` **Spam during cooldown → 1 effect** — Press G ×10 in 200ms. — Expects: exactly 1.
- `[ ]` **Client can't bypass cooldown** — FireServer ×20. — Expects: server enforces.

### R.5 Matchmaking & Lobby (`LobbySystem` lines 989-1058 of `RivalsCore.luau`)

Queues: `OneVOne, TwoVTwo, FiveVFive, Special`. Ranked gate: `Server.server.luau:135` delegates to `PlayerDataManager:CanPlayRanked` (`RivalsCore.luau:438-444`); thresholds are `Level≥50` (`CONFIG.Game.LevelRequirement`, `RivalsCore.luau:27`), `AccountAge≥14` (`CONFIG.Game.RankedAgeRequirement`, `RivalsCore.luau:28`), `TasksCompleted≥30` (hardcoded at `RivalsCore.luau:443`).

- `[ ]` **Casual queue accepts** — `Server:JoinQueue(p, 'FiveVFive')`. — Expects: `true`, `#Queues.FiveVFive==1`.
- `[ ]` **Ranked rejects underage** — Stub AccountAge=1, Level=99. — Expects: `false`.
- `[ ]` **Ranked rejects under-level** — Stub Level=10, AccountAge=30, TasksCompleted=30. — Expects: `false`.
- `[ ]` **Ranked accepts qualified** — Stub Level=60, AccountAge=30, TasksCompleted=30. — Expects: `true`.
- `[ ]` **LeaveQueue removes player** — Join then leave; print length. — Expects: 0.
- `[ ]` **Queue increment** — Insert 3 mocks. — Expects: `1, 2, 3`.
- `[ ]` **5v5 auto-starts at 10** — Push 10 mocks. — Expects: match starts on the 10th insert (`RivalsCore.luau:1017` checks `#Queue >= MaxPlayers`).
- `[ ]` **9 players does NOT auto-start** — Queue 9. — Expects: length stays 9.
- `[ ]` **PlayerRemoving drains queue** — Start playtest, join, Kick. — Expects: all `Queues[*]` empty (`Server.server.luau:205-208`).
- `[ ]` **Queues independent** — 4 to FiveVFive, 4 to TwoVTwo. — Expects: TwoVTwo drains (MaxPlayers=4), FiveVFive stays at 4.
- `[ ]` **Ranked uses TasksCompleted** — Stub Level=99, AccountAge=30, TasksCompleted=5. — Expects: `false`.
- `[ ]` **Duplicate join idempotent** — Call JoinQueue twice for same player. — Expects: length 1.
- `[ ]` **StartMatch splits 5/5** — Inspect after auto-start. — Expects: `#Team1==5, #Team2==5`.

### R.6 GameMode & Rounds (`GameModeManager` lines 840-983)

Match flow: `StartMatch → Warmup(10s) → StartRound (Phase=Playing, 120s) → death triggers GetAliveCount → EndRound → next round or EndMatch at score ≥5`.

- `[ ]` **GameMode constructs in Lobby** — Print Phase, CurrentRound, Team1Score. — Expects: `Lobby / 0 / 0`.
- `[ ]` **StartMatch enters Warmup** — Print Phase + TimeRemaining. — Expects: WarmupTime=10 then Phase=Playing.
- `[ ]` **StartRound assigns team spawns** — Print HumanoidRootPart.CFrame for both. — Expects: Team1 ≈ x=-50, Team2 ≈ x=+50 (hardcoded — **flag that MapSystem.Spawns is unused**).
- `[ ]` **MapSystem.Spawns has 3 CFrames/team** — Require MapSystem, CreateArena, dump lengths. — Expects: `Team1=3, Team2=3`.
- `[ ]` **Death triggers alternation** — Set Team1 Health=0. — Expects: GetAliveCount Team1=0, Team2=1; EndRound('Team2').
- `[ ]` **Round timer counts down** — `:Update(10)` ×5. — Expects: 120→110→…→70.
- `[ ]` **Timer-expiry picks higher alive count** — TimeRemaining=0.1 with 2T1, 1T2 alive. — Expects: EndRound('Team1').
- `[ ]` **EndRound on last-team-alive** — Kill all Team2. — Expects: Score incremented, Phase=RoundEnd.
- `[ ]` **First to 5 wins** — Team1Score=4, EndRound('Team1'). — Expects: Phase=MatchEnd, WinningTeam=Team1.
- `[ ]` **Non-terminating round schedules next** — Team1Score=2, EndRound; wait 6s. — Expects: Phase=Playing, round incremented.
- `[ ]` **UpdateMatchState never fires** — Grep `Server.server.luau` for `UpdateMatchState:FireAllClients`. — Expects: created (`Server.server.luau:48-50`) but never fired — **flag bug**.
- `[ ]` **Phase sequence** — Run full match with event listeners. — Expects: Warmup→Playing→RoundEnd→…→MatchEnd→Lobby.
- `[ ]` **Mid-round disconnect** — Remove Team1 player during Playing. — Expects: `OnPlayerDied` NOT auto-triggered — **flag gap**.
- `[ ]` **ReturnToLobby resets** — EndMatch then wait 11s. — Expects: `Lobby / 0 / 0 / 0`.
- `[ ]` **Players respawn at LobbySpawn** — After ReturnToLobby. — Expects: at `LobbySpawn + (0,5,0)` (`Server.server.luau:103-112`).

### R.7 Player data & Leaderstats (`PlayerDataManager` lines 383-444 of `RivalsCore.luau`)

⚠️ **Pure in-memory** (no DataStoreService). Data resets every server shutdown.

- `[ ]` **leaderstats folder on join** — `get_instance_children` on `Players.<me>`.
- `[ ]` **Three IntValues** — Expects: exactly `Level, Kills, Wins`.
- `[ ]` **Default Level=1**, **Kills=0**, **Wins=0**.
- `[ ]` **WeaponsOwned defaults** — Expects: `{AssaultRifle, Handgun, Fists, Grenade}`.
- `[ ]` **Kills increments** — `set_property Kills.Value=1`; verify. — Flag if not auto-incremented on Humanoid.Died.
- `[ ]` **Wins reflects RankedWins** — Bump `Data.RankedWins`, rebuild `Wins.Value`.
- `[ ]` **CanPlayRanked false for fresh** — Expects: `false`.
- `[ ]` **CanPlayRanked requires Level 50** — Set Level=50, TasksCompleted=30. — Expects: `true` IFF AccountAge≥14.
- `[ ]` **Account-age gate** — Compare `Player.AccountAge` to `CONFIG.RankedAgeRequirement=14`.
- `[ ]` **In-memory only** — Mutate Kills, stop+start playtest. — Expects: resets to 0.
- `[ ]` **JoinQueue blocks Ranked when ineligible** — Fire as fresh player. — Expects: returns `false`.

### R.8 MapSystem (`src/shared/MapSystem.luau`)

- `[ ]` **Arena child count** — Build fresh; count. — Expects: 18 (1 Floor + 4 Walls + 8 Cover + 3 Platforms + 1 Ramp + 1 LobbySpawn).
- `[ ]` **Floor pos/size** — Position `(0,-0.5,0)`, Size `(100,1,60)`.
- `[ ]` **All 4 walls** — Positions `(0,10,30), (0,10,-30), (-50,10,0), (50,10,0)`.
- `[ ]` **8 cover blocks** — Size `(8,6,8)`.
- `[ ]` **Platform heights 12/8/8** — Transparency 0.3.
- `[ ]` **WallRunRamp** — Position `(35,3,0)`, Size `(15,1,30)`.
- `[ ]` **LobbySpawn invisible** — Transparency=1, Position `(0,5,-50)`.
- `[ ]` **Team1 spawns at -X** — X `{-40,-45,-45}`, Y=5, Z `{0,15,-15}`.
- `[ ]` **Team2 spawns at +X** — Mirroring Team1.
- `[ ]` **Warehouse 9 children** — Floor + 5 Pillars + 3 HighPlatforms.
- `[ ]` **Warehouse pillars** — `(±30,10,±20)` plus `(0,10,0)`.
- `[ ]` **Downtown 9 children** — Floor 100×1×100 + 4 Buildings + 4 Ledges.
- `[ ]` **Tallest building** — Position `(25,17.5,25)`, Size 25×35×25.
- `[ ]` **DeleteMap removes folder**.
- `[ ]` **LoadMap renames to `CurrentMap`**.
- `[ ]` **LoadMap only works for Arena** — Warehouse/Downtown not in `self.Maps`.
- `[ ]` **Multiple maps coexist** — Three folders in Workspace.
- `[ ]` **Floor BrickColor** — `"Dark stone gray"` for all three.

### R.9 LobbyPads (`src/server/LobbyPads.luau`)

- `[ ]` **SetupDefaultPads spawns 5** — Parts named `1v1Pad, 2v2Pad, 5v5Pad, SpecialPad, Shooting RangePad`.
- `[ ]` **Pad colors** — 1v1 (0,1,0), 2v2 (0,0.5,1), 5v5 (1,0.2,0.2), Special (1,1,0), Range (0.5,0.5,0.5).
- `[ ]` **TextLabel format** — `"2v2\n0/4"`.
- `[ ]` **ClickDetector present** — Children of 5v5Pad include SpecialMesh, SurfaceGui, ClickDetector.
- `[ ]` **Touched handler fires** — Visual updates to `1/2`.
- `[ ]` **Touch increments counter**.
- `[ ]` **Leave decrements**.
- `[ ]` **1v1 auto-starts at 2** — `[Rivals] Match started with OneVOne`.
- `[ ]` **Pad resets to 0/X after start**.
- `[ ]` **ClickDetector without standing** — MouseClick increments.
- `[ ]` **No TouchTransducer bug** — Grep returns 0 hits.
- `[ ]` **Part physics props** — CanCollide=false, Transparency=0.5, Anchored=true, Size `(6,1,6)`.
- `[ ]` **Intensity scales Part.Color** — 2v2 at 2/4 ≈ (0, 0.4, 0.8).
- `[ ]` **StartMatchFromPad splits by parity** — 4 mocks → Team1={p1,p3}, Team2={p2,p4}.
- `[ ]` **Special requires 8** — `"Special\n0/8"`.

### R.10 Settings & UI (`src/shared/Settings.luau`)

- `[ ]` **`Settings.new()` populates Data** — Non-nil PC/Mobile/Console/Graphics/Audio/Gameplay.
- `[ ]` **Default keybinds match** — Forward=W, Backward=S, Left=A, Right=D, Jump=Space, Sprint=LeftShift, Slide=LeftControl, Reload=R, Weapon1=One, Weapon2=Two, Utility=G, QuickMelee=F, ADS=MouseButton2, Fire=MouseButton1.
- `[ ]` **SetFOV clamps [60,120]** — `SetFOV(30)`/`SetFOV(200)`. — Expects: 60 / 120.
- `[ ]` **SetCrosshairSize clamps [0.5,3.0]**.
- `[ ]` **SetCrosshairColor accepts Color3**.
- `[ ]` **SetMouseSensitivity sets X,Y** — Both axes = 2.
- `[ ]` **BindKey ignores unknown** — Keybinds untouched.
- `[ ]` **BindKey updates known**.
- `[ ]` **ResetToDefaults** — FOV back to 70.
- `[ ]` **SetAimAssist clamps [0,1]**.
- `[ ]` **SettingsUI.new returns instance** — `.Player` and `.Settings` non-nil.
- `[ ]` **CreateMenu builds ScreenGui** — `SettingsMenu` under PlayerGui with Title "SETTINGS".
- `[ ]` **Close button destroys GUI**.
- `[ ]` **CreateSlider drag updates value**.
- `[ ]` **CreateToggle flips on click** — Text "OFF"→"ON", color → (0,0.7,0.3).

### R.11 RemoteEvents (`Server.server.luau`)

- `[ ]` **All 7 RemoteEvents exist** — JoinQueue, LeaveQueue, Ready, SwitchWeapon, UseAbility, UpdateMatchState, KillFeed under ReplicatedStorage.
- `[ ]` **JoinQueue fires OnServerEvent** — `:FireServer("Casual")`.
- `[ ]` **LeaveQueue post-fix dot syntax** — `Server.server.luau:120` is `self.Lobby:LeaveQueue` (not `self:Lobby:`).
- `[ ]` **Ready toggles** — `GameServer.Players[plr].Ready` matches last fire.
- `[ ]` **SwitchWeapon slot validation** — 3rd switch returns `false` (max 2).
- `[ ]` **SwitchWeapon invalid slot** — Slot 99/nil. — **Flag missing range validation**.
- `[ ]` **UseAbility handler missing** — Fire UseAbility; no listener — **bug**.
- `[ ]` **UpdateMatchState FireAllClients reach** — Server-side fire payload; verify clients receive. — Currently **never fired**.
- `[ ]` **KillFeed FireAllClients on death** — Simulate Humanoid.Died.
- `[ ]` **Rate limiting** — Fire ×100 in 1s. — Expects: no throttling — **flag absent rate limiting**.
- `[ ]` **WaitForChild on client** — `:WaitForChild('JoinQueue', 5)` from fresh client.
- `[ ]` **Runtime removal of RemoteEvent** — Destroy Ready, FireServer from client.
- `[ ]` **PlayerRemoving cleanup** — Verify `GameServer.Players[plr]` is `nil` after a player leaves — pre-fix bug resolved at `Server.server.luau:207`.
- `[ ]` **Single handler invocations** — Have 3 players join, fire `JoinQueue` from one client, count server-side handler invocations. Expects: exactly 1 (fix: `SetupRemoteListeners` is now called once from `Server:Start` at `Server.server.luau:199`, not per `PlayerAdded`).

---

## S. Roblox services & engine APIs

These exercise platform features the game uses or could use.

### S.1 Animation & TweenService

⚠️ **`TweenService` is imported at line 14 of `RivalsCore.luau` but never called.**

- `[ ]` **TweenService resolves** — `typeof(game:GetService('TweenService')) == "Instance"`.
- `[ ]` **TweenInfo constructor** — `TweenInfo.new(1, Quad, Out)`.
- `[ ]` **Part position tween reaches target** — `TweenProbe` Position to `(0,20,0)` over 0.5s.
- `[ ]` **EasingStyle Linear/Quad/Sine** — Three concurrent tweens reach target.
- `[ ]` **Pause / Cancel** — Pause mid-travel, Cancel freezes position.
- `[ ]` **Concurrent tweens same instance** — Position + Color simultaneously.
- `[ ]` **GUI fade-in** — Frame BackgroundTransparency 1→0 over 1s.
- `[ ]` **Camera ADS tween (feature add)** — Patch `WeaponSystem:SetADS` to tween FOV 70↔50.
- `[ ]` **Recoil kickback tween (feature add)** — Tween viewmodel CFrame back to neutral post-recoil.
- `[ ]` **Animation Instance creation** — Set AnimationId, parent to Humanoid.
- `[ ]` **Animator:LoadAnimation returns AnimationTrack**.
- `[ ]` **AnimationTrack.Priority** — `Enum.AnimationPriority.Action`.
- `[ ]` **Play / IsPlaying / Stop** — Lifecycle.
- `[ ]` **Tween.Completed signal** — `Enum.PlaybackState.Completed` logged.
- `[ ]` **Dead-code TweenService import** — Grep for `TweenService:` call. — Expects: 0 — either use or remove.

### S.2 Camera & Viewport

⚠️ **ClientController uses `CameraType = Scriptable`** and **CFrame offset for ADS** (not FOV). KillCam / Spectator / Shake / FreeCam are **not implemented**.

- `[ ]` **CurrentCamera exists**.
- `[ ]` **Default FOV = 70**.
- `[ ]` **ADS FOV (70 × 0.7 = 49) — proposed**.
- `[ ]` **CameraType = Scriptable** post-init (`RivalsCore.luau:1507` in `ClientController:SetupCamera`).
- `[ ]` **CameraSubject = LocalPlayer.Humanoid**.
- `[ ]` **Move to arena viewpoint** — `CFrame.new(0,50,0)*CFrame.Angles(-pi/4,0,0)`.
- `[ ]` **Arena screenshot** — Captures arena geometry.
- `[ ]` **ADS CFrame offset** — `(0.5,-0.3,-1)` (`RivalsCore.luau:1609` in `ClientController:UpdateCamera`).
- `[ ]` **ADS sensitivity 0.7×** — Mouse rotation halved.
- `[ ]` **KillCam (flag check)** — `CONFIG.Gameplay.KillCamEnabled` exists?
- `[ ]` **Spectator camera** — Grep "Spectat". — Expects: 0 — **NOT IMPLEMENTED**.
- `[ ]` **FreeCam** — Grep "FreeCam". — Expects: 0 — **NOT IMPLEMENTED**.
- `[ ]` **Camera shake on fire** — Grep "Shake". — Expects: weapon Recoil only — **NOT IMPLEMENTED**.
- `[ ]` **FOV restores post-ADS** — Back to 70 within 0.2s.
- `[ ]` **Viewport aspect sanity** — `ViewportSize` X>0, Y>0.

### S.3 Lighting & Post-FX

- `[ ]` **Brightness = 2** (project.json).
- `[ ]` **Ambient = (0,0,0)**.
- `[ ]` **GlobalShadows = true**.
- `[ ]` **ShadowSoftness = 0.2**.
- `[ ]` **TimeOfDay mutable** — Set `14:00:00`.
- `[ ]` **Add BloomEffect** — Intensity 0.4.
- `[ ]` **Add ColorCorrectionEffect** — Saturation 0.1.
- `[ ]` **Add DepthOfFieldEffect**.
- `[ ]` **Technology = Future/ShadowMap/Voxel** (flag Legacy).
- `[ ]` **Add Atmosphere** — Density 0.3.
- `[ ]` **Baseline screenshot**.
- `[ ]` **Brightness change screenshot** — Set 4; visibly brighter.

### S.4 Sound & SoundService

- `[ ]` **RespectFilteringEnabled = true** (project.json).
- `[ ]` **Create Sound under SoundService**.
- `[ ]` **Assign SoundId** (placeholder asset — substitute real one).
- `[ ]` **Play / Pause / Stop lifecycle** — IsPlaying `{true, false, false}`.
- `[ ]` **Volume respects MasterVolume** — `SFX × Master`.
- `[ ]` **3D positional sound** — Parent to Part; distance attenuation.
- `[ ]` **SFX vs Music SoundGroups** — Volumes 1.0 and 0.5.
- `[ ]` **Sound looping** — Looped=true past TimeLength.
- `[ ]` **PlayOnRemove** — Destroy → playback event.
- `[ ]` **Free Roblox audio loads** — `IsLoaded` within 5s.
- `[ ]` **Mute toggle from Settings** — SoundGroup volumes go 0/restored.

### S.5 Physics & BasePart

- `[ ]` **Workspace.Gravity = 196.2**.
- `[ ]` **All arena parts anchored** — 100%.
- `[ ]` **Cover CanCollide=true**.
- `[ ]` **Platforms Transparency=0.3**.
- `[ ]` **Unanchored part falls** — Y drops below 50.
- `[ ]` **Material round-trip** — Plastic, Neon, Glass, Wood.
- `[ ]` **CustomPhysicalProperties** — Density=2, Friction=0.8.
- `[ ]` **BodyVelocity** — `(0,50,0)` rises.
- `[ ]` **Touched event on walk-over** — During playtest.
- `[ ]` **Weld two parts** — WeldConstraint preserves offset.
- `[ ]` **AssemblyMass** — > 0.
- `[ ]` **Custom CollisionGroup** — "Projectiles".
- `[ ]` **StreamingEnabled toggle** — Flag warning re: all-anchored arena; revert.

### S.6 UI/HUD construction

- `[ ]` **ScreenGui scaffold** under StarterGui.
- `[ ]` **Enabled / ResetOnSpawn** round-trip.
- `[ ]` **MainFrame AnchorPoint + Position**.
- `[ ]` **TextLabel renders** in screenshot.
- `[ ]` **ImageLabel rect crop**.
- `[ ]` **TextButton MouseButton1Click fires**.
- `[ ]` **UICorner rounded** — Radius 8.
- `[ ]` **UIPadding 12px** all sides.
- `[ ]` **UIListLayout auto-arrange** — No overlap.
- `[ ]` **ScrollingFrame ScrollBarThickness=6**.
- `[ ]` **DisplayOrder layering** — SettingsGui occludes HUDGui.
- `[ ]` **TouchGui mobile** — JumpButton + Joystick.
- `[ ]` **Killfeed 5s duration** — Empty after 5s (`CONFIG.Gameplay.KillFeedDuration=5`).
- `[ ]` **Crosshair toggles** — `ShowDamageNumbers, ShowHitMarkers`.
- `[ ]` **ADS overlay** — Right-click full-screen scope.

### S.7 DataStore persistence

⚠️ **Not yet implemented.** Tests validate the path to adding it.

- `[ ]` **Audit imports** — Grep RivalsCore for `DataStoreService`. — Expects: 0 matches.
- `[ ]` **Studio API services enabled** — `:SetAsync` succeeds (or 403 if API off).
- `[ ]` **Round-trip write/read**.
- `[ ]` **Key naming `player_<UserId>`**.
- `[ ]` **UpdateAsync concurrency** — No lost write.
- `[ ]` **GetVersionAsync recovery** — ≥2 versions (published place only).
- `[ ]` **Quota awareness** — Throttle past `60 + 10×players/min`.
- `[ ]` **API-disabled failure mode** — `403`.
- `[ ]` **Leaderstats migration round-trip** — Identical after rehydrate.
- `[ ]` **pcall wrapping** — Every call wrapped.
- `[ ]` **PlayerRemoving + BindToClose save hooks**.
- `[ ]` **Default-data fallback** — Hydrates 18-field defaults.

### S.8 HttpService / external HTTP

- `[ ]` **HttpEnabled = true** (project.json).
- `[ ]` **GetAsync** to `https://httpbin.org/get` — Returns table with `url`.
- `[ ]` **PostAsync JSON body** — `{hello='rivals'}` echoes back.
- `[ ]` **RequestAsync full control** — PUT custom headers, `Success=true, StatusCode=200`.
- `[ ]` **JSONEncode roundtrip** — Deep equal.
- `[ ]` **Default timeout** — `httpbin.org/delay/2` (document observed).
- `[ ]` **pcall catches error** — `nonexistent-domain.invalid`. — `ok=false`.
- `[ ]` **Blocked domain** — `roblox.com/login` blocked.
- `[ ]` **Localhost from non-plugin Script** — Errors "Trust check failed" — Roblox prohibits loopback from non-plugin contexts.
- `[ ]` **SSE / streaming** — `sse.dev/test` — Single buffered Body.
- `[ ]` **Rate limit** — 600 GetAsync. — Throttle past ~500/min/server.

---

## Audit findings (gaps between docs and code)

Surfaced by the agent sweep. None block the test plan; all are real and known.

| Finding | Section | Severity |
|---|---|---|
| `AbilitySystem` referenced in CLAUDE.md but **does not exist** in `RivalsCore.luau` | R.4 | High — feature missing |
| `UseAbility` RemoteEvent created (lines 44-46) but **never `.OnServerEvent:Connect`-ed** | R.4, R.11 | High |
| Client.client.luau has **no UserInputService binding** for G (Utility) or F (QuickMelee) | R.4 | High |
| `GameModeManager:GetSpawnCFrame` hardcodes `±50,10,0`, **ignores `MapSystem.Spawns`** | R.6 | Medium |
| `Server:SetupRemoteListeners` connects per `PlayerAdded` → **duplicate handler invocations** *(legacy bug — already fixed in current build per CLAUDE.md fix #6; `Server:Start` at `Server.server.luau:199` calls it once. Test now verifies the fix.)* | R.11 | Resolved |
| `UpdateMatchState` RemoteEvent **never fired** anywhere | R.6, R.11 | Medium |
| `Server:OnPlayerDied` not auto-triggered by `PlayerRemoving` | R.6 | Medium — mid-round disconnect may stall round |
| `TweenService` imported at line 14 of `RivalsCore.luau` but **never used** | S.1 | Low — dead import |
| `PlayerDataManager` is **in-memory only** — data resets every server | R.7, S.7 | High in production |
| `Server.server.luau` does **no slot range validation** on `SwitchWeapon` | R.11 | Low |
| `Server.server.luau` does **no rate limiting** on any RemoteEvent | R.11 | Medium — exploitable |
| `Server.server.luau` does **no cleanup** of `GameServer.Players[plr]` on PlayerRemoving *(legacy bug — fixed at `Server.server.luau:207` per CLAUDE.md fix #7; test now verifies cleanup)* | R.11 | Resolved |
| `users.json` stores passwords **plaintext** | N | High in production |
| `MapSystem:LoadMap` only works for Arena | R.8 | Low — design limitation |

Treat the relevant test items as **expected to fail** — they document the gap.
