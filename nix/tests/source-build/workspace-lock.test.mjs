import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const toolchain = { lockfileVersion: "9.0", importers: { ".": { packageManagerDependencies: {} } }, packages: {
  "pnpm@12.3.4": { resolution: { integrity: "sha512-toolchain" } },
} };
const workspace = { lockfileVersion: "9.0", importers: { ".": { dependencies: {} } }, packages: {
  "fixture@1.0.0": { resolution: { integrity: "sha512-runtime" } },
  "pnpm@10.0.0": { resolution: { integrity: "sha512-runtime-pnpm" } },
} };
for (const documents of [[workspace], [toolchain, workspace]]) {
  test(`${documents.length}-document lock checks every workspace package, including pnpm`, (t) => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), "pnpm-lock-documents-"));
    t.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const lock = path.join(root, "pnpm-lock.yaml");
    fs.writeFileSync(lock, documents.map((document) => `---\n${JSON.stringify(document)}\n`).join(""));
    const result = spawnSync(process.env.PNPM_WORKSPACE_INTEGRITIES_SH, [lock], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(result.stdout.trim().split("\n"), ["fixture@1.0.0\tsha512-runtime", "pnpm@10.0.0\tsha512-runtime-pnpm"]);
  });
}

test("a workspace with no dependencies has no expected package integrities", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pnpm-empty-workspace-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const lock = path.join(root, "pnpm-lock.yaml");
  fs.writeFileSync(lock, JSON.stringify({ lockfileVersion: "9.0", importers: { ".": {} } }));
  const result = spawnSync(process.env.PNPM_WORKSPACE_INTEGRITIES_SH, [lock], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, "");
});
