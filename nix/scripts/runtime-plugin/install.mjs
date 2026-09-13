import fs from "node:fs";
import path from "node:path";
import {
  collectPackageRoots,
  packageRootForName,
  pruneExtraneousLockedPackages,
  removeNodeModulesBinDirs,
} from "./package-tree.mjs";

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

function fail(message) {
  throw new Error(message);
}

function safeRelativePath(value, label) {
  const normalized = value.replace(/^\.\//, "");
  if (!normalized || path.isAbsolute(normalized)) {
    fail(`${label} must be a relative path inside the plugin root: ${value}`);
  }
  if (normalized.split(/[\\/]+/).includes("..")) {
    fail(`${label} must not escape the plugin root: ${value}`);
  }
  return normalized;
}

const ROOT_FACADE_BASENAMES = [
  "register.runtime.js",
  "runtime-api.js",
  "setup-api.js",
];

function linkDistRootAlias(pluginRoot, basename) {
  const distPath = path.join(pluginRoot, "dist", basename);
  const rootPath = path.join(pluginRoot, basename);
  if (!fs.existsSync(distPath) || fs.existsSync(rootPath)) {
    return;
  }
  fs.symlinkSync(path.posix.join("dist", basename), rootPath);
}

function exposeDistRootAliases(pluginRoot, runtimeEntries) {
  for (const runtimeEntry of runtimeEntries) {
    const relPath = safeRelativePath(runtimeEntry, `runtime entry alias`);
    if (path.dirname(relPath) === "dist") {
      linkDistRootAlias(pluginRoot, path.basename(relPath));
    }
  }
  for (const basename of ROOT_FACADE_BASENAMES) {
    linkDistRootAlias(pluginRoot, basename);
  }
}

function findInvalidSymlink(root, allowedExternalTarget) {
  const rootRealPath = fs.realpathSync(root);
  const allowedExternalRealPath = allowedExternalTarget ? fs.realpathSync(allowedExternalTarget) : null;

  function visit(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isSymbolicLink()) {
        const target = fs.readlinkSync(fullPath);
        const resolved = path.isAbsolute(target) ? target : path.resolve(path.dirname(fullPath), target);
        if (!fs.existsSync(resolved)) {
          return `${fullPath} -> ${target}`;
        }
        const resolvedRealPath = fs.realpathSync(resolved);
        const insidePlugin =
          resolvedRealPath === rootRealPath || resolvedRealPath.startsWith(`${rootRealPath}${path.sep}`);
        const allowedExternal = allowedExternalRealPath && resolvedRealPath === allowedExternalRealPath;
        if (!insidePlugin && !allowedExternal) {
          return `${fullPath} -> ${target}`;
        }
      } else if (entry.isDirectory()) {
        const invalid = visit(fullPath);
        if (invalid) {
          return invalid;
        }
      }
    }
    return null;
  }

  return visit(root);
}

const out = requiredEnv("out");
const expectedId = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_ID");
const expectedPackageName = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME");
const expectedVersion = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_VERSION");
const expectedCompat = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_COMPAT");
const expectedPeer = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_PEER_OPENCLAW");
const runtimeEntriesFile = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_RUNTIME_ENTRIES_FILE");
const bundledPackageRootsFile = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_BUNDLED_PACKAGE_ROOTS_FILE");
const expectedHasRuntimeDependencies = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_HAS_RUNTIME_DEPENDENCIES");
let dependencyMode = process.env.OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE ?? "";
const linkOpenClawPeer = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_LINK_PEER_OPENCLAW") !== "0";
const openclawPackage = linkOpenClawPeer ? requiredEnv("OPENCLAW_GATEWAY_PACKAGE") : "";
let allowedExternalSymlinkTarget = null;

fs.mkdirSync(out, { recursive: true });
fs.cpSync(".", out, { recursive: true, force: true, dereference: false });

const packageJsonPath = path.join(out, "package.json");
const manifestPath = path.join(out, "openclaw.plugin.json");
if (!fs.existsSync(packageJsonPath)) {
  fail("package.json missing from runtime plugin package root");
}
if (!fs.existsSync(manifestPath)) {
  fail("openclaw.plugin.json missing from runtime plugin package root");
}

const packageJson = readJson(packageJsonPath);
const manifest = readJson(manifestPath);
const packageName = packageJson.name;
const packageVersion = packageJson.version;
const dependencies = packageJson.dependencies ?? {};
const optionalDependencies = packageJson.optionalDependencies ?? {};
const hasRuntimeDependencies =
  expectedHasRuntimeDependencies
    ? expectedHasRuntimeDependencies === "1"
    : Object.keys(dependencies).length > 0 || Object.keys(optionalDependencies).length > 0;

if (["shrinkwrap", "package-lock"].includes(dependencyMode)) {
  pruneExtraneousLockedPackages(out, packageJson);
  removeNodeModulesBinDirs(path.join(out, "node_modules"));
}

if (expectedPackageName && packageName !== expectedPackageName) {
  fail(`package name mismatch: expected ${expectedPackageName}, got ${packageName}`);
}
if (expectedVersion && packageVersion !== expectedVersion) {
  fail(`package version mismatch: expected ${expectedVersion}, got ${packageVersion}`);
}
if (manifest.id !== expectedId) {
  fail(`plugin id mismatch: expected ${expectedId}, got ${manifest.id}`);
}
if (expectedCompat && (packageJson.openclaw?.compat?.pluginApi ?? "") !== expectedCompat) {
  fail(
    `OpenClaw plugin API compatibility mismatch for ${expectedId}: expected ${expectedCompat}, got ${packageJson.openclaw?.compat?.pluginApi ?? "missing"}`,
  );
}
if (expectedPeer && (packageJson.peerDependencies?.openclaw ?? "") !== expectedPeer) {
  fail(
    `OpenClaw peer dependency mismatch for ${expectedId}: expected ${expectedPeer}, got ${packageJson.peerDependencies?.openclaw ?? "missing"}`,
  );
}
const openclawPeer = expectedPeer || packageJson.peerDependencies?.openclaw || "";

