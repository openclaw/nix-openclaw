import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

for (const plugins of [{}, { loaded: ["another-plugin"] }]) {
  test(`gateway smoke waits for the configured plugin after early health: ${JSON.stringify(plugins)}`, (t) => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), "gateway-readiness-"));
    t.after(() => fs.rmSync(root, { recursive: true, force: true }));
    fs.mkdirSync(path.join(root, "bin"));
    const executable = path.join(root, "bin/openclaw");
    fs.writeFileSync(executable, `#!${process.execPath}
import fs from "node:fs";
import path from "node:path";
if (process.argv.includes("--version")) console.log("synthetic gateway");
else if (process.argv.includes("run")) setInterval(() => {}, 1000);
else {
  const marker = path.join(process.env.OPENCLAW_STATE_DIR, "probes");
  const count = fs.existsSync(marker) ? Number(fs.readFileSync(marker, "utf8")) : 0;
  fs.writeFileSync(marker, String(count + 1));
  console.log(JSON.stringify({ ok: true, plugins: count === 0 ? ${JSON.stringify(plugins)} : { loaded: ["test-plugin"] } }));
}
`, { mode: 0o755 });
    fs.writeFileSync(path.join(root, "package.json"), '{"type":"module"}');
    const result = spawnSync(process.execPath, [fileURLToPath(new URL("./gateway-smoke.mjs", import.meta.url))], {
      env: { ...process.env, OPENCLAW_GATEWAY: root, OPENCLAW_RUNTIME_PLUGIN_SMOKE_ROOT: root, OPENCLAW_RUNTIME_PLUGIN_SMOKE_ID: "test-plugin" },
      encoding: "utf8",
      timeout: 10000,
    });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /openclaw gateway smoke: ok/);
  });
}
