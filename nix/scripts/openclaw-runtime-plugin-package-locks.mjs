import childProcess from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { isUnsupportedResolvedSource } from "./openclaw-runtime-plugin-prepare-npm.mjs";

const evidenceDirName = "dependency-evidence";
const manifestName = "dependency-evidence-manifest.json";
const reportName = "npm-package-locks.json";

class IncompletePackageLockEvidenceError extends Error {
  code = "package-lock-evidence-incomplete";
}

function run(command, args) {
  const result = childProcess.spawnSync(command, args, {
    encoding: "utf8",
    maxBuffer: 128 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed:\n${result.error ?? result.stderr ?? result.stdout}`);
  }
  return result.stdout;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function dependencyEvidenceAssetName(releaseVersion) {
  return `openclaw-${releaseVersion}-dependency-evidence.zip`;
}

export function dependencyEvidenceAssetUrl({ releaseTag, releaseVersion }) {
  return `https://github.com/openclaw/openclaw/releases/download/${releaseTag}/${dependencyEvidenceAssetName(releaseVersion)}`;
}

// directory is the extraction root, containing dependency-evidence/.
export function parseNpmPackageLocksEvidence({ directory, releaseTag, releaseRev }) {
  function readJson(name) {
    const file = path.join(directory, evidenceDirName, name);
    assert(fs.lstatSync(file).isFile(), `evidence ${name} must be a regular file`);
    return JSON.parse(fs.readFileSync(file, "utf8"));
  }
  const manifest = readJson(manifestName);
  assert(manifest.releaseTag === releaseTag, "dependency evidence releaseTag mismatch");
  assert(manifest.releaseSha === releaseRev, "dependency evidence releaseSha mismatch");
  // Older releases have dependency evidence without an npm lock report.
  if (!fs.existsSync(path.join(directory, evidenceDirName, reportName))) return null;
  const report = readJson(reportName);
  assert(report.schemaVersion === 1, "unsupported npm package-lock evidence schemaVersion");
  assert(report.sourceSha === releaseRev, "npm package-lock evidence sourceSha mismatch");
  assert(report.lockfileVersion === 3, "npm package-lock evidence requires lockfileVersion 3");
  assert(typeof report.generatedAt === "string" && Number.isFinite(Date.parse(report.generatedAt)),
    "npm package-lock evidence has invalid generatedAt");
  assert(Array.isArray(report.packages), "npm package-lock evidence packages must be an array");
  return { sourceSha: report.sourceSha, generatedAt: report.generatedAt, packages: report.packages };
}

export function loadNpmPackageLocksEvidence({
  releaseTag, releaseVersion, releaseRev,
  overrideZipPath = process.env.OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_EVIDENCE_ZIP,
}, { runCommand = run } = {}) {
  const assetName = dependencyEvidenceAssetName(releaseVersion);
  const assetUrl = dependencyEvidenceAssetUrl({ releaseTag, releaseVersion });
  let zipPath = overrideZipPath && path.resolve(overrideZipPath);
  let assetNixHash;
  if (zipPath) {
    assetNixHash = `sha256-${crypto.createHash("sha256").update(fs.readFileSync(zipPath)).digest("base64")}`;
  } else {
    let prefetch;
    try {
      prefetch = JSON.parse(runCommand("nix", ["store", "prefetch-file", "--json", assetUrl]));
    } catch (error) {
      if (/\b(?:HTTP(?: error)?\s+404|404\s+Not Found)\b/i.test(error.message)) return null;
      throw error;
    }
    zipPath = prefetch.storePath;
    assetNixHash = prefetch.hash;
  }
  assert(/^sha256-[A-Za-z0-9+/]{43}=$/.test(assetNixHash), "dependency evidence has invalid Nix hash");
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "openclaw-npm-lock-evidence-"));
  try {
    const members = runCommand("unzip", ["-Z1", zipPath]).split(/\r?\n/);
    const files = [manifestName, reportName].map((name) => `${evidenceDirName}/${name}`);
    assert(members.includes(files[0]), "dependency evidence manifest is missing");
    // Extract only the two contract files, never unrelated archive paths.
    runCommand("unzip", ["-q", zipPath, ...files.filter((file) => members.includes(file)), "-d", directory]);
    const report = parseNpmPackageLocksEvidence({ directory, releaseTag, releaseRev });
    return report && {
      assetName, assetUrl, assetNixHash, source: overrideZipPath ? "override" : "release", ...report,
    };
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

export function selectNpmPackageLock(evidence, packageName, version) {
  if (!evidence) return null;
  const entries = evidence.packages.filter((entry) => entry.name === packageName && entry.version === version);
  if (entries.length === 0) return null;
  assert(entries.length === 1, `duplicate npm package-lock evidence for ${packageName}@${version}`);
  const [entry] = entries;
  assert(entry.bundleRuntimeDependencies === false, `npm package-lock evidence for ${packageName} is bundled`);
  assert(Array.isArray(entry.omittedWorkspaceDependencies)
    && entry.omittedWorkspaceDependencies.every((name) => typeof name === "string" && name.length > 0),
  `npm package-lock evidence for ${packageName} omittedWorkspaceDependencies must be an array of dependency names`);
  if (entry.omittedWorkspaceDependencies.length > 0) {
    throw new IncompletePackageLockEvidenceError(
      `npm package-lock evidence for ${packageName}@${version} omits workspace runtime dependencies: ${entry.omittedWorkspaceDependencies.join(", ")}`,
    );
  }
  const lock = entry.lock;
  assert(isRecord(lock) && lock.lockfileVersion === 3, "npm package-lock requires lockfileVersion 3");
  assert(isRecord(lock.packages), "npm package-lock packages must be an object");
  const root = lock.packages[""];
  assert(root?.name === packageName && root?.version === version, "npm package-lock root name/version mismatch");
  const lockText = `${JSON.stringify(lock, null, 2)}\n`;
  assert(crypto.createHash("sha256").update(lockText).digest("hex") === entry.lockSha256,
    `npm package-lock lockSha256 mismatch for ${packageName}`);
  for (const [packagePath, pkg] of Object.entries(lock.packages)) {
    assert(isRecord(pkg), `invalid npm package-lock entry ${packagePath}`);
    assert(pkg.dev !== true, `npm package-lock contains dev package ${packagePath}`);
    assert(pkg.link !== true, `npm package-lock contains linked package ${packagePath}`);
    assert(typeof pkg.resolved !== "string" || !isUnsupportedResolvedSource(pkg.resolved),
      `npm package-lock contains unsupported resolved source for ${packagePath}`);
    if (packagePath !== "") {
      assert(typeof pkg.resolved === "string" && pkg.resolved.length > 0
        && typeof pkg.integrity === "string" && pkg.integrity.length > 0,
      `npm package-lock entry ${packagePath} requires resolved and integrity`);
    }
  }
  return { entry, lockText };
}

export function verifyNpmPackageLockEvidenceAssets({
  locks, generatedDir, sourceInfo,
  verifyAssets = process.env.OPENCLAW_RUNTIME_PLUGIN_VERIFY_EVIDENCE_ASSET === "1",
}, { loadEvidence = loadNpmPackageLocksEvidence } = {}) {
  if (!verifyAssets) return;
  let publishedEvidence;
  for (const lock of Object.values(locks)) {
    if (lock.dependencyMode !== "package-lock" || lock.npmPackageLockEvidence.source !== "release") continue;
    if (publishedEvidence === undefined) {
      publishedEvidence = loadEvidence({
        releaseTag: sourceInfo.releaseTag, releaseVersion: sourceInfo.releaseVersion,
        releaseRev: sourceInfo.rev, overrideZipPath: "",
      });
    }
    assert(publishedEvidence, "published npm package-lock evidence asset or report is missing");
    const evidence = lock.npmPackageLockEvidence;
    assert(publishedEvidence.source === "release", "package-lock provenance verification requires release evidence");
    assert(publishedEvidence.assetUrl === evidence.assetUrl, `lock ${lock.id} published evidence assetUrl mismatch`);
    assert(publishedEvidence.assetNixHash === evidence.assetNixHash,
      `lock ${lock.id} published evidence assetNixHash mismatch`);
    const selected = selectNpmPackageLock(publishedEvidence, lock.packageName, lock.version);
    assert(selected, `published npm package-lock evidence is missing ${lock.packageName}@${lock.version}`);
    assert(selected.entry.lockSha256 === lock.npmPackageLockSha256,
      `lock ${lock.id} published evidence lockSha256 mismatch`);
    assert(Buffer.from(selected.lockText, "utf8").equals(fs.readFileSync(path.join(generatedDir, lock.npmPackageLockFile))),
      `lock ${lock.id} sidecar bytes differ from published npm package-lock evidence`);
  }
}

// mkDerivation `env` only accepts strings, so interpolate the path: Nix copies
// the file into the store and yields its store path as a string.
export function renderPackageLockProbeEnv(packageLockFile) {
  if (!packageLockFile) return "";
  const escapedPath = JSON.stringify(packageLockFile).replaceAll("${", "\\${");
  return `OPENCLAW_RUNTIME_PLUGIN_PACKAGE_LOCK_FILE = "\${/. + ${escapedPath}}";`;
}

// Keep original evidence bytes separate from the normalized build-time lock.
export function createNpmPackageLockMaterializer({
  releaseTag, releaseVersion, releaseRev, prepare, computeNpmDepsHash,
  loadEvidence = loadNpmPackageLocksEvidence,
}) {
  let evidence;
  const generatedFiles = new Map();
  return {
    generatedFiles,
    materialize({ artifact, packageRoot, attrName, probe, onFailure }) {
      if (evidence === undefined) {
        evidence = loadEvidence({ releaseTag, releaseVersion, releaseRev });
      }
      let selected;
      try {
        selected = selectNpmPackageLock(evidence, artifact.packageName, artifact.version);
      } catch (error) {
        if (error instanceof IncompletePackageLockEvidenceError) return onFailure(error.code, error);
        throw error;
      }
      if (!selected) return null;
      const { entry, lockText } = selected;
      const npmPackageLockFile = `${attrName}.package-lock.json`;
      const evidenceLockPath = path.join(packageRoot, "..", npmPackageLockFile);
      fs.writeFileSync(evidenceLockPath, lockText);
      let stage = "prepare";
      let npmDepsHash;
      try {
        prepare(packageRoot, artifact, "package-lock", evidenceLockPath);
        stage = "npm-deps-hash";
        npmDepsHash = computeNpmDepsHash(path.join(packageRoot, "package-lock.json"));
        stage = "materialization";
        probe(npmDepsHash, evidenceLockPath);
      } catch (error) {
        return onFailure(`package-lock-${stage}-failed`, error);
      }
      generatedFiles.set(npmPackageLockFile, lockText);
      const { packages, ...npmPackageLockEvidence } = evidence;
      return {
        dependencyMode: "package-lock", npmDepsHash, npmPackageLockFile,
        npmPackageLockSha256: entry.lockSha256, npmPackageLockEvidence,
      };
    },
  };
}
