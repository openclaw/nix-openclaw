import fs from "node:fs";
import path from "node:path";

const [buildArg, outputArg] = process.argv.slice(2);
const build = fs.realpathSync(buildArg);
const output = fs.realpathSync(outputArg);
const within = (root, file) => {
  const relative = path.relative(root, file);
  return (
    relative === "" ||
    (relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative))
  );
};
const inStore = (file) => within("/nix/store", file);
const visited = new Set([build]);
const workspaces = new Set();

function installedPackages(nodeModules) {
  if (!fs.existsSync(nodeModules)) return;
  const resolved = fs.realpathSync(nodeModules);
  if (inStore(resolved)) return;
  if (!within(build, resolved))
    throw new Error(`dependency directory outside build: ${nodeModules}`);
  for (const entry of fs.readdirSync(nodeModules, { withFileTypes: true })) {
    if (entry.name.startsWith(".") || (!entry.isDirectory() && !entry.isSymbolicLink())) continue;
    const file = path.join(nodeModules, entry.name);
    if (entry.name.startsWith("@")) installedPackages(file);
    else visitPackage(file);
  }
}

function visitPackage(file) {
  const directory = fs.realpathSync(file);
  if (inStore(directory)) return;
  if (!within(build, directory)) throw new Error(`dependency outside build: ${file}`);
  if (visited.has(directory)) return;
  visited.add(directory);
  if (!path.relative(build, directory).split(path.sep).includes("node_modules")) {
    workspaces.add(directory);
  }
  installedPackages(path.join(directory, "node_modules"));
  let siblings = path.dirname(directory);
  if (path.basename(siblings).startsWith("@")) siblings = path.dirname(siblings);
  // pnpm stores dependency and peer links beside the package, not inside it.
  // Follow this package's slot only; other slots do not establish reachability.
  if (
    path.basename(siblings) === "node_modules" &&
    path.basename(path.dirname(path.dirname(siblings))) === ".pnpm"
  ) {
    installedPackages(siblings);
  }
}

const manifest = JSON.parse(fs.readFileSync(path.join(build, "package.json"), "utf8"));
const optional = manifest.optionalDependencies ?? {};
const seeds = new Map([
  ...Object.keys(manifest.peerDependencies ?? {}).map((name) => [name, false]),
  ...Object.keys(manifest.dependencies ?? {}).map((name) => [name, !Object.hasOwn(optional, name)]),
  ...Object.keys(optional).map((name) => [name, false]),
]);
for (const [name, required] of seeds) {
  const file = path.join(build, "node_modules", name);
  if (!fs.lstatSync(file, { throwIfNoEntry: false })) {
    if (required) throw new Error(`missing required dependency: ${name}`);
    continue;
  }
  visitPackage(file);
}

const roots = [...workspaces].filter(
  (directory) =>
    ![...workspaces].some((parent) => parent !== directory && within(parent, directory)),
);
for (const directory of roots) {
  const destination = path.join(output, path.relative(build, directory));
  fs.cpSync(directory, destination, { recursive: true, verbatimSymlinks: true });
}

function linksIn(directory, visit) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) visit(file);
    else if (entry.isDirectory()) linksIn(file, visit);
  }
}

const installedRoots = [
  path.join(output, "node_modules"),
  ...roots.map((directory) => path.join(output, path.relative(build, directory))),
];
// Keep relative workspace links byte-identical. Only build-absolute links need
// relocation; no output link may rely on the disposable build tree afterwards.
for (const root of installedRoots) {
  linksIn(root, (file) => {
    const target = fs.readlinkSync(file);
    const resolved = path.resolve(path.dirname(file), target);
    if (path.isAbsolute(target) && within(build, resolved)) {
      fs.unlinkSync(file);
      fs.symlinkSync(path.join(output, path.relative(build, resolved)), file);
    } else if (!within(output, resolved) && !inStore(resolved)) {
      throw new Error(`symlink escapes installed build closure: ${file}`);
    }
  });
}
const runtime = path.join(output, "dist-runtime");
if (fs.lstatSync(runtime, { throwIfNoEntry: false })?.isDirectory()) {
  linksIn(runtime, (file) => {
    if (!fs.existsSync(file)) throw new Error(`dangling symlinks found under ${runtime}: ${file}`);
  });
}
for (const root of installedRoots) {
  linksIn(root, (file) => {
    if (!fs.existsSync(file)) throw new Error(`dangling symlinks found under ${root}: ${file}`);
    const target = fs.realpathSync(file);
    if (!within(output, target) && !inStore(target)) {
      throw new Error(`symlink escapes installed build closure: ${file}`);
    }
  });
}
