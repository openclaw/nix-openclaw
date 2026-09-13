import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

for (const variable of ["PNPM_10_PACKAGE", "PNPM_11_PACKAGE", "PNPM_12_PACKAGE"]) {
  test(`${variable}: filtered rebuild runs only the gateway dependency closure`, (t) => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), "pnpm-rebuild-scope-"));
    t.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const project = path.join(root, "project"), markers = path.join(root, "markers");
    fs.mkdirSync(path.join(project, "packages/unrelated"), { recursive: true });
    for (const name of ["fixture-root", "fixture-unrelated"]) {
      const source = path.join(root, name, "package");
      fs.mkdirSync(source, { recursive: true });
      fs.writeFileSync(path.join(source, "package.json"), JSON.stringify({ name, version: "1.0.0", scripts: { postinstall: "node postinstall.cjs" } }));
      fs.writeFileSync(path.join(source, "postinstall.cjs"), `require('node:fs').appendFileSync(process.env.REBUILD_MARKERS, ${JSON.stringify(name + "\n")});`);
      const packed = spawnSync("tar", ["-czf", path.join(project, `${name}.tgz`), "-C", path.dirname(source), "package"], { encoding: "utf8" });
      assert.equal(packed.status, 0, packed.stderr);
    }
    fs.writeFileSync(path.join(project, "package.json"), JSON.stringify({ name: "gateway", private: true, dependencies: { "fixture-root": "file:fixture-root.tgz" } }));
    fs.writeFileSync(path.join(project, "packages/unrelated/package.json"), JSON.stringify({ name: "unrelated-extension", private: true, dependencies: { "fixture-unrelated": "file:../../fixture-unrelated.tgz" } }));
    fs.writeFileSync(path.join(project, "pnpm-workspace.yaml"), "packages:\n  - packages/*\n# Both local fixture scripts are eligible; selection must exclude the unrelated one.\ndangerouslyAllowAllBuilds: true\n");
    const home = path.join(root, "home");
    fs.mkdirSync(home);
    const env = { ...process.env, HOME: home, XDG_CONFIG_HOME: `${home}/config`, XDG_CACHE_HOME: `${home}/cache`, XDG_DATA_HOME: `${home}/data`,
      PNPM_CONFIG_STORE_DIR: path.join(root, "store"), PNPM_CONFIG_OFFLINE: "true", NPM_CONFIG_STORE_DIR: path.join(root, "store"), NPM_CONFIG_OFFLINE: "true", REBUILD_MARKERS: markers };
    const pnpm = path.join(process.env[variable], "bin/pnpm");
    let output = "";
    for (const args of [["install", "--offline", "--ignore-scripts"], ["--include-workspace-root", "--filter", "gateway...", "rebuild", "fixture-root", "fixture-unrelated"]]) {
      const result = spawnSync(pnpm, args, { cwd: project, env, encoding: "utf8" });
      output += result.stdout + result.stderr;
      assert.equal(result.status, 0, output);
    }
    assert.ok(fs.existsSync(markers), output);
    assert.equal(fs.readFileSync(markers, "utf8"), "fixture-root\n", output);
  });
}
