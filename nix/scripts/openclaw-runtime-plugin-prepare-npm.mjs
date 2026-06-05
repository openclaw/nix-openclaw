import fs from "node:fs";
import path from "node:path";

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
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

function isUnsupportedResolvedSource(resolved) {
  return /^(file:|workspace:|git\+|git:|ssh:|https:\/\/github\.com\/)/.test(resolved);
}

const dependencyMode = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE");
if (dependencyMode !== "shrinkwrap") {
  process.exit(0);
}

const expectedPackageName = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME");
const expectedVersion = requiredEnv("OPENCLAW_RUNTIME_PLUGIN_VERSION");
const packageJsonPath = path.resolve("package.json");
const shrinkwrapPath = path.resolve("npm-shrinkwrap.json");

if (!fs.existsSync(packageJsonPath)) {
  fail("package.json missing from shrinkwrapped runtime plugin package root");
}
if (!fs.existsSync(shrinkwrapPath)) {
  fail("npm-shrinkwrap.json missing from shrinkwrapped runtime plugin package root");
}

const packageJson = readJson(packageJsonPath);
const shrinkwrap = readJson(shrinkwrapPath);
const rootLock = shrinkwrap.packages?.[""];

if (packageJson.name !== expectedPackageName) {
  fail(`package name mismatch: expected ${expectedPackageName}, got ${packageJson.name}`);
}
if (packageJson.version !== expectedVersion) {
  fail(`package version mismatch: expected ${expectedVersion}, got ${packageJson.version}`);
}
if (![2, 3].includes(shrinkwrap.lockfileVersion)) {
  fail(`unsupported npm-shrinkwrap.json lockfileVersion ${shrinkwrap.lockfileVersion}`);
}
if (rootLock?.name && rootLock.name !== expectedPackageName) {
  fail(`shrinkwrap root name mismatch: expected ${expectedPackageName}, got ${rootLock.name}`);
}
if (rootLock?.version && rootLock.version !== expectedVersion) {
  fail(`shrinkwrap root version mismatch: expected ${expectedVersion}, got ${rootLock.version}`);
}

for (const [packagePath, entry] of Object.entries(shrinkwrap.packages ?? {})) {
  if (packagePath === "") {
    continue;
  }
  if (entry.dev === true) {
    fail(`shrinkwrap contains dev package ${packagePath}`);
  }
  if (entry.link === true) {
    fail(`shrinkwrap contains linked package ${packagePath}`);
  }
  if (typeof entry.resolved === "string" && isUnsupportedResolvedSource(entry.resolved)) {
    fail(`shrinkwrap contains unsupported resolved source for ${packagePath}: ${entry.resolved}`);
  }
}

if (packageJson.devDependencies) {
  delete packageJson.devDependencies;
  writeJson(packageJsonPath, packageJson);
}
