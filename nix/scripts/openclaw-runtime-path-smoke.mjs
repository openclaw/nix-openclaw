#!/usr/bin/env node
import process from "node:process";
import { spawn, spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import readline from "node:readline";

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`missing ${name}`);
  }
  return value;
}

const gatewayWrapper = requireEnv("OPENCLAW_GATEWAY_WRAPPER");
const codexGatewayWrapper = requireEnv("OPENCLAW_CODEX_GATEWAY_WRAPPER");
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
const codexPathPrepend = requireEnv("OPENCLAW_CODEX_RUNTIME_PATH_PREPEND")
  .split(":")
  .filter(Boolean);

if (!/^[A-Za-z0-9._-]+$/.test(expectedCommand)) {
  throw new Error(`unsafe smoke command name: ${expectedCommand}`);
}

if (!/^[A-Za-z0-9._-]+$/.test(codexExpectedCommand)) {
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

const wrapperVersion = spawnSync(shell, ["-x", gatewayWrapper, "--version"], {
  env: {
    ...process.env,
    PATH: basePath,
    SHELL: shell,
  },
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
  wrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=") ||
  wrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_BIN=")
) {
  throw new Error(`base gateway wrapper must not configure Codex app-server launch env: ${wrapperTrace}`);
}

if (!wrapperTrace.includes("exec ") || !wrapperTrace.includes("/bin/openclaw")) {
  throw new Error(`gateway wrapper did not exec packaged OpenClaw: ${wrapperTrace}`);
}

const codexWrapperVersion = spawnSync(shell, ["-x", codexGatewayWrapper, "--version"], {
  env: {
    ...process.env,
    PATH: basePath,
    SHELL: shell,
  },
  encoding: "utf8",
});

if (codexWrapperVersion.status !== 0 || !codexWrapperVersion.stdout.trim()) {
  throw new Error(
    `Codex gateway wrapper --version failed: ${codexWrapperVersion.stdout}${codexWrapperVersion.stderr}`,
  );
}

const codexWrapperTrace = codexWrapperVersion.stderr;
if (!codexWrapperTrace.includes(codexExpectedBinDir)) {
  throw new Error(`Codex gateway wrapper did not prepend ${codexExpectedBinDir}: ${codexWrapperTrace}`);
}

if (codexWrapperTrace.includes("OPENCLAW_CODEX_APP_SERVER_ARGS=")) {
  throw new Error(`Codex gateway wrapper must not configure app-server argv: ${codexWrapperTrace}`);
}

const codexAppServerLauncherMatch = codexWrapperTrace.match(
  /OPENCLAW_CODEX_APP_SERVER_BIN=("[^"]+"|'[^']+'|[^ \n]+)/,
);
if (!codexAppServerLauncherMatch) {
  throw new Error(`Codex gateway wrapper did not export OPENCLAW_CODEX_APP_SERVER_BIN: ${codexWrapperTrace}`);
}
const codexAppServerLauncher = codexAppServerLauncherMatch[1].replace(/^["']|["']$/g, "");

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
    request(method, params, timeoutMs = 15_000) {
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
  const codexHome = path.join(tempRoot, "agents", "main", "agent", "codex-home");
  const nativeHome = path.join(codexHome, "home");
  mkdirSync(codexHome, { recursive: true });
  const appServerCommand = options.command ?? process.execPath;
  const appServerArgs = options.args ?? [
    codexAppServerCommand,
    "app-server",
    "--listen",
    "stdio://",
  ];
  if (options.linkNativeProfile === true) {
    const profileDir = path.join(nativeHome, ".nix-profile");
    mkdirSync(profileDir, { recursive: true });
    symlinkSync(codexExpectedBinDir, path.join(profileDir, "bin"), "dir");
  }
  const child = spawn(appServerCommand, appServerArgs, {
    env: {
      ...process.env,
      CODEX_HOME: codexHome,
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
    return await fn(client, { codexHome, nativeHome });
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
  "without-native-home-profile",
  { pathValue: baseOnlyPath },
  async (client) =>
    commandExec(client, [
      shell,
      "-lc",
      [
        "set -u",
        "printf 'HOME=%s\\n' \"$HOME\"",
        "printf 'PATH=%s\\n' \"$PATH\"",
        `if command -v ${codexExpectedCommand}; then command -v ${codexExpectedCommand}; ${codexExpectedCommand} --version; else printf '${missingMarker}\\n'; exit 127; fi`,
      ].join("; "),
    ]),
);

if (missingResult.exitCode === 0 || !missingResult.stdout.includes(missingMarker)) {
  throw new Error(
    [
      `Codex app-server unexpectedly resolved ${codexExpectedCommand} without the native-home profile.`,
      `stdout: ${missingResult.stdout}`,
      `stderr: ${missingResult.stderr}`,
    ].join("\n"),
  );
}

let expectedNativeCommandPath = "";
const codexResult = await withCodexAppServer(
  "with-native-home-profile",
  {
    command: codexAppServerLauncher,
    args: ["app-server", "--listen", "stdio://"],
    pathValue: baseOnlyPath,
    linkNativeProfile: true,
  },
  async (client, homes) => {
    expectedNativeCommandPath = path.join(
      homes.nativeHome,
      ".nix-profile",
      "bin",
      codexExpectedCommand,
    );
    return commandExec(client, [
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
  throw new Error(`Codex app-server PATH did not include the native-home profile bin: ${codexLines[1]}`);
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

console.log(
  [
    "openclaw-runtime-path proof:",
    `- generated tools.exec.pathPrepend resolves ${expectedBinDir}/${expectedCommand}`,
    "- gateway wrapper prepends the same runtime tool path",
    "- runtimePackages alone do not configure the Codex app-server launcher",
    "- selecting the Nix-packaged Codex runtime plugin installs the native-home app-server launcher",
    `- native Codex app-server does not resolve ${codexExpectedCommand} with CODEX_HOME alone`,
    `- native Codex app-server resolves ${expectedNativeCommandPath} from HOME=$CODEX_HOME/home`,
  ].join("\n"),
);
