#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

function fail(message) {
  console.error(message);
  process.exit(1);
}

const root = process.env.OPENCLAW_PACKAGE_ROOT;
if (!root) {
  fail("OPENCLAW_PACKAGE_ROOT is required");
}

const distDir = path.join(root, "dist");
if (!fs.existsSync(distDir)) {
  fail(`OpenClaw dist directory missing: ${distDir}`);
}

const discoveryFiles = fs
  .readdirSync(distDir)
  .filter((name) => /^discovery-[A-Za-z0-9_-]+\.js$/.test(name))
  .map((name) => path.join(distDir, name))
  .filter((file) => fs.readFileSync(file, "utf8").includes("function shouldRejectHardlinkedPluginFiles"));

if (discoveryFiles.length !== 1) {
  fail(`expected exactly one bundled discovery policy chunk, found ${discoveryFiles.length}`);
}

const discoveryFile = discoveryFiles[0];
let source = fs.readFileSync(discoveryFile, "utf8");

if (!source.includes("function isTrustedNixStorePluginRoot")) {
  const hardlinkPolicy = /function shouldRejectHardlinkedPluginFiles\(params\) \{\n\tif \(params\.origin === "bundled"\) return false;\n\tif \(resolveIsNixMode\(params\.env\) && isNixStorePluginRoot\(params\.rootDir, params\.realpathCache\)\) return false;\n\treturn true;\n\}/;
  if (!hardlinkPolicy.test(source)) {
    fail("OpenClaw discovery chunk did not contain the expected hardlink policy block");
  }
  source = source.replace(
    hardlinkPolicy,
    `function isTrustedNixStorePluginRoot(params) {
\treturn resolveIsNixMode(params.env ?? process.env) && isNixStorePluginRoot(params.rootDir, params.realpathCache);
}
function shouldRejectHardlinkedPluginFiles(params) {
\tif (params.origin === "bundled") return false;
\tif (isTrustedNixStorePluginRoot(params)) return false;
\treturn true;
}`,
  );
}

const ownershipCheck =
  'params.origin !== "bundled" && params.uid !== null && typeof stat.uid === "number" && stat.uid !== params.uid && stat.uid !== 0';
const patchedOwnershipCheck =
  'params.origin !== "bundled" && params.uid !== null && !isTrustedNixStorePluginRoot(params) && typeof stat.uid === "number" && stat.uid !== params.uid && stat.uid !== 0';

if (!source.includes(patchedOwnershipCheck)) {
  if (!source.includes(ownershipCheck)) {
    fail("OpenClaw discovery chunk did not contain the expected ownership check");
  }
  source = source.replace(ownershipCheck, patchedOwnershipCheck);
}

if (!source.includes("function isTrustedNixStorePluginRoot")) {
  fail("OpenClaw discovery chunk did not receive the Nix store trust helper");
}
if (!source.includes(patchedOwnershipCheck)) {
  fail("OpenClaw discovery chunk did not receive the Nix store ownership patch");
}

fs.writeFileSync(discoveryFile, source);
