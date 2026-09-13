import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { nixString, toNix } from "./runtime-plugin-locks/output.mjs";

function evaluate(expression) {
  const result = spawnSync("nix", ["--extra-experimental-features", "nix-command", "eval", "--json", "--impure", "--expr", expression], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout);
}

const literal = 'quotes " \\ tabs\t newline\n return\r unicode 🦞 ${builtins.abort "interpolation executed"}';
test("Nix string and attribute serialization preserves data without interpolation", () => {
  assert.equal(evaluate(nixString(literal)), literal);
  const value = { [literal]: [literal, null, true, 42] };
  assert.deepEqual(evaluate(toNix(value)), value);
});

test("schema descriptions, enum values and option names remain literal Nix data", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "nix-schema-literal-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const directory = path.join(root, "src/config");
  fs.mkdirSync(directory, { recursive: true });
  const schema = { type: "object", required: [literal], properties: {
    [literal]: { type: "string", description: literal, enum: [literal] },
  } };
  fs.writeFileSync(path.join(directory, "zod-schema.ts"), `export const OpenClawSchema = { toJSONSchema: () => (${JSON.stringify(schema)}) };\n`);
  const output = path.join(root, "options.nix");
  const generated = spawnSync(process.execPath, [path.join(import.meta.dirname, "generate-config-options.ts"), "--repo", root, "--out", output], { encoding: "utf8" });
  assert.equal(generated.status, 0, generated.stderr);
  assert.deepEqual(evaluate(`import (/. + ${JSON.stringify(output)}) { lib = { types.enum = values: values; mkOption = option: option; }; }`), {
    [literal]: { description: literal, type: [literal] },
  });
});

test("NUL is rejected rather than emitting a lossy Nix literal", () => {
  assert.throws(() => nixString("before\0after"), /NUL/);
});
