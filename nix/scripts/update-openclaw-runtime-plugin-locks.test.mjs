import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "runtime-lock-command-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const scripts = path.join(root, "nix/scripts");
  fs.cpSync(import.meta.dirname, scripts, { recursive: true });
  fs.mkdirSync(path.join(root, "nix/sources"));
  fs.writeFileSync(path.join(root, "nix/sources/openclaw-source.nix"), `{
    releaseVersion = "2026.9.4";
    runtimePluginVersion = "2026.9.4";
    releaseTag = "v2026.9.4";
    rev = "fixture-revision";
    hash = "fixture-hash";
  }`);
  const source = path.join(root, "source");
  fs.mkdirSync(path.join(source, "scripts/lib"), { recursive: true });
  fs.writeFileSync(path.join(source, "package.json"), '{"version":"2026.9.4"}');
  for (const kind of ["channel", "plugin", "provider"]) {
    fs.writeFileSync(path.join(source, "scripts/lib", `official-external-${kind}-catalog.json`), "[]");
  }
  const bin = path.join(root, "bin");
  fs.mkdirSync(bin);
  fs.symlinkSync(process.execPath, path.join(bin, "node"));
  const semver = (process.env.PATH ?? "").split(path.delimiter)
    .map((directory) => path.join(directory, "node-semver"))
    .find((candidate) => fs.existsSync(candidate));
  if (semver) fs.symlinkSync(semver, path.join(bin, "node-semver"));
  const marker = path.join(root, "nix-invoked");
  fs.writeFileSync(path.join(bin, "nix"), '#!/bin/sh\nprintf invoked > "$MARKER"\nprintf "%s\\n" "$SOURCE"\n', { mode: 0o755 });
  const generated = path.join(root, "nix/generated/openclaw-runtime-plugins");
  return {
    marker, generated,
    run: (...args) => spawnSync(process.execPath, [path.join(scripts, "update-openclaw-runtime-plugin-locks.mjs"), ...args], {
      cwd: root, encoding: "utf8", env: { ...process.env, PATH: bin, MARKER: marker, SOURCE: source },
    }),
  };
}

for (const args of [["--chek"], ["--check", "unexpected"], ["--check", "--check"]]) {
  test(`rejects ${args.join(" ")} before reading artifacts or writing output`, (t) => {
    const f = fixture(t), result = f.run(...args);
    assert.equal(result.status, 2, result.stderr);
    assert.match(result.stderr, /usage:/i);
    assert.equal(fs.existsSync(f.marker), false);
    assert.equal(fs.existsSync(f.generated), false);
  });
}

test("help does not run Nix or create output", (t) => {
  const f = fixture(t), result = f.run("--help");
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /--check/);
  assert.equal(fs.existsSync(f.marker), false);
  assert.equal(fs.existsSync(f.generated), false);
});

test("check reports missing generated files without creating their directory", (t) => {
  const f = fixture(t), result = f.run("--check");
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, /would update/);
  assert.equal(fs.existsSync(f.generated), false);
});

test("apply creates the generated files and a subsequent check leaves them unchanged", (t) => {
  const f = fixture(t), apply = f.run();
  assert.equal(apply.status, 0, apply.stderr);
  const before = fs.readdirSync(f.generated).map((name) => [name, fs.readFileSync(path.join(f.generated, name), "utf8")]);
  const check = f.run("--check");
  assert.equal(check.status, 0, check.stderr);
  assert.deepEqual(fs.readdirSync(f.generated).map((name) => [name, fs.readFileSync(path.join(f.generated, name), "utf8")]), before);
});
