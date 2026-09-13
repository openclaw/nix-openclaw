import childProcess from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import https from "node:https";

const fetchJsonTimeoutMs = 30_000;

function run(command, args, options = {}) {
  const result = childProcess.spawnSync(command, args, {
    encoding: "utf8",
    maxBuffer: 128 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
    ...options,
  });
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed:\n${result.stderr || result.stdout}`);
  }
  return result.stdout;
}

function sleepMs(milliseconds) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds);
}

function runWithRetries(command, args, options = {}) {
  const attempts = options.attempts ?? 3;
  const retryDelayMs = options.retryDelayMs ?? 1000;
  let lastError = null;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return run(command, args, options.runOptions ?? {});
    } catch (error) {
      lastError = error;
      if (attempt < attempts) {
        sleepMs(retryDelayMs * attempt);
      }
    }
  }
  throw lastError;
}

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    const request = https
      .get(url, { headers: { Accept: "application/json" } }, (response) => {
        if (
          response.statusCode >= 300
          && response.statusCode < 400
          && response.headers.location
        ) {
          response.resume();
          fetchJson(response.headers.location).then(resolve, reject);
          return;
        }
        if (response.statusCode !== 200) {
          reject(new Error(`GET ${url} failed with HTTP ${response.statusCode}`));
          response.resume();
          return;
        }
        let body = "";
        response.setEncoding("utf8");
        response.on("data", (chunk) => {
          body += chunk;
        });
        response.on("end", () => {
          try {
            resolve(JSON.parse(body));
          } catch (error) {
            reject(error);
          }
        });
      })
      .on("error", reject);
    request.setTimeout(fetchJsonTimeoutMs, () => {
      request.destroy(new Error(`GET ${url} timed out after ${fetchJsonTimeoutMs}ms`));
    });
  });
}

async function fetchJsonWithRetries(url, options = {}) {
  const attempts = options.attempts ?? 3;
  const retryDelayMs = options.retryDelayMs ?? 1000;
  let lastError = null;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return await fetchJson(url);
    } catch (error) {
      lastError = error;
      if (attempt < attempts) {
        sleepMs(retryDelayMs * attempt);
      }
    }
  }
  throw lastError;
}

function pickDefined(object) {
  return Object.fromEntries(Object.entries(object).filter(([, value]) => value !== undefined));
}

function sortedObject(object = {}) {
  return Object.fromEntries(Object.entries(object).sort(([a], [b]) => a.localeCompare(b)));
}

function stableJson(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function optionalString(value) {
  return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

function verifyIntegrity(filePath, integrity) {
  const token = optionalString(integrity)
    ?.split(/\s+/)
    .find((entry) => /^(sha512|sha384|sha256)-/.test(entry));
  if (!token) {
    throw new Error(`Missing supported npm integrity for ${filePath}`);
  }
  const [algorithm, expected] = token.split("-", 2);
  const actual = crypto.createHash(algorithm).update(fs.readFileSync(filePath)).digest("base64");
  if (actual !== expected) {
    throw new Error(`Downloaded tarball integrity mismatch for ${filePath}`);
  }
}

function verifyShasum(filePath, shasum) {
  if (!optionalString(shasum)) {
    return;
  }
  const actual = crypto.createHash("sha1").update(fs.readFileSync(filePath)).digest("hex");
  if (actual !== shasum) {
    throw new Error(`Downloaded tarball shasum mismatch for ${filePath}`);
  }
}

function verifySha256Hex(filePath, expectedSha256) {
  const expected = optionalString(expectedSha256)?.replace(/^sha256[:-]?/i, "").toLowerCase();
  if (!expected) {
    throw new Error(`Missing SHA-256 digest for ${filePath}`);
  }
  const actual = crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
  if (actual !== expected) {
    throw new Error(`Downloaded tarball SHA-256 mismatch for ${filePath}`);
  }
}

function briefError(error) {
  const lines = String(error?.message ?? error)
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const interesting = lines.filter((line) =>
    /npm error (?:request|code|Unsupported|Invalid|Missing)|ERROR: npm failed|cache mode is|Unsupported URL Type|No matching version|ERESOLVE|ENOTCACHED|EUNSUPPORTEDPROTOCOL/.test(line),
  );
  return (interesting.length > 0 ? interesting : lines.slice(-12))
    .slice(0, 10)
    .join(" | ")
    .slice(0, 1600);
}

export { run, runWithRetries, fetchJsonWithRetries, pickDefined, sortedObject, stableJson, isRecord, optionalString, verifyIntegrity, verifyShasum, verifySha256Hex, briefError };
