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
    run,
    install: () =>
      run("sh", [installer], {
        cwd: build,
        env: { ...env, out, NODE_BIN: process.execPath, STDENV_SETUP: setup },
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
