import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import path from "node:path";
import test from "node:test";

const configure = path.join(import.meta.dirname, "pnpm-fetch-config.sh");
for (const override of [undefined, "", "https://registry.example.test/npm/"]) {
  test(`source fetch registry with ${override === undefined ? "unset" : JSON.stringify(override)} override`, () => {
    const env = { ...process.env };
    delete env.NIX_NPM_REGISTRY;
    if (override !== undefined) env.NIX_NPM_REGISTRY = override;
    const result = spawnSync("sh", ["-ec", '. "$1"; shift; exec "$@" --registry="$NIX_NPM_REGISTRY"', "fetcher", configure,
      process.execPath, "-e", "console.log(JSON.stringify({args:process.argv.slice(1), inherited:process.env.NIX_NPM_REGISTRY}))", "--"], { encoding: "utf8", env });
    assert.equal(result.status, 0, result.stderr);
    const expected = override || "https://registry.npmjs.org/";
    assert.deepEqual(JSON.parse(result.stdout), { args: [`--registry=${expected}`], inherited: expected });
  });
}
