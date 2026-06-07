#!/usr/bin/env node
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { spawnSync } from "node:child_process";
import { pathToFileURL } from "node:url";

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`missing ${name}`);
  }
  return value;
}

const gateway = requireEnv("OPENCLAW_GATEWAY");
const gatewayWrapper = requireEnv("OPENCLAW_GATEWAY_WRAPPER");
const codexPluginRoot = requireEnv("OPENCLAW_RUNTIME_PATH_CODEX_PLUGIN_ROOT");
const expectedBinDir = requireEnv("OPENCLAW_RUNTIME_PATH_EXPECTED_BIN_DIR");
const expectedCommand = requireEnv("OPENCLAW_RUNTIME_PATH_EXPECTED_COMMAND");
const expectedOutput = requireEnv("OPENCLAW_RUNTIME_PATH_EXPECTED_OUTPUT");
const basePath = requireEnv("OPENCLAW_RUNTIME_PATH_BASE_PATH");
const shell = requireEnv("OPENCLAW_RUNTIME_PATH_SHELL");
const pathPrepend = requireEnv("OPENCLAW_RUNTIME_PATH_PREPEND")
  .split(":")
  .filter(Boolean);

if (!/^[A-Za-z0-9._-]+$/.test(expectedCommand)) {
  throw new Error(`unsafe smoke command name: ${expectedCommand}`);
}

if (!pathPrepend.includes(expectedBinDir)) {
  throw new Error(`generated tools.exec.pathPrepend does not include ${expectedBinDir}`);
}

const codexDistDir = path.join(codexPluginRoot, "dist");
const gatewayWrapperText = await fs.readFile(gatewayWrapper, "utf8");
await fs.access(path.join(codexPluginRoot, "node_modules", "@openai", "codex", "package.json"));

function readShellExport(name) {
  const match = gatewayWrapperText.match(
    new RegExp(`export ${name}=(?:"([^"]*)"|'([^']*)'|([^\\n]+))`),
  );
  return match?.[1] ?? match?.[2] ?? match?.[3]?.trim() ?? "";
}

const appServerArgs = readShellExport("OPENCLAW_CODEX_APP_SERVER_ARGS");
if (!appServerArgs) {
  throw new Error("gateway wrapper does not export OPENCLAW_CODEX_APP_SERVER_ARGS");
}
if (gatewayWrapperText.includes("OPENCLAW_CODEX_APP_SERVER_BIN")) {
  throw new Error("gateway wrapper must not override OpenClaw's managed Codex app-server binary");
}
if (!appServerArgs.includes("shell_environment_policy.set.PATH=")) {
  throw new Error(
    `Codex app-server args do not set shell_environment_policy PATH: ${appServerArgs}`,
  );
}
if (!appServerArgs.includes(expectedBinDir)) {
  throw new Error(`Codex app-server args do not include ${expectedBinDir}: ${appServerArgs}`);
}

async function findPackagedFunction(modulePattern, functionName) {
  for (const file of await fs.readdir(codexDistDir)) {
    if (!modulePattern.test(file)) {
      continue;
    }
    const mod = await import(pathToFileURL(path.join(codexDistDir, file)).href);
    const fn = Object.values(mod).find(
      (value) => typeof value === "function" && value.name === functionName,
    );
    if (typeof fn === "function") {
      return fn;
    }
  }
  throw new Error(`could not find packaged ${functionName} in ${codexDistDir}`);
}

const requestCodexAppServerJson = await findPackagedFunction(
  /^request-[A-Za-z0-9_-]+\.js$/,
  "requestCodexAppServerJson",
);
const resolveCodexAppServerRuntimeOptions = await findPackagedFunction(
  /^config-[A-Za-z0-9_-]+\.js$/,
  "resolveCodexAppServerRuntimeOptions",
);

const root = await fs.mkdtemp(path.join(os.tmpdir(), "openclaw-runtime-path-"));
const stateDir = path.join(root, "state");
const agentDir = path.join(root, "agent");
const codexHome = path.join(agentDir, "codex-home");
await fs.mkdir(stateDir, { recursive: true });
await fs.mkdir(codexHome, { recursive: true });
await fs.writeFile(
  path.join(codexHome, "config.toml"),
  [
    "[shell_environment_policy]",
    'inherit = "all"',
    "",
    "[shell_environment_policy.set]",
    `PATH = ${JSON.stringify(basePath)}`,
    "",
  ].join("\n"),
);

Object.assign(process.env, {
  HOME: root,
  OPENCLAW_STATE_DIR: stateDir,
  PATH: basePath,
  SHELL: shell,
});

