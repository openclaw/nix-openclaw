#!/usr/bin/env node
"use strict";

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const args = process.argv.slice(2);

function run(command, commandArgs, env = process.env) {
  const result = spawnSync(command, commandArgs, {
    env,
    stdio: "inherit",
  });
  if (result.error) {
    console.error(result.error.message);
    process.exit(254);
  }
  process.exit(result.status ?? 0);
}

if (args[0] === "exec" && args[1] && !args[1].startsWith("-")) {
  const bin = path.join(process.cwd(), "node_modules", ".bin", args[1]);
  if (fs.existsSync(bin)) {
    run(bin, args.slice(2));
  }
}

const realPnpm = process.env.OPENCLAW_REAL_PNPM || "pnpm";
const env = { ...process.env };
delete env.npm_execpath;
run(realPnpm, args, env);
