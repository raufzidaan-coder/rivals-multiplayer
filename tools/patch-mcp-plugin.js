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
// The injected Lua block scans 58741..58745 at activation time so the plugin
// stays in sync no matter which port the Node MCP server picks on a given boot.
// A live boshyxd MCP returns SOME HTTP response (404 for /) so pcall succeeds;
// a dead localhost port refuses immediately (TCP RST), so the scan is fast.
const INSERT = `
task.spawn(function()
	task.wait(0.5)
	local ok, err = pcall(function()
		local HttpService = game:GetService("HttpService")
		pcall(function() HttpService.HttpEnabled = true end)

		local foundPort
		for port = 58741, 58745 do
			local probeOk = pcall(function()
				HttpService:RequestAsync({ Url = "http://localhost:" .. port .. "/", Method = "GET" })
			end)
			if probeOk then
				foundPort = port
				break
			end
		end

		if foundPort then
			local elements = UI.getElements()
			if elements and elements.urlInput then
				elements.urlInput.Text = "http://localhost:" .. foundPort
			end
		end

		Communication.activatePlugin(State.getActiveTabIndex() or 1)
		print("[MCP] Auto-activated on plugin load (HTTP enabled" .. (foundPort and (", port " .. foundPort) or ", no listener found") .. ")")
	end)
	if not ok then warn("[MCP] Auto-activate failed: " .. tostring(err)) end
end)`;

// Match any previously-installed version of the auto-activate block so we can
// replace it in place (rather than skip-when-MARKER-present).
const PREV_BLOCK_RE = /\r?\ntask\.spawn\(function\(\)\s+task\.wait\(0\.5\)[\s\S]*?Auto-activate[d]? [^"]*"\)\s+end\)\s+if not ok then warn\([^)]*\)[^)]*\) end\s+end\)/;

// Port reconciliation: the Node MCP server's port floats between runs (58741 is
// the historical default; npm cache rebuilds sometimes bump it). We detect what's
// listening via `netstat`, then patch BOTH BASE_PORT and the UI default URL —
// activatePlugin reads the URL text input and overrides conn.port from it, so
// BASE_PORT alone isn't enough.
function detectPort() {
    const cliFlag = process.argv.find(a => a.startsWith("--port="));
    if (cliFlag) return parseInt(cliFlag.split("=")[1], 10);

    const { execSync } = require("child_process");
    try {
        const out = execSync("netstat -ano", { encoding: "utf8" });
        const candidates = [];
        for (const line of out.split(/\r?\n/)) {
            const m = line.match(/LISTENING.*?:5874([0-9])\b/);
            if (m) candidates.push(58740 + parseInt(m[1], 10));
        }
        if (candidates.length === 0) {
            console.warn("[detectPort] No listener on 5874x — falling back to 58741");
            return 58741;
        }
        return Math.min(...candidates);
    } catch (e) {
        console.warn("[detectPort] netstat failed:", e.message, "— falling back to 58741");
        return 58741;
    }
}

const TARGET_PORT = detectPort();
console.log(`[detectPort] Targeting port ${TARGET_PORT}`);

// Match any existing BASE_PORT / urlInput.Text in the 5874x range so we can
// re-target whether the file currently says 58741 or 58742.
const PORT_PATCHES = [
    { fromRe: /BASE_PORT = 5874\d/, to: `BASE_PORT = ${TARGET_PORT}` },
    { fromRe: /urlInput\.Text = "http:\/\/localhost:5874\d"/, to: `urlInput.Text = "http://localhost:${TARGET_PORT}"` },
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
    if (p.fromRe.test(patched)) {
        const before = patched;
        patched = patched.replace(p.fromRe, p.to);
        if (patched !== before) {
            didPort = true;
        }
    }
}

fs.writeFileSync(PLUGIN, patched);
console.log("Patched. Size:", content.length, "->", patched.length);
if (didActivate) console.log("  [+] Auto-activate + HTTP-enable snippet (re)installed");
if (didPort) console.log(`  [+] Port references retargeted to ${TARGET_PORT}`);
console.log("Restart Studio. Output should print: [MCP] Auto-activated on plugin load (HTTP enabled)");
