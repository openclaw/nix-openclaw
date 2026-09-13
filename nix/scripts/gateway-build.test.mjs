import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const build = path.join(import.meta.dirname, "gateway-build.sh");
function fixture(t, packageBuild = true) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "gateway-build-contract-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const bin = path.join(root, "bin");
  fs.mkdirSync(bin);
  fs.mkdirSync(path.join(root, "store"));
  const scripts = packageBuild ? { "build:package": "upstream package build" } : { build: "upstream build", "ui:build": "upstream UI build" };
  fs.writeFileSync(path.join(root, "package.json"), JSON.stringify({ name: "openclaw", scripts, pnpm: { onlyBuiltDependencies: [] } }));
  const prebuild = path.join(root, "prebuild.sh");
  fs.writeFileSync(prebuild, '. "$OPENCLAW_BUILD_LOG_SH"\nprintf "%s\\n" "$PWD/store" > .pnpm-store-path\n');
  const setup = path.join(root, "setup.sh");
  fs.writeFileSync(setup, 'patchShebangs() { :; }\n');
  const calls = path.join(root, "calls.jsonl");
  fs.writeFileSync(path.join(bin, "pnpm"), `#!${process.execPath}
import fs from 'node:fs';
const args=process.argv.slice(2);
fs.appendFileSync(process.env.CALLS, JSON.stringify(args)+'\\n');
if (args[0]==='install') {
 fs.mkdirSync('node_modules/.pnpm/node_modules/hoisted', {recursive:true});
 fs.writeFileSync('node_modules/.pnpm/node_modules/hoisted/index.js', 'module.exports = "built source fixture";');
 fs.mkdirSync('node_modules/.pnpm/consumer/node_modules/consumer', {recursive:true});
 fs.writeFileSync('node_modules/.pnpm/consumer/node_modules/consumer/index.js', 'module.exports = require("hoisted");');
}
if (args[0]==='config') console.log('{}');
if (args[0]==='run' && ['build:package','build','ui:build'].includes(args[1])) {
 fs.mkdirSync('dist/control-ui',{recursive:true});
 fs.writeFileSync('dist/build-info.json', JSON.stringify({builtAt:process.env.OPENCLAW_BUILD_TIMESTAMP}));
 if(args[1]!=='ui:build') fs.writeFileSync('dist/index.js', 'console.log(require("../node_modules/.pnpm/consumer/node_modules/consumer"))');
 if(args[1]!=='build') fs.writeFileSync('dist/control-ui/index.html','upstream UI');
}
`, { mode: 0o755 });
  return {
    root,
    run: () => spawnSync("sh", [build], {
      cwd: root, encoding: "utf8", env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, CALLS: calls, GATEWAY_PREBUILD_SH: prebuild, STDENV_SETUP: setup, PNPM_BUILD_ENV_SH: path.join(import.meta.dirname, "pnpm-build-env.sh"), OPENCLAW_BUILD_LOG_SH: path.join(import.meta.dirname, "build-log.sh"), OPENCLAW_NIX_TIMINGS: "0", SOURCE_DATE_EPOCH: "1" },
    }),
    calls: () => fs.readFileSync(calls,"utf8").trim().split("\n").map(JSON.parse),
  };
}
for (const packageBuild of [true, false]) {
  test(`source build delegates ${packageBuild ? "package" : "legacy public"} scripts`, (t) => {
    const f = fixture(t, packageBuild), result = f.run();
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.deepEqual(f.calls().filter(([command]) => command === "run"), packageBuild ? [["run","build:package"]] : [["run","build"],["run","ui:build"]]);
    assert.equal(fs.readFileSync(path.join(f.root,"dist/control-ui/index.html"),"utf8"),"upstream UI");
    assert.equal(JSON.parse(fs.readFileSync(path.join(f.root, "dist/build-info.json"), "utf8")).builtAt, "1970-01-01T00:00:01.000Z");
    const executed = spawnSync(process.execPath,[path.join(f.root,"dist/index.js")],{encoding:"utf8"});
    assert.equal(executed.status,0,executed.stderr);
    assert.equal(executed.stdout.trim(),"built source fixture");
  });
}
