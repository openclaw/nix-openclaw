import fs from "node:fs";
import path from "node:path";

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

function collectPackageRoots(nodeModulesDir, baseRel = "node_modules") {
  if (!fs.existsSync(nodeModulesDir)) {
    return [];
  }

  const roots = [];
  for (const entry of fs.readdirSync(nodeModulesDir).sort()) {
    if (entry === ".bin") {
      continue;
    }

    const entryPath = path.join(nodeModulesDir, entry);
    const entryRel = `${baseRel}/${entry}`;
    if (!fs.lstatSync(entryPath).isDirectory()) {
      continue;
    }

    if (entry.startsWith("@")) {
      for (const scopedName of fs.readdirSync(entryPath).sort()) {
        const scopedPath = path.join(entryPath, scopedName);
        const scopedRel = `${entryRel}/${scopedName}`;
        if (fs.lstatSync(scopedPath).isDirectory()) {
          roots.push(scopedRel);
          roots.push(...collectPackageRoots(path.join(scopedPath, "node_modules"), `${scopedRel}/node_modules`));
        }
      }
    } else {
      roots.push(entryRel);
      roots.push(...collectPackageRoots(path.join(entryPath, "node_modules"), `${entryRel}/node_modules`));
    }
  }

  return roots;
}

function removeNodeModulesBinDirs(nodeModulesDir) {
  if (!fs.existsSync(nodeModulesDir)) {
    return;
  }
  const binDir = path.join(nodeModulesDir, ".bin");
  fs.rmSync(binDir, { recursive: true, force: true });

  for (const entry of fs.readdirSync(nodeModulesDir, { withFileTypes: true })) {
    if (!entry.isDirectory() || entry.name === ".bin") {
      continue;
    }
    const entryPath = path.join(nodeModulesDir, entry.name);
    if (entry.name.startsWith("@")) {
      for (const scopedEntry of fs.readdirSync(entryPath, { withFileTypes: true })) {
        if (scopedEntry.isDirectory()) {
          removeNodeModulesBinDirs(path.join(entryPath, scopedEntry.name, "node_modules"));
        }
      }
    } else {
      removeNodeModulesBinDirs(path.join(entryPath, "node_modules"));
    }
  }
}

function packageRootForName(packageName) {
  if (packageName.startsWith("@")) {
    const parts = packageName.split("/");
    if (parts.length !== 2 || !parts[0] || !parts[1]) {
      fail(`invalid scoped package name ${packageName}`);
    }
    const [scope, name] = parts;
    return `node_modules/${scope}/${name}`;
  }
  if (!packageName || packageName.includes("/")) {
    fail(`invalid package name ${packageName}`);
  }
  return `node_modules/${packageName}`;
}

function packageRootParts(packageName) {
  if (packageName.startsWith("@")) {
    const [scope, name] = packageName.split("/");
    if (!scope || !name) {
      fail(`invalid scoped package name ${packageName}`);
    }
    return [scope, name];
  }
  if (!packageName || packageName.includes("/")) {
    fail(`invalid package name ${packageName}`);
  }
  return [packageName];
}

function dependencyNames(packageJson) {
  return [
    ...Object.keys(packageJson.dependencies ?? {}),
    ...Object.keys(packageJson.optionalDependencies ?? {}),
  ].sort();
}

function resolveDependencyRoot(pluginRoot, fromDir, dependencyName) {
  const parts = packageRootParts(dependencyName);
  let current = fromDir;
  while (current === pluginRoot || current.startsWith(`${pluginRoot}${path.sep}`)) {
    const candidate = path.join(current, "node_modules", ...parts);
    if (fs.existsSync(path.join(candidate, "package.json"))) {
      return path.relative(pluginRoot, candidate).split(path.sep).join("/");
    }
    if (current === pluginRoot) {
      break;
    }
    current = path.dirname(current);
  }
  return null;
}

function reachablePackageRoots(pluginRoot, rootPackageJson) {
  const reachable = new Set();
  const queue = [];

  function enqueue(fromDir, dependencyName) {
    const relPath = resolveDependencyRoot(pluginRoot, fromDir, dependencyName);
    if (!relPath || reachable.has(relPath)) {
      return;
    }
    reachable.add(relPath);
    queue.push(relPath);
  }

  for (const dependencyName of dependencyNames(rootPackageJson)) {
    enqueue(pluginRoot, dependencyName);
  }

  for (let index = 0; index < queue.length; index += 1) {
    const relPath = queue[index];
    const packageDir = path.join(pluginRoot, relPath);
    const packageJson = readJson(path.join(packageDir, "package.json"));
    for (const dependencyName of dependencyNames(packageJson)) {
      enqueue(packageDir, dependencyName);
    }
  }

  return reachable;
}

