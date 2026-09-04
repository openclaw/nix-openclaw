#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { once } from "node:events";
import { spawn, spawnSync } from "node:child_process";

const gatewayPackage = process.env.OPENCLAW_GATEWAY;
const runtimePluginSmokeRoot = process.env.OPENCLAW_RUNTIME_PLUGIN_SMOKE_ROOT;
const runtimePluginSmokeId = process.env.OPENCLAW_RUNTIME_PLUGIN_SMOKE_ID ?? "diagnostics-prometheus";

if (!gatewayPackage) {
  console.error("OPENCLAW_GATEWAY is not set");
  process.exit(1);
}

const openclaw = path.join(gatewayPackage, "bin", "openclaw");
const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "openclaw-gateway-smoke-"));
const token = `smoke-${crypto.randomUUID()}`;
const logs = { stdout: "", stderr: "" };

function appendLog(name, chunk) {
  logs[name] += chunk.toString();
  if (logs[name].length > 12000) {
    logs[name] = logs[name].slice(-12000);
  }
}

async function freePort() {
  const server = net.createServer();
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const address = server.address();
  const port = typeof address === "object" && address ? address.port : null;
  await new Promise((resolve) => server.close(resolve));
  if (!port) {
    throw new Error("failed to allocate a local port");
  }
  return port;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function stopProcess(child) {
  if (child.exitCode !== null || child.signalCode !== null) {
    return;
  }
  child.kill("SIGTERM");
  const stopped = await Promise.race([
    once(child, "exit").then(() => true),
    sleep(3000).then(() => false),
  ]);
  if (!stopped) {
    child.kill("SIGKILL");
    await once(child, "exit").catch(() => {});
  }
}

function isolatedEnv() {
  const env = {
    ...process.env,
    HOME: path.join(tmpDir, "home"),
    XDG_CONFIG_HOME: path.join(tmpDir, "config"),
    XDG_CACHE_HOME: path.join(tmpDir, "cache"),
    XDG_DATA_HOME: path.join(tmpDir, "data"),
    OPENCLAW_CONFIG_PATH: path.join(tmpDir, "state", "openclaw.json"),
    OPENCLAW_STATE_DIR: path.join(tmpDir, "state"),
    OPENCLAW_LOG_DIR: path.join(tmpDir, "logs"),
    OPENCLAW_NIX_MODE: "1",
    // Loopback health probes must not advertise shared CI runner hostnames on the LAN.
    OPENCLAW_DISABLE_BONJOUR: "1",
    NO_COLOR: "1",
  };

  for (const key of [
    "HOME",
    "XDG_CONFIG_HOME",
    "XDG_CACHE_HOME",
    "XDG_DATA_HOME",
    "OPENCLAW_STATE_DIR",
    "OPENCLAW_LOG_DIR",
  ]) {
    fs.mkdirSync(env[key], { recursive: true });
  }

  return env;
}

const env = isolatedEnv();
let gateway = null;
let gatewayHealthy = false;

try {
  const version = spawnSync(openclaw, ["--version"], {
    env,
    encoding: "utf8",
  });
  if (version.status !== 0 || !version.stdout.trim()) {
    process.stdout.write(version.stdout ?? "");
    process.stderr.write(version.stderr ?? "");
    throw new Error("openclaw --version failed");
  }

  const port = await freePort();
  if (runtimePluginSmokeRoot) {
    fs.writeFileSync(
      env.OPENCLAW_CONFIG_PATH,
      JSON.stringify(
        {
          gateway: {
            mode: "local",
            port,
          },
          plugins: {
            load: {
              paths: [runtimePluginSmokeRoot],
            },
            entries: {
              [runtimePluginSmokeId]: { enabled: true },
            },
          },
        },
        null,
        2,
      ),
    );
  }

  gateway = spawn(
    openclaw,
    [
      "gateway",
      "run",
      "--allow-unconfigured",
      "--bind",
      "loopback",
      "--port",
      String(port),
      "--auth",
      "token",
      "--token",
      token,
      "--ws-log",
      "compact",
    ],
    {
      cwd: tmpDir,
      env,
      stdio: ["ignore", "pipe", "pipe"],
    },
  );

  gateway.stdout.on("data", (chunk) => appendLog("stdout", chunk));
  gateway.stderr.on("data", (chunk) => appendLog("stderr", chunk));

  const deadline = Date.now() + (runtimePluginSmokeRoot ? 90000 : 30000);
  let lastError = "";

  while (Date.now() < deadline) {
    if (gateway.exitCode !== null || gateway.signalCode !== null) {
      throw new Error(`gateway exited before health check: ${gateway.exitCode ?? gateway.signalCode}`);
    }

    const health = spawnSync(
      openclaw,
      [
        "gateway",
        "health",
        "--url",
        `ws://127.0.0.1:${port}`,
        "--token",
        token,
        "--json",
        "--timeout",
        "3000",
      ],
      {
        cwd: tmpDir,
        env,
        encoding: "utf8",
      },
    );

    if (health.status === 0) {
      let parsed;
      try {
        parsed = JSON.parse(health.stdout);
      } catch (err) {
        lastError = `health returned invalid JSON: ${health.stdout}${health.stderr}`;
        await sleep(500);
        continue;
      }

      if (parsed?.ok === true) {
        if (runtimePluginSmokeRoot) {
          const loadedPlugins = parsed.plugins?.loaded ?? [];
          if (!loadedPlugins.includes(runtimePluginSmokeId)) {
            throw new Error(
              `gateway health did not report Nix-managed ${runtimePluginSmokeId} loaded: ${JSON.stringify(parsed.plugins ?? {})}`,
            );
          }
        }
        console.log(`openclaw gateway smoke: ok (${version.stdout.trim()})`);
        gatewayHealthy = true;
        break;
      }
      lastError = `health JSON did not contain ok=true: ${health.stdout}`;
    } else {
      lastError = `${health.stdout}${health.stderr}`;
    }

    await sleep(500);
  }

  if (!gatewayHealthy) {
    throw new Error(`gateway health did not become ready: ${lastError.trim()}`);
  }
} catch (err) {
  console.error(String(err));
  if (logs.stdout.trim()) {
    console.error("--- gateway stdout ---");
    console.error(logs.stdout.trim());
  }
  if (logs.stderr.trim()) {
    console.error("--- gateway stderr ---");
    console.error(logs.stderr.trim());
  }
  process.exitCode = 1;
} finally {
  if (gateway) {
    await stopProcess(gateway);
  }
  fs.rmSync(tmpDir, { recursive: true, force: true });
}
