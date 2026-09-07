import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  releaseTag, releaseVersion, releaseRev, version, sri,
  jsonText, sha256, packageLock, tempDir, writeJson,
} from "./openclaw-runtime-plugin-package-locks.fixtures.mjs";
import { dependencyEvidenceAssetName, dependencyEvidenceAssetUrl } from "./openclaw-runtime-plugin-package-locks.mjs";

const script = fileURLToPath(new URL("./check-openclaw-runtime-plugin-locks.mjs", import.meta.url));

function fixture(t) {
  const directory = tempDir(t);
  const sourceInfoPath = path.join(tempDir(t), "source.nix");
  fs.writeFileSync(sourceInfoPath, [
    ["releaseVersion", releaseVersion], ["releaseTag", releaseTag], ["rev", releaseRev],
    ["runtimePluginVersion", version], ["hash", sri],
  ].map(([key, value]) => `  ${key} = "${value}";`).join("\n"));
  const supported = ["acpx", "brave", "slack", "discord", "diagnostics-prometheus"].map((id) => ({
    id, status: "supported", selectedSource: "npm", packageName: `@openclaw/${id}`, version,
    dependencyMode: id === "acpx" ? "package-lock" : "none",
  }));
  const locks = Object.fromEntries(supported.map(({ status, ...row }) => [row.id, {
    ...row, label: null, kind: null, catalogSource: null, catalogFile: null,
    catalogEntryName: null, catalogDefaultChoice: null, openclawCompat: null, peerOpenClaw: null,
    manifestId: row.id, tarballUrl: "https://registry.npmjs.org/test.tgz", nixHash: sri,
  }]));
  const lockText = jsonText(packageLock());
  Object.assign(locks.acpx, {
    npmDepsHash: sri, npmPackageLockFile: "acpx.package-lock.json", npmPackageLockSha256: sha256(lockText),
    bundledPackageRoots: [], npmPackageLockEvidence: {
      source: "release", sourceSha: releaseRev, generatedAt: "2026-09-06T12:00:00.000Z",
      assetName: dependencyEvidenceAssetName(releaseVersion), assetNixHash: sri,
      assetUrl: dependencyEvidenceAssetUrl({ releaseTag, releaseVersion }),
    },
  });
  fs.writeFileSync(path.join(directory, "acpx.package-lock.json"), lockText);
  fs.writeFileSync(path.join(directory, "default.nix"), supported.map(({ id }) => `${id} = import ./${id}.nix;`).join("\n"));
  for (const { id } of supported) fs.writeFileSync(path.join(directory, `${id}.nix`), "{}\n");
  writeJson(path.join(directory, "report.json"), {
    openclawVersion: releaseVersion, runtimePluginVersion: version, openclawReleaseTag: releaseTag,
    openclawRev: releaseRev, openclawHash: sri, supported, skipped: [],
  });
  return {
    directory, locks,
    run: (allow = "") => {
      const locksPath = path.join(directory, "locks.json");
      writeJson(locksPath, locks);
      return spawnSync(process.execPath, [script], { encoding: "utf8", env: {
        ...process.env, OPENCLAW_RUNTIME_PLUGIN_LOCK_DIR: directory,
        OPENCLAW_RUNTIME_PLUGIN_LOCKS_JSON: locksPath, OPENCLAW_SOURCE_INFO_PATH: sourceInfoPath,
        OPENCLAW_RUNTIME_PLUGIN_ALLOW_EVIDENCE_OVERRIDE: allow,
      } });
    },
  };
}

test("checker accepts release evidence and gates override evidence explicitly", (t) => {
  const { locks, run } = fixture(t);
  let result = run();
  assert.equal(result.status, 0, result.stderr);
  locks.acpx.npmPackageLockEvidence.source = "override";
  result = run();
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /source must be release/);
  assert.notEqual(run("true").status, 0);
  result = run("1");
  assert.equal(result.status, 0, result.stderr);
  locks.acpx.npmPackageLockEvidence.source = "unknown";
  assert.notEqual(run("1").status, 0);
});

for (const [label, mutate, pattern] of [
  ["digest", (lock) => { lock.npmPackageLockSha256 = "wrong"; }, /npmPackageLockSha256 mismatch/],
  ["missing lock", (lock) => { lock.npmPackageLockFile = "missing.package-lock.json"; }, /file is missing/],
  ["escaping lock", (lock) => { lock.npmPackageLockFile = "../acpx.package-lock.json"; }, /invalid npmPackageLockFile/],
  ["npm hash", (lock) => { lock.npmDepsHash = "sha256-invalid"; }, /invalid npmDepsHash SRI/],
  ["bundled roots", (lock) => { lock.bundledPackageRoots = ["node_modules/acpx"]; }, /should not list bundled roots/],
  ["release URL", (lock) => { lock.npmPackageLockEvidence.assetUrl = "https://example.com/evidence.zip"; }, /assetUrl/],
  ["release tag", (lock) => { lock.npmPackageLockEvidence.assetUrl = dependencyEvidenceAssetUrl({ releaseTag: "wrong", releaseVersion }); }, /assetUrl/],
  ["source SHA", (lock) => { lock.npmPackageLockEvidence.sourceSha = "wrong"; }, /sourceSha mismatch/],
]) {
  test(`checker rejects bad ${label} even with override enabled`, (t) => {
    const { locks, run } = fixture(t);
    locks.acpx.npmPackageLockEvidence.source = "override";
    mutate(locks.acpx);
    const result = run("1");
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, pattern);
  });
}
