#!/usr/bin/env node
// Downloads stylua + selene binaries to tools/ alongside rojo.exe.
// Pinned versions per POWER_USER.md §2.

const fs = require("fs");
const path = require("path");
const https = require("https");
const { execSync } = require("child_process");

const TOOLS = path.join(__dirname);

const RELEASES = [
    {
        name: "stylua",
        version: "2.5.2",
        url: "https://github.com/JohnnyMorganz/StyLua/releases/download/v2.5.2/stylua-windows-x86_64.zip",
        bin: "stylua.exe",
    },
    {
        name: "selene",
        version: "0.30.1",
        url: "https://github.com/Kampfkarren/selene/releases/download/0.30.1/selene-0.30.1-windows.zip",
        bin: "selene.exe",
    },
];

function download(url, dest) {
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(dest);
        const get = (u) => https.get(u, (res) => {
            if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
                return get(res.headers.location);
            }
            if (res.statusCode !== 200) {
                return reject(new Error("HTTP " + res.statusCode + " for " + u));
            }
            res.pipe(file);
            file.on("finish", () => file.close(resolve));
        }).on("error", reject);
        get(url);
    });
}

(async () => {
    for (const r of RELEASES) {
        const binPath = path.join(TOOLS, r.bin);
        if (fs.existsSync(binPath)) {
            console.log(`[skip] ${r.bin} already present`);
            continue;
        }
        const zip = path.join(TOOLS, `${r.name}.zip`);
        console.log(`[download] ${r.name} ${r.version} -> ${zip}`);
        await download(r.url, zip);
        console.log(`[extract] ${zip}`);
        // Use PowerShell's Expand-Archive (always available on Windows)
        execSync(`powershell -NoProfile -Command "Expand-Archive -Path '${zip}' -DestinationPath '${TOOLS}' -Force"`, { stdio: "inherit" });
        fs.unlinkSync(zip);
        if (!fs.existsSync(binPath)) {
            console.error(`[ERR] ${r.bin} not present after extract`);
            process.exit(1);
        }
        const stat = fs.statSync(binPath);
        console.log(`[ok] ${r.bin} (${stat.size} bytes)`);
    }
    console.log("\nDone. Verify:");
    console.log("  tools/stylua.exe --version");
    console.log("  tools/selene.exe --version");
})().catch(e => { console.error(e); process.exit(1); });
