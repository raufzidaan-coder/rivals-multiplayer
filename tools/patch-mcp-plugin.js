#!/usr/bin/env node
// Patches the locally-installed boshyxd robloxstudio-mcp plugin so it
// auto-activates on Studio launch (no toolbar-button click required).
//
// Usage: node tools/patch-mcp-plugin.js          (patch)
//        node tools/patch-mcp-plugin.js --revert (restore .orig backup)
//
// Backup is written to RobloxStudioMCP.rbxmx.orig the first time.

const fs = require("fs");
const path = require("path");

const PLUGIN_DIR =
    process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, "Roblox", "Plugins") ||
    path.join(process.env.HOME || "", "AppData", "Local", "Roblox", "Plugins");
const PLUGIN = path.join(PLUGIN_DIR, "RobloxStudioMCP.rbxmx");
const BACKUP = PLUGIN + ".orig";

const MARKER = "Auto-activated on plugin load";
// Plugin file is CRLF; build regex that tolerates either line ending.
const OLD_RE = /UI\.updateUIState\(\)(\r?\n)Communication\.checkForUpdates\(\)/;
const INSERT = `
task.spawn(function()
	task.wait(0.5)
	local ok, err = pcall(function()
		pcall(function() game:GetService("HttpService").HttpEnabled = true end)
		Communication.activatePlugin(State.getActiveTabIndex() or 1)
		print("[MCP] Auto-activated on plugin load (HTTP enabled)")
	end)
	if not ok then warn("[MCP] Auto-activate failed: " .. tostring(err)) end
end)`;

// Match any previously-installed version of the auto-activate block so we can
// replace it in place (rather than skip-when-MARKER-present).
const PREV_BLOCK_RE = /\r?\ntask\.spawn\(function\(\)\s+task\.wait\(0\.5\)[\s\S]*?Auto-activate[d]? [^"]*"\)\s+end\)\s+if not ok then warn\([^)]*\)[^)]*\) end\s+end\)/;

// Port reconciliation: the Node MCP server in some npm builds listens on 58742
// (not the historical 58741 the plugin hard-codes). Both BASE_PORT *and* the UI
// default URL must be re-pointed — activatePlugin reads the URL text input and
// overrides conn.port from it, so BASE_PORT alone isn't enough.
const PORT_PATCHES = [
    { from: "BASE_PORT = 58741", to: "BASE_PORT = 58742" },
    { from: 'urlInput.Text = "http://localhost:58741"', to: 'urlInput.Text = "http://localhost:58742"' },
];

function die(msg) { console.error(msg); process.exit(1); }

if (!fs.existsSync(PLUGIN)) die("Plugin not found at: " + PLUGIN);

if (process.argv.includes("--revert")) {
    if (!fs.existsSync(BACKUP)) die("No backup found at: " + BACKUP);
    fs.copyFileSync(BACKUP, PLUGIN);
    console.log("Reverted from backup:", BACKUP);
    process.exit(0);
}

if (!fs.existsSync(BACKUP)) {
    fs.copyFileSync(PLUGIN, BACKUP);
    console.log("Backup written to:", BACKUP);
}

let content = fs.readFileSync(PLUGIN, "utf8");

let patched = content;
let didActivate = false;
let didPort = false;

// Strip any prior auto-activate block so we can re-insert the current version
// (this lets us roll out updates idempotently).
if (PREV_BLOCK_RE.test(patched)) {
    patched = patched.replace(PREV_BLOCK_RE, "");
}

const m = patched.match(OLD_RE);
if (!m) {
    die("Insertion point not found. Plugin may have been updated upstream; check the script tail.");
}
const eol = m[1];
const replacement = m[0] + INSERT.replace(/\n/g, eol);
patched = patched.replace(OLD_RE, replacement);
didActivate = true;

for (const p of PORT_PATCHES) {
    if (patched.includes(p.from)) {
        patched = patched.split(p.from).join(p.to);
        didPort = true;
    }
}

fs.writeFileSync(PLUGIN, patched);
console.log("Patched. Size:", content.length, "->", patched.length);
if (didActivate) console.log("  [+] Auto-activate + HTTP-enable snippet (re)installed");
if (didPort) console.log("  [+] BASE_PORT 58741 -> 58742 (matches Node MCP server port)");
console.log("Restart Studio. Output should print: [MCP] Auto-activated on plugin load (HTTP enabled)");
