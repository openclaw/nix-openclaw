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
const policyFiles = fs.readdirSync(dist)
  .filter((name) => /\.m?js$/.test(name))
  .filter((name) => fs.readFileSync(path.join(dist, name), "utf8").includes("function shouldRejectHardlinkedPluginFiles("));
assert.equal(policyFiles.length, 1, "expected one installed plugin hardlink policy");
const policyModule = await import(pathToFileURL(path.join(dist, policyFiles[0])));
const rejectHardlinks = Object.values(policyModule).find((value) => typeof value === "function" && value.name === "shouldRejectHardlinkedPluginFiles");
assert.ok(rejectHardlinks, "plugin hardlink policy is not exported");
const readGatewayAssets = (rootDir) => readAssets(rootDir, { entry: "ui/index.js" }, {
  rejectHardlinks: rejectHardlinks({ rootDir, origin: "config" }),
});
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
  // Newer upstream readers default to strict admission; the gateway supplies
  // the owning plugin's policy. Legacy readers apply that same policy inside.
  if (fs.readFileSync(path.join(dist, files[0]), "utf8").includes("options.rejectHardlinks")) {
    await assert.rejects(readAssets(storeRoot, { entry: "ui/index.js" }), /hardlink/i);
  }
  assert.equal(rejectHardlinks({ rootDir: storeRoot, origin: "config" }), false);
  const result = await readGatewayAssets(storeRoot);
  assert.equal(result.assets.get("index.js").body.toString(), 'export const panel = "synthetic fixture";\n');
  assert.equal(rejectHardlinks({ rootDir: mutableRoot, origin: "config" }), true);
  await assert.rejects(readGatewayAssets(mutableRoot), /hardlink/i);
  process.env.OPENCLAW_NIX_MODE = "0";
  assert.equal(rejectHardlinks({ rootDir: storeRoot, origin: "config" }), true);
  await assert.rejects(readGatewayAssets(storeRoot), /hardlink/i);
  console.log("Control UI: hardlinked Nix-store assets load only in Nix mode; mutable roots stay rejected");
} finally {
  if (previousMode === undefined) delete process.env.OPENCLAW_NIX_MODE;
  else process.env.OPENCLAW_NIX_MODE = previousMode;
  fs.rmSync(storeRoot, { recursive: true, force: true });
  fs.rmSync(mutableRoot, { recursive: true, force: true });
}
