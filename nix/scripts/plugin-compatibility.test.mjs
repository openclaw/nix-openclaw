import assert from "node:assert/strict";
import test from "node:test";
import { spawnSync } from "node:child_process";
import { satisfiesPluginApiRange as api, satisfiesPeerRange as peer, satisfiesMinHostVersion as minimum } from "./plugin-compatibility.mjs";

for (const [version, range, expected] of [
  ["2026.9.4", "*", true], ["2026.9.4", "^2026.9.0", true],
  ["2026.9.4", "~2026.9.0", true], ["2026.10.1", "~2026.9.0", false],
  ["2026.9.4", "2026.9.x", true], ["2026.9.4", ">=2026.9.1 <2026.10.0", true],
  ["2026.9.4", ">=2026.9.5", false], ["2026.10.1", "2026.9", true],
  ["2026.9.4", "2026.9.3 || 2026.9.4", false], ["2026.9.4", "bad", false],
  ["2026.9.4-2", ">=2026.9.4", true], ["2026.9.4-rc.1", ">=2026.9.4", true],
  ["2026.9.4-rc.1", ">=2026.9.4-rc.2", false], ["2026.9.4", "   ", false],
]) test(`plugin API ${version} satisfies ${range}: ${expected}`, () => assert.equal(api(version, range), expected));

for (const [version, range, expected] of [
  ["2026.9.4", "*", true], ["2026.9.4", "^2026.9.0 || ^2027.1.0", true],
  ["2026.9.4", "2026.9.1 - 2026.9.5", true], ["2026.10.1", "2026.9", false],
  ["2026.9.4-2", ">=2026.9.4", true], ["2026.9.4-rc.1", ">=2026.9.4", false],
  ["2026.9.4", "banana", false], ["2026.9.4-rc.1", "*", false],
]) test(`peer ${version} satisfies ${range}: ${expected}`, () => assert.equal(peer(version, range), expected));

for (const [version, range, expected] of [
  ["2026.9.4", ">=2026.9.3", true], ["2026.9.4", "2026.9.3", true],
  ["2026.9.4", ">=2026.9.5", false], ["2026.9.4-2", ">=2026.9.4-1", true],
  ["2026.9.4-1", ">=2026.9.4-2", false], ["2026.9.4", ">=2026.9.4-1", false],
  ["2026.9.4-1", ">=2026.9.4", true], ["2026.9.4-rc.1", ">=2026.9.4", false],
  ["2026.9.5-rc.1", ">=2026.9.4-2", true], ["invalid", ">=2026.9.4", false],
  ["2026.9.4", ">=999999999999999999999.1.1", false], ["2026.9.4", "*", false],
]) test(`host ${version} satisfies ${range}: ${expected}`, () => assert.equal(minimum(version, range), expected));

test("absent optional compatibility requirements remain allowed", () => {
  for (const check of [api, peer, minimum]) for (const value of [undefined, null, ""]) assert.equal(check("2026.9.4", value), true);
});

test("invalid metadata does not disable compatibility checks", () => {
  for (const check of [api, peer, minimum]) for (const value of [false, 0, [], {}]) assert.equal(check("2026.9.4", value), false);
});

test("a missing compatibility tool aborts the builder before processing artifacts", () => {
  const moduleUrl = new URL("./runtime-plugin-locks/builder.mjs", import.meta.url).href;
  const result = spawnSync(process.execPath, ["--input-type=module", "-e", `import {createLockBuilder} from ${JSON.stringify(moduleUrl)}; createLockBuilder({});`], {
    encoding: "utf8", env: { ...process.env, PATH: "/nonexistent/nix-openclaw-tool-fixture" },
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /node-semver is required/);
});
