import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const installer = path.join(import.meta.dirname, "gateway-install.sh");

function fixture(t, version) {
  const temp = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "gateway-install-")));
  t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
  const build = path.join(temp, "build");
  const out = path.join(temp, "out");
  const root = path.join(out, "lib/openclaw");
  const away = path.join(temp, "away");
  const home = path.join(temp, "home");
  for (const dir of [build, away, home]) fs.mkdirSync(dir);
  function put(name, content) {
    const file = path.join(build, name);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, content);
    return file;
  }
  const helperRequired = version === "2026.9.3";
  put(
    "package.json",
    JSON.stringify({
      name: "openclaw",
      version,
      type: "module",
      bin: { openclaw: "openclaw.mjs" },
      exports: { "./cli-entry": "./openclaw.mjs" },
      files: ["openclaw.mjs", ...(helperRequired ? ["node-version.mjs"] : []), "dist/"],
    }),
  );
  const launcher = put(
    "openclaw.mjs",
    helperRequired
      ? 'export { version } from "./node-version.mjs";\n'
      : `export const version = ${JSON.stringify(version)};\n`,
  );
  fs.chmodSync(launcher, 0o755);
  if (helperRequired)
    put("node-version.mjs", `export const version = ${JSON.stringify(version)};\n`);
  put("dist/index.js", 'console.log("fixture dist entry");\n');
  put("dist-runtime/entry.js", "export {};\n");
  fs.mkdirSync(path.join(build, "node_modules/.pnpm"), { recursive: true });
  const setup = path.join(temp, "setup.sh");
  fs.writeFileSync(setup, 'makeWrapper() { printf "%s\\n" "$@" > "$out/wrapper-args"; }\n');
  const env = {
    PATH: `${path.dirname(process.execPath)}:${process.env.PATH}`,
    HOME: home,
    TMPDIR: home,
    NODE_DISABLE_COMPILE_CACHE: "1",
  };
  const run = (command, args, options = {}) =>
    spawnSync(command, args, { cwd: away, env, encoding: "utf8", timeout: 10000, ...options });
  return {
    build,
    out,
    root,
    away,
    put,
    run,
    install: () =>
      run("sh", [installer], {
        cwd: build,
        env: {
          ...env,
          out,
          NODE_BIN: process.execPath,
          STDENV_SETUP: setup,
          NIX_BUILD_TOP: temp,
          OPENCLAW_BUILD_ROOT_SH: path.join(import.meta.dirname, "build-root.sh"),
          COPY_GATEWAY_WORKSPACES_MJS: path.join(
            import.meta.dirname,
            "copy-gateway-workspaces.mjs",
          ),
        },
      }),
  };
}

