#!/usr/bin/env node
import process from "node:process";
import { spawnSync } from "node:child_process";

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`missing ${name}`);
  }
  return value;
}

const gatewayWrapper = requireEnv("OPENCLAW_GATEWAY_WRAPPER");
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
  throw new Error(`gateway wrapper must not configure Codex app-server launch argv: ${wrapperTrace}`);
}

if (!wrapperTrace.includes("exec ") || !wrapperTrace.includes("/bin/openclaw")) {
  throw new Error(`gateway wrapper did not exec packaged OpenClaw: ${wrapperTrace}`);
}

console.log(
  [
    "openclaw-runtime-path proof:",
    `- generated tools.exec.pathPrepend resolves ${expectedBinDir}/${expectedCommand}`,
    "- gateway wrapper prepends the same runtime tool path",
    "- runtimePackages do not configure Codex app-server launch argv",
  ].join("\n"),
);
