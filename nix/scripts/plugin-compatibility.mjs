import { spawnSync } from "node:child_process";

const results = new Map();
function semverMatches(version, range, includePrerelease = true) {
  const key = JSON.stringify([version, range, includePrerelease]);
  if (!results.has(key)) {
    const result = spawnSync("node-semver", [...(includePrerelease ? ["--include-prerelease"] : []), "--range", range, version], { encoding: "utf8" });
    if (result.error || (result.status !== 0 && result.status !== 1)) {
      throw new Error("node-semver is required; run this command in nix develop", { cause: result.error });
    }
    results.set(key, result.status === 0);
  }
  return results.get(key);
}

export function verifyCompatibilityTool() {
  if (!semverMatches("1.0.0", "1.0.0")) throw new Error("node-semver failed its compatibility probe");
}

const correction = /^v?(\d+\.\d+\.\d+)-(\d+)(?:\+[^\s]+)?$/;
const releaseSuffix = /^v?(\d{4}\.[1-9]\d?\.[1-9]\d*)-(?:alpha|beta|rc)\.\d+$/i;
const core = /^v?(\d+\.\d+\.\d+)/;
function apiVersion(version, target) {
  return correction.exec(version)?.[1]
    ?? (target.includes("-") ? version : releaseSuffix.exec(version)?.[1] ?? version);
}

// Match OpenClaw's plugin API rules: bare major.minor is a floor; OR is unsupported.
export function satisfiesPluginApiRange(version, range) {
  if (range == null || range === "") return true;
  if (typeof range !== "string" || !range.trim() || range.includes("||")) return false;
  return range.trim().split(/\s+/).every((token) => {
    const match = /^(>=|<=|>|<|=|\^|~)?(.+)$/.exec(token);
    if (!match || /^[<>=^~]/.test(match[2])) return false;
    const operator = match[1] ?? "";
    const target = match[2];
    const partial = /^v?\d+\.\d+$/.test(target);
    const normalized = partial ? `${target}.0` : target;
    return semverMatches(apiVersion(version, target), `${partial && !operator ? ">=" : operator}${normalized}`);
  });
}

export function satisfiesPeerRange(version, range) {
  if (range == null || range === "") return true;
  if (typeof range !== "string" || !range.trim()) return false;
  if (semverMatches(version, range, false)) return true;
  const stableAlias = correction.exec(version)?.[1];
  return Boolean(stableAlias) && semverMatches(version, "*", true)
    && semverMatches(stableAlias, range, false);
}

// Host versions order numeric correction releases after stable, unlike npm prereleases.
export function satisfiesMinHostVersion(version, range) {
  if (range == null || range === "") return true;
  if (typeof range !== "string") return false;
  const match = /^(?:>=)?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?)$/.exec(range.trim());
  if (!match || !semverMatches(version, "*") || !semverMatches(match[1], "*")) return false;
  const target = match[1];
  const hostCorrection = correction.exec(version);
  const targetCorrection = correction.exec(target);
  if (hostCorrection || targetCorrection) {
    if (core.exec(version)?.[1] === core.exec(target)?.[1]) {
      if (hostCorrection && targetCorrection) return BigInt(hostCorrection[2]) >= BigInt(targetCorrection[2]);
      if (hostCorrection) return true;
      return false;
    }
  }
  return semverMatches(hostCorrection?.[1] ?? version, `>=${targetCorrection?.[1] ?? target}`);
}