let runtimeEntries = fs
  .readFileSync(runtimeEntriesFile, "utf8")
  .split(/\r?\n/)
  .map((line) => line.trim())
  .filter(Boolean);
if (runtimeEntries.length === 0) {
  runtimeEntries = [
    ...(Array.isArray(packageJson.openclaw?.runtimeExtensions) ? packageJson.openclaw.runtimeExtensions : []),
    packageJson.openclaw?.runtimeSetupEntry,
  ].filter((entry) => typeof entry === "string" && entry.trim());
}
if (runtimeEntries.length === 0) {
  fail(`runtime plugin ${expectedId} has no runtime entry`);
}

for (const runtimeEntry of runtimeEntries) {
  const relPath = safeRelativePath(runtimeEntry, `runtime entry for ${expectedId}`);
  if (!fs.existsSync(path.join(out, relPath))) {
    fail(`runtime entry missing for ${expectedId}: ${runtimeEntry}`);
  }
}
exposeDistRootAliases(out, runtimeEntries);

const expectedPackageRoots = new Set(
  fs
    .readFileSync(bundledPackageRootsFile, "utf8")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && line !== ""),
);
const actualPackageRoots = new Set(collectPackageRoots(path.join(out, "node_modules")));
if (!dependencyMode) {
  dependencyMode = hasRuntimeDependencies ? "auto" : "none";
}

if (hasRuntimeDependencies) {
  if (dependencyMode === "auto") {
    const missingDependencyRoots = [
      ...Object.keys(dependencies),
      ...Object.keys(optionalDependencies),
    ]
      .sort()
      .map((dependencyName) => packageRootForName(dependencyName))
      .filter((dependencyRoot) => !actualPackageRoots.has(dependencyRoot));
    if (missingDependencyRoots.length === 0) {
      dependencyMode = "bundled";
    } else if (fs.existsSync(path.join(out, "npm-shrinkwrap.json"))) {
      fail(
        `runtime plugin ${expectedId} has npm-shrinkwrap.json and runtime dependencies; set npmDepsHash = lib.fakeHash, rebuild, and replace it with the suggested hash`,
      );
    } else {
      fail(
        `runtime plugin ${expectedId} has runtime dependencies but no bundled node_modules, npm-shrinkwrap.json, or upstream npm package-lock evidence; publish npm-shrinkwrap.json and set npmDepsHash = lib.fakeHash, or regenerate the catalog locks once upstream ships evidence`,
      );
    }
  }

  if (dependencyMode === "bundled") {
    for (const expectedRoot of expectedPackageRoots) {
      if (!actualPackageRoots.has(expectedRoot)) {
        fail(`runtime plugin ${expectedId} is missing bundled dependency root ${expectedRoot}`);
      }
    }
    if (expectedPackageRoots.size > 0) {
      for (const actualRoot of actualPackageRoots) {
        if (!expectedPackageRoots.has(actualRoot)) {
          fail(`runtime plugin ${expectedId} has unexpected bundled dependency root ${actualRoot}`);
        }
      }
    }
  } else if (["shrinkwrap", "package-lock"].includes(dependencyMode)) {
    const lockName = dependencyMode === "package-lock" ? "package-lock.json" : "npm-shrinkwrap.json";
    if (!fs.existsSync(path.join(out, lockName))) {
      fail(`runtime plugin ${expectedId} has runtime dependencies but no ${lockName}`);
    }
    for (const dependencyName of Object.keys(packageJson.dependencies ?? {}).sort()) {
      const dependencyRoot = packageRootForName(dependencyName);
      if (!actualPackageRoots.has(dependencyRoot)) {
        fail(`runtime plugin ${expectedId} is missing materialized dependency root ${dependencyRoot}`);
      }
    }
    // Optional dependencies may be omitted by npm for the current platform.
    // The generator still requires a lock whenever optional deps exist.
  } else {
    fail(`runtime plugin ${expectedId} has invalid dependency mode ${dependencyMode}`);
  }
} else {
  if (dependencyMode === "auto") {
    dependencyMode = "none";
  }
  if (dependencyMode !== "none") {
    fail(`runtime plugin ${expectedId} declares no runtime dependencies but has dependency mode ${dependencyMode}`);
  }
  if (actualPackageRoots.size > 0) {
    fail(`runtime plugin ${expectedId} declares no runtime dependencies but bundles node_modules`);
  }
}

if (openclawPeer && linkOpenClawPeer) {
  const peerTarget = path.join(openclawPackage, "lib/openclaw");
  if (!fs.existsSync(path.join(peerTarget, "package.json"))) {
    fail(`OpenClaw peer target missing package.json: ${peerTarget}`);
  }
  allowedExternalSymlinkTarget = peerTarget;
  const peerLink = path.join(out, "node_modules", "openclaw");
  fs.mkdirSync(path.dirname(peerLink), { recursive: true });
  try {
    fs.rmSync(peerLink, { recursive: true, force: true });
  } catch {
    // Best-effort cleanup before replacing the peer link.
  }
  fs.symlinkSync(peerTarget, peerLink);
}

const invalidSymlink = findInvalidSymlink(out, allowedExternalSymlinkTarget);
if (invalidSymlink) {
  fail(`runtime plugin ${expectedId} contains invalid symlink: ${invalidSymlink}`);
}
