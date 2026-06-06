#!/usr/bin/env node
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { pathToFileURL } from "node:url";

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`missing ${name}`);
  }
  return value;
}

const gateway = requireEnv("OPENCLAW_GATEWAY");
const expectedBinDir = requireEnv("OPENCLAW_RUNTIME_EXPECTED_BIN_DIR");
const expectedCommand = requireEnv("OPENCLAW_RUNTIME_EXPECTED_COMMAND");
const expectedOutputPrefix = requireEnv("OPENCLAW_RUNTIME_EXPECTED_OUTPUT_PREFIX");
const basePath = requireEnv("OPENCLAW_RUNTIME_BASE_PATH");
const shell = requireEnv("OPENCLAW_RUNTIME_SHELL");
const pathPrepend = requireEnv("OPENCLAW_RUNTIME_PATH_PREPEND")
  .split(":")
  .filter(Boolean);

if (!/^[A-Za-z0-9._-]+$/.test(expectedCommand)) {
  throw new Error(`unsafe smoke command name: ${expectedCommand}`);
}

if (!pathPrepend.includes(expectedBinDir)) {
  throw new Error(`generated tools.exec.pathPrepend does not include ${expectedBinDir}`);
}

const distDir = path.join(gateway, "lib", "openclaw", "dist");
const runtimeFile = (await fs.readdir(distDir)).find((name) =>
  /^bash-tools\.exec-runtime-.*\.js$/.test(name),
);

if (!runtimeFile) {
  throw new Error(`could not find packaged bash-tools.exec-runtime in ${distDir}`);
}

const runtimeModule = await import(pathToFileURL(path.join(distDir, runtimeFile)).href);
const runExecProcess = Object.values(runtimeModule).find(
  (value) => typeof value === "function" && value.name === "runExecProcess",
);

if (typeof runExecProcess !== "function") {
  throw new Error(`could not find runExecProcess export in ${runtimeFile}`);
}

const root = await fs.mkdtemp(path.join(os.tmpdir(), "openclaw-runtime-path-"));
const stateDir = path.join(root, "state");
await fs.mkdir(stateDir, { recursive: true });

const run = await runExecProcess({
  command: `command -v ${expectedCommand} && ${expectedCommand}`,
  workdir: root,
  env: {
    HOME: root,
    OPENCLAW_EXEC_SHELL_SNAPSHOT: "0",
    OPENCLAW_STATE_DIR: stateDir,
    PATH: basePath,
    SHELL: shell,
  },
  pathPrepend,
  usePty: false,
  warnings: [],
  maxOutput: 10_000,
  pendingMaxOutput: 10_000,
  notifyOnExit: false,
  timeoutSec: 10,
});

const result = await run.promise;
const output = String(result.aggregated ?? "").trim();
const lines = output.split(/\r?\n/).filter(Boolean);

if (result.exitCode !== 0) {
  throw new Error(`${expectedCommand} smoke failed with exit ${result.exitCode}: ${output}`);
}

if (lines[0] !== `${expectedBinDir}/${expectedCommand}`) {
  throw new Error(
    `${expectedCommand} resolved to ${lines[0] ?? "(missing)"}, expected ${expectedBinDir}/${expectedCommand}`,
  );
}

if (!(lines[1] ?? "").startsWith(expectedOutputPrefix)) {
  throw new Error(`${expectedCommand} output missing from exec result: ${output}`);
}
