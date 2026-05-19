#!/usr/bin/env node
// Usage: node tools/publish.js
// Required env: ROBLOX_API_KEY, ROBLOX_UNIVERSE_ID, ROBLOX_PLACE_ID
// Optional: PUBLISH_TYPE=Saved|Published (default: Saved)
//
// Get your API key at https://create.roblox.com/dashboard/credentials
// (Asset:Write scope on the target universe).
//
// One-command publisher: wraps `tools/rojo.exe build` + Open Cloud upload so
// `node tools/publish.js` ships the current src/ to the live place.

const fs = require("fs");
const os = require("os");
const path = require("path");
const https = require("https");
const { execSync } = require("child_process");

function die(msg, body) {
    console.error("ERROR: " + msg);
    if (body) console.error(body);
    process.exit(1);
}

const API_KEY = process.env.ROBLOX_API_KEY;
const UNIVERSE_ID = process.env.ROBLOX_UNIVERSE_ID;
const PLACE_ID = process.env.ROBLOX_PLACE_ID;
const PUBLISH_TYPE = process.env.PUBLISH_TYPE || "Saved";

if (!API_KEY) die("ROBLOX_API_KEY env var is required.");
if (!UNIVERSE_ID) die("ROBLOX_UNIVERSE_ID env var is required.");
if (!PLACE_ID) die("ROBLOX_PLACE_ID env var is required.");
if (PUBLISH_TYPE !== "Saved" && PUBLISH_TYPE !== "Published") {
    die(`PUBLISH_TYPE must be "Saved" or "Published" (got "${PUBLISH_TYPE}").`);
}

// Resolve paths relative to repo root (parent of tools/), so this works no
// matter what cwd the user invoked us from.
const REPO_ROOT = path.resolve(__dirname, "..");
const ROJO = path.join(REPO_ROOT, "tools", "rojo.exe");
const PROJECT = path.join(REPO_ROOT, "default.project.json");
// Use the OS temp dir; "/tmp/publish.rbxl" is Linux-only and would fail on Win.
const OUT = path.join(os.tmpdir(), "publish.rbxl");

if (!fs.existsSync(ROJO)) die("rojo.exe not found at: " + ROJO);
if (!fs.existsSync(PROJECT)) die("default.project.json not found at: " + PROJECT);

console.log(`[1/2] Building ${PROJECT} -> ${OUT}`);
try {
    execSync(`"${ROJO}" build "${PROJECT}" -o "${OUT}"`, { stdio: "inherit" });
} catch (e) {
    die("rojo build failed (exit " + (e.status || "?") + ").");
}
if (!fs.existsSync(OUT)) die("Build reported success but output is missing: " + OUT);

const bytes = fs.readFileSync(OUT);
console.log(`      Built ${bytes.length} bytes.`);

console.log(`[2/2] Uploading to universe ${UNIVERSE_ID} place ${PLACE_ID} as ${PUBLISH_TYPE}`);

const req = https.request({
    method: "POST",
    hostname: "apis.roblox.com",
    path: `/universes/v1/${encodeURIComponent(UNIVERSE_ID)}/places/${encodeURIComponent(PLACE_ID)}/versions?versionType=${PUBLISH_TYPE}`,
    headers: {
        "x-api-key": API_KEY,
        "Content-Type": "application/octet-stream",
        "Content-Length": bytes.length,
    },
}, (res) => {
    const chunks = [];
    res.on("data", (c) => chunks.push(c));
    res.on("end", () => {
        const body = Buffer.concat(chunks).toString("utf8");
        if (res.statusCode < 200 || res.statusCode >= 300) {
            die(`Upload failed: HTTP ${res.statusCode}`, body);
        }
        let parsed;
        try { parsed = JSON.parse(body); } catch (_) {
            die("Upload returned non-JSON response.", body);
        }
        if (typeof parsed.versionNumber !== "number") {
            die("Upload response missing versionNumber.", body);
        }
        console.log(`SUCCESS: versionNumber = ${parsed.versionNumber}`);
        process.exit(0);
    });
});

req.on("error", (e) => die("Request error: " + e.message));
req.write(bytes);
req.end();
