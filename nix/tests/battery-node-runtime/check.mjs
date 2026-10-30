import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import fs from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const run = promisify(execFile);
const root = await fs.mkdtemp(path.join(os.tmpdir(), "openclaw-battery-node-"));
const marker = "OpenClaw packaged summarize extraction works";
const article = `<html><head><title>${marker}</title></head><body><article><h1>${marker}</h1>${`<p>${marker}. This synthetic article verifies the selected CLI can read its actual runtime dependencies and extract readable text.</p>`.repeat(20)}</article></body></html>`;
const server = http.createServer((_request, response) => {
  response.writeHead(200, { "content-type": "text/html" });
  response.end(article);
});

try {
  const scenarios = [process.env.OPENCLAW_TOOLS_PATH, process.env.EXPOSED_SUMMARIZE_PATH].filter(Boolean);
  assert.ok(scenarios.length > 0, "packaged summarize delivery paths must be supplied");
  for (const [index, toolsPath] of scenarios.entries()) {
    const candidates = toolsPath
      .split(path.delimiter)
      .filter(Boolean)
      .map((directory) => path.join(directory, "summarize"));
    let executable;
    for (const candidate of candidates) {
      if (await fs.access(candidate).then(() => true, () => false)) {
        executable = candidate;
        break;
      }
    }
    assert.ok(executable, "summarize must be on the packaged OpenClaw tools PATH");
    if (!server.listening) {
      await new Promise((resolve, reject) => {
        server.once("error", reject);
        server.listen(0, "127.0.0.1", resolve);
      });
    }
    const probe = path.join(root, `selected-node-${index}`);
    const env = {
      ...process.env,
      HOME: root,
      XDG_CACHE_HOME: path.join(root, "cache"),
      XDG_CONFIG_HOME: path.join(root, "config"),
      NODE_OPTIONS: `--require=${fileURLToPath(new URL("./probe.cjs", import.meta.url))}`,
      OPENCLAW_BATTERY_RUNTIME_PROBE: probe,
    };
    const { stdout } = await run(executable, [
      `http://127.0.0.1:${server.address().port}`,
      "--extract", "--plain", "--format", "text", "--firecrawl", "off", "--timeout", "10s",
    ], { env, timeout: 30_000, maxBuffer: 1_000_000 });
    assert.ok(stdout.includes(marker), "actual summarize must extract the fixture article");
    const actual = await fs.realpath((await fs.readFile(probe, "utf8")).trim());
    const expected = await fs.realpath(process.env.EXPECTED_NODE);
    assert.equal(actual, expected, "summarize must execute OpenClaw's patched Node runtime");
    console.log(`summarize extraction passed: ${executable} using ${actual}`);
  }
} finally {
  await new Promise((resolve) => server.close(resolve));
  await fs.rm(root, { recursive: true, force: true });
}
