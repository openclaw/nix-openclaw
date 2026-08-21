#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import fs from "node:fs";

import { markdownTableCell as markdownCell } from "./markdown-table.mjs";

function usage() {
  process.stderr.write(`Usage:
  maintainers/scripts/summarize-nix-build-closure.mjs [--label <label>] [--limit <count>] [--summary-file <path>] <outputs-file>
`);
}

function parseArgs(argv) {
  const args = {
    label: "nix-build",
    limit: 12,
    summaryFile: process.env.GITHUB_STEP_SUMMARY || null,
    outputsFile: null,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--label") {
      args.label = requireValue(argv, ++i, arg);
    } else if (arg === "--limit") {
      args.limit = Number(requireValue(argv, ++i, arg));
      if (!Number.isInteger(args.limit) || args.limit < 1) {
        throw new Error("--limit must be a positive integer");
      }
    } else if (arg === "--summary-file") {
      args.summaryFile = requireValue(argv, ++i, arg);
    } else if (arg.startsWith("-")) {
      throw new Error(`Unknown option: ${arg}`);
    } else if (!args.outputsFile) {
      args.outputsFile = arg;
    } else {
      throw new Error(`Unexpected argument: ${arg}`);
    }
  }

  if (!args.outputsFile) {
    throw new Error("Missing outputs file");
  }
  return args;
}

function requireValue(argv, index, flag) {
  const value = argv[index];
  if (!value) {
    throw new Error(`Missing value for ${flag}`);
  }
  return value;
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    maxBuffer: 256 * 1024 * 1024,
    ...options,
  });
  if (result.status !== 0) {
    const stderr = result.stderr?.trim();
    throw new Error(`${command} ${args.join(" ")} failed${stderr ? `: ${stderr}` : ""}`);
  }
  return result.stdout;
}

function buildResultsFromFile(path) {
  const text = fs.readFileSync(path, "utf8");
  const trimmed = text.trim();
  if (!trimmed) {
    return { outputs: [], derivers: [] };
  }

  if (trimmed.startsWith("[") || trimmed.startsWith("{")) {
    return buildResultsFromJson(trimmed);
  }

  return {
    outputs: unique(
      text
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter((line) => /^\/nix\/store\/[0-9a-z]{32}-/.test(line)),
    ),
    derivers: [],
  };
}

function buildResultsFromJson(text) {
  const parsed = JSON.parse(text);
  const results = Array.isArray(parsed) ? parsed : [parsed];
  const outputs = [];
  const derivers = [];

  for (const result of results) {
    if (typeof result?.drvPath === "string" && result.drvPath.endsWith(".drv")) {
      derivers.push(result.drvPath);
    }
    if (result?.outputs && typeof result.outputs === "object") {
      for (const output of Object.values(result.outputs)) {
        if (typeof output === "string" && /^\/nix\/store\/[0-9a-z]{32}-/.test(output)) {
          outputs.push(output);
        }
      }
    }
  }

  return {
    outputs: unique(outputs),
    derivers: unique(derivers),
  };
}

function unique(values) {
  return [...new Set(values)];
}

function deriversFor(outputs) {
  const derivers = [];
  for (const output of outputs) {
    const stdout = run("nix-store", ["-q", "--deriver", output]).trim();
    if (stdout && stdout !== "unknown-deriver" && stdout.endsWith(".drv")) {
      derivers.push(stdout);
    }
  }
  return unique(derivers);
}

function buildClosurePaths(derivers) {
  const paths = [];
  for (const deriver of derivers) {
    const stdout = run("nix-store", ["-qR", "--include-outputs", deriver]);
    paths.push(
      ...stdout
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter((line) => line && !line.endsWith(".drv")),
    );
  }
  return unique(paths);
}

function pathInfo(paths) {
  if (paths.length === 0) {
    return [];
  }
  const stdout = run(
    "nix",
    ["path-info", "--json", "--json-format", "2", "--size", "--closure-size", "--stdin"],
    { input: `${paths.join("\n")}\n` },
  );
  const parsed = JSON.parse(stdout);
  const storeDir = parsed.storeDir || "/nix/store";
  const info = parsed.info || parsed;
  return Object.entries(info).map(([key, value]) => {
    const path = key.startsWith("/") ? key : `${storeDir}/${key}`;
    return {
      path,
      name: pathName(path),
      narSize: Number(value.narSize || 0),
      closureSize: Number(value.closureSize || 0),
    };
  });
}

function pathName(path) {
  return path.replace(/^.*\//, "").replace(/^[0-9a-z]{32}-/, "");
}

function render({ label, limit, outputs, derivers, closurePaths, entries }) {
  const totalNarSize = entries.reduce((sum, entry) => sum + entry.narSize, 0);
  const lines = [`### Nix Build Closure: ${label}`, ""];

  lines.push(
    `Build-closure paths: ${formatCount(closurePaths.length)}; derivers: ${formatCount(
      derivers.length,
    )}; outputs: ${formatCount(outputs.length)}; summed NAR size: ${formatBytes(totalNarSize)}.`,
  );
  lines.push("");
  lines.push("This is the build-input/output closure behind the metered derivation, not only the final output runtime closure.");

  lines.push("", "#### Top Paths By NAR Size", "");
  lines.push("| Path | NAR size | Closure size |", "| --- | ---: | ---: |");
  for (const entry of top(entries, "narSize", limit)) {
    lines.push(`| ${markdownCell(entry.name)} | ${formatBytes(entry.narSize)} | ${formatBytes(entry.closureSize)} |`);
  }

  lines.push("", "#### Top Paths By Closure Size", "");
  lines.push("| Path | NAR size | Closure size |", "| --- | ---: | ---: |");
  for (const entry of top(entries, "closureSize", limit)) {
    lines.push(`| ${markdownCell(entry.name)} | ${formatBytes(entry.narSize)} | ${formatBytes(entry.closureSize)} |`);
  }

  return `${lines.join("\n")}\n`;
}

function top(entries, field, limit) {
  return [...entries]
    .sort((left, right) => right[field] - left[field] || left.name.localeCompare(right.name))
    .slice(0, limit);
}

function formatBytes(bytes) {
  if (!Number.isFinite(bytes) || bytes <= 0) {
    return "0 B";
  }
  const units = ["B", "KiB", "MiB", "GiB", "TiB"];
  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return `${value >= 10 || unit === 0 ? value.toFixed(0) : value.toFixed(1)} ${units[unit]}`;
}

function formatCount(value) {
  return new Intl.NumberFormat("en-US").format(value);
}

try {
  const args = parseArgs(process.argv.slice(2));
  const captured = buildResultsFromFile(args.outputsFile);
  if (captured.outputs.length === 0 && captured.derivers.length === 0) {
    process.stdout.write(`### Nix Build Closure: ${args.label}\n\nNo output paths were captured.\n`);
    process.exit(0);
  }

  const derivers = unique([...captured.derivers, ...deriversFor(captured.outputs)]);
  const closurePaths = buildClosurePaths(derivers);
  const entries = pathInfo(closurePaths);
  const markdown = render({
    label: args.label,
    limit: args.limit,
    outputs: captured.outputs,
    derivers,
    closurePaths,
    entries,
  });

  process.stdout.write(markdown);
  if (args.summaryFile) {
    fs.appendFileSync(args.summaryFile, `\n${markdown}`);
  }
} catch (error) {
  usage();
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
}
