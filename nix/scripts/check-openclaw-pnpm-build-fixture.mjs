import assert from "node:assert/strict";
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";

export const policy =
  "packages:\n  - '.'\n  - 'packages/*'\nminimumReleaseAge: 10080\nminimumReleaseAgeStrict: true\nallowBuilds:\n  pnpm-contract-mature: true\n";

export function packageFixtures() {
  return ["mature", "young", "shared", "dev", "optional"].map((kind) => {
    const lifecycle = kind === "mature";
    return {
      manifest: {
        name: `pnpm-contract-${kind}`,
        version: "1.0.0",
        main: "index.js",
        ...(["mature", "dev"].includes(kind)
          ? { dependencies: { "pnpm-contract-shared": "1.0.0" } }
          : {}),
        ...(lifecycle ? { scripts: { postinstall: "node postinstall.cjs" } } : {}),
      },
      files: {
        "index.js": `${lifecycle ? 'require("pnpm-contract-shared");' : ""}module.exports = "registry-offline-ok";\n`,
        ...(lifecycle
          ? {
              "postinstall.cjs":
                'const fs=require("node:fs");if(fs.existsSync("built.json"))throw Error("LIFECYCLE_RERUN");fs.writeFileSync("built.json",\'{"built":"once"}\\n\');\n',
            }
          : {}),
      },
      published: kind === "young" ? new Date().toISOString() : "2020-01-01T00:00:00.000Z",
    };
  });
}

export function workspaceFixture(packages, name) {
  const devDependencies = { "pnpm-contract-dev": "1.0.0" };
  const optionalDependencies = { "pnpm-contract-optional": "1.0.0" };
  const worker = {
    name: "pnpm-contract-workspace",
    version: "1.0.0",
    main: "index.cjs",
    dependencies: { [name]: "1.0.0" },
    devDependencies,
    optionalDependencies,
  };
  const manifest = {
    private: true,
    scripts: { build: "node build.cjs" },
    dependencies: { [name]: "1.0.0", "pnpm-contract-workspace": "workspace:*" },
    devDependencies,
    optionalDependencies,
  };
  const importer = (pkg) =>
    Object.fromEntries(
      ["dependencies", "devDependencies", "optionalDependencies"].map((kind) => [
        kind,
        Object.fromEntries(
          Object.entries(pkg[kind]).map(([key, version]) => [
            key,
            {
              specifier: version,
              version: version === "workspace:*" ? "link:packages/worker" : version,
            },
          ]),
        ),
      ]),
    );
  const selected = [name, "pnpm-contract-shared", "pnpm-contract-dev", "pnpm-contract-optional"];
  return {
    manifest,
    workspace: {
      lockfileVersion: "9.0",
      settings: { autoInstallPeers: true, excludeLinksFromLockfile: false },
      importers: { ".": importer(manifest), "packages/worker": importer(worker) },
      packages: Object.fromEntries(
        selected.map((key) => [
          `${key}@1.0.0`,
          { resolution: { integrity: packages.get(key).integrity } },
        ]),
      ),
      snapshots: Object.fromEntries(
        selected.map((key) => [
          `${key}@1.0.0`,
          packages.get(key).manifest.dependencies
            ? { dependencies: packages.get(key).manifest.dependencies }
            : {},
        ]),
      ),
    },
    files: {
      "packages/worker/package.json": JSON.stringify(worker),
      "packages/worker/index.cjs": `module.exports = require(${JSON.stringify(name)});\n`,
      "build.cjs": `
const fs = require("node:fs"), assert = require("node:assert/strict");
assert.equal(fs.readFileSync("node_modules/pnpm-contract-mature/built.json","utf8"), '{"built":"once"}\\n');
for (const project of [".", "packages/worker"]) {
  const r = require("node:module").createRequire(require("node:path").resolve(project, "package.json"));
  assert.ok(r.resolve("pnpm-contract-dev"));
}
const artifacts = {
  "dist/control-ui/index.html": "CONTROL_UI\\n",
  "dist/plugin-sdk/index.d.ts": "DECLARATIONS\\n",
  "packages/worker/dist/built.txt": "WORKSPACE_ARTIFACT\\n",
};
for (const [file, bytes] of Object.entries(artifacts)) {
  fs.mkdirSync(require("node:path").dirname(file), {recursive:true});
  fs.writeFileSync(file, bytes);
}
fs.writeFileSync("built-before.json", JSON.stringify({
  ...artifacts, "node_modules/pnpm-contract-mature/built.json": '{"built":"once"}\\n',
}));
`,
    },
  };
}

export function verifyBuiltProject(cwd) {
  const r = createRequire(path.join(cwd, "package.json"));
  for (const name of [
    "pnpm-contract-mature",
    "pnpm-contract-optional",
    "pnpm-contract-workspace",
  ]) {
    assert.equal(r(name), "registry-offline-ok");
  }
  const prod = createRequire(r.resolve("pnpm-contract-mature"));
  assert.equal(prod("pnpm-contract-shared"), "registry-offline-ok");
  const worker = createRequire(path.join(cwd, "packages/worker/package.json"));
  assert.equal(worker("pnpm-contract-mature"), "registry-offline-ok");
  assert.equal(worker("pnpm-contract-optional"), "registry-offline-ok");
  for (const importer of [cwd, `${cwd}/packages/worker`]) {
    assert.throws(
      () => createRequire(path.join(importer, "package.json")).resolve("pnpm-contract-dev"),
      { code: "MODULE_NOT_FOUND" },
    );
    assert.equal(fs.existsSync(`${importer}/node_modules/pnpm-contract-dev`), false);
  }
  assert.equal(
    fs
      .readdirSync(`${cwd}/node_modules/.pnpm`)
      .some((name) => name.startsWith("pnpm-contract-dev@")),
    false,
  );
  const before = JSON.parse(fs.readFileSync(`${cwd}/built-before.json`, "utf8"));
  assert.equal(Object.keys(before).length, 4);
  for (const [file, bytes] of Object.entries(before)) {
    assert.equal(fs.readFileSync(`${cwd}/${file}`, "utf8"), bytes);
  }
}
