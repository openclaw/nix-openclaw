import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import {
  dependencyEvidenceAssetName, dependencyEvidenceAssetUrl, parseNpmPackageLocksEvidence,
  selectNpmPackageLock, createNpmPackageLockMaterializer, loadNpmPackageLocksEvidence,
  renderPackageLockProbeEnv,
} from "./openclaw-runtime-plugin-package-locks.mjs";
import {
  releaseTag, releaseVersion, releaseRev, packageName, version, sri,
  jsonText, packageLock, packageEntry, evidenceReport, evidenceDirectory, tempDir,
} from "./openclaw-runtime-plugin-package-locks.fixtures.mjs";

test("asset identity uses release version, not the runtime plugin version", () => {
  assert.equal(dependencyEvidenceAssetName(releaseVersion), "openclaw-2026.9.1-2-dependency-evidence.zip");
  assert.equal(dependencyEvidenceAssetUrl({ releaseTag, releaseVersion }),
    "https://github.com/openclaw/openclaw/releases/download/v2026.9.1-2/openclaw-2026.9.1-2-dependency-evidence.zip");
});

test("probe evidence paths are quoted Nix paths even with spaces", () => {
  assert.equal(renderPackageLockProbeEnv("/tmp/plugin evidence/acpx.package-lock.json"),
    'OPENCLAW_RUNTIME_PLUGIN_PACKAGE_LOCK_FILE = /. + "/tmp/plugin evidence/acpx.package-lock.json";');
  assert.equal(renderPackageLockProbeEnv(""), "");
});

test("probe evidence paths escape quotes, backslashes, and Nix interpolation", () => {
  assert.equal(renderPackageLockProbeEnv('/tmp/a"b\\c/${value}/acpx.package-lock.json'),
    String.raw`OPENCLAW_RUNTIME_PLUGIN_PACKAGE_LOCK_FILE = /. + "/tmp/a\"b\\c/\${value}/acpx.package-lock.json";`);
});

test("parses evidence and selects the exact package with canonical lock bytes", (t) => {
  const directory = evidenceDirectory(t);
  const evidence = parseNpmPackageLocksEvidence({ directory, releaseTag, releaseRev });
  const selected = selectNpmPackageLock(evidence, packageName, version);
  assert.deepEqual(selected.entry, packageEntry());
  assert.equal(selected.lockText, jsonText(packageLock()));
  assert.equal(evidence.sourceSha, releaseRev);
  assert.equal(evidence.generatedAt, "2026-09-06T12:00:00.000Z");
  assert.equal(selectNpmPackageLock(evidence, "@openclaw/missing", version), null);
  assert.equal(selectNpmPackageLock(evidence, packageName, releaseVersion), null);
  assert.equal(selectNpmPackageLock(null, packageName, version), null);
});

for (const [label, reportPatch, manifestPatch, pattern] of [
  ["sourceSha", { sourceSha: "b".repeat(40) }, {}, /sourceSha mismatch/],
  ["releaseSha", {}, { releaseSha: "b".repeat(40) }, /releaseSha mismatch/],
  ["releaseTag", {}, { releaseTag: "v2026.8.1" }, /releaseTag mismatch/],
  ["schemaVersion", { schemaVersion: 2 }, {}, /schemaVersion/],
  ["lockfileVersion", { lockfileVersion: 2 }, {}, /lockfileVersion/],
]) {
  test(`rejects wrong evidence ${label}`, (t) => {
    const directory = evidenceDirectory(t, { ...evidenceReport(), ...reportPatch }, manifestPatch);
    assert.throws(() => parseNpmPackageLocksEvidence({ directory, releaseTag, releaseRev }), pattern);
  });
}

test("old release evidence without an npm report returns null", (t) => {
  const directory = evidenceDirectory(t);
  fs.unlinkSync(path.join(directory, "dependency-evidence/npm-package-locks.json"));
  assert.equal(parseNpmPackageLocksEvidence({ directory, releaseTag, releaseRev }), null);
});

