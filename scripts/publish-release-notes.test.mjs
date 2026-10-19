import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

const script = readFileSync(new URL("./publish-release-tag.sh", import.meta.url), "utf8");
const start = script.indexOf("write_release_notes() {");
const end = script.indexOf("\nsync_github_release() {", start);
assert.ok(start >= 0 && end > start);
const renderer = script.slice(start, end);

function fixture(t, changelog) {
  const root = mkdtempSync(join(tmpdir(), "release-notes-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  if (changelog !== null) writeFileSync(join(root, "CHANGELOG.md"), changelog);
  return (version = "2026.9.4") => {
    const output = join(root, "notes.md");
    const result = spawnSync("bash", ["-eu", "-c", `${renderer}\nwrite_release_notes "$1" "$2" "$3" "$4" "$5" "$6"`,
      "release-notes-test", output, `v${version}`, version, "source-sha", "package-sha", "https://example.invalid/ci"], {
      env: { ...process.env, repo_root: root }, encoding: "utf8",
    });
    assert.equal(result.status, 0, result.stderr);
    return readFileSync(output, "utf8");
  };
}

test("published notes retain the exact dated release section across repeated syncs", (t) => {
  const section = "## 2026.9.4 - 2026-09-11\n\n**Highlights:** Supported runtime.\n\n### Fixed\n\n- Keep `literal $text` and thanks @contributor.\n\n";
  const render = fixture(t, `# Changelog\n\n## Unreleased\n\n- Future work.\n\n${section}## 2026.9.3 - 2026-09-10\n\n- Older work.\n`);
  const notes = render();
  assert.ok(notes.includes(section));
  assert.match(notes, /https:\/\/github.com\/openclaw\/openclaw\/releases\/tag\/v2026\.9\.4/);
  assert.match(notes, /nix run github:openclaw\/nix-openclaw\/v2026\.9\.4#openclaw/);
  assert.doesNotMatch(notes, /Future work|Older work|## Unreleased/);
  assert.equal(render(), notes);
});

test("release selection matches a complete version, not a prefix", (t) => {
  const render = fixture(t, "## 2026.9.40 - 2026-09-11\n\n- Different release.\n");
  assert.doesNotMatch(render(), /Different release|## 2026\.9\.40/);
});

test("historical releases without a changelog retain their generated metadata", (t) => {
  const notes = fixture(t, null)("2026.7.1");
  assert.match(notes, /nix-openclaw package state for OpenClaw `v2026\.7\.1`/);
  assert.match(notes, /CI proof: https:\/\/example\.invalid\/ci/);
});

test("the workflow dry run validates eligible metadata without calling GitHub", (t) => {
  const root = mkdtempSync(join(tmpdir(), "release-dry-run-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  for (const directory of ["scripts", "nix/sources", "nix/packages", "bin"]) {
    mkdirSync(join(root, directory), { recursive: true });
  }
  writeFileSync(join(root, "scripts/publish-release-tag.sh"), script);
  chmodSync(join(root, "scripts/publish-release-tag.sh"), 0o755);
  writeFileSync(join(root, "nix/sources/openclaw-source.nix"),
    'releaseTag = "v2026.9.4";\nreleaseVersion = "2026.9.4";\nrev = "source-sha";\n');
  writeFileSync(join(root, "nix/packages/openclaw-app.nix"),
    'version = "2026.9.4";\nurl = "https://github.com/openclaw/openclaw/releases/download/v2026.9.4/OpenClaw-2026.9.4.zip";\n');
  writeFileSync(join(root, "bin/gh"), "#!/bin/sh\necho unexpected GitHub call >&2\nexit 91\n");
  chmodSync(join(root, "bin/gh"), 0o755);
  const workflow = readFileSync(new URL("../.github/workflows/publish-mirrored-release-tag.yml", import.meta.url), "utf8");
  const command = workflow.match(/name: Validate mirrored release without publishing\n[^\n]+\n\s+run: ([^\n]+)/)?.[1];
  assert.ok(command, "workflow must expose the credential-free validation step");
  const result = spawnSync("bash", ["-euc", command], {
    cwd: root, encoding: "utf8", env: { ...process.env, PATH: `${join(root, "bin")}:${process.env.PATH}` },
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /eligible=true/);
  assert.doesNotMatch(result.stderr, /unexpected GitHub call/);
});
