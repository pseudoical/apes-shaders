/**
 * Usage:
 *   $ node ./src/shaders.mjs
 *       - Download the WASM file if needed and extract shaders.
 *   $ node ./src/shaders.mjs --fetch
 *       - Force download the WASM file and extract shaders.
 */

// @ts-check

import fs from "node:fs";
import path from "node:path";

const wasmPath = path.join(import.meta.dirname, "game.wasm");

if (!fs.existsSync(wasmPath) || process.argv[2] === "--fetch") {
    const response = await fetch("https://apes.io/game/260916-28dd180-ls/game.wasm");
    const data = await response.bytes();
    fs.writeFileSync(wasmPath, data);
}

const wasm = fs.readFileSync(wasmPath);

let start = 0x4778C2;
const end = 0x4D8A65;

/**
 * ```text
 * 0x10000           0A 00 00 00 - string size
 * 0x10004 (+4)      61 .. .. 7A - glsl file name
 * 0x1000E (+0x0A)   0A 0A 00 00 - string size
 * 0x10012 (+4)      61 .. .. 7A - glsl source code
 * 0x10A1C (+0x0A0A) .. .. .. .. - repeat
 * 0x711A3                       - end
 * ```
 * @returns {string}
 */
function nextString() {
    const length = wasm.readUInt32LE(start);
    start += 4;

    const string = wasm.toString("utf8", start, start + length);
    start += length;

    return string;
}

const shadersPath = "shaders";

fs.rmSync(shadersPath, { recursive: true, force: true });
fs.mkdirSync(shadersPath, { recursive: true });

for (let i = 0; start !== end; ++i) {
    const fileName = nextString();
    const sourceCode = nextString();

    const id = i.toString().padStart(2, "0");
    const sourcePath = path.join(shadersPath, `${id}-${fileName}`);

    // Write files concurrently for performance.
    fs.promises.writeFile(sourcePath, sourceCode);
}
