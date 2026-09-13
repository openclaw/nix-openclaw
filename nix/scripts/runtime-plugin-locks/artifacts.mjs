import {
  fetchJsonWithRetries, isRecord, optionalString, run,
  verifyIntegrity, verifyShasum, verifySha256Hex,
} from "./io.mjs";
import { clawHubArtifactUrl, npmRegistryUrl, skip } from "./catalog.mjs";

async function resolveNpmArtifact(row, npmPackage) {
  const packageMetadata = await fetchJsonWithRetries(npmRegistryUrl(npmPackage.packageName));
  const versionMetadata = packageMetadata.versions?.[npmPackage.version];
  if (!versionMetadata) {
    return {
      skipped: skip(
        row,
        npmPackage.packageName.startsWith("@openclaw/")
          ? "missing-pinned-artifact"
          : "missing-catalog-pinned-artifact",
        `${npmPackage.packageName}@${npmPackage.version} is not published`,
      ),
    };
  }

  if (row.install?.expectedIntegrity && versionMetadata.dist?.integrity !== row.install.expectedIntegrity) {
    return {
      skipped: skip(
        row,
        "npm-integrity-mismatch",
        `catalog expected ${row.install.expectedIntegrity}; npm returned ${versionMetadata.dist?.integrity ?? "missing"}`,
      ),
    };
  }

  if (!versionMetadata.dist?.tarball) {
    return { skipped: skip(row, "missing-npm-tarball", `${npmPackage.packageName}@${npmPackage.version}`) };
  }
  if (!versionMetadata.dist?.integrity) {
    return { skipped: skip(row, "missing-npm-integrity", `${npmPackage.packageName}@${npmPackage.version}`) };
  }

  const prefetch = JSON.parse(run("nix", ["store", "prefetch-file", "--json", versionMetadata.dist.tarball]));
  verifyIntegrity(prefetch.storePath, versionMetadata.dist.integrity);
  verifyShasum(prefetch.storePath, versionMetadata.dist.shasum);

  return {
    artifact: {
      selectedSource: "npm",
      npmSpec: row.install?.npmSpec,
      packageName: npmPackage.packageName,
      version: npmPackage.version,
      tarballUrl: versionMetadata.dist.tarball,
      npmIntegrity: versionMetadata.dist.integrity,
      npmShasum: versionMetadata.dist.shasum,
      nixHash: prefetch.hash,
      storePath: prefetch.storePath,
      versionMetadata,
      bundleDependencies: [
        ...(versionMetadata.bundleDependencies ?? versionMetadata.bundledDependencies ?? []),
      ].sort(),
    },
  };
}

async function resolveClawHubArtifact(row, clawhubPackage) {
  const artifactUrl = clawHubArtifactUrl(clawhubPackage.packageName, clawhubPackage.version);
  let payload;
  try {
    payload = await fetchJsonWithRetries(artifactUrl);
  } catch (error) {
    if (String(error?.message ?? error).includes("HTTP 404")) {
      return {
        skipped: skip(
          row,
          "missing-clawhub-artifact",
          `${clawhubPackage.packageName}@${clawhubPackage.version} returned HTTP 404`,
        ),
      };
    }
    throw error;
  }
  const artifactMetadata = payload.artifact ?? payload.version?.artifact ?? payload.packageVersion?.artifact;
  if (!isRecord(artifactMetadata)) {
    return {
      skipped: skip(row, "missing-clawhub-artifact", `${clawhubPackage.packageName}@${clawhubPackage.version}`),
    };
  }

  const kind = optionalString(artifactMetadata.kind) ?? optionalString(artifactMetadata.type);
  if (kind !== "npm-pack") {
    return {
      skipped: skip(
        row,
        "unsupported-clawhub-artifact-kind",
        `ClawHub artifact kind is ${kind ?? "missing"}`,
      ),
    };
  }

  const tarballUrl =
    optionalString(artifactMetadata.tarballUrl)
    ?? optionalString(artifactMetadata.url)
    ?? optionalString(artifactMetadata.downloadUrl);
  if (!tarballUrl || !tarballUrl.startsWith("https://")) {
    return { skipped: skip(row, "missing-clawhub-tarball", "ClawHub npm-pack artifact has no HTTPS tarball URL") };
  }

  const sha256 =
    optionalString(artifactMetadata.sha256)
    ?? optionalString(artifactMetadata.digest?.sha256)
    ?? optionalString(artifactMetadata.digest);
  if (!sha256) {
    return { skipped: skip(row, "missing-clawhub-sha256", "ClawHub artifact has no SHA-256 digest") };
  }

  const npmIntegrity =
    optionalString(artifactMetadata.npmIntegrity)
    ?? optionalString(artifactMetadata.integrity)
    ?? optionalString(artifactMetadata.dist?.integrity);
  const npmShasum =
    optionalString(artifactMetadata.npmShasum)
    ?? optionalString(artifactMetadata.shasum)
    ?? optionalString(artifactMetadata.dist?.shasum);

  if (row.install?.expectedIntegrity && row.install.expectedIntegrity !== npmIntegrity) {
    return {
      skipped: skip(
        row,
        "clawhub-integrity-mismatch",
        `catalog expected ${row.install.expectedIntegrity}; ClawHub returned ${npmIntegrity ?? "missing"}`,
      ),
    };
  }

  const prefetch = JSON.parse(run("nix", ["store", "prefetch-file", "--json", tarballUrl]));
  verifySha256Hex(prefetch.storePath, sha256);
  if (npmIntegrity) {
    verifyIntegrity(prefetch.storePath, npmIntegrity);
  }
  verifyShasum(prefetch.storePath, npmShasum);

  return {
    artifact: {
      selectedSource: "clawhub",
      clawhubSpec: row.install?.clawhubSpec,
      packageName: clawhubPackage.packageName,
      version: clawhubPackage.version,
      tarballUrl,
      npmIntegrity: npmIntegrity ?? "",
      npmShasum: npmShasum ?? "",
      nixHash: prefetch.hash,
      storePath: prefetch.storePath,
      bundleDependencies: [],
      clawhubPackageName: clawhubPackage.packageName,
      clawhubVersion: clawhubPackage.version,
      clawhubArtifactKind: kind,
      clawhubArtifactSha256: sha256,
    },
  };
}

export { resolveNpmArtifact, resolveClawHubArtifact };
