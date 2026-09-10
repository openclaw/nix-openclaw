import assert from "node:assert/strict";
import fs from "node:fs";
import { createRequire, stripTypeScriptTypes } from "node:module";
import path from "node:path";
import test from "node:test";
import { pathToFileURL } from "node:url";

// Run against the patched source after dependency materialization. The parser
// and path helper come from that source's dependencies, not a second test install.
assert.ok(process.argv[2], "Usage: node ownership.mjs <materialized-openclaw-source>");
const sourceRoot = path.resolve(process.argv[2]);
const require = createRequire(path.join(sourceRoot, "package.json"));
const { parse } = require("acorn");
const { isPathInside } = await import(pathToFileURL(require.resolve("@openclaw/fs-safe/path")));

function declarations(file, names) {
  const source = stripTypeScriptTypes(fs.readFileSync(path.join(sourceRoot, file), "utf8"));
  const ast = parse(source, { ecmaVersion: "latest", sourceType: "module" });
  const selected = new Map();
  for (const statement of ast.body) {
    const node = statement.type === "ExportNamedDeclaration" ? statement.declaration : statement;
    if (node?.type === "FunctionDeclaration" && names.includes(node.id.name))
      selected.set(node.id.name, source.slice(node.start, node.end));
    if (node?.type === "VariableDeclaration")
      for (const declaration of node.declarations)
        if (names.includes(declaration.id.name))
          selected.set(
            declaration.id.name,
            `${node.kind} ${source.slice(declaration.start, declaration.end)};`,
          );
  }
  assert.deepEqual(
    [...selected.keys()].sort(),
    [...names].sort(),
    `Missing owner declaration in ${file}`,
  );
  return [...selected.values()].join("\n");
}

const discovery = declarations("src/plugins/discovery.ts", [
  "currentUid",
  "checkSourceEscapesRoot",
  "checkPathStatAndPermissions",
  "findCandidateBlockIssue",
  "formatCandidateBlockMessage",
  "isUnsafePluginCandidate",
]);
const policySource = stripTypeScriptTypes(
  fs.readFileSync(path.join(sourceRoot, "src/plugins/hardlink-policy.ts"), "utf8"),
);
const policyAst = parse(policySource, { ecmaVersion: "latest", sourceType: "module" });
const policy = policyAst.body
  .filter((node) => node.type !== "ImportDeclaration")
  .map((node) => (node.type === "ExportNamedDeclaration" ? node.declaration : node))
  .map((node) => policySource.slice(node.start, node.end))
  .join("\n");
const nixMode = declarations("src/config/paths.ts", ["resolveIsNixMode"]);
const cached = fs.existsSync(path.join(sourceRoot, "src/plugins/plugin-cache-files.ts"));
const cache = cached
  ? declarations("src/plugins/plugin-cache-files.ts", [
      "pathFacts",
      "pluginCacheRealpathSync",
      "pluginCacheStatSync",
      "refreshPluginCacheStat",
    ])
  : "";

function owner() {
  const realpaths = new Map();
  const stats = new Map();
  const roots = new Map();
  const realpath = (file) => {
    if (!realpaths.has(file)) throw new Error("fixture path missing");
    return realpaths.get(file);
  };
  const stat = (file) => {
    if (!stats.has(file)) throw new Error("fixture stat missing");
    return stats.get(file);
  };
  const fileSystem = {
    realpathSync: Object.assign(realpath, { native: realpath }),
    statSync: stat,
    chmodSync: (file, mode) => stats.set(file, { ...stat(file), mode }),
  };
  const helpers = {
    fs: fileSystem,
    path,
    process: { platform: "linux", env: {}, getuid: () => 1000 },
    isPathInside,
    formatPosixMode: (mode) => mode.toString(8),
    getPluginCacheRoot: (dir) => {
      if (!roots.has(dir)) roots.set(dir, { paths: new Map() });
      return roots.get(dir);
    },
    safeRealpathSync: (file) => realpaths.get(file) ?? null,
    safeStatSync: (file) => stats.get(file) ?? null,
  };
  const boundary = new Function(
    ...Object.keys(helpers),
    `
    ${nixMode}
    ${cache}
    ${policy}
    ${discovery}
    return { isUnsafePluginCandidate, shouldRejectHardlinkedPluginFiles };
  `,
  )(...Object.values(helpers));
  return { ...boundary, realpaths, stats };
}

