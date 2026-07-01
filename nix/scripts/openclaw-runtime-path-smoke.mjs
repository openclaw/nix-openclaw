#!/usr/bin/env node
import process from "node:process";
import { spawn, spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readlinkSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import readline from "node:readline";

const appServerListenStdio = "stdio://";
const codexJsonRpcTimeoutMs = 15_000;
const nixStorePrefix = "/nix/store/";
const openclawAgentCodexHome = path.join("agents", "main", "agent", "codex-home");
// The smoke commands are fixture-controlled, but they are interpolated into
// shell snippets below. Keep them as command names only: no paths, whitespace,
// or shell metacharacters.
const safeCommandNamePattern = /^[A-Za-z0-9._-]+$/;

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`missing ${name}`);
  }
  return value;
}

const gatewayWrapper = requireEnv("OPENCLAW_GATEWAY_WRAPPER");
const codexGatewayWrapper = requireEnv("OPENCLAW_CODEX_GATEWAY_WRAPPER");
const customCodexGatewayWrapper = requireEnv("OPENCLAW_CUSTOM_CODEX_GATEWAY_WRAPPER");
const customCodexArgsGatewayWrapper = requireEnv("OPENCLAW_CUSTOM_CODEX_ARGS_GATEWAY_WRAPPER");
const customCodexEnvGatewayWrapper = requireEnv("OPENCLAW_CUSTOM_CODEX_ENV_GATEWAY_WRAPPER");
const customCodexEnvExpectedBin = requireEnv("OPENCLAW_CUSTOM_CODEX_ENV_EXPECTED_BIN");
const customCodexEnvArgsGatewayWrapper = requireEnv("OPENCLAW_CUSTOM_CODEX_ENV_ARGS_GATEWAY_WRAPPER");
const customCodexEnvArgsExpected = requireEnv("OPENCLAW_CUSTOM_CODEX_ENV_ARGS_EXPECTED");
const websocketCodexGatewayWrapper = requireEnv("OPENCLAW_WEBSOCKET_CODEX_GATEWAY_WRAPPER");
const expectedBinDir = requireEnv("OPENCLAW_RUNTIME_PATH_EXPECTED_BIN_DIR");
const expectedCommand = requireEnv("OPENCLAW_RUNTIME_PATH_EXPECTED_COMMAND");
const expectedOutput = requireEnv("OPENCLAW_RUNTIME_PATH_EXPECTED_OUTPUT");
const basePath = requireEnv("OPENCLAW_RUNTIME_PATH_BASE_PATH");
const shell = requireEnv("OPENCLAW_RUNTIME_PATH_SHELL");
const pathPrepend = requireEnv("OPENCLAW_RUNTIME_PATH_PREPEND")
  .split(":")
  .filter(Boolean);
const codexAppServerCommand = requireEnv("OPENCLAW_CODEX_APP_SERVER_COMMAND");
const codexExpectedBinDir = requireEnv("OPENCLAW_CODEX_RUNTIME_EXPECTED_BIN_DIR");
const codexExpectedCommand = requireEnv("OPENCLAW_CODEX_RUNTIME_EXPECTED_COMMAND");
const codexExpectedVersionPrefix = requireEnv("OPENCLAW_CODEX_RUNTIME_EXPECTED_VERSION_PREFIX");
const codexRuntimeProfileBinDir = requireEnv("OPENCLAW_CODEX_RUNTIME_PROFILE_BIN_DIR");
const codexPathPrepend = requireEnv("OPENCLAW_CODEX_RUNTIME_PATH_PREPEND")
  .split(":")
  .filter(Boolean);

if (!safeCommandNamePattern.test(expectedCommand)) {
  throw new Error(`unsafe smoke command name: ${expectedCommand}`);
}

if (!safeCommandNamePattern.test(codexExpectedCommand)) {
  throw new Error(`unsafe Codex smoke command name: ${codexExpectedCommand}`);
}

if (!pathPrepend.includes(expectedBinDir)) {
  throw new Error(`generated tools.exec.pathPrepend does not include ${expectedBinDir}`);
}

if (!codexPathPrepend.includes(codexExpectedBinDir)) {
  throw new Error(`generated Codex runtime path does not include ${codexExpectedBinDir}`);
}

const toolPath = [...pathPrepend, ...basePath.split(":").filter(Boolean)].join(":");
const toolLookup = spawnSync(
  shell,
  ["-c", `command -v ${expectedCommand} && ${expectedCommand}`],
  {
    env: {
      ...process.env,
      PATH: toolPath,
      SHELL: shell,
    },
    encoding: "utf8",
  },
);

