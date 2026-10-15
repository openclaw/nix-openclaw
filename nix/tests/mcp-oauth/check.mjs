import assert from "node:assert/strict";
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { pathToFileURL } from "node:url";
import vm from "node:vm";

const root = process.env.OPENCLAW_PACKAGE_ROOT;
assert.ok(root, "OPENCLAW_PACKAGE_ROOT is required");
const require = createRequire(path.join(root, "package.json"));
const { auth } = await import(pathToFileURL(require.resolve("@modelcontextprotocol/sdk/client/auth.js")));
const realIssuer = "https://auth.example.test";
const hostileIssuer = "https://untrusted.example.test";
const resource = "https://mcp.example.test";

for (const issuer of [hostileIssuer, realIssuer]) {
  const requests = [];
  let savedTokens;
  const provider = {
    redirectUrl: "http://127.0.0.1:8989/oauth/callback",
    clientMetadata: { redirect_uris: ["http://127.0.0.1:8989/oauth/callback"] },
    clientInformation: () => ({ client_id: "test-client", client_secret: "synthetic-secret", issuer: realIssuer }),
    tokens: () => ({ access_token: "old", token_type: "Bearer", refresh_token: "synthetic-refresh", issuer: realIssuer }),
    saveClientInformation() {},
    saveTokens(tokens) { savedTokens = tokens; },
    discoveryState: () => ({
      authorizationServerUrl: issuer,
      resourceMetadata: { resource, authorization_servers: [issuer] },
      authorizationServerMetadata: {
        issuer, authorization_endpoint: `${issuer}/authorize`, token_endpoint: `${issuer}/token`,
        response_types_supported: ["code"], token_endpoint_auth_methods_supported: ["client_secret_post"],
        code_challenge_methods_supported: ["S256"],
      },
    }),
    redirectToAuthorization() { throw new Error("unexpected interactive authorization"); },
  };
  let outcome;
  try {
    outcome = await auth(provider, {
      serverUrl: resource,
      fetchFn: async (url, init) => {
        requests.push({ url: String(url), body: String(init?.body) });
        return new Response(JSON.stringify({ access_token: "new", token_type: "Bearer", refresh_token: "new-refresh" }), {
          status: 200, headers: { "content-type": "application/json" },
        });
      },
    });
  } catch (error) {
    assert.equal(issuer, hostileIssuer, error.stack);
  }
  if (issuer === hostileIssuer) {
    assert.equal(requests.length, 0, "OAuth credentials were presented to another issuer");
  } else {
    assert.equal(outcome, "AUTHORIZED");
    assert.equal(requests.length, 1);
    assert.equal(requests[0].url, `${realIssuer}/token`);
    assert.ok(requests[0].body.includes("synthetic-refresh"));
    assert.equal(savedTokens.issuer, realIssuer, "refreshed credentials must retain their issuer");
  }
}

// Exercise the installed provider's storage boundary without opening user state.
const sources = fs.readdirSync(path.join(root, "dist"))
  .filter((name) => /\.m?js$/.test(name))
  .map((name) => fs.readFileSync(path.join(root, "dist", name), "utf8"))
  .filter((source) => source.includes("function createMcpOAuthClientProvider("));
assert.equal(sources.length, 1, "expected one installed MCP OAuth provider");
const body = sources[0].match(/^function createMcpOAuthClientProvider\([^\n]*\) \{\n[\s\S]*?^\}/m)?.[0];
assert.ok(body, "unsupported installed MCP OAuth provider");
let store = {};
const context = vm.createContext({
  bindMcpOAuthLeaseAssertion: () => undefined,
  normalizeOptionalString: (value) => value,
  readMcpOAuthStore: () => store,
  updateMcpOAuthStore: (_key, update) => { store = update(store); },
  beginMcpOAuthAuthorization: (value) => ({ ...value }),
  resolveTokenExpiresAt: () => undefined,
});
vm.runInContext(body, context);
const provider = context.createMcpOAuthClientProvider({ identity: { storeKey: "test" } });
for (const issuer of [undefined, null, "", 123, realIssuer]) {
  store = {
    clientInformation: { client_id: "test", client_secret: "synthetic-secret", issuer },
    tokens: { access_token: "test", token_type: "Bearer", refresh_token: "synthetic-refresh", issuer },
    discoveryState: { authorizationServerUrl: realIssuer },
    tokensAuthorizationServerUrl: realIssuer,
  };
  assert.equal(Boolean(provider.clientInformation()), issuer === realIssuer, "unbound client must require login");
  assert.equal(Boolean(provider.tokens()), issuer === realIssuer, "unbound tokens must require login");
}
provider.saveClientInformation({ client_id: "test", issuer: realIssuer });
provider.saveTokens({ access_token: "new", token_type: "Bearer", issuer: realIssuer });
assert.equal(store.clientInformation.issuer, realIssuer);
assert.equal(store.tokens.issuer, realIssuer);
console.log("MCP OAuth: foreign issuer rejected, matching issuer refreshed, legacy credentials require login");
