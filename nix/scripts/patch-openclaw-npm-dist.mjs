#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

function fail(message) {
  console.error(message);
  process.exit(1);
}
function unique(values, label) {
  if (values.length !== 1) fail(`expected exactly one ${label}, found ${values.length}`);
  return values[0];
}
function requireContract(condition, label) {
  if (!condition) fail(`OpenClaw ${label} contract is unsupported or already patched`);
}
function declaration(source, name) {
  return unique(
    [...source.matchAll(new RegExp(`^(?:async )?function ${name}\\([^\\n]*\\) \\{\\n[\\s\\S]*?^\\}`, "gm"))],
    name,
  )[0];
}

const root = process.env.OPENCLAW_PACKAGE_ROOT;
if (!root) fail("OPENCLAW_PACKAGE_ROOT is required");
const distDir = path.join(root, "dist");
if (!fs.existsSync(distDir)) fail(`OpenClaw dist directory missing: ${distDir}`);
// The sealed worker is another build graph. Only regular root modules own these transforms.
const modules = new Map(
  fs
    .readdirSync(distDir, { withFileTypes: true })
    .filter((entry) => entry.isFile() && /\.m?js$/.test(entry.name))
    .map((entry) => [entry.name, fs.readFileSync(path.join(distDir, entry.name), "utf8")]),
);
const owner = (marker, label) =>
  unique(
    [...modules].filter(([, source]) => source.includes(marker)),
    label,
  );
const [policyName, policy] = owner("function shouldRejectHardlinkedPluginFiles", "bundled hardlink policy chunk");
const old = policyName.endsWith(".js");
const ext = old ? "js" : "mjs";
const cacheArg = old ? ", realpathCache" : "";
const paramsCache = old ? ", params.realpathCache" : "";
const realpath = old ? "safeRealpathSync" : "pluginCacheRealpathSync";

