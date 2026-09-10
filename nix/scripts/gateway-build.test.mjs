import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const builder = path.join(import.meta.dirname, "gateway-build.sh");

function fixture(t, failAt = "", extraEnv = {}) {
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
  const prebuild = put("prebuild.sh", 'printf "prepare\\n" >> "$EVENTS"\n');
  const setup = put("setup.sh", 'patchShebangs() { printf "shebangs\\n" >> "$EVENTS"; }\n');
  put(
    "bin/pnpm",
    `#!/bin/sh
set -eu
printf '%s\\n' "$1" >> "$EVENTS"
if [ "$1" = "$FAIL_AT" ]; then exit 37; fi
case "$1" in
  install)
    test "$2" = --offline
    test "$3" = --frozen-lockfile
    test "$4" = --ignore-scripts
    test "$5" = --store-dir
    test "$6" = "$PNPM_STORE_DIR"
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
  prune)
    test "$2" = --prod
    test "$PNPM_CONFIG_OFFLINE" = true
    test -f dist/control-ui/index.html
    test -f dist/plugin-sdk/index.d.ts
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
      ...extraEnv,
    },
  });
  return {
    result,
    events: fs.readFileSync(events, "utf8").trim().split("\n"),
    root,
  };
}

test("source build delegates complete artifacts to the upstream package command", (t) => {
  const { result, events, root } = fixture(t);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.deepEqual(events, [
    "prepare",
    "install",
    "rebuild",
    "shebangs",
    "build",
    "prune",
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
  ["install", ["prepare", "install"]],
  ["rebuild", ["prepare", "install", "rebuild"]],
  ["build", ["prepare", "install", "rebuild", "shebangs", "build"]],
  ["prune", ["prepare", "install", "rebuild", "shebangs", "build", "prune"]],
]) {
  test(`${failAt} failure preserves exit status and prevents later phases`, (t) => {
    const { result, events } = fixture(t, failAt);
    assert.equal(result.status, 37, result.stdout + result.stderr);
    assert.deepEqual(events, expected);
  });
}
