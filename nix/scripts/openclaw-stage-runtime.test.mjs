import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

for (const separateSource of [false, true]) {
  test(`restore missing legacy manifests from ${separateSource ? "source" : "package"} extensions without replacing compiled manifests`, (t) => {
    const temp = fs.mkdtempSync(path.join(os.tmpdir(), "openclaw-runtime-layout-"));
    t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
    const root = path.join(temp, "package");
    const source = separateSource ? path.join(temp, "source/extensions") : path.join(root, "extensions");
    function put(base, name, text) {
      const file = path.join(base, name);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, text);
    }
    put(source, "legacy/openclaw.plugin.json", '{"id":"legacy"}');
    put(source, "modern/openclaw.plugin.json", '{"id":"stale"}');
    put(source, "unbuilt/openclaw.plugin.json", '{"id":"unbuilt"}');
    put(root, "dist/extensions/legacy/index.js", "export {};\n");
    put(root, "dist/extensions/modern/openclaw.plugin.json", '{"id":"modern"}');
    const args = [path.join(import.meta.dirname, "openclaw-stage-runtime.sh"), root];
    if (separateSource) args.push(source);
    const result = spawnSync("sh", args, { encoding: "utf8", env: { ...process.env, OPENCLAW_BUNDLED_ACPX: "" } });
    assert.equal(result.status, 0, result.stderr);
    for (const directory of ["dist/extensions", "extensions", "dist-runtime/extensions"]) {
      assert.equal(fs.readFileSync(path.join(root, directory, "legacy/openclaw.plugin.json"), "utf8"), '{"id":"legacy"}');
      assert.equal(fs.readFileSync(path.join(root, directory, "modern/openclaw.plugin.json"), "utf8"), '{"id":"modern"}');
    }
    assert.equal(fs.existsSync(path.join(root, "dist/extensions/unbuilt")), false);
    assert.equal(fs.readlinkSync(path.join(root, "dist-runtime")), "dist");
  });
}
