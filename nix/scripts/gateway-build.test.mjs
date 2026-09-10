import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const builder = path.join(import.meta.dirname, "gateway-build.sh");

function fixture(t, failAt = "", extraEnv = {}, sourceVariant) {
  const root = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "gateway-build-")));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  function put(name, contents, mode = 0o644) {
    const file = path.join(root, name);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, contents, { mode });
    return file;
  }
  for (const dir of ["home", "store", "node_modules/.bin", "node_modules/.pnpm"])
    fs.mkdirSync(path.join(root, dir), { recursive: true });
  put("package.json", JSON.stringify({ pnpm: { onlyBuiltDependencies: ["fixture-native"] } }));
  put(".pnpm-store-path", path.join(root, "store"));
  let source;
  if (sourceVariant) {
    const target = "node_modules/.pnpm/fs-safe/node_modules/@openclaw/fs-safe";
    put(`${target}/package.json`, '{"name":"@openclaw/fs-safe","version":"1.0.0"}\n');
    fs.mkdirSync(path.join(root, "node_modules/@openclaw"), { recursive: true });
    fs.symlinkSync(
      "../.pnpm/fs-safe/node_modules/@openclaw/fs-safe",
      path.join(root, "node_modules/@openclaw/fs-safe"),
    );
    put("prepared-source/src/index.ts", "prepared input\n");
    put("prepared-source/tsconfig.json", "prepared config\n");
    // A whole-package copy must not replace installed metadata or existing inputs.
    put("prepared-source/package.json", '{"name":"wrong-manifest"}\n');
    if (sourceVariant === "existing") {
      put(`${target}/src/index.ts`, "installed input\n");
      put(`${target}/tsconfig.json`, "installed config\n");
    }
    source = path.join(root, "prepared-source");
  }
  const packageRoot = path.join(root, "node_modules/@openclaw/fs-safe");
  const identity = () => ({
    target: fs.readlinkSync(packageRoot),
    inode: fs.statSync(`${packageRoot}/package.json`).ino,
    manifest: fs.readFileSync(`${packageRoot}/package.json`, "utf8"),
  });
  const before = source ? identity() : undefined;
  const prebuild = put("prebuild.sh", 'printf "prepare\\n" >> "$EVENTS"\n');
  const setup = put("setup.sh", 'patchShebangs() { printf "shebangs\\n" >> "$EVENTS"; }\n');
  put(
    "bin/pnpm",
    `#!/bin/sh
set -eu
stage="$1"
if [ "$1" = install ]; then
  if [ "$2" = --prod ]; then stage=install-prod; else stage=install-dev; fi
fi
printf '%s\\n' "$stage" >> "$EVENTS"
if [ "$stage" = "$FAIL_AT" ]; then exit 37; fi
test "$PNPM_CONFIG_STORE_DIR" = "$(cat .pnpm-store-path)"
test "$NPM_CONFIG_STORE_DIR" = "$PNPM_CONFIG_STORE_DIR"
if [ "$stage" = install-prod ]; then
  test "$PNPM_CONFIG_MODULES_CACHE_MAX_AGE" = 0
  test "$NPM_CONFIG_MODULES_CACHE_MAX_AGE" = 0
else
  test -z "\${PNPM_CONFIG_MODULES_CACHE_MAX_AGE+x}\${NPM_CONFIG_MODULES_CACHE_MAX_AGE+x}"
fi
case "$1" in
  install)
    if [ "$stage" = install-prod ]; then
      test -f dist/control-ui/index.html
      test -f dist/plugin-sdk/index.d.ts
      shift
    fi
    test "$CI" = true
    test "$2" = --offline
    test "$3" = --frozen-lockfile
    test "$4" = --ignore-scripts
    test "$5" = --store-dir
    test "$6" = "$PNPM_CONFIG_STORE_DIR"
    ;;
  rebuild)
    test "$2" = fixture-native
    test "$NODE_LLAMA_CPP_SKIP_DOWNLOAD" = 1
    test "$PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD" = 1
    ;;
  build)
    test "$#" = 1
    test "\${OPENCLAW_RUN_NODE_SKIP_DTS_BUILD:-0}" = 0
    mkdir -p dist/control-ui dist/plugin-sdk
    printf 'ui' > dist/control-ui/index.html
    printf 'declarations' > dist/plugin-sdk/index.d.ts
    ;;
  exec)
    test "$2" = tsc
    test "$3" = -p
    test -f "$4"
    mkdir -p node_modules/@openclaw/fs-safe/dist
    printf 'declarations' > node_modules/@openclaw/fs-safe/dist/index.d.ts
    ;;
  *) exit 91 ;;
esac
`,
    0o755,
  );
  // Nix uses GNU find. Model its final broken-link cleanup on BSD hosts only.
  put(
    "bin/find",
    `#!/bin/sh
set -eu
test "$*" = 'node_modules -xtype l -delete'
printf 'cleanup\\n' >> "$EVENTS"
`,
    0o755,
  );
  const events = path.join(root, "events");
  const result = spawnSync("sh", [builder], {
    cwd: root,
    encoding: "utf8",
    timeout: 10000,
    env: {
      PATH: `${path.join(root, "bin")}:${path.dirname(process.execPath)}:${process.env.PATH}`,
      HOME: path.join(root, "home"),
      TMPDIR: path.join(root, "home"),
      GATEWAY_PREBUILD_SH: prebuild,
      STDENV_SETUP: setup,
      EVENTS: events,
      FAIL_AT: failAt,
      ...(source ? { OPENCLAW_FS_SAFE_SOURCE: source } : {}),
      ...extraEnv,
    },
  });
  return {
    result,
    events: fs.readFileSync(events, "utf8").trim().split("\n"),
    root,
    before,
    identity,
  };
}