function pruneExtraneousShrinkwrapPackages(pluginRoot, rootPackageJson) {
  const nodeModulesDir = path.join(pluginRoot, "node_modules");
  if (!fs.existsSync(nodeModulesDir)) {
    return;
  }

  const reachable = reachablePackageRoots(pluginRoot, rootPackageJson);
  const actual = collectPackageRoots(nodeModulesDir);
  for (const relPath of actual.filter((item) => !reachable.has(item)).sort((left, right) => right.length - left.length)) {
    fs.rmSync(path.join(pluginRoot, relPath), { recursive: true, force: true });
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
const expectedPackageName = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME");
const expectedVersion = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_VERSION");
const expectedCompat = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_COMPAT");
const expectedPeer = optionalEnv("OPENCLAW_RUNTIME_PLUGIN_PEER_OPENCLAW");
const runtimeEntriesFile = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_RUNTIME_ENTRIES_FILE");
const bundledPackageRootsFile = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_BUNDLED_PACKAGE_ROOTS_FILE");
const hasRuntimeDependencies = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_HAS_RUNTIME_DEPENDENCIES") === "1";
const dependencyMode =
  process.env.OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE ?? (hasRuntimeDependencies ? "bundled" : "none");
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
if (dependencyMode === "shrinkwrap") {
  pruneExtraneousShrinkwrapPackages(out, packageJson);
  removeNodeModulesBinDirs(path.join(out, "node_modules"));
}

if (packageJson.name !== expectedPackageName) {
  fail(`package name mismatch: expected ${expectedPackageName}, got ${packageJson.name}`);
}
if (packageJson.version !== expectedVersion) {
  fail(`package version mismatch: expected ${expectedVersion}, got ${packageJson.version}`);
}
if (manifest.id !== expectedId) {
  fail(`plugin id mismatch: expected ${expectedId}, got ${manifest.id}`);
}
if ((packageJson.openclaw?.compat?.pluginApi ?? "") !== expectedCompat) {
  fail(`OpenClaw plugin API compatibility mismatch for ${expectedId}`);
}
if ((packageJson.peerDependencies?.openclaw ?? "") !== expectedPeer) {
  fail(`OpenClaw peer dependency mismatch for ${expectedId}`);
}

const runtimeEntries = fs
  .readFileSync(runtimeEntriesFile, "utf8")
  .split(/\r?\n/)
  .map((line) => line.trim())
  .filter(Boolean);
if (runtimeEntries.length === 0) {
  fail(`runtime plugin ${expectedId} has no runtime entry`);
}

for (const runtimeEntry of runtimeEntries) {
  const relPath = safeRelativePath(runtimeEntry, `runtime entry for ${expectedId}`);
  if (!fs.existsSync(path.join(out, relPath))) {
    fail(`runtime entry missing for ${expectedId}: ${runtimeEntry}`);
  }
}

const expectedPackageRoots = new Set(
  fs
    .readFileSync(bundledPackageRootsFile, "utf8")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && line !== ""),
);
const actualPackageRoots = new Set(collectPackageRoots(path.join(out, "node_modules")));

if (hasRuntimeDependencies) {
  if (dependencyMode === "bundled") {
    for (const expectedRoot of expectedPackageRoots) {
      if (!actualPackageRoots.has(expectedRoot)) {
        fail(`runtime plugin ${expectedId} is missing bundled dependency root ${expectedRoot}`);
      }
    }
    for (const actualRoot of actualPackageRoots) {
      if (!expectedPackageRoots.has(actualRoot)) {
        fail(`runtime plugin ${expectedId} has unexpected bundled dependency root ${actualRoot}`);
      }
    }
  } else if (dependencyMode === "shrinkwrap") {
    if (!fs.existsSync(path.join(out, "npm-shrinkwrap.json"))) {
      fail(`runtime plugin ${expectedId} has runtime dependencies but no npm-shrinkwrap.json`);
    }
    for (const dependencyName of Object.keys(packageJson.dependencies ?? {}).sort()) {
      const dependencyRoot = packageRootForName(dependencyName);
      if (!actualPackageRoots.has(dependencyRoot)) {
        fail(`runtime plugin ${expectedId} is missing materialized dependency root ${dependencyRoot}`);
      }
    }
    // Optional dependencies may be omitted by npm for the current platform.
    // The generator still requires shrinkwrap whenever optional deps exist.
  } else {
    fail(`runtime plugin ${expectedId} has invalid dependency mode ${dependencyMode}`);
  }
} else {
  if (dependencyMode !== "none") {
    fail(`runtime plugin ${expectedId} declares no runtime dependencies but has dependency mode ${dependencyMode}`);
  }
  if (actualPackageRoots.size > 0) {
    fail(`runtime plugin ${expectedId} declares no runtime dependencies but bundles node_modules`);
  }
}

if (expectedPeer && linkOpenClawPeer) {
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