const toolOutput = `${toolLookup.stdout ?? ""}${toolLookup.stderr ?? ""}`.trim();
const toolLines = toolOutput.split(/\r?\n/).filter(Boolean);

if (toolLookup.status !== 0) {
  throw new Error(`${expectedCommand} smoke failed with exit ${toolLookup.status}: ${toolOutput}`);
}

if (toolLines[0] !== `${expectedBinDir}/${expectedCommand}`) {
  throw new Error(
    `${expectedCommand} resolved to ${toolLines[0] ?? "(missing)"}, expected ${expectedBinDir}/${expectedCommand}`,
  );
}

if ((toolLines[1] ?? "") !== expectedOutput) {
  throw new Error(`${expectedCommand} output missing from smoke result: ${toolOutput}`);
}

function traceWrapperVersion(label, wrapper, envOverrides = {}) {
  const result = spawnSync(shell, ["-x", wrapper, "--version"], {
    env: {
      ...process.env,
      ...envOverrides,
      PATH: basePath,
      SHELL: shell,
    },
    encoding: "utf8",
  });
  if (result.status !== 0 || !result.stdout.trim()) {
    throw new Error(`${label} wrapper --version failed: ${result.stdout}${result.stderr}`);
  }
  return result.stderr;
}

const wrapperTrace = traceWrapperVersion("gateway", gatewayWrapper);
if (!wrapperTrace.includes(expectedBinDir)) {
  throw new Error(`gateway wrapper did not prepend ${expectedBinDir}: ${wrapperTrace}`);
}

if (
  wrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=") ||
  wrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_BIN=")
) {
  throw new Error(`base gateway wrapper must not export Codex app-server command or args: ${wrapperTrace}`);
}

if (!wrapperTrace.includes("exec ") || !wrapperTrace.includes("/bin/openclaw")) {
  throw new Error(`gateway wrapper did not exec packaged OpenClaw: ${wrapperTrace}`);
}

const codexWrapperTrace = traceWrapperVersion("Codex gateway", codexGatewayWrapper);
if (!codexWrapperTrace.includes(codexExpectedBinDir)) {
  throw new Error(`Codex gateway wrapper did not prepend ${codexExpectedBinDir}: ${codexWrapperTrace}`);
}

if (codexWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=")) {
  throw new Error(`Codex gateway wrapper must not configure app-server argv: ${codexWrapperTrace}`);
}

