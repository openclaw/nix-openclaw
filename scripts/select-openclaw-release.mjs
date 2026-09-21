#!/usr/bin/env node
import { pathToFileURL } from "node:url";

export function selectOpenClawRelease(releases) {
  if (!Array.isArray(releases)) {
    throw new Error("Expected a GitHub releases JSON array");
  }

  const stableReleases = releases.filter((release) => {
    return release && release.draft !== true && release.prerelease !== true;
  });
  const latestStable = stableReleases[0] ?? null;
  const latestStableSource = latestStable
    ? stableSourceSelection(latestStable)
    : null;
  const appLagStableReleases = [];

  for (const release of stableReleases) {
    const tagName = release.tag_name ?? release.tagName;
    if (!tagName) {
      appLagStableReleases.push({
        tagName: null,
        reason: "missing-tag",
      });
      continue;
    }

    // The shared Darwin pin must serve both architectures, even when thin ZIPs
    // appear before the universal app in the upstream asset list.
    const universalAppName = `OpenClaw-${tagName.replace(/^v/, "")}.zip`;
    const appAsset = (release.assets ?? []).find(
      (asset) =>
        asset?.name === universalAppName && Boolean(asset?.browser_download_url),
    );

    if (!appAsset) {
      appLagStableReleases.push({
        tagName,
        reason: "missing-macos-zip",
      });
      continue;
    }

    return {
      latestStable: latestStableSource
        ? { tagName: latestStableSource.tagName }
        : null,
      latestStableSource,
      latestMacAppStable: {
        tagName,
        releaseVersion: tagName.replace(/^v/, ""),
        appAssetName: appAsset.name,
        appUrl: appAsset.browser_download_url,
      },
      appLagStableReleases,
    };
  }

  return {
    latestStable: latestStableSource
      ? { tagName: latestStableSource.tagName }
      : null,
    latestStableSource,
    latestMacAppStable: null,
    appLagStableReleases,
  };
}

function stableSourceSelection(release) {
  const tagName = release.tag_name ?? release.tagName;
  if (!tagName) {
    return null;
  }

  return {
    tagName,
    releaseVersion: tagName.replace(/^v/, ""),
  };
}

function readStdin() {
  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => {
      data += chunk;
    });
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", reject);
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const input = await readStdin();
  const releases = JSON.parse(input);
  const selection = selectOpenClawRelease(releases);
  process.stdout.write(`${JSON.stringify(selection, null, 2)}\n`);
}
