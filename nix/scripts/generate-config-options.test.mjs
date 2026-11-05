import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

for (const union of ["oneOf", "anyOf"]) {
  test(`${union}: generate reachable type and source discriminator branches`, (t) => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), "nix-schema-union-"));
    t.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const directory = path.join(root, "src/config");
    fs.mkdirSync(directory, { recursive: true });
    const variant = (key, value, extra = {}) => ({
      type: "object", required: [key], properties: { [key]: { const: value }, ...extra },
    });
    const schema = { type: "object", properties: {
      runtime: { [union]: [variant("type", "embedded"), variant("type", "acp", {
        acp: { type: "object", properties: { mode: { enum: ["oneshot", "persistent"] } } },
      })] },
      secret: { [union]: [variant("source", "env", { id: { type: "string" } }),
        variant("source", "file", { path: { type: "string" } })] },
    } };
    fs.writeFileSync(path.join(directory, "zod-schema.ts"), `export const OpenClawSchema = { toJSONSchema: () => (${JSON.stringify(schema)}) };\n`);
    const output = path.join(root, "options.nix");
    const result = spawnSync(process.execPath, [path.join(import.meta.dirname, "generate-config-options.ts"), "--repo", root, "--out", output], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    const generated = fs.readFileSync(output, "utf8");
    assert.doesNotMatch(generated, /t\.oneOf/);
    assert.match(generated, /t\.enum \[ "embedded" "acp" \]/);
    assert.match(generated, /t\.enum \[ "env" "file" \]/);
  });
}