// The wrapper is executed with `sh -x`; shells print export assignments with
// implementation-specific quoting. This regex extracts only the assigned value
// so the smoke can launch the generated wrapper through the same path OpenClaw
// would inherit.
const codexAppServerLauncherMatch = codexWrapperTrace.match(
  /OPENCLAW_CODEX_APP_SERVER_BIN=("[^"]+"|'[^']+'|[^ \n]+)/,
);
if (!codexAppServerLauncherMatch) {
  throw new Error(`Codex gateway wrapper did not export OPENCLAW_CODEX_APP_SERVER_BIN: ${codexWrapperTrace}`);
}
const codexAppServerLauncher = codexAppServerLauncherMatch[1].replace(/^["']|["']$/g, "");

const inheritedCodexOverrideTrace = traceWrapperVersion("inherited-env Codex gateway", codexGatewayWrapper, {
  OPENCLAW_CODEX_APP_SERVER_BIN: "/inherited/codex",
});
if (
  inheritedCodexOverrideTrace.includes("OPENCLAW_CODEX_APP_SERVER_BIN=") ||
  inheritedCodexOverrideTrace.includes("openclaw-codex-app-server")
) {
  throw new Error(
    `inherited OPENCLAW_CODEX_APP_SERVER_BIN must keep the Nix Codex launcher out of the gateway wrapper: ${inheritedCodexOverrideTrace}`,
  );
}

const customCodexWrapperTrace = traceWrapperVersion("custom-command Codex gateway", customCodexGatewayWrapper);
if (
  customCodexWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=") ||
  customCodexWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_BIN=")
) {
  throw new Error(
    `custom Codex appServer.command must keep OPENCLAW_CODEX_APP_SERVER_BIN and OPENCLAW_CODEX_APP_SERVER_ARGS out of the gateway wrapper: ${customCodexWrapperTrace}`,
  );
}

const customCodexArgsWrapperTrace = traceWrapperVersion("custom-args Codex gateway", customCodexArgsGatewayWrapper);
if (customCodexArgsWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=")) {
  throw new Error(
    `config appServer.args must stay in OpenClaw config, not the gateway wrapper environment: ${customCodexArgsWrapperTrace}`,
  );
}

if (!customCodexArgsWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_BIN=")) {
  throw new Error(
    `config appServer.args must still use the Nix Codex launcher because args do not choose the executable: ${customCodexArgsWrapperTrace}`,
  );
}

const customCodexEnvWrapperTrace = traceWrapperVersion("custom-env Codex gateway", customCodexEnvGatewayWrapper);
if (!customCodexEnvWrapperTrace.includes(`OPENCLAW_CODEX_APP_SERVER_BIN=${customCodexEnvExpectedBin}`)) {
  throw new Error(
    `custom OPENCLAW_CODEX_APP_SERVER_BIN was not preserved in the gateway wrapper: ${customCodexEnvWrapperTrace}`,
  );
}

if (
  customCodexEnvWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=") ||
  customCodexEnvWrapperTrace.includes("openclaw-codex-app-server")
) {
  throw new Error(
    `custom OPENCLAW_CODEX_APP_SERVER_BIN must keep the Nix Codex launcher out of the gateway wrapper: ${customCodexEnvWrapperTrace}`,
  );
}

const customCodexEnvArgsWrapperTrace = traceWrapperVersion(
  "custom-env-args Codex gateway",
  customCodexEnvArgsGatewayWrapper,
);
if (!customCodexEnvArgsWrapperTrace.includes(`OPENCLAW_CODEX_APP_SERVER_ARGS=${customCodexEnvArgsExpected}`)) {
  throw new Error(
    `custom OPENCLAW_CODEX_APP_SERVER_ARGS was not preserved in the gateway wrapper: ${customCodexEnvArgsWrapperTrace}`,
  );
}

if (!customCodexEnvArgsWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_BIN=")) {
  throw new Error(
    `custom OPENCLAW_CODEX_APP_SERVER_ARGS must still use the Nix Codex launcher because args do not choose the executable: ${customCodexEnvArgsWrapperTrace}`,
  );
}

const websocketCodexWrapperTrace = traceWrapperVersion("websocket Codex gateway", websocketCodexGatewayWrapper);
if (
  websocketCodexWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=") ||
  websocketCodexWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_BIN=")
) {
  throw new Error(
    `Codex websocket transport must keep local stdio app-server command and args out of the gateway wrapper: ${websocketCodexWrapperTrace}`,
  );
}

function createJsonRpcClient(child) {
  const pending = new Map();
  let nextId = 1;
  let stderr = "";

  child.stderr.on("data", (chunk) => {
    stderr += chunk.toString();
  });

  const rl = readline.createInterface({ input: child.stdout });
  rl.on("line", (line) => {
    if (!line.trim()) {
      return;
    }
    let message;
    try {
      message = JSON.parse(line);
    } catch (error) {
      for (const request of pending.values()) {
        request.reject(new Error(`Codex app-server emitted invalid JSON: ${line}\n${error}`));
      }
      pending.clear();
      return;
    }
    if (message.id === undefined || !pending.has(message.id)) {
      return;
    }
    const request = pending.get(message.id);
    pending.delete(message.id);
    clearTimeout(request.timer);
    if (message.error) {
      request.reject(
        new Error(`Codex app-server ${request.method} failed: ${JSON.stringify(message.error)}`),
      );
    } else {
      request.resolve(message.result);
    }
  });

  child.on("exit", (code, signal) => {
    for (const request of pending.values()) {
      clearTimeout(request.timer);
      request.reject(
        new Error(
          `Codex app-server exited before ${request.method} completed: code=${code} signal=${signal}\n${stderr}`,
        ),
      );
    }
    pending.clear();
  });

  return {
    get stderr() {
      return stderr;
    },
    request(method, params, timeoutMs = codexJsonRpcTimeoutMs) {
      const id = nextId;
      nextId += 1;
      const payload = JSON.stringify({ id, method, params });
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          pending.delete(id);
          reject(new Error(`Timed out waiting for Codex app-server ${method}\n${stderr}`));
        }, timeoutMs);
        pending.set(id, { method, resolve, reject, timer });
        child.stdin.write(`${payload}\n`);
      });
    },
  };
}

