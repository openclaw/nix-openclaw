import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import os from "node:os";
import path from "node:path";
import vm from "node:vm";

const root = fs.mkdtempSync(path.join(os.tmpdir(), "openclaw-source-patch-"));
try {
  for (const name of ["plugins/discovery.ts", "plugins/hardlink-policy.ts", "plugins/control-ui-assets.ts", "gateway/control-ui-plugin-assets.ts"]) {
    const target = path.join(root, "src", name);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, fs.readFileSync(path.join(process.env.OPENCLAW_SOURCE, "src", name)));
  }
  const discoveryPath = path.join(root, "src/plugins/discovery.ts");
  const originalDiscovery = fs.readFileSync(discoveryPath, "utf8");
  const legacyDiscovery = originalDiscovery.includes("function findCandidateBlockIssue(");
  const ownershipPatch = legacyDiscovery ? process.env.OWNERSHIP_PATCH : process.env.OWNERSHIP_DIRECT_PATCH;
  const availabilityImport = 'import { inspectPluginLoadPath, pluginPathFailureDiagnostic } from "./discovery-availability.js";\n';
  const beforeAvailabilityImport = originalDiscovery.replace(availabilityImport, "");
  const variants = legacyDiscovery ? ["", availabilityImport].map((addedImport) => beforeAvailabilityImport.replace(
      'import type { PluginCandidate, PluginDiscoveryResult }',
      `${addedImport}import type { PluginCandidate, PluginDiscoveryResult }`,
    )) : [originalDiscovery];
  for (const variant of variants) {
    fs.writeFileSync(discoveryPath, variant);
    const probe = spawnSync("patch", ["--dry-run", "--batch", "--fuzz=0", "-p1", "-i", ownershipPatch], { cwd: root, encoding: "utf8" });
    assert.equal(probe.status, 0, probe.stdout + probe.stderr);
  }
  fs.writeFileSync(discoveryPath, originalDiscovery);
  const patched = spawnSync("patch", ["--batch", "--fuzz=0", "-p1", "-i", ownershipPatch], { cwd: root, encoding: "utf8" });
  assert.equal(patched.status, 0, patched.stdout + patched.stderr);
  let policy = fs.readFileSync(path.join(root, "src/plugins/hardlink-policy.ts"), "utf8");
  policy = policy.replace(/^import .*;\n/gm, "").replaceAll("export function", "function");
  const discovery = fs.readFileSync(path.join(root, "src/plugins/discovery.ts"), "utf8");
  const permissions = discovery.match(/^function checkPathStatAndPermissions\([\s\S]*?^\}$/m)?.[0];
  const candidate = legacyDiscovery
    ? discovery.match(/^function findCandidateBlockIssue\([\s\S]*?^\}$/m)?.[0]
    : `function findCandidateBlockIssue(params) {
        const resolved = params.source, resolvedRoot = params.rootDir;
        const ownershipUid = params.ownershipUid, env = params.env;
        return ${discovery.match(/const issue =\s*([\s\S]*?);\n/)?.[1]};
      }`;
  assert.ok(permissions && candidate, "expected source ownership checks");
  const code = stripTypeScriptTypes([policy, permissions, candidate].join("\n"));
  let stat = { mode: 0o555, uid: 30001 };
  const realpaths = new Map();
  const testEnv = {};
  let assetOptions;
  const context = vm.createContext({
    path, Buffer, process: { platform: "linux", env: testEnv },
    resolveIsNixMode: (env = testEnv) => env.OPENCLAW_NIX_MODE === "1",
    pluginCacheRealpathSync: (file) => realpaths.get(file) ?? file,
    pluginCacheStatSync: () => stat,
    currentUid: (uid) => uid,
    formatPosixMode: (mode) => mode.toString(8),
    checkSourceEscapesRoot: () => null,
    fs: { chmodSync: () => { throw new Error("fixture cannot chmod"); } },
  });
  vm.runInContext(code, context);
  const params = (rootDir, nix) => ({ rootDir, source: `${rootDir}/index.js`, origin: "config", uid: 1000, ownershipUid: 1000, env: { OPENCLAW_NIX_MODE: nix } });
  const issueText = (params) => {
    const issue = context.findCandidateBlockIssue(params);
    return issue.reason ?? issue.message;
  };
  assert.equal(context.findCandidateBlockIssue(params("/nix/store/plugin", "1")), null);
  assert.match(issueText(params("/nix/store/plugin", "0")), /path_suspicious_ownership|suspicious ownership/);
  assert.match(issueText(params("/tmp/plugin", "1")), /path_suspicious_ownership|suspicious ownership/);
  assert.match(issueText(params("/nix/store-other/plugin", "1")), /path_suspicious_ownership|suspicious ownership/);
  realpaths.set("/nix/store/escaped", "/tmp/plugin");
  assert.match(issueText(params("/nix/store/escaped", "1")), /path_suspicious_ownership|suspicious ownership/);
  stat = { mode: 0o777, uid: 30001 };
  assert.match(issueText(params("/nix/store/plugin", "1")), /path_world_writable|world-writable path/);
  stat = null;
  assert.match(issueText(params("/nix/store/plugin", "1")), /path_stat_failed|cannot stat path/);
  assert.equal(context.shouldRejectHardlinkedPluginFiles(params("/nix/store/plugin", "1")), false);
  assert.equal(context.shouldRejectHardlinkedPluginFiles(params("/tmp/plugin", "1")), true);
  const assetsSource = fs.readFileSync(path.join(root, "src/plugins/control-ui-assets.ts"), "utf8");
  // Use the pinned module's constants so upstream renames cannot stale the harness.
  const assetConstants = [...assetsSource.matchAll(/^(?:export )?const [A-Z][A-Z0-9_]* = .+;$/gm)]
    .map(([declaration]) => declaration.replace("export ", "")).join("\n");
  assert.ok(assetConstants, "expected source Control UI asset limits");
  vm.runInContext(stripTypeScriptTypes(assetConstants), context);
  context.root = async (rootDir, options) => {
    assetOptions = options;
    return { rootReal: rootDir, readBytes: async () => Buffer.from("test") };
  };
  context.walkRootDirectory = async function* (_root, _directory, options) {
    assert.equal(options.maxEntries, 128);
    assert.equal(options.limitBehavior, "throw");
    yield { kind: "file", relativePath: "ui/index.js" };
  };
  const assetPath = assetsSource.match(/^export function isPluginControlUiAssetPath\([\s\S]*?^\}$/m)?.[0];
  if (assetPath) vm.runInContext(stripTypeScriptTypes(assetPath.replace("export function", "function")), context);
  vm.runInContext(stripTypeScriptTypes(assetsSource.slice(assetsSource.indexOf("export async function")).replace("export async function", "async function")), context);
  const reloadSource = fs.readFileSync(path.join(root, "src/gateway/control-ui-plugin-assets.ts"), "utf8");
  const reloadCall = reloadSource.match(/loadPluginManifest\(\n[\s\S]*?\n          \)/)?.[0];
  assert.ok(reloadCall, "expected patched manifest reload call");
  context.loadPluginManifest = (_rootDir, rejectHardlinks) => rejectHardlinks;
  vm.runInContext(stripTypeScriptTypes(`function reload(record: { rootDir: string }) { return ${reloadCall}; }`), context);
  for (const rootDir of ["/nix/store/plugin", "/tmp/plugin", "/nix/store/escaped"]) {
    for (const mode of ["1", "0"]) {
      testEnv.OPENCLAW_NIX_MODE = mode;
      const allow = rootDir === "/nix/store/plugin" && mode === "1";
      await context.readPluginControlUiAssets(rootDir, { entry: "ui/index.js" });
      assert.equal(assetOptions.hardlinks, allow ? "allow" : "reject");
      assert.equal(assetOptions.symlinks, "reject");
      assert.equal(assetOptions.maxBytes, 4 * 1024 * 1024);
      assert.equal(context.reload({ rootDir }), !allow);
    }
  }
  console.log("pinned source patch application, caller environment, ownership and path guards: PASS");
} finally {
  fs.rmSync(root, { recursive: true, force: true });
}
