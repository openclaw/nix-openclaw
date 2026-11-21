import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const runtimeRoot = process.argv[2];
assert.ok(runtimeRoot, "The selected Node runtime package path is required");
assert.equal(fs.realpathSync(path.join(runtimeRoot, "bin/node")), fs.realpathSync(process.execPath));
const [major, minor, patch] = process.versions.node.split(".").map(Number);
assert.ok(
  major === 24 && (minor > 22 || (minor === 22 && patch >= 1)),
  `OpenClaw requires Node >=24.22.1 <25; got ${process.versions.node}`,
);
assert.match(execFileSync(path.join(runtimeRoot, "bin/npm"), ["--version"], { encoding: "utf8" }).trim(), /^\d+\.\d+\.\d+$/);
console.log(`OpenClaw Node runtime: ${process.versions.node}; npm available`);
