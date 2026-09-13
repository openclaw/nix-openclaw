import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

for (const variable of ["PNPM_10_PACKAGE", "PNPM_11_PACKAGE", "PNPM_12_PACKAGE"]) {
  test(`${variable}: production deployment preserves declared files and workspace dependencies`, (t) => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), "pnpm-deployment-"));
    t.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const project = path.join(root, "project"), output = path.join(root, "output"), deployed = path.join(output, "lib/openclaw"), home = path.join(root, "home");
    fs.mkdirSync(path.join(project, "packages/workspace-tool"), { recursive: true });
    fs.mkdirSync(home);
    fs.writeFileSync(path.join(project, "package.json"), JSON.stringify({ name: "gateway", version: "1.0.0", private: true, files: ["launcher.cjs", "runtime.cjs"], bin: { openclaw: "launcher.cjs" }, dependencies: { "workspace-tool": "workspace:*" } }));
    fs.writeFileSync(path.join(project, "launcher.cjs"), 'console.log(require("./runtime.cjs"));\n');
    fs.writeFileSync(path.join(project, "runtime.cjs"), 'module.exports = require("workspace-tool");\n');
    fs.writeFileSync(path.join(project, "development-only.txt"), "excluded");
    fs.writeFileSync(path.join(project, "packages/workspace-tool/package.json"), JSON.stringify({ name: "workspace-tool", version: "1.0.0", main: "index.cjs", files: ["index.cjs"] }));
    fs.writeFileSync(path.join(project, "packages/workspace-tool/index.cjs"), 'module.exports = "standalone runtime";\n');
    fs.writeFileSync(path.join(project, "pnpm-workspace.yaml"), "packages:\n  - packages/*\n");
    const env = { ...process.env, HOME: home, XDG_CONFIG_HOME: `${home}/config`, XDG_CACHE_HOME: `${home}/cache`, XDG_DATA_HOME: `${home}/data`,
      PNPM_CONFIG_STORE_DIR: path.join(root, "store"), PNPM_CONFIG_OFFLINE: "true", NPM_CONFIG_STORE_DIR: path.join(root, "store"), NPM_CONFIG_OFFLINE: "true", NODE_PATH: "", NODE_BIN: process.execPath, out: output };
    const pnpm = path.join(process.env[variable], "bin/pnpm");
    const installed = spawnSync(pnpm, ["install", "--offline", "--ignore-scripts"], { cwd: project, env, encoding: "utf8" });
    assert.equal(installed.status, 0, installed.stdout + installed.stderr);
    fs.writeFileSync(path.join(project, ".pnpm-store-path"), path.join(root, "store"));
    const packaged = spawnSync("sh", [process.env.GATEWAY_INSTALL_SH], {
      cwd: project, env: { ...env, PATH: `${process.env[variable]}/bin:${env.PATH}` }, encoding: "utf8",
    });
    assert.equal(packaged.status, 0, packaged.stdout + packaged.stderr);
    fs.rmSync(project, { recursive: true, force: true });
    fs.rmSync(path.join(root, "store"), { recursive: true, force: true });
    assert.equal(fs.existsSync(path.join(deployed, "development-only.txt")), false);
    const result = spawnSync(path.join(output, "bin/openclaw"), [], { cwd: root, env, encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stdout.trim(), "standalone runtime");
  });
}