async function withCodexAppServer(label, options, fn) {
  const tempRoot = mkdtempSync(path.join(tmpdir(), `openclaw-codex-${label}-`));
  const codexHome = path.join(tempRoot, openclawAgentCodexHome);
  const nativeHome = path.join(codexHome, "home");
  const inheritedHome = path.join(tempRoot, "inherited-home");
  mkdirSync(codexHome, { recursive: true });
  mkdirSync(inheritedHome, { recursive: true });
  if (options.prepareHome) {
    options.prepareHome({ codexHome, nativeHome });
  }
  const appServerCommand = options.command ?? process.execPath;
  const appServerArgs = options.args ?? [
    codexAppServerCommand,
    "app-server",
    "--listen",
    appServerListenStdio,
  ];
  const child = spawn(appServerCommand, appServerArgs, {
    env: {
      ...process.env,
      CODEX_HOME: codexHome,
      HOME: inheritedHome,
      // Keep the smoke focused on command execution and HOME/PATH. Managed
      // config generation is upstream Codex behavior, not what this Nix check
      // is proving.
      CODEX_APP_SERVER_DISABLE_MANAGED_CONFIG: "1",
      PATH: options.pathValue,
      RUST_LOG: "warn",
    },
    stdio: ["pipe", "pipe", "pipe"],
  });
  const client = createJsonRpcClient(child);
  try {
    await client.request("initialize", {
      clientInfo: {
        name: "openclaw-runtime-path-smoke",
        version: "0.1.0",
      },
      capabilities: {
        experimentalApi: true,
        requestAttestation: false,
      },
    });
    return await fn(client, { codexHome, inheritedHome, nativeHome });
  } finally {
    child.kill("SIGTERM");
    rmSync(tempRoot, { recursive: true, force: true });
  }
}

async function commandExec(client, command) {
  return await client.request("command/exec", {
    command,
    sandboxPolicy: { type: "dangerFullAccess" },
    tty: false,
    streamStdin: false,
    streamStdoutStderr: false,
    disableTimeout: true,
  });
}

const baseOnlyPath = basePath;
const missingMarker = `OPENCLAW_${codexExpectedCommand.toUpperCase()}_MISSING`;
const missingResult = await withCodexAppServer(
  "without-nix-managed-launcher",
  {
    pathValue: baseOnlyPath,
    prepareHome: ({ nativeHome }) => {
      // Preseed $CODEX_HOME/home/.nix-profile/bin to prove CODEX_HOME is not
      // enough by itself. Without the Nix launcher, Codex command/exec still
      // uses inherited HOME/PATH and cannot see this bin directory.
      const profileDir = path.join(nativeHome, ".nix-profile");
      mkdirSync(profileDir, { recursive: true });
      symlinkSync(codexRuntimeProfileBinDir, path.join(profileDir, "bin"));
    },
  },
  async (client) =>
    commandExec(client, [
      shell,
      "-lc",
      [
        "set -u",
        "printf 'HOME=%s\\n' \"$HOME\"",
        "printf 'CODEX_HOME=%s\\n' \"$CODEX_HOME\"",
        "profile_bin=\"$CODEX_HOME/home/.nix-profile/bin\"",
        "if [ -L \"$profile_bin\" ]; then printf 'CODEX_HOME_PROFILE=%s\\n' \"$(readlink \"$profile_bin\")\"; else printf 'CODEX_HOME_PROFILE_MISSING\\n'; fi",
        "printf 'PATH=%s\\n' \"$PATH\"",
        `if command -v ${codexExpectedCommand}; then command -v ${codexExpectedCommand}; ${codexExpectedCommand} --version; else printf '${missingMarker}\\n'; exit 127; fi`,
      ].join("; "),
    ]),
);

if (missingResult.exitCode === 0 || !missingResult.stdout.includes(missingMarker)) {
  throw new Error(
    [
      `Codex app-server unexpectedly resolved ${codexExpectedCommand} without $CODEX_HOME/home/.nix-profile/bin on PATH.`,
      `stdout: ${missingResult.stdout}`,
      `stderr: ${missingResult.stderr}`,
    ].join("\n"),
  );
}

if (!missingResult.stdout.includes(`CODEX_HOME_PROFILE=${codexRuntimeProfileBinDir}`)) {
  throw new Error(
    [
      `Codex app-server before-state did not include the preseeded $CODEX_HOME/home/.nix-profile/bin symlink.`,
      `expected: ${codexRuntimeProfileBinDir}`,
      `stdout: ${missingResult.stdout}`,
      `stderr: ${missingResult.stderr}`,
    ].join("\n"),
  );
}

