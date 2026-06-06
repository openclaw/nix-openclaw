#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const configPath = process.env.OPENCLAW_CONFIG_PATH;
const gatewayPackage = process.env.OPENCLAW_GATEWAY;
const expectedWorkspace = process.env.OPENCLAW_EXPECTED_WORKSPACE;
const runtimePluginSmokeId = process.env.OPENCLAW_RUNTIME_PLUGIN_SMOKE_ID;
const expectRuntimePlugin = Boolean(runtimePluginSmokeId);

if (!configPath) {
  console.error("OPENCLAW_CONFIG_PATH is not set");
  process.exit(1);
}

if (!gatewayPackage) {
  console.error("OPENCLAW_GATEWAY is not set");
  process.exit(1);
}

if (!expectedWorkspace) {
  console.error("OPENCLAW_EXPECTED_WORKSPACE is not set");
  process.exit(1);
}

const openclaw = path.join(gatewayPackage, "bin", "openclaw");
const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "openclaw-config-validity-"));

try {
  const env = {
    ...process.env,
    HOME: path.join(tmpDir, "home"),
    XDG_CONFIG_HOME: path.join(tmpDir, "config"),
    XDG_CACHE_HOME: path.join(tmpDir, "cache"),
    XDG_DATA_HOME: path.join(tmpDir, "data"),
    OPENCLAW_CONFIG_PATH: configPath,
    OPENCLAW_STATE_DIR: path.join(tmpDir, "state"),
    OPENCLAW_LOG_DIR: path.join(tmpDir, "logs"),
    OPENCLAW_NIX_MODE: "1",
    SLACK_APP_TOKEN: "xapp-openclaw-nix-check",
    SLACK_BOT_TOKEN: "xoxb-openclaw-nix-check",
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

  fs.mkdirSync(path.join(env.OPENCLAW_STATE_DIR, "plugins"), { recursive: true });
  fs.writeFileSync(path.join(env.OPENCLAW_STATE_DIR, "plugins", "installs.json"), "{ stale registry json");

  const validate = spawnSync(openclaw, ["config", "validate", "--json"], {
    env,
    encoding: "utf8",
  });

  if (validate.status !== 0) {
    if (validate.stdout) {
      process.stdout.write(validate.stdout);
    }
    if (validate.stderr) {
      process.stderr.write(validate.stderr);
    }
    console.error(`openclaw config validation failed with exit code ${validate.status ?? "unknown"}`);
    process.exit(validate.status ?? 1);
  }

  const validation = JSON.parse(validate.stdout);
  if (!validation || validation.valid !== true) {
    console.error("openclaw config validation did not report valid=true");
    process.exit(1);
  }

  const workspace = spawnSync(openclaw, ["config", "get", "agents.defaults.workspace", "--json"], {
    env,
    encoding: "utf8",
  });

  if (workspace.status !== 0) {
    if (workspace.stdout) {
      process.stdout.write(workspace.stdout);
    }
    if (workspace.stderr) {
      process.stderr.write(workspace.stderr);
    }
    console.error(`openclaw config get failed with exit code ${workspace.status ?? "unknown"}`);
    process.exit(workspace.status ?? 1);
  }

  const actualWorkspace = JSON.parse(workspace.stdout);
  if (actualWorkspace !== expectedWorkspace) {
    console.error(
      `openclaw config returned unexpected workspace: ${JSON.stringify(actualWorkspace)} != ${JSON.stringify(expectedWorkspace)}`,
    );
    process.exit(1);
  }

  const plugins = spawnSync(openclaw, ["plugins", "list", "--json", "--verbose"], {
    env,
    encoding: "utf8",
  });

  if (plugins.status !== 0) {
    if (plugins.stdout) {
      process.stdout.write(plugins.stdout);
    }
    if (plugins.stderr) {
      process.stderr.write(plugins.stderr);
    }
    console.error(`openclaw plugins list failed with exit code ${plugins.status ?? "unknown"}`);
    process.exit(plugins.status ?? 1);
  }

  const pluginList = JSON.parse(plugins.stdout);
  const runtimePlugin = (pluginList.plugins ?? []).find((plugin) => plugin.id === runtimePluginSmokeId);
  if (expectRuntimePlugin && !runtimePlugin) {
    console.error(
      `openclaw plugins list ids: ${JSON.stringify((pluginList.plugins ?? []).map((plugin) => ({
        id: plugin.id,
        origin: plugin.origin,
        status: plugin.status,
        diagnostics: plugin.diagnostics,
      })))}`,
    );
    console.error(`openclaw plugins diagnostics: ${JSON.stringify(pluginList.diagnostics ?? [])}`);
    console.error(`openclaw plugins list did not discover the ${runtimePluginSmokeId} runtime plugin`);
    process.exit(1);
  }
  if (
    expectRuntimePlugin
    && (runtimePlugin.origin !== "config" || runtimePlugin.enabled !== true || runtimePlugin.status !== "loaded")
  ) {
    console.error(`Runtime plugin was not loaded from config: ${JSON.stringify(runtimePlugin)}`);
    process.exit(1);
  }
  if (expectRuntimePlugin && !(runtimePlugin.channelIds ?? []).includes(runtimePluginSmokeId)) {
    console.error(`Runtime plugin did not expose its channel: ${JSON.stringify(runtimePlugin)}`);
    process.exit(1);
  }
  if (expectRuntimePlugin && runtimePlugin.dependencyStatus?.requiredInstalled !== true) {
    console.error(`Runtime plugin dependencies were not installed: ${JSON.stringify(runtimePlugin)}`);
    process.exit(1);
  }

  const status = spawnSync(openclaw, ["status", "--timeout", "1000"], {
    env,
    encoding: "utf8",
  });

  if (status.status !== 0) {
    if (status.stdout) {
      process.stdout.write(status.stdout);
    }
    if (status.stderr) {
      process.stderr.write(status.stderr);
    }
    console.error(`openclaw status failed with exit code ${status.status ?? "unknown"}`);
    process.exit(status.status ?? 1);
  }

  const statusOutput = `${status.stdout}\n${status.stderr}`.toLowerCase();
  if (expectRuntimePlugin && !statusOutput.includes(runtimePluginSmokeId)) {
    console.error(`openclaw status did not include ${runtimePluginSmokeId}:\n${status.stdout}${status.stderr}`);
    process.exit(1);
  }
  if (statusOutput.includes("plugin not installed") || statusOutput.includes("openclaw plugins install")) {
    console.error(`openclaw status reported a mutable install hint for Nix-managed Slack:\n${status.stdout}${status.stderr}`);
    process.exit(1);
  }

  console.log("openclaw config validation: ok");
} finally {
  fs.rmSync(tmpDir, { recursive: true, force: true });
}
