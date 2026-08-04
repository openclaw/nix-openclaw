#!/usr/bin/env node
import fs from "node:fs";
import { pathToFileURL } from "node:url";

export function correctionBaseVersion(releaseVersion) {
  return releaseVersion.match(/^(\d+\.\d+\.\d+)-[1-9]\d*$/)?.[1] ?? null;
}

export function resolveRuntimePluginVersion(releaseVersion, packageVersion) {
  const allowedVersions = [releaseVersion, correctionBaseVersion(releaseVersion)].filter(Boolean);
  if (!allowedVersions.includes(packageVersion)) {
    throw new Error(
      `OpenClaw package version ${packageVersion} must match release ${releaseVersion}`
      + ` or its correction base version`,
    );
  }
  return packageVersion;
}

export function defaultCatalogVersion(catalogSource, releaseVersion, runtimePluginVersion) {
  return catalogSource === "official" ? runtimePluginVersion : releaseVersion;
}

function main(args) {
  if (args.length !== 2) {
    throw new Error(
      "usage: openclaw-runtime-plugin-version.mjs <release-version> <source-package.json>",
    );
  }
  const [releaseVersion, packageJsonPath] = args;
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
  if (typeof packageJson.version !== "string" || !packageJson.version) {
    throw new Error(`${packageJsonPath} has no package version`);
  }
  console.log(resolveRuntimePluginVersion(releaseVersion, packageJson.version));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2));
}
