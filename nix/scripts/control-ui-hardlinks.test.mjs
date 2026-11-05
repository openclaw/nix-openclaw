import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fixture, patch, load, envFor, restoreEnv, snapshot } from "./patch-openclaw-npm-dist.fixtures.mjs";

function uiFixture(t) {
  const f = fixture(t, "mjs");
  fs.writeFileSync(path.join(f.root, "dist/control-ui-assets-fixture.mjs"), `
async function root(_rootDir, options) { return options; }
async function readPluginControlUiAssets(rootDir, declaration) {
\tconst pluginRoot = await root(rootDir, {
\t\thardlinks: "reject",
\t\tsymlinks: "reject",
\t\tmaxBytes: 4194304
\t});
  return pluginRoot;
}

export { readPluginControlUiAssets };
`);
  fs.writeFileSync(path.join(f.root, "dist/control-ui-plugin-assets-fixture.mjs"), `
function loadPluginManifest(_root, rejectHardlinks) { return rejectHardlinks; }
export function reload(record) { return loadPluginManifest(record.rootDir, true, record.rootDir); }
`);
  return f;
}

function upstreamUiFixture(t) {
  const f = uiFixture(t);
  const assets = path.join(f.dist, "control-ui-assets-fixture.mjs");
  fs.writeFileSync(assets, fs.readFileSync(assets, "utf8")
    .replace("rootDir, declaration)", "rootDir, declaration, options = {})")
    .replace('hardlinks: "reject"', 'hardlinks: options.rejectHardlinks === false ? "allow" : "reject"'));
  fs.writeFileSync(path.join(f.dist, "control-ui-plugin-assets-fixture.mjs"), `
import { t as shouldRejectHardlinkedPluginFiles } from "./${f.policy}";
import { readPluginControlUiAssets as readPluginControlUiAssets } from "./control-ui-assets-fixture.mjs";
function loadPluginManifest(_root, rejectHardlinks) { return rejectHardlinks; }
function createPluginCache() { return {}; }
function withPluginCache(_cache, callback) { return callback(); }
async function snapshotBrowserBuild(record, declaration) {
  return await readPluginControlUiAssets(record.rootDir, declaration, { rejectHardlinks: shouldRejectHardlinkedPluginFiles({
\t\torigin: record.origin,
\t\trootDir: record.rootDir
\t}) });
}
function reload(record) {
\t\t\t\tconst rootDir = record.rootDir;
\t\t\t\tif (!rootDir) throw new Error("plugin is no longer active");
\t\t\t\tconst rejectManifestHardlinks = shouldRejectHardlinkedPluginFiles({
\t\t\t\t\torigin: record.origin,
\t\t\t\t\trootDir
\t\t\t\t});
\t\t\t\tconst loaded = withPluginCache(createPluginCache(), () => loadPluginManifest(rootDir, rejectManifestHardlinks, rootDir));
  return loaded;
}
export { snapshotBrowserBuild, reload };
`);
  return f;
}

test("upstream Control UI policy is preserved and retains Nix-store boundaries", async (t) => {
  const f = upstreamUiFixture(t);
  const before = Object.fromEntries(snapshot(f));
  const result = patch(f);
  assert.equal(result.status, 0, result.stderr);
  const after = Object.fromEntries(snapshot(f));
  for (const name of ["control-ui-assets-fixture.mjs", "control-ui-plugin-assets-fixture.mjs"])
    assert.deepEqual(after[name], before[name]);
  const facts = await load(f, f.dependency);
  const { snapshotBrowserBuild, reload } = await load(f, "control-ui-plugin-assets-fixture.mjs");
  restoreEnv(t);
  for (const rootDir of ["/nix/store/plugin", "/nix/store-other/plugin", "/alias"]) {
    facts.realpaths.set(rootDir, rootDir === "/alias" ? "/tmp/plugin" : rootDir);
    for (const mode of ["0", "1"]) {
      Object.assign(process.env, envFor(mode));
      const record = { rootDir, origin: "config" };
      const allowed = mode === "1" && rootDir === "/nix/store/plugin";
      const options = await snapshotBrowserBuild(record, {});
      assert.equal(options.hardlinks, allowed ? "allow" : "reject");
      assert.equal(options.symlinks, "reject");
      assert.equal(options.maxBytes, 4194304);
      assert.equal(reload(record), !allowed);
    }
  }
});

for (const [from, to] of [
  ['origin: record.origin', 'origin: "bundled"'],
  ['symlinks: "reject"', 'symlinks: "allow"'],
  ['loadPluginManifest(rootDir, rejectManifestHardlinks, rootDir)', 'loadPluginManifest(rootDir, false, rootDir)'],
]) test(`reject altered upstream Control UI policy: ${to}`, (t) => {
  const f = upstreamUiFixture(t);
  for (const name of ["control-ui-assets-fixture.mjs", "control-ui-plugin-assets-fixture.mjs"]) {
    const file = path.join(f.dist, name);
    fs.writeFileSync(file, fs.readFileSync(file, "utf8").replaceAll(from, to));
  }
  const before = snapshot(f);
  assert.notEqual(patch(f).status, 0);
  assert.deepEqual(snapshot(f), before);
});

test("Control UI assets and reload admit only canonical Nix-store hardlinks in Nix mode", async (t) => {
  const f = uiFixture(t);
  const result = patch(f);
  assert.equal(result.status, 0, result.stderr);
  const facts = await load(f, f.dependency);
  const { readPluginControlUiAssets } = await load(f, "control-ui-assets-fixture.mjs");
  const { reload } = await load(f, "control-ui-plugin-assets-fixture.mjs");
  restoreEnv(t);
  for (const [rootDir, canonical, store] of [
    ["/nix/store/plugin", "/nix/store/plugin", true],
    ["/alias", "/nix/store/plugin", true],
    ["/nix/store/escape", "/tmp/plugin", false],
    ["/nix/store-other/plugin", "/nix/store-other/plugin", false],
    ["/tmp/plugin", "/tmp/plugin", false],
  ]) {
    facts.realpaths.set(rootDir, canonical);
    for (const mode of ["0", "1", "true"]) {
      Object.assign(process.env, envFor(mode));
      const allowed = mode === "1" && store;
      const options = await readPluginControlUiAssets(rootDir, {});
      assert.equal(options.hardlinks, allowed ? "allow" : "reject");
      assert.equal(options.symlinks, "reject");
      assert.equal(options.maxBytes, 4194304);
      assert.equal(reload({ rootDir }), !allowed);
    }
  }
});

test("unknown Control UI reload layout fails before writing any patch", (t) => {
  const f = uiFixture(t);
  const file = path.join(f.root, "dist/control-ui-plugin-assets-fixture.mjs");
  fs.writeFileSync(file, fs.readFileSync(file, "utf8").replace("record.rootDir, true, record.rootDir", "record.rootDir, false, record.rootDir"));
  const before = snapshot(f);
  assert.notEqual(patch(f).status, 0);
  assert.deepEqual(snapshot(f), before);
});