let expectedNativeCommandPath = "";
let profileBinTarget = "";
const codexResult = await withCodexAppServer(
  "with-nix-managed-launcher",
  {
    command: codexAppServerLauncher,
    args: ["app-server", "--listen", appServerListenStdio],
    pathValue: baseOnlyPath,
  },
  async (client, homes) => {
    expectedNativeCommandPath = path.join(
      homes.nativeHome,
      ".nix-profile",
      "bin",
      codexExpectedCommand,
    );
    const result = await commandExec(client, [
      shell,
      "-lc",
      [
        "set -u",
        "printf 'HOME=%s\\n' \"$HOME\"",
        "printf 'PATH=%s\\n' \"$PATH\"",
        `command -v ${codexExpectedCommand}`,
        `${codexExpectedCommand} --version`,
      ].join("; "),
    ]);
    profileBinTarget = readlinkSync(path.dirname(expectedNativeCommandPath));
    return result;
  },
);

if (codexResult.exitCode !== 0) {
  throw new Error(
    [
      `Codex app-server ${codexExpectedCommand} smoke failed with exit ${codexResult.exitCode}.`,
      `result: ${JSON.stringify(codexResult)}`,
      `stdout: ${codexResult.stdout}`,
      `stderr: ${codexResult.stderr}`,
    ].join("\n"),
  );
}

const codexLines = codexResult.stdout.split(/\r?\n/).filter(Boolean);
if (!codexLines[0]?.startsWith("HOME=")) {
  throw new Error(`Codex app-server did not print HOME before ${codexExpectedCommand} lookup: ${codexResult.stdout}`);
}

if (!codexLines[0].endsWith("/codex-home/home")) {
  throw new Error(`Codex app-server HOME was not the OpenClaw native home: ${codexLines[0]}`);
}

if (!codexLines[1]?.startsWith("PATH=")) {
  throw new Error(`Codex app-server did not print PATH before ${codexExpectedCommand} lookup: ${codexResult.stdout}`);
}

if (!codexLines[1].includes("/codex-home/home/.nix-profile/bin")) {
  throw new Error(`Codex app-server PATH did not include $CODEX_HOME/home/.nix-profile/bin: ${codexLines[1]}`);
}

if (codexLines[2] !== expectedNativeCommandPath) {
  throw new Error(
    `${codexExpectedCommand} resolved to ${codexLines[2] ?? "(missing)"}, expected ${expectedNativeCommandPath}\n${codexLines[1]}`,
  );
}

if (!(codexLines[3] ?? "").startsWith(codexExpectedVersionPrefix)) {
  throw new Error(
    `${codexExpectedCommand} version output ${codexLines[3] ?? "(missing)"} did not start with ${codexExpectedVersionPrefix}`,
  );
}

if (!profileBinTarget.startsWith(nixStorePrefix) || !profileBinTarget.endsWith("/bin")) {
  throw new Error(
    `Nix Codex launcher linked ${path.dirname(expectedNativeCommandPath)} to ${profileBinTarget}, expected a Nix store-backed bin directory`,
  );
}

console.log(
  [
    "openclaw-runtime-path proof:",
    `- generated tools.exec.pathPrepend resolves ${expectedBinDir}/${expectedCommand}`,
    "- gateway wrapper prepends the same runtime tool path",
    "- runtimePackages alone do not configure the Codex app-server launcher",
    "- selecting the Nix-packaged Codex runtime plugin makes the gateway wrapper export the Nix app-server launcher",
    "- a user appServer.command keeps the Nix Codex launcher out of the gateway wrapper",
    "- a user appServer.args still uses the Nix Codex launcher because args do not choose the executable",
    "- a user OPENCLAW_CODEX_APP_SERVER_BIN keeps the Nix Codex launcher out of the gateway wrapper",
    "- a user OPENCLAW_CODEX_APP_SERVER_ARGS is preserved and still uses the Nix Codex launcher because args do not choose the executable",
    "- inherited OPENCLAW_CODEX_APP_SERVER_BIN keeps the Nix Codex launcher out of the gateway wrapper",
    "- Codex websocket transport keeps the local stdio launcher out of the gateway wrapper",
    `- before Nix-managed Codex launcher: exitCode=${missingResult.exitCode}`,
    missingResult.stdout.trim(),
    `- after Nix-managed Codex launcher: exitCode=${codexResult.exitCode}`,
    codexResult.stdout.trim(),
    `- Nix Codex launcher links ${path.dirname(expectedNativeCommandPath)} -> ${profileBinTarget}`,
    `- Codex command/exec through the app-server resolves ${expectedNativeCommandPath} from HOME=$CODEX_HOME/home`,
  ].join("\n"),
);
