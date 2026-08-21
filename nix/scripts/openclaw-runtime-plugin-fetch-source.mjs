import fs from "node:fs";
import https from "node:https";

function fail(message) {
  throw new Error(message);
}

function optionalString(value) {
  return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isExactVersion(version) {
  return /^[0-9]+(?:\.[0-9]+){1,2}(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$/.test(version);
}

function parseNpmSpec(spec) {
  const normalized = optionalString(spec)?.replace(/^npm:/, "").replace(/^clawhub:/, "");
  if (!normalized) {
    return null;
  }

  if (normalized.startsWith("@")) {
    const slashIndex = normalized.indexOf("/");
    if (slashIndex === -1) {
      return null;
    }
    const versionIndex = normalized.indexOf("@", slashIndex + 1);
    if (versionIndex === -1) {
      return { packageName: normalized, version: null };
    }
    return {
      packageName: normalized.slice(0, versionIndex),
      version: normalized.slice(versionIndex + 1) || null,
    };
  }

  const versionIndex = normalized.lastIndexOf("@");
  if (versionIndex <= 0) {
    return { packageName: normalized, version: null };
  }
  return {
    packageName: normalized.slice(0, versionIndex),
    version: normalized.slice(versionIndex + 1) || null,
  };
}

function npmRegistryUrl(packageName) {
  return `https://registry.npmjs.org/${encodeURIComponent(packageName)}`;
}

function clawHubArtifactUrl(packageName, version) {
  return `https://clawhub.ai/api/v1/packages/${encodeURIComponent(packageName)}/versions/${encodeURIComponent(version)}/artifact`;
}

function get(url, onResponse) {
  return new Promise((resolve, reject) => {
    const request = https
      .get(url, { headers: { Accept: "application/json" } }, (response) => {
        if (
          response.statusCode >= 300
          && response.statusCode < 400
          && response.headers.location
        ) {
          response.resume();
          get(response.headers.location, onResponse).then(resolve, reject);
          return;
        }
        if (response.statusCode !== 200) {
          response.resume();
          reject(new Error(`GET ${url} failed with HTTP ${response.statusCode}`));
          return;
        }
        onResponse(response).then(resolve, reject);
      })
      .on("error", reject);
    request.setTimeout(30_000, () => {
      request.destroy(new Error(`GET ${url} timed out after 30000ms`));
    });
  });
}

async function fetchJson(url) {
  return get(url, async (response) => {
    let body = "";
    response.setEncoding("utf8");
    for await (const chunk of response) {
      body += chunk;
    }
    return JSON.parse(body);
  });
}

async function downloadFile(url, outPath) {
  if (!url.startsWith("https://")) {
    fail(`plugin artifact URL must be HTTPS: ${url}`);
  }
  await get(url, async (response) => {
    await new Promise((resolve, reject) => {
      const output = fs.createWriteStream(outPath);
      response.pipe(output);
      output.on("finish", resolve);
      output.on("error", reject);
      response.on("error", reject);
    });
  });
}

async function resolveNpmTarball(packageName, version) {
  const metadata = await fetchJson(npmRegistryUrl(packageName));
  const versionMetadata = metadata.versions?.[version];
  const tarballUrl = optionalString(versionMetadata?.dist?.tarball);
  if (!tarballUrl) {
    fail(`npm package ${packageName}@${version} does not expose a tarball URL`);
  }
  return tarballUrl;
}

async function resolveClawHubTarball(packageName, version) {
  const payload = await fetchJson(clawHubArtifactUrl(packageName, version));
  const artifact = payload.artifact ?? payload.version?.artifact ?? payload.packageVersion?.artifact;
  if (!isRecord(artifact)) {
    fail(`ClawHub package ${packageName}@${version} does not expose an artifact`);
  }
  const kind = optionalString(artifact.kind) ?? optionalString(artifact.type);
  if (kind !== "npm-pack") {
    fail(`ClawHub package ${packageName}@${version} artifact kind is ${kind ?? "missing"}, not npm-pack`);
  }
  const tarballUrl =
    optionalString(artifact.tarballUrl)
    ?? optionalString(artifact.url)
    ?? optionalString(artifact.downloadUrl);
  if (!tarballUrl) {
    fail(`ClawHub package ${packageName}@${version} does not expose a tarball URL`);
  }
  return tarballUrl;
}

const spec = optionalString(process.argv[2]);
const outPath = optionalString(process.argv[3]);
if (!spec || !outPath) {
  fail("usage: openclaw-runtime-plugin-fetch-source.mjs <npm:...|clawhub:...> <out>");
}

const parsed = parseNpmSpec(spec);
if (!parsed?.packageName || !parsed.version) {
  fail(`runtime plugin source spec must include an exact version: ${spec}`);
}
if (!isExactVersion(parsed.version)) {
  fail(`runtime plugin source spec must use an exact version, not a dist-tag/range: ${spec}`);
}

let tarballUrl;
if (spec.startsWith("npm:")) {
  tarballUrl = await resolveNpmTarball(parsed.packageName, parsed.version);
} else if (spec.startsWith("clawhub:")) {
  tarballUrl = await resolveClawHubTarball(parsed.packageName, parsed.version);
} else {
  fail(`runtime plugin source spec must start with npm: or clawhub:: ${spec}`);
}

await downloadFile(tarballUrl, outPath);
