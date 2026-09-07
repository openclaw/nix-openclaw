import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

function optionalEnv(name) {
  return process.env[name] ?? "";
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function writeJson(file, value) {
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

function fail(message) {
  throw new Error(message);
}

export function isUnsupportedResolvedSource(resolved) {
  return /^(file:|workspace:|git\+|git:|ssh:|https:\/\/github\.com\/)/.test(resolved);
}

function dependencyPackagePath(lock, parentPath, dependencyName) {
  let current = parentPath;
  while (true) {
    const candidate = `${current ? `${current}/` : ""}node_modules/${dependencyName}`;
    if (lock.packages?.[candidate]) {
      return candidate;
    }
    if (!current) {
      return null;
    }
    const nestedIndex = current.lastIndexOf("/node_modules/");
    if (nestedIndex !== -1) {
      current = current.slice(0, nestedIndex);
      continue;
    }
    if (current.startsWith("node_modules/")) {
      current = "";
      continue;
    }
    return null;
  }
}

export function normalizeLockedDependencySpecs(lock) {
  let changed = false;
  for (const [packagePath, entry] of Object.entries(lock.packages ?? {})) {
    for (const field of ["dependencies", "optionalDependencies"]) {
      const dependencies = entry[field];
      if (!dependencies || typeof dependencies !== "object" || Array.isArray(dependencies)) {
        continue;
      }
      for (const dependencyName of Object.keys(dependencies).sort()) {
        const resolvedPath = dependencyPackagePath(lock, packagePath, dependencyName);
        const lockedVersion = resolvedPath ? lock.packages?.[resolvedPath]?.version : null;
        if (!lockedVersion || dependencies[dependencyName] === lockedVersion) {
          continue;
        }
        dependencies[dependencyName] = lockedVersion;
        changed = true;
      }
    }
  }
  return changed;
}

function prepare() {
  const dependencyMode = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE");
  if (!["shrinkwrap", "package-lock"].includes(dependencyMode)) {
    return;
  }

  const packageJsonPath = path.resolve("package.json");
  const lockName = dependencyMode === "package-lock" ? "package-lock.json" : "npm-shrinkwrap.json";
  const lockPath = path.resolve(lockName);
  if (!fs.existsSync(packageJsonPath)) {
    fail(`package.json missing from ${dependencyMode} runtime plugin package root`);
  }
  if (dependencyMode === "package-lock") {
    const evidenceLock = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_PACKAGE_LOCK_FILE");
    for (const existing of ["package-lock.json", "npm-shrinkwrap.json"]) {
      if (fs.existsSync(existing)) {
        fail(`cannot inject package-lock evidence: package already contains ${existing}`);
      }
    }
    fs.copyFileSync(evidenceLock, lockPath);
    // Nix store inputs are read-only; the build copy must allow normalization.
    fs.chmodSync(lockPath, 0o644);
  }
  if (!fs.existsSync(lockPath)) {
    fail(`${lockName} missing from ${dependencyMode} runtime plugin package root`);
  }

  const packageJson = readJson(packageJsonPath);
  const lock = readJson(lockPath);
  const rootLock = lock.packages?.[""];
  const expectedPackageName = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME") || packageJson.name;
  const expectedVersion = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_VERSION") || packageJson.version;

  if (packageJson.name !== expectedPackageName) {
    fail(`package name mismatch: expected ${expectedPackageName}, got ${packageJson.name}`);
  }
  if (packageJson.version !== expectedVersion) {
    fail(`package version mismatch: expected ${expectedVersion}, got ${packageJson.version}`);
  }
  if (![2, 3].includes(lock.lockfileVersion)) {
    fail(`unsupported ${lockName} lockfileVersion ${lock.lockfileVersion}`);
  }
  if (rootLock?.name && rootLock.name !== expectedPackageName) {
    fail(`${dependencyMode} root name mismatch: expected ${expectedPackageName}, got ${rootLock.name}`);
  }
  if (rootLock?.version && rootLock.version !== expectedVersion) {
    fail(`${dependencyMode} root version mismatch: expected ${expectedVersion}, got ${rootLock.version}`);
  }

  for (const [packagePath, entry] of Object.entries(lock.packages ?? {})) {
    if (packagePath === "") {
      continue;
    }
    if (entry.dev === true) {
      fail(`${dependencyMode} contains dev package ${packagePath}`);
    }
    if (entry.link === true) {
      fail(`${dependencyMode} contains linked package ${packagePath}`);
    }
    if (typeof entry.resolved === "string" && isUnsupportedResolvedSource(entry.resolved)) {
      fail(`${dependencyMode} contains unsupported resolved source for ${packagePath}: ${entry.resolved}`);
    }
  }

  const lockChanged = normalizeLockedDependencySpecs(lock);
  if (packageJson.devDependencies) {
    delete packageJson.devDependencies;
    writeJson(packageJsonPath, packageJson);
  }
  if (lockChanged) {
    writeJson(lockPath, lock);
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  prepare();
}