for (const [label, rootDir, canonical, mode, expected] of [
  ["immutable store", "/nix/store/pkg", "/nix/store/pkg", "1", false],
  ["store mode off", "/nix/store/pkg", "/nix/store/pkg", "0", true],
  ["mode alone", "/tmp/plugin", "/tmp/plugin", "1", true],
  ["store prefix collision", "/nix/store-other/pkg", "/nix/store-other/pkg", "1", true],
  ["alias into store", "/tmp/plugin", "/nix/store/pkg", "1", false],
  ["alias outside store", "/nix/store/pkg", "/tmp/plugin", "1", true],
]) {
  test(`${label}: ownership and hardlink policy preserve the trust boundary`, () => {
    const o = owner();
    o.realpaths.set(rootDir, canonical);
    o.realpaths.set(`${rootDir}/entry.js`, `${canonical}/entry.js`);
    o.stats.set(rootDir, { uid: 3000, mode: 0o755 });
    o.stats.set(`${rootDir}/entry.js`, { uid: 3000, mode: 0o644 });
    const params = {
      rootDir,
      source: `${rootDir}/entry.js`,
      origin: "config",
      ownershipUid: 1000,
      env: { OPENCLAW_NIX_MODE: mode },
      realpathCache: new Map(),
      diagnostics: [],
    };
    assert.equal(o.isUnsafePluginCandidate(params), expected);
    assert.equal(o.shouldRejectHardlinkedPluginFiles(params), expected);
    if (expected) assert.match(params.diagnostics[0].message, /suspicious ownership/);
    else assert.deepEqual(params.diagnostics, []);
  });
}

for (const [label, target, mode, escape, reason] of [
  ["writable root", "root", 0o777, false, /world-writable/],
  ["writable entry", "entry", 0o666, false, /world-writable/],
  ["entry escape", "entry", 0o644, true, /escapes plugin root/],
  ["missing entry", "missing", 0o644, false, /cannot stat/],
]) {
  test(`${label}: Nix ownership exemption does not bypass other discovery gates`, () => {
    const o = owner();
    const rootDir = "/nix/store/pkg",
      source = `${rootDir}/entry.js`;
    o.realpaths.set(rootDir, rootDir);
    o.realpaths.set(source, escape ? "/tmp/outside.js" : source);
    o.stats.set(rootDir, { uid: 3000, mode: target === "root" ? mode : 0o755 });
    if (target !== "missing")
      o.stats.set(source, { uid: 3000, mode: target === "entry" ? mode : 0o644 });
    const diagnostics = [];
    assert.equal(
      o.isUnsafePluginCandidate({
        rootDir,
        source,
        origin: "config",
        ownershipUid: 1000,
        env: { OPENCLAW_NIX_MODE: "1" },
        realpathCache: new Map(),
        diagnostics,
      }),
      true,
    );
    assert.match(diagnostics[0].message, reason);
  });
}

for (const [label, uid, origin] of [
  ["runtime owner", 1000, "config"],
  ["root owner", 0, "config"],
  ["bundled owner", 3000, "bundled"],
]) {
  test(`${label}: ordinary accepted ownership remains accepted outside the store`, () => {
    const o = owner();
    const rootDir = "/tmp/plugin";
    o.realpaths.set(rootDir, rootDir);
    o.stats.set(rootDir, { uid, mode: 0o755 });
    const diagnostics = [];
    assert.equal(
      o.isUnsafePluginCandidate({
        rootDir,
        source: rootDir,
        origin,
        ownershipUid: 1000,
        env: {},
        realpathCache: new Map(),
        diagnostics,
      }),
      false,
    );
    assert.deepEqual(diagnostics, []);
  });
}