const wrapperVersion = spawnSync(shell, ["-x", gatewayWrapper, "--version"], {
  cwd: root,
  env: process.env,
  encoding: "utf8",
});
if (wrapperVersion.status !== 0 || !wrapperVersion.stdout.trim()) {
  throw new Error(
    `gateway wrapper --version failed: ${wrapperVersion.stdout}${wrapperVersion.stderr}`,
  );
}
const wrapperTrace = wrapperVersion.stderr;
if (!wrapperTrace.includes(expectedBinDir)) {
  throw new Error(`gateway wrapper did not prepend ${expectedBinDir}: ${wrapperTrace}`);
}
if (
  !wrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=") ||
  !wrapperTrace.includes("shell_environment_policy.set.PATH=")
) {
  throw new Error(`gateway wrapper did not export Codex app-server env: ${wrapperTrace}`);
}
if (wrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_BIN=")) {
  throw new Error(`gateway wrapper overrode OpenClaw's managed Codex app-server: ${wrapperTrace}`);
}
if (!wrapperTrace.includes("exec ") || !wrapperTrace.includes("/bin/openclaw")) {
  throw new Error(`gateway wrapper did not exec packaged OpenClaw: ${wrapperTrace}`);
}

const inheritedRuntimePath = [...pathPrepend, ...basePath.split(":").filter(Boolean)].join(":");
Object.assign(process.env, {
  PATH: inheritedRuntimePath,
});

function startOptionsFromEnv(extraEnv) {
  return resolveCodexAppServerRuntimeOptions({
    env: { ...process.env, ...extraEnv },
  }).start;
}

async function runCodexCommand(startOptions) {
  return requestCodexAppServerJson({
    method: "command/exec",
    requestParams: {
      command: [
        shell,
        "-c",
        `printf 'PATH=%s\\n' "$PATH"; command -v ${expectedCommand} && ${expectedCommand}`,
      ],
      cwd: root,
      sandboxPolicy: { type: "dangerFullAccess" },
      timeoutMs: 10_000,
    },
    timeoutMs: 30_000,
    startOptions,
    authProfileId: null,
    agentDir,
    config: {},
    isolated: true,
  });
}

function assertRuntimePathArg(startOptions) {
  if (startOptions.command !== "codex" || startOptions.commandSource !== "managed") {
    throw new Error(
      `Codex app-server should use OpenClaw managed resolution: ${JSON.stringify(startOptions)}`,
    );
  }
  const configIndex = startOptions.args.indexOf("-c");
  if (configIndex < 0) {
    throw new Error(`Codex app-server args are missing -c: ${JSON.stringify(startOptions.args)}`);
  }
  const configArg = startOptions.args[configIndex + 1] ?? "";
  if (!configArg.startsWith("shell_environment_policy.set.PATH=")) {
    throw new Error(
      `Codex app-server -c arg does not set shell_environment_policy PATH: ${JSON.stringify(startOptions.args)}`,
    );
  }
  if (!configArg.includes(expectedBinDir)) {
    throw new Error(`Codex app-server PATH does not include probe dir: ${configArg}`);
  }
}

const missingStartOptions = startOptionsFromEnv({
  OPENCLAW_CODEX_APP_SERVER_ARGS: "",
});
const missingResult = await runCodexCommand(missingStartOptions);
if (missingResult?.exitCode === 0) {
  throw new Error(
    `${expectedCommand} resolved despite Codex config masking inherited wrapper PATH`,
  );
}

const startOptions = startOptionsFromEnv({
  OPENCLAW_CODEX_APP_SERVER_ARGS: appServerArgs,
});
assertRuntimePathArg(startOptions);

const result = await runCodexCommand(startOptions);
const output = `${result?.stdout ?? ""}${result?.stderr ?? ""}`.trim();
const lines = output.split(/\r?\n/).filter(Boolean);

if (result?.exitCode !== 0) {
  throw new Error(`${expectedCommand} smoke failed with exit ${result?.exitCode}: ${output}`);
}

if (!lines[0]?.startsWith("PATH=") || !lines[0].includes(expectedBinDir)) {
  throw new Error(`${expectedCommand} PATH missing ${expectedBinDir}: ${output}`);
}

if (lines[1] !== `${expectedBinDir}/${expectedCommand}`) {
  throw new Error(
    `${expectedCommand} resolved to ${lines[1] ?? "(missing)"}, expected ${expectedBinDir}/${expectedCommand}`,
  );
}

if ((lines[2] ?? "") !== expectedOutput) {
  throw new Error(`${expectedCommand} output missing from exec result: ${output}`);
}

console.log(
  [
    "openclaw-runtime-path proof:",
    `- generated tools.exec.pathPrepend includes ${expectedCommand}`,
    "- wrapper exports Codex app-server PATH args without overriding the managed Codex binary",
    "- Codex command/exec fails when isolated Codex config masks inherited wrapper PATH",
    `- Codex command/exec succeeds when generated PATH resolves ${expectedBinDir}/${expectedCommand}`,
  ].join("\n"),
);
