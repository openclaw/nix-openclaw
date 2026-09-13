import assert from "node:assert/strict";
import fs from "node:fs";
import { spawnSync } from "node:child_process";

const expected = JSON.parse(fs.readFileSync(process.env.EXPECTED_ENV_FILE, "utf8"));
const env = { ...process.env };
for (const key of Object.keys(expected)) delete env[key];
const result = spawnSync(process.env.GATEWAY_WRAPPER, Object.keys(expected), {
  env, encoding: "utf8",
});
assert.equal(result.status, 0, result.stderr);
assert.deepEqual(result.stdout.split("\0").slice(0, -1), Object.values(expected));
assert.equal(fs.existsSync("unexpected-command"), false);
console.log("generated gateway environment: literal values, file values, and overrides PASS");

for (const [variable, succeeds] of [["GUARD_VALID", true], ["GUARD_MISSING", false], ["GUARD_EMPTY", false]]) {
  const guard = spawnSync(process.env[variable], [], { env, encoding: "utf8" });
  assert.equal(guard.status === 0, succeeds, guard.stderr);
  if (!succeeds) {
    assert.ok(guard.stderr.includes("plugin $(touch unexpected-command)"), guard.stderr);
    assert.ok(guard.stderr.includes("instance $value"), guard.stderr);
  }
}
const failedRead = spawnSync(process.env.BASH_BIN, ["-euo", "pipefail", "-c",
  '. "$1"; openclawExportEnv NIX_TEST_READ_FAILURE "$2" "$3"; echo unexpected-success',
  "env-test", process.env.ENV_EXPORT_HELPER, process.env.READ_FAILURE_FILE, process.env.FALSE_BIN,
], { env, encoding: "utf8" });
assert.notEqual(failedRead.status, 0);
assert.equal(failedRead.stdout, "");
assert.equal(fs.existsSync("unexpected-command"), false);
console.log("generated plugin guards and failed file reads: PASS");
