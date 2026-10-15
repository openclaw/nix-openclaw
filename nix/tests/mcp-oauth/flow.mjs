import assert from "node:assert/strict";
import { fork } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

async function entryPoints(root, marker) {
  const files = fs.readdirSync(path.join(root, "dist"))
    .filter((name) => /\.m?js$/.test(name))
    .filter((name) => fs.readFileSync(path.join(root, "dist", name), "utf8").includes(`function ${marker}(`));
  assert.equal(files.length, 1, marker);
  const exports = Object.values(await import(pathToFileURL(path.join(root, "dist", files[0]))));
  return (name) => {
    const fn = exports.find((value) => typeof value === "function" && value.name === name);
    assert.ok(fn, `missing packaged entry point: ${name}`);
    return fn;
  };
}

async function child() {
  const [root, base, action] = process.argv.slice(3);
  const oauth = await entryPoints(root, "startMcpOAuthAuthorization");
  const stores = await entryPoints(root, "readMcpOAuthStore");
  const transport = await entryPoints(root, "buildMcpHttpFetch");
  const read = stores("readMcpOAuthStore");
  const update = stores("updateMcpOAuthStore");
  const identity = { storeKey: "synthetic-oauth-flow", serverName: "synthetic", serverUrl: `${base}/mcp` };
  const config = { url: identity.serverUrl, oauth: { redirectUrl: `${base}/callback` }, requestTimeoutMs: 5000 };
  if (action === "login") {
    const pending = await oauth("startMcpOAuthAuthorization")(identity, config, {});
    assert.equal(pending.status, "redirect");
    const response = await fetch(pending.authorizationUrl, { redirect: "manual" });
    assert.equal(response.status, 302);
    const callback = new URL(response.headers.get("location"));
    assert.equal(await oauth("completeOAuthCallback")(identity, config, {
      code: callback.searchParams.get("code"), state: callback.searchParams.get("state"),
    }), "authorized");
    update("unrelated-synthetic-row", () => ({ marker: "preserved" }));
  } else if (action === "legacy") {
    update(identity.storeKey, (store) => {
      const clientInformation = { ...store.clientInformation };
      const tokens = { ...store.tokens };
      delete clientInformation.issuer;
      delete tokens.issuer;
      return { ...store, clientInformation, tokens, tokenExpiresAt: Date.now() + 600000 };
    });
  } else if (action === "clear") {
    await oauth("clearMcpOAuthCredentials")(identity);
    assert.equal(read("unrelated-synthetic-row").marker, "preserved");
  } else {
    const store = read(identity.storeKey);
    try {
      await oauth("resolveMcpOAuthAccessToken")({
        identity, config: config.oauth,
        ...(action === "read" ? {} : { rejectedAccessToken: store.tokens.access_token }),
        fetchFn: transport("buildMcpHttpFetch")({ resourceUrl: identity.serverUrl, timeoutMs: 5000 }),
        ...(action === "foreign" ? {
          authorizationChallenge: true,
          resourceMetadataUrl: new URL(`${base}/.well-known/oauth-protected-resource?changed=1`),
        } : {}),
      });
      process.send({ authorized: true, bound: Boolean(read(identity.storeKey).tokens?.issuer) });
    } catch (error) {
      assert.match(error.message, /OAuth|authorization|auth server/i);
      process.send({ rejected: true });
    }
    assert.equal(read("unrelated-synthetic-row").marker, "preserved");
    return;
  }
  const store = read(identity.storeKey);
  process.send({ bound: Boolean(store.tokens?.issuer && store.clientInformation?.issuer) });
}

