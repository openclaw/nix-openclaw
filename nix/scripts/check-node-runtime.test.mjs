import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

test("runtime check follows the selected package across split Node and npm outputs", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "node-outputs-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const runtime = path.join(root, "runtime");
  const npmOutput = path.join(root, "npm");
  fs.mkdirSync(path.join(runtime, "bin"), { recursive: true });
  fs.mkdirSync(npmOutput);
  fs.symlinkSync(process.execPath, path.join(runtime, "bin/node"));
  const npm = path.join(npmOutput, "npm");
  fs.writeFileSync(npm, `#!/bin/sh\necho checked > "${root}/checked"\necho 12.2.0\n`, { mode: 0o755 });
  fs.symlinkSync(npm, path.join(runtime, "bin/npm"));
  const check = () => spawnSync(path.join(runtime, "bin/node"), [
    fileURLToPath(new URL("./check-node-runtime.mjs", import.meta.url)), runtime,
  ], { encoding: "utf8" });
  const result = check();
  assert.equal(result.status, 0, result.stderr);
  assert.equal(fs.readFileSync(path.join(root, "checked"), "utf8").trim(), "checked");
  fs.unlinkSync(path.join(runtime, "bin/npm"));
  assert.notEqual(check().status, 0, "npm outside the selected runtime cannot satisfy the check");
});
