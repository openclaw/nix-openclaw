import { createHash } from "node:crypto";

// Audited npm 2026.11.6 graph. Hash complete chunks before editing: minified
// locals and independently sealed workers must not widen the patch boundary.
const contracts = {
  policy: ["hardlink-policy-Kq1Lxk7_.mjs", "e5000d760748ef8ff222619de44657ea06a8c5c1ec6b4b4cd932ad6a86084a87"],
  paths: ["paths-DAcAg5aV.mjs", "604be616d9b7cee1cba3c3a21e179f8405bd81eaafd4dfaba1ae1904e5e06173"],
  cache: ["plugin-cache-files-e1aGp2KM.mjs", "04db668149f2e77372dd78fc6a0c1e61b8fae7342c5e1cb3c88481653c7e7110"],
  ownership: ["discovery-BgZOfCNQ.mjs", "699b5258ca43b3e61eafb1b4fe429cd10d97341f3d2a5825204c8871b08e33ec"],
  install: ["missing-configured-plugin-install-CyAFRPCm.mjs", "65415b7f09e6339dff72073e73ff76bcdf058342537dc7fb026561e0f723c1fd"],
  oauth: ["mcp-oauth-CFvUyOtB.mjs", "b13a5bdda770f887aa8f730def213c18d10964cc3264b3cf1cf7de77e88d3524"],
  assets: ["control-ui-assets-CzHZdjPy.mjs", "d552022caf31784e75ad50f9f465affaf3213bedb3550a45e6e486898b917fd1"],
  reload: ["control-ui-plugin-assets-CEmivLdA.mjs", "41438b4ea6d3cc4bb2dd5b16a053753dba16b8a408e8aa1bda4f673e80a3575b"],
};

export function usesMinifiedNpmContract(modules) {
  return [...modules].some(([name, source]) => name.startsWith("hardlink-policy-") &&
    source.includes("function shouldRejectHardlinkedPluginFiles(e) {"));
}

export function verifyMinifiedNpmContract(modules) {
  const sources = {};
  for (const [key, [name, expected]] of Object.entries(contracts)) {
    const source = modules.get(name);
    if (source === undefined || createHash("sha256").update(source).digest("hex") !== expected) {
      throw new Error(`OpenClaw minified ${key} contract is unsupported or already patched: ${name}`);
    }
    sources[key] = source;
  }
  return sources;
}

function replaceOnce(source, before, after, label) {
  if (source.split(before).length !== 2) throw new Error(`OpenClaw minified ${label} contract is unsupported`);
  return source.replace(before, after);
}

export function transformMinifiedNpmSources(sources) {
  const ownership = replaceOnce(sources.ownership,
    'e.origin !== "bundled" && e.uid !== null && typeof i.uid === "number"',
    'e.origin !== "bundled" && e.uid !== null && shouldRejectHardlinkedPluginFiles(e) && typeof i.uid === "number"',
    "ownership");
  let install = sources.install;
  for (const loop of [
    "for (const e of a.collectInstallCandidates(s, f))",
    "for (const t of o.collectInstallCandidates(O, A))",
  ]) {
    install = replaceOnce(install, loop, `if ((e.env ?? process.env).OPENCLAW_NIX_MODE !== "1") ${loop}`, "candidate loop");
  }
  let oauth = sources.oauth;
  for (const [before, after, label] of [
    [
      "\t\t\treturn r;\n\t\t},\n\t\tasync saveClientInformation",
      '\t\t\treturn typeof r?.issuer === "string" && r.issuer.length > 0 ? r : void 0;\n\t\t},\n\t\tasync saveClientInformation',
      "OAuth client getter",
    ],
    [
      "return canReuseStoredTokens(t) ? t.tokens : void 0;",
      'return typeof t.tokens?.issuer === "string" && t.tokens.issuer.length > 0 && canReuseStoredTokens(t) ? t.tokens : void 0;',
      "OAuth token getter",
    ],
    [
      "if (!n?.access_token || t.rejectedAccessToken === n.access_token)",
      'if (!n?.access_token || typeof n.issuer !== "string" || !n.issuer || t.rejectedAccessToken === n.access_token)',
      "OAuth read-only helper",
    ],
    [
      "const c = !o?.access_token || s;",
      'const c = !o?.access_token || typeof o.issuer !== "string" || !o.issuer || s;',
      "OAuth authorization challenge",
    ],
    [
      "if (!o?.access_token) {",
      'if (!o?.access_token || typeof o.issuer !== "string" || !o.issuer) {',
      "OAuth leased token resolver",
    ],
  ]) oauth = replaceOnce(oauth, before, after, label);
  return { ownership, install, oauth };
}

export function patchMinifiedNpmBundle(modules) {
  const sources = verifyMinifiedNpmContract(modules);
  return Object.entries(transformMinifiedNpmSources(sources)).map(([key, source]) => [contracts[key][0], source]);
}
