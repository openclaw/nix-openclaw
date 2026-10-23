import assert from "node:assert/strict";
import http from "node:http";
import { createRequire } from "node:module";
import path from "node:path";
import { pathToFileURL } from "node:url";

const root = process.env.OPENCLAW_PACKAGE_ROOT;
assert.ok(root, "OPENCLAW_PACKAGE_ROOT is required");
const require = createRequire(path.join(root, "package.json"));
const { StreamableHTTPClientTransport } = await import(pathToFileURL(
  require.resolve("@modelcontextprotocol/sdk/client/streamableHttp.js"),
));
const received = [];
const listen = (server) => new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const url = (server) => `http://127.0.0.1:${server.address().port}`;
const record = async (request) => {
  let body = "";
  for await (const chunk of request) body += chunk;
  received.push({ key: request.headers["x-synthetic-key"], body });
};
const otherOrigin = http.createServer(async (request, response) => {
  await record(request);
  response.writeHead(202).end();
});
const origin = http.createServer(async (request, response) => {
  if (request.url === "/accepted") {
    await record(request);
    response.writeHead(202).end();
  } else {
    request.resume();
    response.writeHead(307, {
      location: request.url === "/same" ? `${url(origin)}/accepted` : `${url(otherOrigin)}/accepted`,
    }).end();
  }
});
const message = { jsonrpc: "2.0", method: "notifications/synthetic", params: { value: "synthetic-payload" } };
try {
  await listen(otherOrigin);
  await listen(origin);
  for (const route of ["cross", "same"]) {
    const transport = new StreamableHTTPClientTransport(new URL(`${url(origin)}/${route}`), {
      requestInit: { headers: { "X-Synthetic-Key": "synthetic-key" } },
    });
    try {
      if (route === "cross") {
        await assert.rejects(transport.send(message), /redirect.*not followed/i);
        assert.equal(received.length, 0, "another origin must receive neither the custom header nor the body");
      } else {
        await transport.send(message);
        assert.deepEqual(received, [{ key: "synthetic-key", body: JSON.stringify(message) }]);
      }
    } finally {
      await transport.close();
    }
  }
} finally {
  origin.closeAllConnections();
  otherOrigin.closeAllConnections();
  await Promise.all([new Promise((resolve) => origin.close(resolve)), new Promise((resolve) => otherOrigin.close(resolve))]);
}
console.log("MCP redirects: cross-origin rejected; same-origin retained");
