import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import {
  fixture, install, resolveFrom, put, dependency, snapshot, legacyNames, acpxAliases, pluginInstaller,
} from "./openclaw-gateway-npm-install.fixtures.mjs";

for (const layout of ["mixed", "nested", "hoisted"]) {
  test(`${layout}: output retains ESM and CJS dependency versions after build removal`, (t) => {
    const f = fixture(t, layout);
    install(f);
    t.diagnostic("installer exit=0; build input removed; fresh output-only execution");
    const result = f.run(process.execPath, [path.join(f.root, "dist/index.js")]);
    assert.equal(result.status, 0, result.stderr);
    const loaded = JSON.parse(result.stdout);
    assert.deepEqual(
      [loaded.direct.marker, loaded.nested.marker, loaded.scoped.marker, loaded.cjs.marker],
      [7, 2, 3, 7],
    );
    for (const file of [
      loaded.direct.file,
      loaded.nested.file,
      loaded.scoped.file,
      loaded.cjs.file,
      loaded.locatePath,
      loaded.entry,
    ])
      assert.ok(file.startsWith(`${f.out}/lib/node_modules/`), file);
    assert.equal(fs.readlinkSync(f.root), "node_modules/openclaw");
    assert.equal(fs.realpathSync(f.root), path.join(f.out, "lib/node_modules/openclaw"));
    assert.equal(fs.readFileSync(path.join(f.root, "patch-seen"), "utf8"), "patched");
    assert.equal(fs.readFileSync(path.join(f.out, "lib/node_modules/.fixture-marker"), "utf8"), "retained");
    assert.equal(fs.statSync(path.join(f.out, "lib/node_modules/.bin/marker")).mode & 0o777, 0o755);
    assert.equal(fs.existsSync(path.join(f.out, "lib/node_modules/omitted-platform-addon")), false);
    assert.equal(fs.existsSync(path.join(f.root, "node_modules")), layout !== "hoisted");
    for (const rel of [
      "extensions/memory-core/openclaw.plugin.json",
      "dist-runtime/extensions/memory-core/openclaw.plugin.json",
    ])
      assert.equal(fs.readFileSync(path.join(f.root, rel), "utf8"), '{"id":"memory-core"}');
    assert.deepEqual(fs.readFileSync(path.join(f.out, "wrapper-args"), "utf8").trim().split("\n"), [
      process.execPath,
      path.join(f.out, "bin/openclaw"),
      "--add-flags",
      path.join(f.root, "dist/index.js"),
      "--prefix",
      "PATH",
      ":",
      path.dirname(process.execPath),
      "--set-default",
      "OPENCLAW_NIX_MODE",
      "1",
      "--set-default",
      "OPENCLAW_DISABLE_PERSISTED_PLUGIN_REGISTRY",
      "1",
    ]);
  });
}

for (const ext of ["js", "mjs"]) {
  test(`${ext}: staged relative imports retain one canonical module graph`, (t) => {
    const f = fixture(t);
    const entry = "extensions/memory-core/provider-policy-api.js";
    put(f.packageRoot, `dist/${entry}`, `export { state } from "../../state.${ext}";\n`);
    put(f.packageRoot, `dist/state.${ext}`, `export { state } from "./nested/state.${ext}";\n`);
    put(f.packageRoot, `dist/nested/state.${ext}`, "export const state = {};\n");
    const original = snapshot(path.join(f.packageRoot, "dist"));
    install(f);
    const copied = snapshot(path.join(f.root, "dist"));
    for (const name of Object.keys(copied)) if (name.startsWith("extensions/acpx/")) delete copied[name];
    assert.deepEqual(copied, original);
    const code = `
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";
const [root, entry] = process.argv.slice(1);
const staged = await import(pathToFileURL(root + "/dist-runtime/" + entry));
const direct = await import(pathToFileURL(root + "/dist/" + entry));
assert.strictEqual(staged.state, direct.state);
`;
    const loaded = f.node(code, f.root, entry);
    assert.equal(loaded.status, 0, loaded.stderr);
    fs.unlinkSync(path.join(f.root, `dist/nested/state.${ext}`));
    const missing = f.node(code, f.root, entry);
    assert.notEqual(missing.status, 0);
    assert.match(missing.stderr, /ERR_MODULE_NOT_FOUND/);
  });
}

test("bundled ACPX stays physically contained with its complete built closure", (t) => {
  const f = fixture(t);
  const original = snapshot(f.acpx);
  install(f);
  for (const spelling of ["dist-runtime", "dist"]) {
    const bundled = fs.realpathSync(path.join(f.root, spelling, "extensions"));
    const acpx = path.join(bundled, "acpx");
    assert.ok(fs.realpathSync(acpx).startsWith(`${bundled}/`), "ACPX package directory escapes bundled root");
    assert.deepEqual(snapshot(acpx), original);
  }
  assert.deepEqual(snapshot(f.acpx), original);
  fs.rmSync(f.acpx, { recursive: true });
  const result = f.node(
    `
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";
for (const dir of ["dist", "dist-runtime"]) for (const name of JSON.parse(process.argv[2])) {
  const { default: dependency } = await import(pathToFileURL(process.argv[1] + "/" + dir + "/extensions/acpx/" + name));
  assert.equal(dependency.marker, 9);
  assert.ok(dependency.file.startsWith(process.argv[3] + "/"));
}
`,
    f.root,
    JSON.stringify(acpxAliases),
    f.out,
  );
  assert.equal(result.status, 0, result.stderr);
});

