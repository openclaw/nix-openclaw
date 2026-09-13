import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const installer = path.join(import.meta.dirname, "openclaw-gateway-npm-install.sh");
const checker = path.join(import.meta.dirname, "check-package-contents.sh");
const pluginInstaller = path.join(import.meta.dirname, "runtime-plugin/install.mjs");
const legacyNames = ["hasown", "combined-stream"];
const acpxAliases = ["index.js", "register.runtime.js", "runtime-api.js", "setup-api.js"];

function put(root, name, text = "") {
  const file = path.join(root, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
  return file;
}

function dependency(modules, name, marker, code) {
  const root = path.join(modules, name);
  put(root, "package.json", JSON.stringify({ name, version: `${marker}.0.0`, type: "commonjs", main: "index.cjs" }));
  put(root, "index.cjs", code ?? `module.exports = { marker: ${marker}, file: __filename };\n`);
  return root;
}

function snapshot(root) {
  const files = {};
  for (const name of fs.readdirSync(root, { recursive: true }).sort()) {
    const file = path.join(root, name);
    const stat = fs.lstatSync(file);
    if (!stat.isDirectory())
      files[name] = stat.isSymbolicLink() ? fs.readlinkSync(file) : fs.readFileSync(file).toString("hex");
  }
  return files;
}

function fixture(t, layout = "mixed") {
  const temp = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "openclaw-npm-output-")));
  t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
  const build = path.join(temp, "build");
  const modules = path.join(build, "node_modules");
  const packageRoot = path.join(modules, "openclaw");
  const out = path.join(temp, "out");
  const root = path.join(out, "lib/openclaw");
  const away = path.join(temp, "away");
  const home = path.join(temp, "home");
  const acpx = path.join(temp, "acpx");
  for (const dir of [packageRoot, away, home, acpx]) fs.mkdirSync(dir, { recursive: true });
  const localModules = path.join(packageRoot, "node_modules");
  if (layout !== "hoisted") fs.mkdirSync(localModules);
  const graph = layout === "nested" ? localModules : modules;
  const limit = dependency(graph, "p-limit", 7);
  const locate = dependency(graph, "p-locate", 4, 'module.exports = require("p-limit");\n');
  dependency(path.join(locate, "node_modules"), "p-limit", 2);
  dependency(graph, "@fixture/scoped", 3);
  put(
    packageRoot,
    "package.json",
    JSON.stringify({
      name: "openclaw",
      version: "1.0.0",
      type: "module",
      files: ["dist/", "docs/", "skills/"],
      dependencies: { "p-limit": "^7.0.0", "p-locate": "^4.0.0", "@fixture/scoped": "3.0.0" },
      optionalDependencies: { "omitted-platform-addon": "1.0.0" },
    }),
  );
  put(
    packageRoot,
    "dist/index.js",
    `
import limit from "p-limit";
import locate from "p-locate";
import scoped from "@fixture/scoped";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
console.log(JSON.stringify({ direct: limit, nested: locate, scoped,
  cjs: require("p-limit"), locatePath: require.resolve("p-locate"), entry: import.meta.filename }));
`,
  );
  put(packageRoot, "dist/extensions/memory-core/openclaw.plugin.json", '{"id":"memory-core"}');
  for (const name of ["AGENTS", "SOUL", "IDENTITY", "USER", "BOOTSTRAP", "TOOLS"])
    put(packageRoot, `docs/reference/templates/${name}.md`, name);
  put(packageRoot, "skills/fixture/SKILL.md", "# Fixture");
  put(packageRoot, "dist/target.js", "export {};\n");
  put(packageRoot, "dist/runtime-model-auth.runtime.js", 'export * from "./target.js";\n');
  put(
    packageRoot,
    "dist/public-surface-loader-fixture.mjs",
    `
function loadBundledPluginPublicArtifactModuleSync() { return { fixture: true }; }
export { loadBundledPluginPublicArtifactModuleSync };
`,
  );
  put(acpx, "package.json", '{"name":"@fixture/acpx","type":"module"}');
  put(acpx, "openclaw.plugin.json", '{"id":"acpx"}');
  put(acpx, "skills/acp-router/SKILL.md", "fixture");
  dependency(path.join(acpx, "node_modules"), "@fixture/acpx-dep", 9);
  for (const name of acpxAliases) {
    put(acpx, `dist/${name}`, 'export { default } from "@fixture/acpx-dep";\n');
    fs.symlinkSync(`dist/${name}`, path.join(acpx, name));
  }
  put(modules, ".fixture-marker", "retained");
  const bin = put(limit, "bin/marker", "#!/bin/sh\nexit 0\n");
  fs.chmodSync(bin, 0o755);
  fs.mkdirSync(path.join(modules, ".bin"));
  fs.symlinkSync(path.relative(path.join(modules, ".bin"), bin), path.join(modules, ".bin/marker"));
  const setup = put(temp, "setup.sh", 'makeWrapper() { printf "%s\\n" "$@" > "$out/wrapper-args"; }\n');
  const patcher = put(
    temp,
    "patch.mjs",
    `
import fs from "node:fs";
import path from "node:path";
fs.writeFileSync(path.join(process.env.OPENCLAW_PACKAGE_ROOT, "patch-seen"), "patched");
`,
  );
  const env = {
    PATH: `${path.dirname(process.execPath)}:${process.env.PATH ?? ""}`,
    HOME: home,
    TMPDIR: home,
    LANG: "C.UTF-8",
  };
  const run = (command, args, options = {}) =>
    spawnSync(command, args, {
      cwd: away,
      env,
      encoding: "utf8",
      timeout: 15000,
      ...options,
    });
  return {
    temp,
    build,
    modules,
    packageRoot,
    out,
    root,
    acpx,
    env,
    run,
    node: (code, ...args) => run(process.execPath, ["--input-type=module", "-e", code, ...args]),
    install: () =>
      run("sh", [installer], {
        cwd: build,
        env: {
          ...env,
          out,
          NODE_BIN: process.execPath,
          STDENV_SETUP: setup,
          OPENCLAW_NPM_PACKAGE_ROOT: "node_modules/openclaw",
          OPENCLAW_PATCH_NPM_DIST_SCRIPT: patcher,
          OPENCLAW_BUNDLED_ACPX: acpx,
        },
      }),
    removeBuild: () => fs.rmSync(build, { recursive: true, force: true }),
    check: () => run("sh", [checker], { env: { ...env, OPENCLAW_GATEWAY: out } }),
  };
}

function install(f) {
  const result = f.install();
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /openclaw npm install: wrap openclaw/);
  f.removeBuild();
  assert.equal(fs.existsSync(f.build), false);
}

function resolveFrom(f, owner, names) {
  return f.node(
    `
import { createRequire } from "node:module";
const require = createRequire(process.argv[1]);
console.log(JSON.stringify(JSON.parse(process.argv[2]).map(name => require(name))));
`,
    owner,
    JSON.stringify(names),
  );
}

export { fixture, install, resolveFrom, put, dependency, snapshot, legacyNames, acpxAliases, pluginInstaller };