async function main() {
  const root = process.env.OPENCLAW_PACKAGE_ROOT;
  assert.ok(root, "OPENCLAW_PACKAGE_ROOT is required");
  const baseline = process.env.OPENCLAW_BASELINE_PACKAGE_ROOT;
  const stateRoot = fs.mkdtempSync(path.join(os.tmpdir(), "mcp-oauth-flow-"));
  const events = [];
  let active = "trusted";
  let base;
  let challenge;
  const server = http.createServer(async (request, response) => {
    try {
      const url = new URL(request.url, base);
      let body = "";
      for await (const chunk of request) body += chunk;
      const carriesCredential = /synthetic-(secret|refresh)/.test(body + (request.headers.authorization ?? ""));
      events.push({ path: url.pathname, carriesCredential });
      response.setHeader("content-type", "application/json");
      if (url.pathname.includes("oauth-protected-resource")) {
        response.end(JSON.stringify({ resource: `${base}/mcp`, authorization_servers: [`${base}/${active}`] }));
      } else if (url.pathname.includes(".well-known")) {
        const issuer = `${base}/${url.pathname.includes("foreign") ? "foreign" : active}`;
        response.end(JSON.stringify({
          issuer, authorization_endpoint: `${issuer}/authorize`, token_endpoint: `${issuer}/token`,
          registration_endpoint: `${issuer}/register`, response_types_supported: ["code"],
          code_challenge_methods_supported: ["S256"], token_endpoint_auth_methods_supported: ["client_secret_post"],
        }));
      } else if (url.pathname.endsWith("/register")) {
        response.end(JSON.stringify({ ...JSON.parse(body), client_id: "synthetic-client", client_secret: "synthetic-secret", token_endpoint_auth_method: "client_secret_post" }));
      } else if (url.pathname.endsWith("/authorize")) {
        challenge = url.searchParams.get("code_challenge");
        const callback = new URL(url.searchParams.get("redirect_uri"));
        callback.searchParams.set("code", "synthetic-code");
        callback.searchParams.set("state", url.searchParams.get("state"));
        response.writeHead(302, { location: callback.href });
        response.end();
      } else if (url.pathname.endsWith("/token")) {
        const params = new URLSearchParams(body);
        if (params.get("grant_type") === "authorization_code") {
          assert.equal(createHash("sha256").update(params.get("code_verifier")).digest("base64url"), challenge);
        }
        response.end(JSON.stringify({ access_token: "synthetic-access", refresh_token: "synthetic-refresh", token_type: "Bearer", expires_in: 600 }));
      } else {
        response.writeHead(404);
        response.end("{}");
      }
    } catch (error) {
      response.writeHead(500);
      response.end(JSON.stringify({ error: error.message }));
    }
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  base = `http://127.0.0.1:${server.address().port}`;
  async function run(packageRoot, state, action) {
    return await new Promise((resolve, reject) => {
      const worker = fork(import.meta.filename, ["child", packageRoot, base, action], {
        env: { ...process.env, OPENCLAW_STATE_DIR: path.join(stateRoot, state), OPENCLAW_NIX_MODE: "1" },
        stdio: ["ignore", "pipe", "pipe", "ipc"],
      });
      let result;
      let errors = "";
      const timer = setTimeout(() => { worker.kill(); reject(new Error(`packaged OAuth ${action} timed out`)); }, 30000);
      worker.on("message", (value) => { result = value; });
      worker.stderr.on("data", (chunk) => { errors += chunk; });
      worker.on("error", reject);
      worker.on("exit", (code) => {
        clearTimeout(timer);
        if (code === 0 && result) resolve(result);
        else reject(new Error(`packaged OAuth ${action} failed: ${errors}`));
      });
    });
  }
  try {
    if (baseline) {
      assert.equal((await run(baseline, "baseline", "login")).bound, false);
      assert.equal((await run(baseline, "baseline", "refresh")).authorized, true);
      active = "foreign";
      const start = events.length;
      assert.equal((await run(baseline, "baseline", "foreign")).rejected, true);
      assert.equal(events.slice(start).some((event) => event.path.startsWith("/foreign/") && event.carriesCredential), false);
      console.log("Baseline gateway: issuer-less credentials refresh; existing foreign-refresh guard holds");
      active = "trusted";
    }
    await run(baseline ?? root, "upgrade", "login");
    if (!baseline) await run(root, "upgrade", "legacy");
    const legacyStart = events.length;
    assert.equal((await run(root, "upgrade", "read")).rejected, true);
    assert.equal((await run(root, "upgrade", "refresh")).rejected, true);
    assert.equal(events.slice(legacyStart).some((event) => event.carriesCredential), false);
    await run(root, "upgrade", "clear");
    assert.equal((await run(root, "upgrade", "login")).bound, true);
    assert.equal((await run(root, "upgrade", "refresh")).bound, true);
    active = "foreign";
    const foreignStart = events.length;
    assert.equal((await run(root, "upgrade", "foreign")).rejected, true);
    assert.equal(events.slice(foreignStart).some((event) => event.path.startsWith("/foreign/") && event.carriesCredential), false);
    console.log("Packaged OAuth + HTTP + SQLite: login, refresh, legacy upgrade/recovery, and foreign-issuer rejection passed");
  } finally {
    await new Promise((resolve) => server.close(resolve));
    fs.rmSync(stateRoot, { recursive: true, force: true });
  }
}

if (process.argv[2] === "child") {
  await child();
  process.disconnect();
}
else await main();
