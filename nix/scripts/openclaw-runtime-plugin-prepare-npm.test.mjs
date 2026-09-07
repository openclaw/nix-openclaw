import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  packageName, version, jsonText, packageLock, tempDir, writeJson,
} from "./openclaw-runtime-plugin-package-locks.fixtures.mjs";

const script = fileURLToPath(new URL("./openclaw-runtime-plugin-prepare-npm.mjs", import.meta.url));

function fixture(t, mode = "package-lock") {
  const directory = tempDir(t);
  const root = path.join(directory, "package");
  fs.mkdirSync(root);
  const lock = packageLock();
  lock.packages["node_modules/acpx"].optionalDependencies = { helper: "^2.0.0" };
  lock.packages["node_modules/acpx/node_modules/helper"] = {
    version: "2.1.0", resolved: "https://registry.npmjs.org/helper/-/helper-2.1.0.tgz", integrity: "sha512-test",
  };
  const packageJson = { ...lock.packages[""], devDependencies: { test: "^1.0.0" } };
  const file = path.join(directory, "evidence.package-lock.json");
  writeJson(path.join(root, "package.json"), packageJson);
  writeJson(file, lock);
  fs.chmodSync(file, 0o444);
  if (mode === "shrinkwrap") writeJson(path.join(root, "npm-shrinkwrap.json"), lock);
  const env = {
    ...process.env, OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE: mode,
    OPENCLAW_RUNTIME_PLUGIN_PACKAGE_LOCK_FILE: file,
    OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME: packageName, OPENCLAW_RUNTIME_PLUGIN_VERSION: version,
  };
  return { root, file, lock, env,
    run: (extraEnv = {}) => spawnSync(process.execPath, [script], {
      cwd: root, env: { ...env, ...extraEnv }, encoding: "utf8",
    }),
  };
}

for (const mode of ["package-lock", "shrinkwrap"]) {
  test(`${mode} prepares exact dependency specs and strips devDependencies`, (t) => {
    const { root, file, lock, run } = fixture(t, mode);
    const result = run();
    assert.equal(result.status, 0, result.stderr);
    const lockName = mode === "package-lock" ? "package-lock.json" : "npm-shrinkwrap.json";
    const prepared = JSON.parse(fs.readFileSync(path.join(root, lockName)));
    const expected = structuredClone(lock);
    expected.packages[""].dependencies.acpx = "1.0.1";
    expected.packages["node_modules/acpx"].optionalDependencies.helper = "2.1.0";
    assert.deepEqual(prepared, expected);
    assert.equal(JSON.parse(fs.readFileSync(path.join(root, "package.json"))).devDependencies, undefined);
    assert.equal(fs.readFileSync(file, "utf8"), jsonText(lock));
    assert.equal(fs.existsSync(path.join(root, mode === "package-lock" ? "npm-shrinkwrap.json" : "package-lock.json")), false);
  });
}

for (const existing of ["package-lock.json", "npm-shrinkwrap.json"]) {
  test(`package-lock injection rejects pre-existing ${existing} without overwriting`, (t) => {
    const { root, run } = fixture(t);
    const target = path.join(root, existing);
    fs.writeFileSync(target, "existing lock\n");
    const result = run();
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /package already contains/);
    assert.equal(fs.readFileSync(target, "utf8"), "existing lock\n");
  });
}

test("package-lock mode requires evidence file env", (t) => {
  const result = fixture(t).run({ OPENCLAW_RUNTIME_PLUGIN_PACKAGE_LOCK_FILE: "" });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /OPENCLAW_RUNTIME_PLUGIN_PACKAGE_LOCK_FILE is required/);
});

for (const [label, mutate, pattern] of [
  ["version", (lock) => { lock.packages[""].version = "wrong"; }, /root version mismatch/],
  ["name", (lock) => { lock.packages[""].name = "wrong"; }, /root name mismatch/],
  ["lockfile version", (lock) => { lock.lockfileVersion = 1; }, /unsupported package-lock.json lockfileVersion/],
  ["dev", (lock) => { lock.packages["node_modules/acpx"].dev = true; }, /contains dev package/],
  ["link", (lock) => { lock.packages["node_modules/acpx"].link = true; }, /contains linked package/],
  ["resolved", (lock) => { lock.packages["node_modules/acpx"].resolved = "workspace:*"; }, /unsupported resolved/],
]) {
  test(`package-lock preparation rejects invalid ${label}`, (t) => {
    const { lock, file, run } = fixture(t);
    mutate(lock);
    fs.chmodSync(file, 0o644);
    writeJson(file, lock);
    const result = run();
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, pattern);
  });
}
