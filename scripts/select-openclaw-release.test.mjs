#!/usr/bin/env node
import assert from "node:assert/strict";
import { selectOpenClawRelease } from "./select-openclaw-release.mjs";

const releases = [
  {
    tag_name: "v2026.5.3-1",
    draft: false,
    prerelease: false,
    assets: [],
  },
  {
    tag_name: "v2026.5.3",
    draft: false,
    prerelease: false,
    assets: [],
  },
  {
    tag_name: "v2026.5.2-beta.1",
    draft: false,
    prerelease: true,
    assets: [
      {
        name: "OpenClaw-2026.5.2-beta.1.zip",
        browser_download_url:
          "https://github.com/openclaw/openclaw/releases/download/v2026.5.2-beta.1/OpenClaw-2026.5.2-beta.1.zip",
      },
    ],
  },
  {
    tag_name: "v2026.5.2",
    draft: false,
    prerelease: false,
    assets: [
      {
        name: "OpenClaw-2026.5.2.dmg",
        browser_download_url:
          "https://github.com/openclaw/openclaw/releases/download/v2026.5.2/OpenClaw-2026.5.2.dmg",
      },
      {
        name: "OpenClaw-2026.5.2.dSYM.zip",
        browser_download_url:
          "https://github.com/openclaw/openclaw/releases/download/v2026.5.2/OpenClaw-2026.5.2.dSYM.zip",
      },
      {
        name: "OpenClaw-2026.5.2.zip",
        browser_download_url:
          "https://github.com/openclaw/openclaw/releases/download/v2026.5.2/OpenClaw-2026.5.2.zip",
      },
    ],
  },
];

const selection = selectOpenClawRelease(releases);

assert.equal(selection.latestStable.tagName, "v2026.5.3-1");
assert.equal(selection.latestStableSource.tagName, "v2026.5.3-1");
assert.equal(selection.latestStableSource.releaseVersion, "2026.5.3-1");
assert.equal(selection.latestMacAppStable.tagName, "v2026.5.2");
assert.equal(selection.latestMacAppStable.releaseVersion, "2026.5.2");
assert.equal(
  selection.latestMacAppStable.appUrl,
  "https://github.com/openclaw/openclaw/releases/download/v2026.5.2/OpenClaw-2026.5.2.zip",
);
assert.deepEqual(
  selection.appLagStableReleases.map((release) => release.tagName),
  ["v2026.5.3-1", "v2026.5.3"],
);

const none = selectOpenClawRelease([
  {
    tag_name: "v2026.5.3",
    draft: false,
    prerelease: false,
    assets: [],
  },
]);

assert.equal(none.latestStable.tagName, "v2026.5.3");
assert.equal(none.latestStableSource.tagName, "v2026.5.3");
assert.equal(none.latestStableSource.releaseVersion, "2026.5.3");
assert.equal(none.latestMacAppStable, null);
assert.deepEqual(none.appLagStableReleases, [
  { tagName: "v2026.5.3", reason: "missing-macos-zip" },
]);

const appVersion = "2026.5.3-1";
const universalAppName = `OpenClaw-${appVersion}.zip`;
const appAssets = [
  universalAppName,
  `OpenClaw-${appVersion}-arm64.zip`,
  `OpenClaw-${appVersion}-x86_64.zip`,
  `OpenClaw-${appVersion}.dSYM.zip`,
].map((name) => ({
  name,
  browser_download_url: `https://github.com/openclaw/openclaw/releases/download/v${appVersion}/${name}`,
}));

function permutations(items) {
  return items.length === 0
    ? [[]]
    : items.flatMap((item, index) =>
        permutations(items.filter((_, otherIndex) => otherIndex !== index)).map(
          (rest) => [item, ...rest],
        ),
      );
}

for (const assets of permutations(appAssets)) {
  const result = selectOpenClawRelease([{ ...releases[0], assets }]);
  assert.equal(result.latestMacAppStable.appAssetName, universalAppName);
  assert.equal(result.latestMacAppStable.appUrl, appAssets[0].browser_download_url);
  assert.equal(result.latestMacAppStable.releaseVersion, appVersion);
  assert.deepEqual(result.appLagStableReleases, []);
}

const thinOnlyRelease = { ...releases[0], assets: appAssets.slice(1) };
const appLag = selectOpenClawRelease([thinOnlyRelease, releases[3]]);
assert.equal(appLag.latestStableSource.releaseVersion, appVersion);
assert.deepEqual(appLag.latestMacAppStable, selection.latestMacAppStable);
assert.deepEqual(appLag.appLagStableReleases, [
  { tagName: `v${appVersion}`, reason: "missing-macos-zip" },
]);

const thinOnly = selectOpenClawRelease([thinOnlyRelease]);
assert.equal(thinOnly.latestStableSource.releaseVersion, appVersion);
assert.equal(thinOnly.latestMacAppStable, null);
assert.deepEqual(thinOnly.appLagStableReleases, appLag.appLagStableReleases);

console.log("release selection: ok");

function release(version, hasApp = true) {
  return {
    tag_name: `v${version}`,
    draft: false,
    prerelease: false,
    assets: hasApp ? [{
      name: `OpenClaw-${version}.zip`,
      browser_download_url: `https://github.com/openclaw/openclaw/releases/download/v${version}/OpenClaw-${version}.zip`,
    }] : [],
  };
}

// GitHub lists a newly published backport before a higher stable version.
const backportFirst = [release("2026.7.35"), release("2026.9.5"), release("2026.9.4")];
const backportSelection = selectOpenClawRelease(backportFirst);
assert.equal(backportSelection.latestStableSource.releaseVersion, "2026.9.5");
assert.equal(backportSelection.latestMacAppStable.releaseVersion, "2026.9.5");
assert.deepEqual(backportSelection.appLagStableReleases, []);
assert.equal(backportFirst[0].tag_name, "v2026.7.35", "selection must not reorder caller input");

for (const rows of permutations([
  release("2026.9.5-2", false),
  release("2026.9.5-10", false),
  release("2026.9.5"),
  release("2026.7.35"),
])) {
  const result = selectOpenClawRelease(rows);
  assert.equal(result.latestStableSource.releaseVersion, "2026.9.5-10");
  assert.equal(result.latestMacAppStable.releaseVersion, "2026.9.5");
  assert.deepEqual(result.appLagStableReleases.map(({ tagName }) => tagName), ["v2026.9.5-10", "v2026.9.5-2"]);
}

const invalidReleases = [
  { tag_name: "latest", assets: [] },
  { tag_name: "v2027.1.1-beta.1", prerelease: false, assets: [] },
  { ...release("2027.1.1"), draft: true },
  { ...release("2027.1.2"), prerelease: true },
  { assets: [] },
  null,
];
assert.equal(selectOpenClawRelease([...invalidReleases, release("2026.9.5")]).latestStableSource.releaseVersion, "2026.9.5");
assert.equal(selectOpenClawRelease(invalidReleases).latestStableSource, null);
assert.equal(selectOpenClawRelease([release("2026.9.9"), release("2026.10.1")]).latestStableSource.releaseVersion, "2026.10.1");
assert.equal(selectOpenClawRelease([{ tagName: "v2026.9.5" }]).latestStableSource.releaseVersion, "2026.9.5");
