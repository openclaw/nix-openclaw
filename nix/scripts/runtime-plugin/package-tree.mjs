import fs from "node:fs";
import path from "node:path";

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
      throw new Error(`invalid scoped package name ${packageName}`);
    }
    const [scope, name] = parts;
    return `node_modules/${scope}/${name}`;
  }
  if (!packageName || packageName.includes("/")) {
    throw new Error(`invalid package name ${packageName}`);
  }
  return `node_modules/${packageName}`;
}

function packageRootParts(packageName) {
  if (packageName.startsWith("@")) {
    const [scope, name] = packageName.split("/");
    if (!scope || !name) {
      throw new Error(`invalid scoped package name ${packageName}`);
    }
    return [scope, name];
  }
  if (!packageName || packageName.includes("/")) {
    throw new Error(`invalid package name ${packageName}`);
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
    const packageJson = JSON.parse(fs.readFileSync(path.join(packageDir, "package.json"), "utf8"));
    for (const dependencyName of dependencyNames(packageJson)) {
      enqueue(packageDir, dependencyName);
    }
  }

  return reachable;
}

function pruneExtraneousLockedPackages(pluginRoot, rootPackageJson) {
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

export {
  collectPackageRoots,
  packageRootForName,
  pruneExtraneousLockedPackages,
  removeNodeModulesBinDirs,
};