for (const version of ["2026.7.1", "2026.9.3"]) {
  test(`${version}: installed CLI export survives removal of the build tree`, (t) => {
    const f = fixture(t, version);
    const installed = f.install();
    assert.equal(installed.status, 0, installed.stdout + installed.stderr);
    fs.rmSync(f.build, { recursive: true });
    fs.mkdirSync(path.join(f.away, "node_modules"));
    fs.symlinkSync(f.root, path.join(f.away, "node_modules/openclaw"));
    const loaded = f.run(process.execPath, [
      "--input-type=module",
      "-e",
      'import { version } from "openclaw/cli-entry"; console.log(version);',
    ]);
    assert.equal(loaded.status, 0, loaded.stderr);
    assert.equal(loaded.stdout.trim(), version);
    assert.ok(fs.statSync(path.join(f.root, "openclaw.mjs")).mode & 0o111);
    const wrapperArgs = fs
      .readFileSync(path.join(f.out, "wrapper-args"), "utf8")
      .trim()
      .split("\n");
    assert.deepEqual(wrapperArgs, [
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

for (const [version, missing] of [
  ["2026.7.1", "openclaw.mjs"],
  ["2026.9.3", "node-version.mjs"],
]) {
  test(`${version}: missing declared root runtime file fails installation: ${missing}`, (t) => {
    const f = fixture(t, version);
    fs.unlinkSync(path.join(f.build, missing));
    const result = f.install();
    assert.notEqual(result.status, 0, result.stdout + result.stderr);
    assert.ok(result.stderr.includes(missing), result.stderr);
    assert.equal(fs.existsSync(path.join(f.out, "wrapper-args")), false);
  });
}

for (const dir of ["node_modules", "dist-runtime"]) {
  test(`${dir}: dangling links still fail before wrapping`, (t) => {
    const f = fixture(t, "2026.9.3");
    fs.symlinkSync("absent", path.join(f.build, dir, "broken"));
    const result = f.install();
    assert.notEqual(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stderr, /dangling symlinks found/);
    assert.equal(fs.existsSync(path.join(f.out, "wrapper-args")), false);
  });
}

function workspaceFixture(t) {
  const f = fixture(t, "2026.9.3");
  const manifest = JSON.parse(fs.readFileSync(path.join(f.build, "package.json"), "utf8"));
  Object.assign(manifest, {
    dependencies: { "registry-bridge": "1.0.0" },
    optionalDependencies: { "@fixture/optional": "workspace:*", "absent-optional": "1.0.0" },
    peerDependencies: { "fixture-peer": "*", "absent-peer": "*" },
    devDependencies: { "unreachable-workspace": "workspace:*" },
  });
  f.put("package.json", JSON.stringify(manifest));
  const link = (name, target) => {
    const file = path.join(f.build, name);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.symlinkSync(target, file);
  };
  const pkg = (dir, name, content) => {
    f.put(
      `${dir}/package.json`,
      JSON.stringify({ name, version: "1.0.0", main: "dist/index.cjs" }),
    );
    f.put(`${dir}/dist/index.cjs`, content);
    f.put(`${dir}/src/input.txt`, `source:${name}\n`);
    f.put(`${dir}/test/input.txt`, `test:${name}\n`);
  };
  pkg(
    "packages/alpha",
    "workspace-alpha",
    'exports.value = "alpha"; exports.beta = () => require("workspace-beta").value;\n',
  );
  pkg(
    "packages/beta",
    "workspace-beta",
    'exports.value = "beta"; exports.alpha = () => require("workspace-alpha").value;\n',
  );
  pkg("packages/optional", "@fixture/optional", 'module.exports = "optional";\n');
  pkg("packages/peer", "fixture-peer", 'module.exports = "peer";\n');
  pkg("packages/dev-only", "unreachable-workspace", 'module.exports = "dev";\n');
  const slot = "node_modules/.pnpm/registry-bridge@1.0.0/node_modules";
  pkg(
    `${slot}/registry-bridge`,
    "registry-bridge",
    'exports.alpha = require("workspace-alpha"); exports.beta = require("workspace-beta");\n',
  );
  link("node_modules/registry-bridge", ".pnpm/registry-bridge@1.0.0/node_modules/registry-bridge");
  link(`${slot}/workspace-alpha`, "../../../../packages/alpha");
  link(`${slot}/registry-bridge/node_modules/workspace-beta`, path.join(f.build, "packages/beta"));
  link("packages/alpha/node_modules/workspace-beta", "../../beta");
  link("packages/alpha/node_modules/openclaw", "../../..");
  link("packages/beta/node_modules/workspace-alpha", "../../alpha");
  link("node_modules/@fixture/optional", "../../packages/optional");
  link("node_modules/fixture-peer", "../packages/peer");
  link("packages/alpha/dist/absolute.txt", path.join(f.build, "packages/beta/src/input.txt"));
  link("packages/alpha/dist/relative.txt", "../src/input.txt");
  const store = path.join(f.away, "fixture-store");
  fs.mkdirSync(store);
  fs.writeFileSync(path.join(store, "artifact"), "native-built-bytes\n");
  fs.linkSync(path.join(store, "artifact"), path.join(f.build, "packages/alpha/dist/native.bin"));
  return { ...f, link, store };
}

function inventory(root) {
  const files = {};
  function visit(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const file = path.join(dir, entry.name);
      const relative = path.relative(root, file);
      if (entry.isDirectory()) visit(file);
      else if (entry.isSymbolicLink()) files[relative] = { link: fs.readlinkSync(file) };
      else files[relative] = { bytes: fs.readFileSync(file).toString("base64") };
    }
  }
  visit(root);
  return files;
}

test("workspace closure survives removal of build and store with artifacts and imports intact", (t) => {
  const f = workspaceFixture(t);
  const reached = ["alpha", "beta", "optional", "peer"];
  const expected = Object.fromEntries(
    reached.map((name) => [name, inventory(path.join(f.build, "packages", name))]),
  );
  const installed = f.install();
  assert.equal(installed.status, 0, installed.stdout + installed.stderr);
  assert.equal(fs.existsSync(path.join(f.root, "packages/dev-only")), false);
  for (const name of reached) {
    const actual = inventory(path.join(f.root, "packages", name));
    const remapped = Object.fromEntries(
      Object.entries(expected[name]).map(([file, value]) => [
        file,
        value.link?.startsWith(`${f.build}/`)
          ? { link: path.join(f.root, path.relative(f.build, value.link)) }
          : value,
      ]),
    );
    assert.deepEqual(actual, remapped);
  }
  assert.equal(
    fs.readlinkSync(
      path.join(
        f.root,
        "node_modules/.pnpm/registry-bridge@1.0.0/node_modules/registry-bridge/node_modules/workspace-beta",
      ),
    ),
    path.join(f.root, "packages/beta"),
  );
  fs.rmSync(f.build, { recursive: true });
  fs.rmSync(f.store, { recursive: true });
  const loaded = f.run(process.execPath, [
    "-e",
    `
const assert = require("node:assert/strict");
const req = require("node:module").createRequire(${JSON.stringify(path.join(f.root, "package.json"))});
const bridge = req("registry-bridge");
assert.equal(bridge.alpha.value, "alpha");
assert.equal(bridge.alpha.beta(), "beta");
assert.equal(bridge.beta.alpha(), "alpha");
assert.equal(req("@fixture/optional"), "optional");
assert.equal(req("fixture-peer"), "peer");
assert.throws(() => req("unreachable-workspace"), {code: "MODULE_NOT_FOUND"});
assert.equal(require("node:fs").readFileSync(${JSON.stringify(path.join(f.root, "packages/alpha/dist/native.bin"))}, "utf8"), "native-built-bytes\\n");
console.log("WORKSPACE_CLOSURE_OK");
`,
  ]);
  assert.equal(loaded.status, 0, loaded.stderr);
  assert.equal(loaded.stdout.trim(), "WORKSPACE_CLOSURE_OK");
  assert.ok(fs.existsSync(path.join(f.out, "wrapper-args")));
});

test("workspace closure fails for a missing required root dependency", (t) => {
  const f = workspaceFixture(t);
  fs.unlinkSync(path.join(f.build, "node_modules/registry-bridge"));
  const installed = f.install();
  assert.notEqual(installed.status, 0);
  assert.match(installed.stderr, /required dependency.*registry-bridge/i);
  assert.equal(fs.existsSync(path.join(f.out, "wrapper-args")), false);
});

for (const absolute of [false, true]) {
  test(`workspace closure rejects ${absolute ? "absolute" : "relative"} escapes before wrapping`, (t) => {
    const f = workspaceFixture(t);
    const outside = path.join(f.away, "external-package");
    fs.mkdirSync(outside);
    fs.writeFileSync(path.join(outside, "package.json"), '{"name":"external-package"}');
    const file = "packages/alpha/node_modules/external-package";
    f.link(
      file,
      absolute ? outside : path.relative(path.dirname(path.join(f.build, file)), outside),
    );
    const installed = f.install();
    assert.notEqual(installed.status, 0);
    assert.match(installed.stderr, /outside.*build|escape/i);
    assert.equal(fs.existsSync(path.join(f.out, "wrapper-args")), false);
  });
}

test("workspace closure keeps validation strict for broken workspace artifact links", (t) => {
  const f = workspaceFixture(t);
  f.link("packages/alpha/dist/broken", "missing-artifact");
  const installed = f.install();
  assert.notEqual(installed.status, 0);
  assert.match(installed.stderr, /dangling|ENOENT|broken/i);
  assert.equal(fs.existsSync(path.join(f.out, "wrapper-args")), false);
});
