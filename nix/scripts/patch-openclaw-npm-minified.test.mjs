import assert from "node:assert/strict";
import test from "node:test";
import vm from "node:vm";
import {
  usesMinifiedNpmContract, verifyMinifiedNpmContract, transformMinifiedNpmSources,
} from "./patch-openclaw-npm-minified.mjs";

function sources() {
  return {
    ownership: `
function check(e, i) {
  if (e.origin !== "bundled" && e.uid !== null && typeof i.uid === "number" && i.uid !== e.uid && i.uid !== 0) return "ownership";
  return null;
}`,
    install: `
function health(e) {
  const a = { collectInstallCandidates: () => [1] }, s = {}, f = new Set(), found = [];
  for (const e of a.collectInstallCandidates(s, f)) found.push(e);
  return found;
}
function repair(e) {
  const o = { collectInstallCandidates: () => [1] }, O = {}, A = new Set(), found = ["recorded"];
  for (const t of o.collectInstallCandidates(O, A)) found.push(t);
  return found;
}`,
    oauth: `
function client(n) {
  return {
    async clientInformation() {
      const r = n.clientInformation;
\t\t\treturn r;
\t\t},
\t\tasync saveClientInformation() {},
    async tokens() {
      const t = n;
      return canReuseStoredTokens(t) ? t.tokens : void 0;
    }
  };
}
function usable(e, t) {
  const n = e.tokens;
  if (!n?.access_token || t.rejectedAccessToken === n.access_token) return false;
  return e.expires > Date.now();
}
function leased(e) {
  const o = e.tokens, s = false;
  const c = !o?.access_token || s;
  if (!o?.access_token) { throw new Error("requires OAuth authorization"); }
  return { token: o.access_token, missing: c };
}`,
  };
}

test("minified contract selects the shared policy rather than sealed workers", () => {
  const source = "function shouldRejectHardlinkedPluginFiles(e) {";
  assert.equal(usesMinifiedNpmContract(new Map([["managed-handoff-runtime.mjs", source]])), false);
  assert.equal(usesMinifiedNpmContract(new Map([["hardlink-policy-test.mjs", source]])), true);
  assert.throws(() => verifyMinifiedNpmContract(new Map()), /minified policy contract is unsupported/);
});

test("minified transforms retain ownership, Nix mode and OAuth issuer boundaries", async () => {
  const result = transformMinifiedNpmSources(sources());
  const context = vm.createContext({
    process: { env: { OPENCLAW_NIX_MODE: "0" } },
    shouldRejectHardlinkedPluginFiles: (e) => !(e.nix && e.store),
    canReuseStoredTokens: () => true,
  });
  vm.runInContext(Object.values(result).join("\n"), context);
  assert.equal(context.check({ origin: "config", uid: 1, nix: true, store: true }, { uid: 2 }), null);
  assert.equal(context.check({ origin: "config", uid: 1, nix: false, store: true }, { uid: 2 }), "ownership");
  assert.equal(context.check({ origin: "config", uid: 1, nix: true, store: false }, { uid: 2 }), "ownership");
  for (const mode of ["0", "1"]) {
    const e = { env: { OPENCLAW_NIX_MODE: mode } };
    assert.equal(context.health(e).length, mode === "1" ? 0 : 1);
    assert.equal(context.repair(e).length, mode === "1" ? 1 : 2);
  }
  for (const issuer of [undefined, null, "", 123, "https://auth.example.test"]) {
    const valid = typeof issuer === "string" && issuer.length > 0;
    const e = { clientInformation: { issuer }, tokens: { issuer, access_token: "synthetic" }, expires: Date.now() + 60000 };
    const client = context.client(e);
    assert.equal(Boolean(await client.clientInformation()), valid);
    assert.equal(Boolean(await client.tokens()), valid);
    assert.equal(context.usable(e, {}), valid);
    assert.equal(context.usable(e, { rejectedAccessToken: "synthetic" }), false);
    if (valid) assert.equal(context.leased(e).missing, false);
    else assert.throws(() => context.leased(e), /requires OAuth/);
  }
});

test("minified transforms reject incomplete contracts without mutating inputs", () => {
  const original = sources();
  const invalid = { ...original, oauth: original.oauth.replace("const c = !o?.access_token || s;", "const c = false;") };
  const before = structuredClone(invalid);
  assert.throws(() => transformMinifiedNpmSources(invalid), /OAuth authorization challenge contract is unsupported/);
  assert.deepEqual(invalid, before);
});