test("source build delegates complete artifacts to the upstream package command", (t) => {
  const { result, events, root } = fixture(t);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.deepEqual(events, [
    "prepare",
    "install-dev",
    "rebuild",
    "shebangs",
    "build",
    "install-prod",
    "cleanup",
  ]);
  assert.equal(fs.readFileSync(path.join(root, "dist/control-ui/index.html"), "utf8"), "ui");
  assert.equal(
    fs.readFileSync(path.join(root, "dist/plugin-sdk/index.d.ts"), "utf8"),
    "declarations",
  );
});

test("package build cannot inherit an updater's runtime-only declaration profile", (t) => {
  const { result } = fixture(t, "", { OPENCLAW_RUN_NODE_SKIP_DTS_BUILD: "1" });
  assert.equal(result.status, 0, result.stdout + result.stderr);
});

for (const [failAt, expected] of [
  ["install-dev", ["prepare", "install-dev"]],
  ["rebuild", ["prepare", "install-dev", "rebuild"]],
  ["build", ["prepare", "install-dev", "rebuild", "shebangs", "build"]],
  ["install-prod", ["prepare", "install-dev", "rebuild", "shebangs", "build", "install-prod"]],
]) {
  test(`${failAt} failure preserves exit status and prevents later phases`, (t) => {
    const { result, events } = fixture(t, failAt);
    assert.equal(result.status, 37, result.stdout + result.stderr);
    assert.deepEqual(events, expected);
  });
}

for (const variant of ["existing", "missing"]) {
  test(`fs-safe preparation preserves pnpm ownership and ${variant} inputs`, (t) => {
    const { result, root, before, identity, events } = fixture(t, "", {}, variant);
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.deepEqual(identity(), before);
    assert.ok(events.includes("exec"));
    const expected = variant === "existing" ? "installed" : "prepared";
    assert.equal(
      fs.readFileSync(`${root}/node_modules/@openclaw/fs-safe/src/index.ts`, "utf8"),
      `${expected} input\n`,
    );
    assert.equal(
      fs.readFileSync(`${root}/node_modules/@openclaw/fs-safe/tsconfig.json`, "utf8"),
      `${expected} config\n`,
    );
    // This harness proves shell filesystem ownership, not compiler correctness.
    assert.equal(
      fs.readFileSync(`${root}/node_modules/@openclaw/fs-safe/dist/index.d.ts`, "utf8"),
      "declarations",
    );
  });
}
