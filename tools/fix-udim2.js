#!/usr/bin/env node
// Replaces UDim2.new(X, 0, Y, 0) -> UDim2.fromScale(X, Y) and
//          UDim2.new(0, X, 0, Y) -> UDim2.fromOffset(X, Y)
// across src/. Mechanical, idempotent.

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..", "src");
const files = [];
function walk(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
        const p = path.join(d, e.name);
        if (e.isDirectory()) walk(p);
        else if (p.endsWith(".luau") || p.endsWith(".lua")) files.push(p);
    }
}
walk(root);

// Match X and Y as numbers, function calls, or simple expressions (anything not containing a top-level comma).
// We only collapse calls where 2nd and 4th args are literal 0.
const num = String.raw`[\w.\-+*/()\s]+?`;

// Conservative: only collapse when 2nd and 4th args are literal "0" (no surrounding context).
const scaleRe = new RegExp(String.raw`UDim2\.new\((` + num + String.raw`),\s*0,\s*(` + num + String.raw`),\s*0\)`, "g");
const offsetRe = new RegExp(String.raw`UDim2\.new\(0,\s*(` + num + String.raw`),\s*0,\s*(` + num + String.raw`)\)`, "g");

let totalScale = 0, totalOffset = 0;
for (const file of files) {
    let src = fs.readFileSync(file, "utf8");
    const before = src;

    src = src.replace(scaleRe, (m, x, y) => {
        totalScale++;
        return `UDim2.fromScale(${x.trim()}, ${y.trim()})`;
    });
    src = src.replace(offsetRe, (m, x, y) => {
        totalOffset++;
        return `UDim2.fromOffset(${x.trim()}, ${y.trim()})`;
    });

    if (src !== before) {
        fs.writeFileSync(file, src);
        console.log(`updated ${path.relative(path.dirname(root), file)}`);
    }
}

console.log(`\nfromScale: ${totalScale}, fromOffset: ${totalOffset}, total: ${totalScale + totalOffset}`);