test("loader treats only missing release assets as absent evidence", () => {
  for (const message of ["HTTP error 404", "HTTP 404 Not Found", "404 Not Found"]) {
    assert.equal(loadNpmPackageLocksEvidence({ releaseTag, releaseVersion, releaseRev, overrideZipPath: "" }, {
      runCommand: () => { throw new Error(message); },
    }), null);
  }
  assert.throws(() => loadNpmPackageLocksEvidence({ releaseTag, releaseVersion, releaseRev, overrideZipPath: "" }, {
    runCommand: () => { throw new Error("HTTP error 503"); },
  }), /503/);
});

for (const source of ["release", "override"]) {
  test(`loader records ${source} provenance and cleans extraction directory`, (t) => {
    const fixture = evidenceDirectory(t);
    const zipPath = path.join(tempDir(t), "evidence.zip");
    fs.writeFileSync(zipPath, Buffer.alloc(0));
    let extracted;
    let prefetches = 0;
    const evidence = loadNpmPackageLocksEvidence({
      releaseTag, releaseVersion, releaseRev, overrideZipPath: source === "override" ? zipPath : "",
    }, { runCommand: (command, args) => {
      if (command === "nix") {
        prefetches += 1;
        assert.deepEqual(args, ["store", "prefetch-file", "--json", dependencyEvidenceAssetUrl({ releaseTag, releaseVersion })]);
        return JSON.stringify({ storePath: zipPath, hash: sri });
      }
      assert.equal(command, "unzip");
      assert.equal(args[1], zipPath);
      if (args[0] === "-Z1") {
        return "dependency-evidence/dependency-evidence-manifest.json\ndependency-evidence/npm-package-locks.json\nunrelated\n";
      }
      assert.deepEqual(args.slice(0, -1), ["-q", zipPath,
        "dependency-evidence/dependency-evidence-manifest.json", "dependency-evidence/npm-package-locks.json", "-d"]);
      extracted = args.at(-1);
      fs.cpSync(path.join(fixture, "dependency-evidence"), path.join(extracted, "dependency-evidence"), { recursive: true });
      return "";
    } });
    assert.equal(evidence.source, source);
    assert.equal(evidence.sourceSha, releaseRev);
    assert.equal(evidence.assetNixHash, source === "override"
      ? "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=" : sri);
    assert.equal(prefetches, source === "override" ? 0 : 1);
    assert.equal(fs.existsSync(extracted), false);
  });
}

test("rejects a wrong lock digest or bundled entry", () => {
  assert.throws(() => selectNpmPackageLock(evidenceReport({ ...packageEntry(), lockSha256: "bad" }),
    packageName, version), /lockSha256 mismatch/);
  assert.throws(() => selectNpmPackageLock(evidenceReport({ ...packageEntry(), bundleRuntimeDependencies: true }),
    packageName, version), /is bundled/);
});

for (const [label, patch, pattern] of [
  ["dev", { dev: true }, /dev package/],
  ["link", { link: true }, /linked package/],
  ["missing resolved", { resolved: undefined }, /requires resolved and integrity/],
  ["missing integrity", { integrity: undefined }, /requires resolved and integrity/],
  ...["file:local", "workspace:*", "git+https://example.com/repo", "git:repo", "ssh:repo",
    "https://github.com/example/repo"].map((resolved) => [resolved, { resolved }, /unsupported resolved/]),
]) {
  test(`rejects ${label} in package lock`, () => {
    const lock = packageLock();
    Object.assign(lock.packages["node_modules/acpx"], patch);
    assert.throws(() => selectNpmPackageLock(evidenceReport(packageEntry(lock)), packageName, version), pattern);
  });
}

for (const field of ["name", "version"]) {
  test(`rejects wrong root ${field}`, () => {
    const lock = packageLock();
    lock.packages[""][field] = "wrong";
    assert.throws(() => selectNpmPackageLock(evidenceReport(packageEntry(lock)), packageName, version), /root name\/version/);
  });
}

