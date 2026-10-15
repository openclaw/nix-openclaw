import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const root = process.env.OPENCLAW_PACKAGE_ROOT;
assert.ok(root, "OPENCLAW_PACKAGE_ROOT is required");
assert.ok(process.env.out?.startsWith("/nix/store/"), "fixture output must be in the Nix store");
const dist = path.join(root, "dist");
const files = fs.readdirSync(dist)
  .filter((name) => /\.m?js$/.test(name))
  .filter((name) => fs.readFileSync(path.join(dist, name), "utf8").includes("function readPluginControlUiAssets("));
assert.equal(files.length, 1, "expected one installed Control UI asset reader");
const module = await import(pathToFileURL(path.join(dist, files[0])));
const readAssets = Object.values(module).find((value) => typeof value === "function" && value.name === "readPluginControlUiAssets");
assert.ok(readAssets, "Control UI asset reader is not exported");
fs.mkdirSync(process.env.out, { recursive: true });
const storeRoot = fs.mkdtempSync(path.join(process.env.out, "control-ui-"));
const mutableRoot = fs.mkdtempSync(path.join(os.tmpdir(), "control-ui-"));
const previousMode = process.env.OPENCLAW_NIX_MODE;

try {
  for (const directory of [storeRoot, mutableRoot]) {
    fs.mkdirSync(path.join(directory, "ui"));
    const panel = path.join(directory, "ui/index.js");
    fs.writeFileSync(panel, 'export const panel = "synthetic fixture";\n');
    fs.linkSync(panel, path.join(directory, "duplicate"));
    assert.equal(fs.statSync(panel).nlink, 2);
  }
  process.env.OPENCLAW_NIX_MODE = "1";
  const result = await readAssets(storeRoot, { entry: "ui/index.js" });
  assert.equal(result.assets.get("index.js").body.toString(), 'export const panel = "synthetic fixture";\n');
  await assert.rejects(readAssets(mutableRoot, { entry: "ui/index.js" }), /hardlink/i);
  process.env.OPENCLAW_NIX_MODE = "0";
  await assert.rejects(readAssets(storeRoot, { entry: "ui/index.js" }), /hardlink/i);
  console.log("Control UI: hardlinked Nix-store assets load only in Nix mode; mutable roots stay rejected");
} finally {
  if (previousMode === undefined) delete process.env.OPENCLAW_NIX_MODE;
  else process.env.OPENCLAW_NIX_MODE = previousMode;
  fs.rmSync(storeRoot, { recursive: true, force: true });
  fs.rmSync(mutableRoot, { recursive: true, force: true });
}
