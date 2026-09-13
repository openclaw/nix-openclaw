import fs from "node:fs";
import path from "node:path";
import { isRecord, optionalString, pickDefined } from "./io.mjs";

export const catalogFiles = [
  "official-external-channel-catalog.json",
  "official-external-plugin-catalog.json",
  "official-external-provider-catalog.json",
];

function parseCatalogEntries(raw) {
  if (Array.isArray(raw)) {
    return raw.filter(isRecord);
  }
  if (!isRecord(raw)) {
    return [];
  }
  const list = raw.entries ?? raw.packages ?? raw.plugins;
  return Array.isArray(list) ? list.filter(isRecord) : [];
}

function catalogManifest(entry) {
  return isRecord(entry.openclaw) ? entry.openclaw : {};
}

function catalogPluginId(entry) {
  const manifest = catalogManifest(entry);
  return (
    optionalString(manifest.plugin?.id)
    ?? optionalString(manifest.channel?.id)
    ?? optionalString(manifest.providers?.[0]?.id)
  );
}

function catalogInstall(entry) {
  const manifest = catalogManifest(entry);
  const install = isRecord(manifest.install) ? manifest.install : {};
  const npmSpec = optionalString(install.npmSpec) ?? optionalString(entry.name);
  const clawhubSpec = optionalString(install.clawhubSpec);
  const localPath = optionalString(install.localPath);
  const defaultChoice =
    ["npm", "clawhub", "local"].includes(install.defaultChoice)
      ? install.defaultChoice
      : npmSpec
        ? "npm"
        : clawhubSpec
          ? "clawhub"
          : localPath
            ? "local"
            : undefined;

  if (!npmSpec && !clawhubSpec && !localPath) {
    return null;
  }

  return pickDefined({
    npmSpec,
    clawhubSpec,
    localPath,
    defaultChoice,
    minHostVersion: optionalString(install.minHostVersion),
    expectedIntegrity: optionalString(install.expectedIntegrity),
  });
}

function selectedSource(install) {
  if (!install) {
    return null;
  }
  return install.defaultChoice ?? (install.npmSpec ? "npm" : install.clawhubSpec ? "clawhub" : "local");
}

function parseNpmSpec(spec) {
  const normalized = optionalString(spec)?.replace(/^npm:/, "");
  if (!normalized) {
    return null;
  }

  if (normalized.startsWith("@")) {
    const slashIndex = normalized.indexOf("/");
    if (slashIndex === -1) {
      return null;
    }
    const versionIndex = normalized.indexOf("@", slashIndex + 1);
    if (versionIndex === -1) {
      return { packageName: normalized, version: null };
    }
    return {
      packageName: normalized.slice(0, versionIndex),
      version: normalized.slice(versionIndex + 1) || null,
    };
  }

  const versionIndex = normalized.lastIndexOf("@");
  if (versionIndex <= 0) {
    return { packageName: normalized, version: null };
  }
  return {
    packageName: normalized.slice(0, versionIndex),
    version: normalized.slice(versionIndex + 1) || null,
  };
}

function parseClawHubSpec(spec) {
  const normalized = optionalString(spec)?.replace(/^clawhub:/, "");
  return normalized ? parseNpmSpec(normalized) : null;
}

function npmRegistryUrl(packageName) {
  return `https://registry.npmjs.org/${encodeURIComponent(packageName)}`;
}

function clawHubArtifactUrl(packageName, version) {
  return `https://clawhub.ai/api/v1/packages/${encodeURIComponent(packageName)}/versions/${encodeURIComponent(version)}/artifact`;
}

function isExactVersion(version) {
  return /^[0-9]+(?:\.[0-9]+){1,2}(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$/.test(version);
}

function attrNameForId(id) {
  const attrName = id
    .split(/[^A-Za-z0-9]+/)
    .filter(Boolean)
    .map((part, index) => (index === 0 ? part : `${part.charAt(0).toUpperCase()}${part.slice(1)}`))
    .join("");
  return attrName.replace(/^[0-9]/, "_$&");
}

function reportBase(row) {
  return pickDefined({
    id: row.id,
    label: row.label,
    kind: row.kind,
    source: row.source,
    catalogFile: row.catalogFile,
    catalogEntryName: row.catalogEntryName,
    catalogDefaultChoice: row.install?.defaultChoice,
    selectedSource: row.selectedSource,
    npmSpec: row.install?.npmSpec,
    clawhubSpec: row.install?.clawhubSpec,
    localPath: row.install?.localPath,
    minHostVersion: row.install?.minHostVersion,
    expectedIntegrity: row.install?.expectedIntegrity,
  });
}

function skip(row, reason, detail) {
  return {
    ...reportBase(row),
    status: "skipped",
    reason,
    ...(detail ? { detail } : {}),
  };
}

function supportedReport(lock) {
  return pickDefined({
    id: lock.id,
    status: "supported",
    label: lock.label,
    kind: lock.kind,
    source: lock.catalogSource,
    catalogFile: lock.catalogFile,
    catalogEntryName: lock.catalogEntryName,
    catalogDefaultChoice: lock.catalogDefaultChoice,
    selectedSource: lock.selectedSource,
    packageName: lock.packageName,
    version: lock.version,
    dependencyMode: lock.dependencyMode,
    openclawCompat: lock.openclawCompat,
    peerOpenClaw: lock.peerOpenClaw,
  });
}

function readCatalogRows(openclawSourcePath) {
  const rows = [];
  for (const catalogFile of catalogFiles) {
    const catalogPath = path.join(openclawSourcePath, "scripts/lib", catalogFile);
    const raw = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
    for (const entry of parseCatalogEntries(raw)) {
      const manifest = catalogManifest(entry);
      const install = catalogInstall(entry);
      const id = catalogPluginId(entry);
      const label =
        optionalString(manifest.plugin?.label)
        ?? optionalString(manifest.channel?.label)
        ?? optionalString(manifest.providers?.[0]?.name)
        ?? optionalString(entry.name)
        ?? id;

      rows.push({
        entry,
        id,
        label,
        kind: optionalString(entry.kind) ?? "plugin",
        source: optionalString(entry.source),
        catalogFile,
        catalogEntryName: optionalString(entry.name),
        install,
        selectedSource: selectedSource(install),
      });
    }
  }
  return rows;
}

export { parseNpmSpec, parseClawHubSpec, npmRegistryUrl, clawHubArtifactUrl, isExactVersion, attrNameForId, skip, supportedReport, readCatalogRows };