test("rejects dev/link flags on the root too", () => {
  for (const field of ["dev", "link"]) {
    const lock = packageLock();
    lock.packages[""][field] = true;
    assert.throws(() => selectNpmPackageLock(evidenceReport(packageEntry(lock)), packageName, version), /contains/);
  }
});

test("materializer loads once, hashes prepared bytes, and retains original generated bytes", (t) => {
  let loads = 0;
  const evidence = { ...evidenceReport(), assetName: dependencyEvidenceAssetName(releaseVersion),
    assetUrl: dependencyEvidenceAssetUrl({ releaseTag, releaseVersion }), assetNixHash: sri, source: "release" };
  const materializer = createNpmPackageLockMaterializer({
    releaseTag, releaseVersion, releaseRev,
    loadEvidence: (options) => {
      assert.deepEqual(options, { releaseTag, releaseVersion, releaseRev });
      loads += 1;
      return evidence;
    },
    prepare: (root, artifact, mode, file) => {
      assert.equal(mode, "package-lock");
      assert.equal(fs.readFileSync(file, "utf8"), jsonText(packageLock()));
      const lock = JSON.parse(fs.readFileSync(file, "utf8"));
      lock.packages[""].dependencies.acpx = "1.0.1";
      fs.writeFileSync(path.join(root, "package-lock.json"), jsonText(lock));
    },
    computeNpmDepsHash: (file) => {
      assert.equal(JSON.parse(fs.readFileSync(file)).packages[""].dependencies.acpx, "1.0.1");
      return sri;
    },
  });
  const root = path.join(tempDir(t), "package");
  fs.mkdirSync(root);
  const artifact = { packageName, version };
  let probes = 0;
  const result = materializer.materialize({
    artifact, packageRoot: root, attrName: "acpx",
    probe: (hash, file) => {
      probes += 1;
      assert.equal(hash, sri);
      assert.equal(fs.readFileSync(file, "utf8"), jsonText(packageLock()));
    },
    onFailure: (reason, error) => { throw error; },
  });
  assert.equal(result.dependencyMode, "package-lock");
  assert.equal(result.npmPackageLockSha256, packageEntry().lockSha256);
  assert.equal(result.npmPackageLockFile, "acpx.package-lock.json");
  assert.equal(result.npmPackageLockEvidence.sourceSha, releaseRev);
  assert.equal("packages" in result.npmPackageLockEvidence, false);
  assert.equal(materializer.generatedFiles.get("acpx.package-lock.json"), jsonText(packageLock()));
  assert.equal(materializer.materialize({ artifact: { ...artifact, version: "missing" } }), null);
  assert.equal(loads, 1);
  assert.equal(probes, 1);
});

test("materializer caches absent evidence too", () => {
  let loads = 0;
  const materializer = createNpmPackageLockMaterializer({ loadEvidence: () => { loads += 1; return null; } });
  for (let i = 0; i < 2; i += 1) {
    assert.equal(materializer.materialize({ artifact: { packageName, version } }), null);
  }
  assert.equal(loads, 1);
  assert.equal(materializer.generatedFiles.size, 0);
});

for (const stage of ["prepare", "npm-deps-hash", "materialization"]) {
  test(`failed ${stage} does not emit a generated sidecar`, (t) => {
    const root = path.join(tempDir(t), "package");
    fs.mkdirSync(root);
    const fail = () => { throw new Error("probe failed"); };
    const materializer = createNpmPackageLockMaterializer({
      loadEvidence: () => evidenceReport(),
      prepare: stage === "prepare" ? fail : () => {},
      computeNpmDepsHash: stage === "npm-deps-hash" ? fail : () => sri,
    });
    const result = materializer.materialize({
      artifact: { packageName, version }, packageRoot: root, attrName: "acpx",
      probe: stage === "materialization" ? fail : () => {},
      onFailure: (reason, error) => ({ reason, message: error.message }),
    });
    assert.deepEqual(result, { reason: `package-lock-${stage}-failed`, message: "probe failed" });
    assert.equal(materializer.generatedFiles.size, 0);
  });
}