test("dangling hoisted sibling links are rejected before wrapping", (t) => {
  const f = fixture(t);
  fs.symlinkSync("absent", path.join(f.modules, "p-limit/broken"));
  const result = f.install();
  assert.equal(result.status, 1, result.stdout + result.stderr);
  assert.match(result.stderr, /dangling symlinks found/);
  assert.match(result.stderr, /p-limit\/broken/);
  assert.equal(fs.existsSync(path.join(f.out, "wrapper-args")), false);
});

for (const placement of ["local", "hoisted", "nested-only"]) {
  test(`legacy dependency aliases preserve ${placement} resolution`, (t) => {
    const f = fixture(t);
    for (const name of legacyNames) {
      dependency(path.join(f.packageRoot, "node_modules/deep/node_modules"), name, 2);
      if (placement !== "nested-only") dependency(f.modules, name, 7);
      if (placement === "local") dependency(path.join(f.packageRoot, "node_modules"), name, 1);
    }
    install(f);
    const result = resolveFrom(f, path.join(fs.realpathSync(f.root), "package.json"), legacyNames);
    assert.equal(result.status, 0, result.stderr);
    const resolved = JSON.parse(result.stdout);
    assert.deepEqual(
      resolved.map((item) => item.marker),
      legacyNames.map(() => ({ local: 1, hoisted: 7, "nested-only": 2 })[placement]),
    );
    for (const item of resolved) assert.ok(item.file.startsWith(`${f.out}/`), item.file);
  });
}

for (const layout of ["npm", "source"])
  for (const missing of [null, ...legacyNames]) {
    test(`${layout} form-data resolves its own dependencies: ${missing ?? "conflicting versions"}`, (t) => {
      const f = fixture(t, layout === "source" ? "nested" : "mixed");
      const local = path.join(f.packageRoot, "node_modules");
      const form = dependency(
        layout === "source" ? local : f.modules,
        "form-data",
        4,
        'module.exports = ["hasown", "combined-stream"].map(name => require(name));\n',
      );
      for (const name of legacyNames) {
        dependency(path.join(form, "node_modules"), name, 2);
        dependency(local, name, 7);
      }
      if (missing) {
        fs.rmSync(path.join(form, "node_modules", missing), { recursive: true });
        if (layout === "source") fs.rmSync(path.join(local, missing), { recursive: true });
      }
      install(f);
      if (layout === "source") {
        const physical = fs.realpathSync(f.root);
        fs.unlinkSync(f.root);
        fs.renameSync(physical, f.root);
        fs.rmSync(path.join(f.out, "lib/node_modules"), { recursive: true });
      }
      const result = f.check();
      assert.equal(result.status, missing ? 1 : 0, result.stdout + result.stderr);
      if (missing) assert.ok(result.stderr.includes(missing), result.stderr);
      else {
        assert.match(result.stdout, /openclaw package contents: ok/);
        const modules = layout === "source" ? path.join(f.root, "node_modules") : path.join(f.out, "lib/node_modules");
        const loaded = resolveFrom(f, path.join(modules, "form-data/package.json"), legacyNames);
        assert.equal(loaded.status, 0, loaded.stderr);
        assert.deepEqual(
          JSON.parse(loaded.stdout).map((item) => item.marker),
          [2, 2],
        );
      }
    });
  }

test("hoisted form-data is checked without package-local node_modules", (t) => {
  const f = fixture(t, "hoisted");
  const form = dependency(f.modules, "form-data", 4);
  dependency(path.join(form, "node_modules"), "combined-stream", 2);
  install(f);
  assert.equal(fs.existsSync(path.join(f.root, "node_modules")), false);
  const result = f.check();
  assert.equal(result.status, 1, result.stdout + result.stderr);
  assert.match(result.stderr, /Cannot find module 'hasown'/);
});

test("runtime plugin peer validation accepts the internal package alias", (t) => {
  const f = fixture(t);
  install(f);
  const plugin = path.join(f.temp, "plugin");
  const peerOut = path.join(f.temp, "plugin-out");
  put(
    plugin,
    "package.json",
    JSON.stringify({
      name: "@fixture/peer",
      version: "1.0.0",
      peerDependencies: { openclaw: "*" },
      openclaw: { runtimeExtensions: ["dist/index.js"] },
    }),
  );
  put(plugin, "openclaw.plugin.json", '{"id":"peer-fixture"}');
  put(plugin, "dist/index.js", "export default {};\n");
  const entries = put(f.temp, "runtime-entries", "dist/index.js\n");
  const bundled = put(f.temp, "bundled-roots");
  const result = f.run(process.execPath, [pluginInstaller], {
    cwd: plugin,
    env: {
      ...f.env,
      out: peerOut,
      OPENCLAW_GATEWAY_PACKAGE: f.out,
      OPENCLAW_RUNTIME_PLUGIN_ID: "peer-fixture",
      OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE: "none",
      OPENCLAW_RUNTIME_PLUGIN_RUNTIME_ENTRIES_FILE: entries,
      OPENCLAW_RUNTIME_PLUGIN_BUNDLED_PACKAGE_ROOTS_FILE: bundled,
    },
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.equal(fs.realpathSync(path.join(peerOut, "node_modules/openclaw")), fs.realpathSync(f.root));
});
