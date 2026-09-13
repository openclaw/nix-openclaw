import fs from "node:fs";
import path from "node:path";
import { collectPackageRoots, packageRootForName } from "../runtime-plugin/package-tree.mjs";
import { isRecord, optionalString, run } from "./io.mjs";

function declaredDependencyRoots(dependencies = {}, optionalDependencies = {}) {
  return [
    ...new Set(
      [
        ...Object.keys(dependencies),
        ...Object.keys(optionalDependencies),
      ].map((dependencyName) => packageRootForName(dependencyName)),
    ),
  ].sort();
}

function listManifestStringField(value, fieldName) {
  if (value === undefined || value === null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw new Error(`package.json ${fieldName} must be an array`);
  }
  return value.map((entry, index) => {
    const normalized = optionalString(entry);
    if (!normalized) {
      throw new Error(`package.json ${fieldName}[${index}] must be a non-empty string`);
    }
    return normalized;
  });
}

function safePackageEntry(entry, label) {
  const normalized = entry.replace(/\\/g, "/").replace(/^\.\//, "");
  if (!normalized || path.isAbsolute(normalized) || normalized.split("/").includes("..")) {
    throw new Error(`${label} must stay inside the package root: ${entry}`);
  }
  return normalized;
}

function isTypeScriptPackageEntry(entry) {
  return [".ts", ".mts", ".cts"].includes(path.extname(entry).toLowerCase());
}

function listBuiltRuntimeEntryCandidates(entry) {
  if (!isTypeScriptPackageEntry(entry)) {
    return [];
  }
  const normalized = entry.replace(/\\/g, "/");
  const withoutExtension = normalized.replace(/\.[^.]+$/u, "");
  const normalizedRelative = normalized.replace(/^\.\//u, "");
  const distWithoutExtension = normalizedRelative.startsWith("src/")
    ? `./dist/${normalizedRelative.slice("src/".length).replace(/\.[^.]+$/u, "")}`
    : `./dist/${withoutExtension.replace(/^\.\//u, "")}`;
  const withJavaScriptExtensions = (basePath) => [
    `${basePath}.js`,
    `${basePath}.mjs`,
    `${basePath}.cjs`,
  ];
  return [...new Set([
    ...withJavaScriptExtensions(distWithoutExtension),
    ...withJavaScriptExtensions(withoutExtension),
  ])].filter((candidate) => candidate !== normalized);
}

function packageEntryExists(packageRoot, entry, label) {
  const safeEntry = safePackageEntry(entry, label);
  return fs.existsSync(path.join(packageRoot, safeEntry)) ? `./${safeEntry}` : null;
}

function resolveRuntimeEntry(packageRoot, sourceEntry, explicitRuntimeEntry, label) {
  if (explicitRuntimeEntry) {
    const existing = packageEntryExists(packageRoot, explicitRuntimeEntry, `${label} runtime entry`);
    if (!existing) {
      throw new Error(`${label} runtime entry not found: ${explicitRuntimeEntry}`);
    }
    return existing;
  }

  for (const candidate of listBuiltRuntimeEntryCandidates(sourceEntry)) {
    const existing = packageEntryExists(packageRoot, candidate, `${label} inferred runtime entry`);
    if (existing) {
      return existing;
    }
  }

  const source = packageEntryExists(packageRoot, sourceEntry, `${label} source entry`);
  if (source && !isTypeScriptPackageEntry(sourceEntry)) {
    return source;
  }
  if (source && isTypeScriptPackageEntry(sourceEntry)) {
    throw new Error(`${label} requires compiled runtime output for TypeScript entry ${sourceEntry}`);
  }
  throw new Error(`${label} source entry not found: ${sourceEntry}`);
}

function resolveRuntimeEntries(packageRoot, packageJson) {
  const openclaw = isRecord(packageJson.openclaw) ? packageJson.openclaw : {};
  const extensions = listManifestStringField(openclaw.extensions, "openclaw.extensions");
  if (extensions.length === 0) {
    throw new Error("package has no package.json openclaw.extensions entries");
  }
  const explicitRuntimeExtensions = listManifestStringField(
    openclaw.runtimeExtensions,
    "openclaw.runtimeExtensions",
  );
  if (explicitRuntimeExtensions.length > 0 && explicitRuntimeExtensions.length !== extensions.length) {
    throw new Error(
      `package.json openclaw.runtimeExtensions length (${explicitRuntimeExtensions.length}) must match openclaw.extensions length (${extensions.length})`,
    );
  }

  const runtimeExtensions = extensions.map((entry, index) =>
    resolveRuntimeEntry(packageRoot, entry, explicitRuntimeExtensions[index], "extension"),
  );

  const setupEntry = optionalString(openclaw.setupEntry);
  const explicitRuntimeSetupEntry = optionalString(openclaw.runtimeSetupEntry);
  if (explicitRuntimeSetupEntry && !setupEntry) {
    throw new Error("package.json openclaw.runtimeSetupEntry requires openclaw.setupEntry");
  }

  return {
    runtimeExtensions,
    runtimeSetupEntry: setupEntry
      ? resolveRuntimeEntry(packageRoot, setupEntry, explicitRuntimeSetupEntry, "setup")
      : null,
  };
}

function validateTarMembers(tarball) {
  const memberList = run("tar", [
    "-tzf",
    tarball,
  ]);
  for (const member of memberList.split(/\r?\n/).filter(Boolean)) {
    if (path.isAbsolute(member) || member.split("/").includes("..")) {
      throw new Error(`unsafe tar member path in ${tarball}: ${member}`);
    }
    if (!member.startsWith("package/")) {
      throw new Error(`unexpected tar member outside package/ in ${tarball}: ${member}`);
    }
  }
}

export { collectPackageRoots, declaredDependencyRoots, resolveRuntimeEntries, validateTarMembers };
