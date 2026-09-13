import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { defaultCatalogVersion } from "../openclaw-runtime-plugin-version.mjs";
import { briefError, pickDefined, run, sortedObject } from "./io.mjs";
import {
  attrNameForId, isExactVersion, parseClawHubSpec, parseNpmSpec,
  satisfiesVersionRange, skip, supportedReport,
} from "./catalog.mjs";
import {
  collectPackageRoots, declaredDependencyRoots, resolveRuntimeEntries, validateTarMembers,
} from "./package.mjs";
import { resolveClawHubArtifact, resolveNpmArtifact } from "./artifacts.mjs";

export function createLockBuilder({
  releaseVersion, packageLocks, prepareLockedPackage, computeNpmDepsHash, probeLockMaterialization,
}) {
  function dependencyModeForArtifact(
    row,
    artifact,
    packageRoot,
    dependencies,
    optionalDependencies,
    bundledPackageRoots,
    shrinkwrap,
  ) {
    const hasRuntimeDependencies =
      Object.keys(dependencies).length > 0 || Object.keys(optionalDependencies).length > 0;

    if (!hasRuntimeDependencies && bundledPackageRoots.length > 0) {
      return {
        skipped: skip(
          row,
          "unexpected-bundled-dependencies",
          "package bundles node_modules but declares no runtime dependencies",
        ),
      };
    }
    if (!hasRuntimeDependencies) {
      return { dependencyMode: "none", npmDepsHash: undefined };
    }

    if (bundledPackageRoots.length > 0) {
      const bundledRootSet = new Set(bundledPackageRoots);
      const missingBundledRoots = declaredDependencyRoots(dependencies, optionalDependencies)
        .filter((dependencyRoot) => !bundledRootSet.has(dependencyRoot));
      if (missingBundledRoots.length > 0) {
        return {
          skipped: skip(
            row,
            "partial-bundled-runtime-dependencies",
            `declared dependency roots missing from bundled node_modules: ${missingBundledRoots.join(", ")}`,
          ),
        };
      }
      return { dependencyMode: "bundled", npmDepsHash: undefined };
    }

    if (!shrinkwrap) {
      const result = packageLocks.materialize({
        artifact, packageRoot, attrName: attrNameForId(row.id),
        probe: (hash, lockFile) => probeLockMaterialization(row, artifact, hash, "package-lock", lockFile),
        onFailure: (reason, error) => ({
          skipped: skip(row, reason,
            reason === "package-lock-evidence-incomplete" ? error.message : briefError(error)),
        }),
      });
      if (result) return result;
      return {
        skipped: skip(
          row,
          "runtime-dependencies-without-shrinkwrap",
          "package has runtime dependencies but no npm-shrinkwrap.json, bundled node_modules, or upstream npm package-lock evidence",
        ),
      };
    }

    const shrinkwrapPath = path.join(packageRoot, "npm-shrinkwrap.json");
    try {
      prepareLockedPackage(packageRoot, artifact);
    } catch (error) {
      return {
        skipped: skip(row, "shrinkwrap-prepare-failed", briefError(error)),
      };
    }

    let npmDepsHash;
    try {
      npmDepsHash = computeNpmDepsHash(shrinkwrapPath);
    } catch (error) {
      return {
        skipped: skip(row, "shrinkwrap-npm-deps-hash-failed", briefError(error)),
      };
    }

    try {
      probeLockMaterialization(row, artifact, npmDepsHash);
    } catch (error) {
      return {
        skipped: skip(row, "shrinkwrap-materialization-failed", briefError(error)),
      };
    }

    return { dependencyMode: "shrinkwrap", npmDepsHash };
  }

  async function buildArtifactLock(row, artifact) {
    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "openclaw-runtime-plugin-lock-"));
    try {
      validateTarMembers(artifact.storePath);
      run("tar", [
        "-xzf",
        artifact.storePath,
        "-C",
        tmpDir,
      ]);

      const packageRoot = path.join(tmpDir, "package");
      const packageJsonPath = path.join(packageRoot, "package.json");
      const manifestPath = path.join(packageRoot, "openclaw.plugin.json");
      if (!fs.existsSync(packageJsonPath) || !fs.existsSync(manifestPath)) {
        return {
          skipped: skip(row, "not-native-runtime-plugin", "package lacks package.json or openclaw.plugin.json"),
        };
      }

      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
      const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
      const shrinkwrapPath = path.join(packageRoot, "npm-shrinkwrap.json");
      const shrinkwrap = fs.existsSync(shrinkwrapPath)
        ? JSON.parse(fs.readFileSync(shrinkwrapPath, "utf8"))
        : null;
      const shrinkwrapPackagePaths = new Set(Object.keys(shrinkwrap?.packages ?? {}));
      const bundledPackageRoots = collectPackageRoots(path.join(packageRoot, "node_modules"));

      if (packageJson.name !== artifact.packageName) {
        return { skipped: skip(row, "package-name-mismatch", `package.json name is ${packageJson.name}`) };
      }
      if (packageJson.version !== artifact.version) {
        return { skipped: skip(row, "package-version-mismatch", `package.json version is ${packageJson.version}`) };
      }
      if (manifest.id !== row.id) {
        return { skipped: skip(row, "manifest-id-mismatch", `openclaw.plugin.json id is ${manifest.id}`) };
      }

      const openclawCompat = packageJson.openclaw?.compat?.pluginApi ?? "";
      const peerOpenClaw = packageJson.peerDependencies?.openclaw ?? "";
      const compatibilityRanges = [
        ["catalog minHostVersion", row.install?.minHostVersion ?? ""],
        ["openclaw.compat.pluginApi", openclawCompat],
        ["peerDependencies.openclaw", peerOpenClaw],
      ];
      for (const [name, range] of compatibilityRanges) {
        if (range && !satisfiesVersionRange(releaseVersion, range)) {
          return {
            skipped: skip(row, "host-compatibility-mismatch", `${name} ${range} does not include OpenClaw ${releaseVersion}`),
          };
        }
      }

      let resolvedRuntimeEntries;
      try {
        resolvedRuntimeEntries = resolveRuntimeEntries(packageRoot, packageJson);
      } catch (error) {
        return { skipped: skip(row, "missing-runtime-entry", error.message) };
      }

      const dependencies = sortedObject(packageJson.dependencies ?? artifact.versionMetadata?.dependencies ?? {});
      const optionalDependencies = sortedObject(
        packageJson.optionalDependencies ?? artifact.versionMetadata?.optionalDependencies ?? {},
      );

      if (shrinkwrap) {
        for (const bundledRoot of bundledPackageRoots) {
          if (!shrinkwrapPackagePaths.has(bundledRoot)) {
            return {
              skipped: skip(
                row,
                "bundled-dependency-missing-from-shrinkwrap",
                `bundled dependency ${bundledRoot} is not in npm-shrinkwrap.json`,
              ),
            };
          }
        }
      }

      const dependencyResult = dependencyModeForArtifact(
        row,
        artifact,
        packageRoot,
        dependencies,
        optionalDependencies,
        bundledPackageRoots,
        shrinkwrap,
      );
      if (dependencyResult.skipped) {
        return { skipped: dependencyResult.skipped };
      }

      const lock = pickDefined({
        id: row.id,
        attrName: attrNameForId(row.id),
        label: row.label,
        kind: row.kind,
        catalogSource: row.source,
        catalogFile: row.catalogFile,
        catalogEntryName: row.catalogEntryName,
        catalogDefaultChoice: row.install?.defaultChoice ?? null,
        selectedSource: artifact.selectedSource,
        npmSpec: artifact.npmSpec,
        clawhubSpec: artifact.clawhubSpec,
        minHostVersion: row.install?.minHostVersion ?? "",
        expectedIntegrity: row.install?.expectedIntegrity ?? "",
        packageName: artifact.packageName,
        version: artifact.version,
        tarballUrl: artifact.tarballUrl,
        npmIntegrity: artifact.npmIntegrity,
        npmShasum: artifact.npmShasum,
        nixHash: artifact.nixHash,
        ...dependencyResult,
        manifestId: manifest.id,
        openclawCompat,
        peerOpenClaw,
        runtimeExtensions: resolvedRuntimeEntries.runtimeExtensions,
        runtimeSetupEntry: resolvedRuntimeEntries.runtimeSetupEntry,
        channels: manifest.channels ?? [],
        contracts: manifest.contracts ?? {},
        dependencies,
        optionalDependencies,
        bundleDependencies: dependencyResult.dependencyMode === "bundled" ? artifact.bundleDependencies : [],
        bundledPackageRoots,
        clawhubPackageName: artifact.clawhubPackageName,
        clawhubVersion: artifact.clawhubVersion,
        clawhubArtifactKind: artifact.clawhubArtifactKind,
        clawhubArtifactSha256: artifact.clawhubArtifactSha256,
      });

      return { lock, supported: supportedReport(lock) };
    } finally {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }
  }

  async function processRow(row, releaseVersion, runtimePluginVersion) {
    if (!row.id) {
      return { skipped: skip(row, "missing-plugin-id", "catalog row has no plugin, channel, or provider id") };
    }
    if (!row.install) {
      return { skipped: skip(row, "missing-install-metadata", "catalog row has no install metadata") };
    }
    if (row.selectedSource === "local") {
      return { skipped: skip(row, "local-source-unsupported", "catalog-selected local paths are not reproducible Nix artifacts") };
    }
    if (row.selectedSource === "clawhub") {
      const clawhubPackage = parseClawHubSpec(row.install.clawhubSpec);
      if (!clawhubPackage) {
        return { skipped: skip(row, "invalid-clawhub-spec", row.install.clawhubSpec ?? "") };
      }
      if (!clawhubPackage.version) {
        clawhubPackage.version = defaultCatalogVersion(
          row.source,
          releaseVersion,
          runtimePluginVersion,
        );
      }
      if (!isExactVersion(clawhubPackage.version)) {
        return {
          skipped: skip(row, "exact-version-required", `ClawHub version ${clawhubPackage.version} is not an exact version`),
        };
      }
      const resolved = await resolveClawHubArtifact(row, clawhubPackage);
      return resolved.artifact ? buildArtifactLock(row, resolved.artifact) : resolved;
    }
    if (row.selectedSource !== "npm") {
      return { skipped: skip(row, "unsupported-selected-source", `selected source is ${row.selectedSource ?? "missing"}`) };
    }

    const npmPackage = parseNpmSpec(row.install.npmSpec);
    if (!npmPackage) {
      return { skipped: skip(row, "invalid-npm-spec", row.install.npmSpec ?? "") };
    }

    if (!npmPackage.version) {
      npmPackage.version = defaultCatalogVersion(
        row.source,
        releaseVersion,
        runtimePluginVersion,
      );
    }

    if (!isExactVersion(npmPackage.version)) {
      return {
        skipped: skip(row, "exact-version-required", `npm version ${npmPackage.version} is not an exact version`),
      };
    }

    const resolved = await resolveNpmArtifact(row, npmPackage);
    return resolved.artifact ? buildArtifactLock(row, resolved.artifact) : resolved;
  }

  return { processRow };
}
