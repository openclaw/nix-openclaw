import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export const releaseTag = "v2026.9.1-2";
export const releaseVersion = "2026.9.1-2";
export const releaseRev = "a".repeat(40);
export const packageName = "@openclaw/acpx";
export const version = "2026.9.1";
export const sri = `sha256-${Buffer.alloc(32).toString("base64")}`;
export const jsonText = (value) => `${JSON.stringify(value, null, 2)}\n`;
export const sha256 = (text) => crypto.createHash("sha256").update(text).digest("hex");
export const writeJson = (file, value) => fs.writeFileSync(file, jsonText(value));

export function tempDir(t) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "openclaw-lock-test-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  return directory;
}

export function packageLock() {
  return {
    name: packageName, version, lockfileVersion: 3, requires: true,
    packages: {
      "": { name: packageName, version, dependencies: { acpx: "^1.0.0" } },
      "node_modules/acpx": {
        version: "1.0.1", resolved: "https://registry.npmjs.org/acpx/-/acpx-1.0.1.tgz",
        integrity: "sha512-test",
      },
    },
  };
}

export function packageEntry(lock = packageLock()) {
  return {
    packageDir: "extensions/acpx", name: packageName, version,
    bundleRuntimeDependencies: false, dependencyCount: 1, optionalDependencyCount: 0,
    omittedWorkspaceDependencies: [],
    lockSha256: sha256(jsonText(lock)), lock,
  };
}

export function evidenceReport(entry = packageEntry()) {
  return {
    schemaVersion: 1, generatedAt: "2026-09-06T12:00:00.000Z",
    sourceSha: releaseRev, lockfileVersion: 3, packages: [entry],
    packagesWithOmittedWorkspaceDependencies: entry.omittedWorkspaceDependencies?.length > 0 ? 1 : 0,
  };
}

export function evidenceDirectory(t, report = evidenceReport(), manifest = {}) {
  const directory = tempDir(t);
  fs.mkdirSync(path.join(directory, "dependency-evidence"));
  writeJson(path.join(directory, "dependency-evidence/dependency-evidence-manifest.json"), {
    releaseTag, releaseSha: releaseRev, ...manifest,
  });
  writeJson(path.join(directory, "dependency-evidence/npm-package-locks.json"), report);
  return directory;
}
