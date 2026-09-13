#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createNpmPackageLockMaterializer } from "./openclaw-runtime-plugin-package-locks.mjs";
import { resolveRuntimePluginVersion } from "./openclaw-runtime-plugin-version.mjs";
import { catalogFiles, readCatalogRows, skip } from "./runtime-plugin-locks/catalog.mjs";
import { createNixTools } from "./runtime-plugin-locks/nix.mjs";
import { createLockBuilder } from "./runtime-plugin-locks/builder.mjs";
import { createGeneratedOutput } from "./runtime-plugin-locks/output.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, "../..");
const sourceInfoPath = path.join(repoRoot, "nix/sources/openclaw-source.nix");
const outputDir = path.join(repoRoot, "nix/generated/openclaw-runtime-plugins");
const prepareNpmScriptPath = path.join(scriptDir, "openclaw-runtime-plugin-prepare-npm.mjs");
const checkMode = process.argv.includes("--check");
const { resolveOpenClawSourcePath, prepareLockedPackage, computeNpmDepsHash, probeLockMaterialization } =
  createNixTools({ repoRoot, sourceInfoPath, prepareNpmScriptPath });

function readSourceField(field) {
  const sourceInfo = fs.readFileSync(sourceInfoPath, "utf8");
  const match = sourceInfo.match(new RegExp(`${field} = "([^"]+)";`));
  if (!match) {
    throw new Error(`Could not read ${field} from ${sourceInfoPath}`);
  }
  return match[1];
}

const releaseVersion = readSourceField("releaseVersion");
const runtimePluginVersion = readSourceField("runtimePluginVersion");
const releaseTag = readSourceField("releaseTag");
const pinnedRev = readSourceField("rev");
const pinnedHash = readSourceField("hash");
const packageLocks = createNpmPackageLockMaterializer({
  releaseTag, releaseVersion, releaseRev: pinnedRev,
  prepare: prepareLockedPackage, computeNpmDepsHash,
});
const { processRow } = createLockBuilder({
  releaseVersion, packageLocks, prepareLockedPackage, computeNpmDepsHash, probeLockMaterialization,
});
const { desiredGeneratedFiles, existingGeneratedFiles, checkGeneratedFiles } =
  createGeneratedOutput({ repoRoot, outputDir, packageLocks });
const openclawSourcePath = resolveOpenClawSourcePath();
const taggedPackageVersion = JSON.parse(
  fs.readFileSync(path.join(openclawSourcePath, "package.json"), "utf8"),
).version;
const expectedRuntimePluginVersion = resolveRuntimePluginVersion(
  releaseVersion,
  taggedPackageVersion,
);
if (runtimePluginVersion !== expectedRuntimePluginVersion) {
  throw new Error(
    `runtimePluginVersion ${runtimePluginVersion} does not match tagged package metadata`
    + ` ${expectedRuntimePluginVersion}`,
  );
}
const rows = readCatalogRows(openclawSourcePath);
const locks = [];
const supported = [];
const skipped = [];
const seenCatalogKeys = new Set();

for (const row of rows) {
  const dedupeKey = row.id ?? row.catalogEntryName ?? "";
  if (seenCatalogKeys.has(dedupeKey)) {
    skipped.push(skip(row, "duplicate-catalog-row", `duplicate catalog key ${dedupeKey}`));
    continue;
  }
  seenCatalogKeys.add(dedupeKey);

  const result = await processRow(row, releaseVersion, runtimePluginVersion);
  if (result.lock) {
    locks.push(result.lock);
    supported.push(result.supported);
  } else if (result.skipped) {
    skipped.push(result.skipped);
  } else {
    throw new Error(`No lock or skip result for ${row.id ?? row.catalogEntryName}`);
  }
}

locks.sort((a, b) => a.id.localeCompare(b.id));
supported.sort((a, b) => a.id.localeCompare(b.id));
skipped.sort((a, b) =>
  `${a.catalogFile}:${a.id ?? a.catalogEntryName ?? ""}`.localeCompare(
    `${b.catalogFile}:${b.id ?? b.catalogEntryName ?? ""}`,
  ),
);

fs.mkdirSync(outputDir, { recursive: true });

const report = {
  openclawVersion: releaseVersion,
  runtimePluginVersion,
  openclawReleaseTag: releaseTag,
  openclawRev: pinnedRev,
  openclawHash: pinnedHash,
  catalogFiles,
  supported,
  skipped,
};
const desiredFiles = desiredGeneratedFiles(locks, report);

if (checkMode) {
  checkGeneratedFiles(desiredFiles);
  console.log(
    `${path.relative(repoRoot, outputDir)} is up to date for OpenClaw ${releaseVersion}: ${supported.length} supported, ${skipped.length} skipped`,
  );
  process.exit(0);
}

for (const file of existingGeneratedFiles()) {
  if (!desiredFiles.has(file)) {
    fs.rmSync(file);
  }
}

for (const [file, content] of desiredFiles) {
  fs.writeFileSync(file, content);
}

console.log(
  `wrote ${path.relative(repoRoot, outputDir)} for OpenClaw ${releaseVersion}: ${supported.length} supported, ${skipped.length} skipped`,
);
