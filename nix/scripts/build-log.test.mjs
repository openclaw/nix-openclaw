import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import path from "node:path";
import test from "node:test";

const helper = path.join(import.meta.dirname, "build-log.sh");
for (const timings of ["0", "1"]) {
  test(`build logging preserves literal arguments and caller state (timings=${timings})`, () => {
    const result = spawnSync("sh", ["-ec", `
      . "$1"
      step_name=caller
      command_fixture() { printf '%s\\n' "$@"; changed=yes; }
      log_step 'display label' command_fixture 'literal $HOME' 'two words' 'a"quote'
      [ "$step_name" = caller ]
      [ "${"${changed:-unset}"}" = unset ]
    `, "test", helper], { encoding: "utf8", env: { ...process.env, OPENCLAW_NIX_TIMINGS: timings } });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stdout, 'literal $HOME\ntwo words\na"quote\n');
    assert.equal(result.stderr.includes("[timing] display label"), timings === "1");
  });
  test(`build logging preserves failure status (timings=${timings})`, () => {
    const result = spawnSync("sh", ["-ec", '. "$1"; log_step "failing step" sh -c "exit 23"; echo should-not-run', "test", helper], {
      encoding: "utf8", env: { ...process.env, OPENCLAW_NIX_TIMINGS: timings },
    });
    assert.equal(result.status, 23, result.stderr);
    assert.equal(result.stdout, "");
  });
}
