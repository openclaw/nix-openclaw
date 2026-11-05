import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";

const dryRun = process.argv.slice(2);
assert.ok(dryRun.length === 0 || (dryRun.length === 1 && dryRun[0] === "--dry-run"));
const read = (name) => readFileSync(`src/${name}`, "utf8");
const assets = read("plugins/control-ui-assets.ts");
const reload = read("gateway/control-ui-plugin-assets.ts");
const patches = [read("plugins/discovery.ts").includes("function findCandidateBlockIssue(")
  ? process.env.PATCH_NIX_STORE_PLUGIN_OWNERSHIP
  : process.env.PATCH_NIX_STORE_PLUGIN_OWNERSHIP_DIRECT];
if (assets.includes("options.rejectHardlinks")) {
  // OpenClaw 2026.10.10 owns these decisions. Require both callers and the
  // strict reader default before retaining upstream's implementation unchanged.
  const compact = (text) => text.replace(/\s+/g, " ");
  assert.match(compact(assets), /options: \{ rejectHardlinks\?: boolean \} = \{\},? \) \{ const pluginRoot = await root\(rootDir, \{ hardlinks: options.rejectHardlinks === false \? "allow" : "reject", symlinks: "reject",/);
  assert.match(reload, /import \{ shouldRejectHardlinkedPluginFiles \} from "\.\.\/plugins\/hardlink-policy.js";/);
  assert.ok(compact(reload).includes('await readPluginControlUiAssets( record.rootDir, declaration, { rejectHardlinks: shouldRejectHardlinkedPluginFiles({ origin: record.origin, rootDir: record.rootDir, }), }, )'));
  assert.ok(compact(reload).includes('const rejectManifestHardlinks = shouldRejectHardlinkedPluginFiles({ origin: record.origin, rootDir, });'));
  assert.ok(compact(reload).includes('loadPluginManifest(rootDir, rejectManifestHardlinks, rootDir)'));
} else {
  patches.push(process.env.PATCH_NIX_STORE_PLUGIN_CONTROL_UI);
}
for (const patch of patches) {
  assert.ok(patch, "missing source ownership patch");
  const args = ["--batch", "--fuzz=0", "-p1", "-i", patch];
  const probe = spawnSync("patch", ["--dry-run", ...args], { encoding: "utf8" });
  assert.equal(probe.status, 0, probe.stdout + probe.stderr);
}
if (!dryRun.length) {
  for (const patch of patches) {
    const result = spawnSync("patch", ["--batch", "--fuzz=0", "-p1", "-i", patch], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stdout + result.stderr);
  }
}
