#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const generatedDir = process.env.OPENCLAW_RUNTIME_PLUGIN_LOCK_DIR;
if (!generatedDir) {
  console.error("OPENCLAW_RUNTIME_PLUGIN_LOCK_DIR is required");
  process.exit(1);
}
const sourceInfoPath = process.env.OPENCLAW_SOURCE_INFO_PATH;
if (!sourceInfoPath) {
  console.error("OPENCLAW_SOURCE_INFO_PATH is required");
  process.exit(1);
}
const locksJsonPath = process.env.OPENCLAW_RUNTIME_PLUGIN_LOCKS_JSON;
if (!locksJsonPath) {
  console.error("OPENCLAW_RUNTIME_PLUGIN_LOCKS_JSON is required");
  process.exit(1);
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

function assert(condition, message) {
  if (!condition) {
    fail(message);
  }
}

function findById(rows, id) {
  return rows.find((row) => row.id === id);
}

function readNixStringFields(file) {
  const text = fs.readFileSync(file, "utf8");
  return Object.fromEntries(
    [...text.matchAll(/^\s*([A-Za-z0-9_'-]+)\s*=\s*"([^"]*)";/gm)].map((match) => [
      match[1],
      match[2],
    ]),
  );
}

function parseVersion(value) {
  const match = typeof value === "string" ? value.match(/^v?(\d+)\.(\d+)\.(\d+)(?:[-+].*)?$/) : null;
  return match ? match.slice(1).map((part) => Number.parseInt(part, 10)) : null;
}

function compareVersions(left, right) {
  const a = parseVersion(left);
  const b = parseVersion(right);
  if (!a || !b) {
    return null;
  }
  for (let index = 0; index < 3; index += 1) {
    if (a[index] !== b[index]) {
      return a[index] < b[index] ? -1 : 1;
    }
  }
  return 0;
}

function satisfiesVersionRange(version, range) {
  const parts = typeof range === "string" ? range.trim().split(/\s+/).filter(Boolean) : [];
  if (parts.length === 0) {
    return true;
  }
  for (const part of parts) {
    const match = part.match(/^(>=|>|<=|<|=)?(.+)$/);
    if (!match) {
      return false;
    }
    const operator = match[1] ?? "=";
    const comparison = compareVersions(version, match[2]);
    if (comparison === null) {
      return false;
    }
    if (operator === ">=" && comparison < 0) return false;
    if (operator === ">" && comparison <= 0) return false;
    if (operator === "<=" && comparison > 0) return false;
    if (operator === "<" && comparison >= 0) return false;
    if (operator === "=" && comparison !== 0) return false;
  }
  return true;
}

function sameArray(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

function lockSourceIsValid(lock) {
  if (lock.selectedSource === "npm") {
    return typeof lock.tarballUrl === "string" && lock.tarballUrl.startsWith("https://registry.npmjs.org/");
  }
  if (lock.selectedSource === "clawhub") {
    const validClawHubUrl =
      typeof lock.tarballUrl === "string"
      && (
        lock.tarballUrl.startsWith("https://clawhub.ai/api/npm/")
        || lock.tarballUrl.startsWith("https://clawhub.ai/api/v1/packages/")
      );
    return (
      validClawHubUrl
      && lock.clawhubArtifactKind === "npm-pack"
      && typeof lock.clawhubArtifactSha256 === "string"
      && lock.clawhubArtifactSha256.length > 0
      && lock.clawhubPackageName === lock.packageName
      && lock.clawhubVersion === lock.version
    );
  }
  return false;
}

const report = readJson(path.join(generatedDir, "report.json"));
const sourceInfo = readNixStringFields(sourceInfoPath);
const locks = readJson(locksJsonPath);
const supported = report.supported ?? [];
const skipped = report.skipped ?? [];
const supportedIds = supported.map((row) => row.id).sort();
const lockIds = Object.keys(locks).sort();
const defaultNix = fs.readFileSync(path.join(generatedDir, "default.nix"), "utf8");
const lockFiles = fs
  .readdirSync(generatedDir)
  .filter((entry) => entry.endsWith(".nix") && entry !== "default.nix")
  .sort();

assert(report.openclawVersion && !/[~^*]|latest|beta$/.test(report.openclawVersion), "report has invalid OpenClaw version");
assert(report.openclawVersion === sourceInfo.releaseVersion, "report OpenClaw version is stale relative to openclaw-source.nix");
assert(report.openclawReleaseTag === sourceInfo.releaseTag, "report OpenClaw release tag is stale relative to openclaw-source.nix");
assert(report.openclawRev === sourceInfo.rev, "report OpenClaw rev is stale relative to openclaw-source.nix");
assert(report.openclawHash === sourceInfo.hash, "report OpenClaw hash is stale relative to openclaw-source.nix");
assert(supported.length > 0, "report has no supported runtime plugins");
assert(new Set(supportedIds).size === supportedIds.length, "report has duplicate supported ids");
assert(lockFiles.length === supported.length, "supported count does not match generated lock files");
assert(sameArray(lockIds, supportedIds), "imported lock ids do not match report supported ids");

for (const row of supported) {
  const lock = locks[row.id];
  assert(row.status === "supported", `supported row ${row.id} has wrong status`);
  assert(row.selectedSource === "npm" || row.selectedSource === "clawhub", `supported row ${row.id} has invalid source`);
  assert(row.packageName, `supported row ${row.id} has no packageName`);
  assert(
    row.dependencyMode === "none" || row.dependencyMode === "bundled" || row.dependencyMode === "shrinkwrap",
    `supported row ${row.id} has invalid dependencyMode`,
  );
  assert(!/[~^*]|latest/.test(row.version), `supported row ${row.id} has a floating version`);
  assert(defaultNix.includes(`${row.id} = import ./`), `default.nix does not import ${row.id}`);
  assert(lock, `missing imported lock for ${row.id}`);
  for (const [lockField, rowField] of [
    ["id", "id"],
    ["label", "label"],
    ["kind", "kind"],
    ["catalogSource", "source"],
    ["catalogFile", "catalogFile"],
    ["catalogEntryName", "catalogEntryName"],
    ["catalogDefaultChoice", "catalogDefaultChoice"],
    ["selectedSource", "selectedSource"],
    ["packageName", "packageName"],
    ["version", "version"],
    ["dependencyMode", "dependencyMode"],
    ["openclawCompat", "openclawCompat"],
    ["peerOpenClaw", "peerOpenClaw"],
  ]) {
    assert(lock[lockField] === (row[rowField] ?? null), `lock ${row.id}.${lockField} diverges from report`);
  }
  assert(!("v1aClass" in lock), `lock ${row.id} still contains obsolete v1aClass`);
  assert(lock.manifestId === row.id, `lock ${row.id} manifestId does not match id`);
  assert(lockSourceIsValid(lock), `lock ${row.id} has invalid source metadata`);
  assert(!lock.npmIntegrity || /^(sha512|sha384|sha256)-/.test(lock.npmIntegrity), `lock ${row.id} has invalid npm SRI integrity`);
  assert(/^sha256-/.test(lock.nixHash), `lock ${row.id} has missing Nix hash`);
  if (lock.dependencyMode === "shrinkwrap") {
    assert(/^sha256-/.test(lock.npmDepsHash), `lock ${row.id} has missing npmDepsHash`);
    assert((lock.bundledPackageRoots ?? []).length === 0, `lock ${row.id} shrinkwrap mode should not list bundled roots`);
  } else {
    assert(!lock.npmDepsHash, `lock ${row.id} has unexpected npmDepsHash`);
  }
  assert(!lock.minHostVersion || satisfiesVersionRange(report.openclawVersion, lock.minHostVersion), `lock ${row.id} minHostVersion excludes OpenClaw ${report.openclawVersion}`);
  assert(!lock.openclawCompat || satisfiesVersionRange(report.openclawVersion, lock.openclawCompat), `lock ${row.id} openclawCompat excludes OpenClaw ${report.openclawVersion}`);
  assert(!lock.peerOpenClaw || satisfiesVersionRange(report.openclawVersion, lock.peerOpenClaw), `lock ${row.id} peerOpenClaw excludes OpenClaw ${report.openclawVersion}`);
}

for (const row of skipped) {
  assert(row.status === "skipped", `skipped row ${row.id ?? row.catalogEntryName} has wrong status`);
  assert(row.reason, `skipped row ${row.id ?? row.catalogEntryName} has no reason`);
  assert(row.detail, `skipped row ${row.id ?? row.catalogEntryName} has no detail`);
  assert(row.catalogFile, `skipped row ${row.id ?? row.catalogEntryName} has no catalogFile`);
}

for (const expected of ["slack", "discord", "brave", "diagnostics-prometheus"]) {
  assert(findById(supported, expected), `previously supported id ${expected} disappeared`);
}