function importedOwner(source, local, prefix) {
  const match = unique(
    [
      ...source.matchAll(
        new RegExp(`^import \\{ (\\w+) as ${local} \\} from "\\./(${prefix}-[\\w-]+\\.${ext})";$`, "gm"),
      ),
    ],
    `${local} import`,
  );
  const dependency = modules.get(match[2]);
  requireContract(dependency !== undefined, `${local} regular root dependency`);
  const exports = unique([...dependency.matchAll(/^export \{ ([^\n]+) \};$/gm)], `${local} exports`)[1].split(", ");
  requireContract(exports.includes(`${local} as ${match[1]}`), `${local} export binding`);
  return dependency;
}
const envSource = importedOwner(policy, "resolveIsNixMode", "paths");
requireContract(
  declaration(envSource, "resolveIsNixMode") ===
    `function resolveIsNixMode(env = process.env) {
\treturn env.OPENCLAW_NIX_MODE === "1";
}`,
  "Nix environment resolver",
);
const realpathSource = importedOwner(policy, realpath, old ? "path" : "(?:plugin-cache-files|package-manifest)");
const optimizedRealpath = !old && realpathSource.includes("function resolveRealpath(");
if (optimizedRealpath) {
  requireContract(
    [
      `function resolveRealpath(targetPath) {
\tconst absolute = path.resolve(targetPath);
\ttry {
\t\tif (absolute === targetPath && fs.realpathSync.native(targetPath) === targetPath) return targetPath;
\t} catch {}
\treturn fs.realpathSync(targetPath);
}`,
      `function resolveRealpath(targetPath) {
\tif (path.resolve(targetPath) === targetPath && pluginCacheRealpathSync(targetPath, true) === targetPath) return targetPath;
\treturn fs.realpathSync(targetPath);
}`,
      `function resolveRealpath(targetPath) {
\tif (path.resolve(targetPath) === targetPath) {
\t\tif (pathFacts(targetPath).nativeRealpath === targetPath) return targetPath;
\t\tif (process.platform !== "win32") {
\t\t\tconst parent = path.dirname(targetPath);
\t\t\tconst stat = pluginCacheLstatSync(targetPath);
\t\t\tif (parent !== targetPath && stat && !stat.isSymbolicLink()) {
\t\t\t\tconst realParent = pluginCacheRealpathSync(parent);
\t\t\t\tif (realParent) return path.join(realParent, path.basename(targetPath));
\t\t\t}
\t\t} else if (pluginCacheRealpathSync(targetPath, true) === targetPath) return targetPath;
\t}
\treturn fs.realpathSync(targetPath);
}`,
    ].includes(declaration(realpathSource, "resolveRealpath")),
    "canonical realpath helper",
  );
  if (declaration(realpathSource, "resolveRealpath").includes("const stat = pluginCacheLstatSync(targetPath);")) {
    requireContract(declaration(realpathSource, "pluginCacheLstatSync") === `function pluginCacheLstatSync(targetPath) {
\tconst facts = pathFacts(targetPath);
\tif (facts.lstat === void 0) try {
\t\tfacts.lstat = fs.lstatSync(targetPath);
\t} catch {
\t\tfacts.lstat = null;
\t}
\treturn facts.lstat;
}`, "canonical realpath lstat helper");
  }
}
requireContract(
  declaration(realpathSource, realpath) ===
    (old
      ? `function safeRealpathSync(targetPath, cache) {
\tconst cached = cache?.get(targetPath);
\tif (cached) return cached;
\ttry {
\t\tconst resolved = fs.realpathSync(targetPath);
\t\tcache?.set(targetPath, resolved);
\t\tcache?.set(resolved, resolved);
\t\treturn resolved;
\t} catch {
\t\treturn null;
\t}
}`
      : `function pluginCacheRealpathSync(targetPath, native = false) {
\tconst facts = pathFacts(targetPath);
\tconst key = native ? "nativeRealpath" : "realpath";
\tif (facts[key] === void 0) try {
\t\tfacts[key] = native ? fs.realpathSync.native(targetPath) : ${optimizedRealpath ? "resolveRealpath" : "fs.realpathSync"}(targetPath);
\t\tpathFacts(facts[key])[key] = facts[key];
\t} catch {
\t\tfacts[key] = null;
\t}
\treturn facts[key];
}`),
  "realpath/cache",
);
// Match complete decisions, retaining newlines (including JavaScript return/ASI semantics).
const policyBody = policy
  .replace(
    /^import \{ \w+ as (?:resolveIsNixMode|safeRealpathSync|pluginCacheRealpathSync) \} from "\.\/[\w-]+\.m?js";\n/gm,
    "",
  )
  .replace(/^import "\.\/path-safety-[\w-]+\.js";\n/gm, "")
  .replace(/^import path from "node:path";\n/gm, "")
  .replace(/^\/\/#(?:end)?region[^\n]*\n/gm, "")
  .replace(/^\/\*\* [^\n]* \*\/\n/gm, "")
  .trim();
requireContract((policy.match(/^import path from "node:path";$/gm) ?? []).length === 1, "policy path import");
requireContract(
  policyBody ===
    `const NIX_STORE_ROOT = "/nix/store";
function isNixStorePluginRoot(rootDir${cacheArg}) {
\tconst rootRealPath = ${realpath}(rootDir${cacheArg}) ?? path.resolve(rootDir);
\treturn rootRealPath === NIX_STORE_ROOT || rootRealPath.startsWith(\`\${NIX_STORE_ROOT}/\`);
}
function shouldRejectHardlinkedPluginFiles(params) {
\tif (params.origin === "bundled") return false;
\tif (resolveIsNixMode(params.env) && isNixStorePluginRoot(params.rootDir${paramsCache})) return false;
\treturn true;
}
export { shouldRejectHardlinkedPluginFiles as t };`,
  "hardlink policy decisions",
);

const ownershipCheck =
  'params.origin !== "bundled" && params.uid !== null && typeof stat.uid === "number" && stat.uid !== params.uid && stat.uid !== 0';
const [ownershipName, ownership] = owner(ownershipCheck, "bundled ownership policy chunk");
const importLine = `import { t as shouldRejectHardlinkedPluginFiles } from "./${policyName}";`;
requireContract(
  ownershipName.endsWith(`.${ext}`) && ownership.split("\n").filter((line) => line === importLine).length === 1,
  "ownership policy import",
);
requireContract(
  ownership.split(ownershipCheck).length === 2 && !ownership.includes("isTrustedNixStorePluginRoot"),
  "ownership condition",
);
const patchedOwnership = ownership.replace(
  ownershipCheck,
  ownershipCheck.replace(
    "params.uid !== null && ",
    "params.uid !== null && shouldRejectHardlinkedPluginFiles(params) && ",
  ),
);

const directLoop = "for (const candidate of collectDownloadableInstallCandidates({";
const [installName, install] = owner(
  'Failed to install missing configured plugin "',
  "missing configured plugin install chunk",
);
requireContract(ownershipName !== installName, "distinct transform owners");
const functions = old
  ? ["collectUpdateDeferredPluginIds", "detectConfiguredPluginInstallHealthIssues", "repairMissingPluginInstalls"]
  : ["detectConfiguredPluginInstallHealthIssues", "repairMissingPluginInstallsWithLease"];
// OpenClaw 2026.10.5 shares candidate selection through the resolved install context.
const contextLoops = !old && install.includes("context.collectInstallCandidates(");
const loops = contextLoops
  ? [
      "for (const candidate of context.collectInstallCandidates(records, deferredPluginIds))",
      "for (const candidate of installContext.collectInstallCandidates(nextRecords, deferredPluginIds))",
    ]
  : functions.map(() => directLoop);
requireContract(
  installName.endsWith(`.${ext}`) && install.split("for (const candidate of ").length === functions.length + 1,
  "missing-install loop count",
);
for (const [index, name] of functions.entries()) {
  const body = declaration(install, name);
  const loop = loops[index];
  requireContract(body.split(loop).length === 2 && body.includes(`\n\t${loop}`), `${name} candidate loop`);
}
// Preserve the existing health/deferred suppression and recorded-update limitations.
// This adapter does not add an all-effects install gate or propagate caller env.
let patchedInstall = install;
for (const loop of new Set(loops)) {
  patchedInstall = patchedInstall.replaceAll(loop, `if ((params.env ?? process.env).OPENCLAW_NIX_MODE !== "1") ${loop}`);
}

// SDK issuer binding cannot protect credentials saved before that binding existed.
// Require reauthorization instead of letting discovery adopt an unbound secret.
const providerFiles = [...modules.keys()].filter((name) => modules.get(name).includes("function createMcpOAuthClientProvider("));
const oauthPatches = [];
if (providerFiles.length) {
  const name = unique(providerFiles, "MCP OAuth provider");
  const source = modules.get(name);
  const asyncStore = source.includes("const clientInformation = store.clientInformation;");
  const clientGetter = asyncStore ? "return clientInformation;" : "return readMcpOAuthStore(storeKey).clientInformation;";
  const tokenGetter = asyncStore
    ? "return canReuseStoredTokens(store) ? store.tokens : void 0;"
    : "tokens() {\n\t\t\tif (params.suppressStoredTokens) return;\n\t\t\tconst store = readMcpOAuthStore(storeKey);";
  requireContract(source.split(clientGetter).length === 2, "MCP OAuth client getter");
  requireContract(source.split(tokenGetter).length === 2, "MCP OAuth token getter");
  let patchedProvider = source
    .replace(clientGetter, `const client = ${asyncStore ? "clientInformation" : "readMcpOAuthStore(storeKey).clientInformation"};
\t\t\treturn typeof client?.issuer === "string" && client.issuer.length > 0 ? client : void 0;`)
    .replace(tokenGetter, asyncStore
      ? `if (typeof store.tokens?.issuer !== "string" || !store.tokens.issuer) return;
\t\t\t${tokenGetter}`
      : `${tokenGetter}
\t\t\tif (typeof store.tokens?.issuer !== "string" || !store.tokens.issuer) return;`);
  if (source.includes("function resolveMcpOAuthAccessToken(")) {
    // The read-only fast path must reject unbound credentials before the lease.
    if (source.includes("readMcpOAuthStoreReadOnly(storeKey)")) {
      const usable = `function isStoredMcpOAuthAccessTokenUsable(store, params) {
\tconst tokens = store.tokens;
\tif (!tokens?.access_token || params.rejectedAccessToken === tokens.access_token) return false;
\treturn store.tokenExpiresAt !== void 0 && store.tokenExpiresAt > Date.now() + TOKEN_EXPIRY_SKEW_MS || store.tokenExpiresAt === void 0 && (params.acceptUnknownExpiry === true || !tokens.refresh_token);
}`;
      requireContract(declaration(source, "isStoredMcpOAuthAccessTokenUsable") === usable,
        "MCP OAuth read-only access token helper");
      const resolver = declaration(source, "resolveMcpOAuthAccessToken");
      requireContract(resolver.includes("if (store.pendingAuthorizationChallenge?.requiresAuthorization !== true && isStoredMcpOAuthAccessTokenUsable(store, params)) return store.tokens?.access_token;") &&
        resolver.split("isStoredMcpOAuthAccessTokenUsable(store, params)").length === 3,
      "MCP OAuth read-only access token callers");
      patchedProvider = patchedProvider.replace(usable, usable.replace(
        "if (!tokens?.access_token || ",
        'if (!tokens?.access_token || typeof tokens.issuer !== "string" || !tokens.issuer || ',
      ));
    }
    const missingToken = "if (!tokens?.access_token)";
    requireContract(source.split(missingToken).length === 2, "MCP OAuth access token entry point");
    patchedProvider = patchedProvider.replace(missingToken,
      'if (!tokens?.access_token || typeof tokens.issuer !== "string" || !tokens.issuer)');
  }
  oauthPatches.push([name, patchedProvider]);
}

const uiFiles = [...modules.keys()].filter((name) => modules.get(name).includes("function readPluginControlUiAssets("));
const uiPatches = [];
if (uiFiles.length) {
  const assetName = unique(uiFiles, "Control UI asset reader");
  const assets = modules.get(assetName);
  const assetRoot = 'const pluginRoot = await root(rootDir, {\n\t\thardlinks: "reject"';
  const reloadCall = "loadPluginManifest(record.rootDir, true, record.rootDir)";
  if (!assets.includes(assetRoot)) {
    // Newer upstream releases already apply the shared policy at both call sites.
    requireContract(assets.includes(`async function readPluginControlUiAssets(rootDir, declaration, options = {}) {
\tconst pluginRoot = await root(rootDir, {
\t\thardlinks: options.rejectHardlinks === false ? "allow" : "reject",
\t\tsymlinks: "reject",`), "Control UI upstream asset policy");
    const [, reload] = owner("loadPluginManifest(rootDir, rejectManifestHardlinks, rootDir)", "Control UI upstream manifest reload");
    requireContract(reload.split(importLine).length === 2, "Control UI upstream policy import");
    requireContract(reload.includes(` as readPluginControlUiAssets } from "./${assetName}";`), "Control UI upstream asset import");
    requireContract(reload.includes(`await readPluginControlUiAssets(record.rootDir, declaration, { rejectHardlinks: shouldRejectHardlinkedPluginFiles({
\t\torigin: record.origin,
\t\trootDir: record.rootDir
\t}) })`), "Control UI upstream asset caller");
    requireContract(reload.includes(`const rootDir = record.rootDir;
\t\t\t\tif (!rootDir) throw new Error("plugin is no longer active");
\t\t\t\tconst rejectManifestHardlinks = shouldRejectHardlinkedPluginFiles({
\t\t\t\t\torigin: record.origin,
\t\t\t\t\trootDir
\t\t\t\t});
\t\t\t\tconst loaded = withPluginCache(createPluginCache(), () => loadPluginManifest(rootDir, rejectManifestHardlinks, rootDir));`), "Control UI upstream reload policy");
  } else {
    const [reloadName, reload] = owner(reloadCall, "Control UI manifest reload");
    requireContract(assets.split(assetRoot).length === 2, "Control UI asset root");
    requireContract(reload.split(reloadCall).length === 2, "Control UI manifest reload count");
    requireContract(assetName !== reloadName, "distinct Control UI transform owners");
    for (const source of [assets, reload]) {
      requireContract(!source.includes("shouldRejectHardlinkedPluginFiles"), "Control UI policy import");
    }
    // Treat both reads as config-origin roots: only Nix mode and a canonical
    // store path relax hardlinks; mutable roots and symlinks remain restricted.
    uiPatches.push([
      assetName,
      `${importLine}\n${assets.replace(assetRoot, 'const pluginRoot = await root(rootDir, {\n\t\thardlinks: shouldRejectHardlinkedPluginFiles({ rootDir, origin: "config" }) ? "reject" : "allow"')}`,
    ], [
      reloadName,
      `${importLine}\n${reload.replace(reloadCall, 'loadPluginManifest(record.rootDir, shouldRejectHardlinkedPluginFiles({ rootDir: record.rootDir, origin: "config" }), record.rootDir)')}`,
    ]);
  }
}

// No contract failure may leave the earlier ownership transform partially written.
for (const [name, source] of [
  [ownershipName, patchedOwnership],
  [installName, patchedInstall],
  ...oauthPatches,
  ...uiPatches,
]) {
  fs.writeFileSync(path.join(distDir, name), source);
}
