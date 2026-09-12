import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";

const workflow = readFileSync(new URL("../.github/workflows/pin-stable-openclaw-version.yml", import.meta.url), "utf8");
// Execute the workflow's actual shell bodies so a staging regression cannot
// hide behind a separate test implementation of promotion.
function stepScripts(name) {
  return [...workflow.matchAll(new RegExp(`      - name: ${name}\\n[\\s\\S]*?        run: \\|\\n((?:          .*\\n|\\n)+)`, "g"))]
    .map((match) => match[1].replace(/^          /gm, ""));
}
const digestScripts = stepScripts("Record materialized diff digest");
const [promotionScript] = stepScripts("Promote selected release");
assert.equal(digestScripts.length, 2);
assert.ok(promotionScript);

function fixture(t, { deletionOnly = false, removePlugin = true } = {}) {
  const root = mkdtempSync(join(tmpdir(), "pin-promotion-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const env = {
    ...process.env,
    GIT_AUTHOR_NAME: "Pin test", GIT_AUTHOR_EMAIL: "pin@example.invalid",
    GIT_COMMITTER_NAME: "Pin test", GIT_COMMITTER_EMAIL: "pin@example.invalid",
    GIT_CONFIG_NOSYSTEM: "1", GIT_CONFIG_GLOBAL: "/dev/null",
    GITHUB_ACTIONS: "true", GITHUB_OUTPUT: join(root, "output"),
    PROMOTE_REF: "refs/heads/test-promotion",
  };
  const git = (...args) => execFileSync("git", args, { cwd: root, env, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
  const write = (path, text) => {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), text);
  };
  git("init", "--quiet", "--initial-branch=main");
  write("nix/sources/openclaw-source.nix", "old pin\n");
  write("nix/generated/openclaw-runtime-plugins/qqbot.nix", "retired plugin\n");
  write("README.md", "unrelated\n");
  // Only materialization is stubbed: these tests exercise real Git staging,
  // hashing, commit creation, and the branch's no-publication boundary.
  write("scripts/update-pins.sh", `#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == apply ]]; then exit 0; fi
printf '%s\\n' nix/sources/openclaw-source.nix
{
  git ls-files -- nix/generated/openclaw-runtime-plugins
  find nix/generated/openclaw-runtime-plugins -type f
} | sort -u
`);
  execFileSync("chmod", ["+x", join(root, "scripts/update-pins.sh")]);
  git("add", ".");
  git("commit", "--quiet", "-m", "fixture");
  const baseline = git("rev-parse", "HEAD");
  if (removePlugin) rmSync(join(root, "nix/generated/openclaw-runtime-plugins/qqbot.nix"));
  if (!deletionOnly) {
    write("nix/sources/openclaw-source.nix", "new pin\n");
    write("nix/generated/openclaw-runtime-plugins/new-plugin.nix", "new plugin\n");
  }
  write("README.md", "unrelated dirty edit\n");
  const shell = (script, extraEnv = {}) => spawnSync("bash", ["-e", "-c", script.replace(/\$\{\{[^}]+\}\}/g, "fixture")], {
    cwd: root, env: { ...env, ...extraEnv }, encoding: "utf8",
  });
  return { root, git, shell, baseline };
}
function checked(result) {
  assert.equal(result.status, 0, result.stderr + result.stdout);
  return result.stdout;
}
function digest(f, script) {
  checked(f.shell(script));
  return readFileSync(join(f.root, "output"), "utf8").trim().split("=")[1];
}

for (const deletionOnly of [false, true]) {
  test(`promotion includes removed plugins${deletionOnly ? " in a deletion-only update" : ", additions, and modified pins"}`, (t) => {
    const validators = digestScripts.map((script) => {
      const f = fixture(t, { deletionOnly });
      return digest(f, script);
    });
    assert.equal(validators[0], validators[1]);
    assert.notEqual(validators[0], createHash("sha256").update("").digest("hex"));
    const f = fixture(t, { deletionOnly });
    const output = checked(f.shell(promotionScript, { VALIDATED_MATERIALIZATION_DIGEST: validators[0] }));
    assert.match(output, /Validated promotion commit.*skipping main push/);
    assert.notEqual(f.git("rev-parse", "HEAD"), f.baseline);
    const changes = f.git("diff-tree", "--no-commit-id", "--name-status", "-r", "HEAD");
    assert.match(changes, /D\s+nix\/generated\/openclaw-runtime-plugins\/qqbot.nix/);
    if (!deletionOnly) {
      assert.match(changes, /A\s+nix\/generated\/openclaw-runtime-plugins\/new-plugin.nix/);
      assert.match(changes, /M\s+nix\/sources\/openclaw-source.nix/);
    }
    assert.doesNotMatch(changes, /README/);
    assert.equal(f.git("status", "--porcelain", "--untracked-files=no"), "M README.md");
  });
}

test("a different removed-plugin set fails before committing", (t) => {
  const validator = fixture(t, { removePlugin: false });
  const expected = digest(validator, digestScripts[0]);
  const promoter = fixture(t);
  const result = promoter.shell(promotionScript, { VALIDATED_MATERIALIZATION_DIGEST: expected });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /different release diff/);
  assert.equal(promoter.git("rev-parse", "HEAD"), promoter.baseline);
});

test("unchanged pins do not create a promotion commit", (t) => {
  const f = fixture(t, { deletionOnly: true, removePlugin: false });
  assert.match(checked(f.shell(promotionScript)), /No pin changes detected/);
  assert.equal(f.git("rev-parse", "HEAD"), f.baseline);
});
