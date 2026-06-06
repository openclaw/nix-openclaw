#!/usr/bin/env node
import fs from "node:fs";

function usage() {
  process.stderr.write(`Usage:
  scripts/summarize-nix-eval-jobs.mjs [--label <label>] [--limit <count>] [--summary-file <path>] <jsonl>
`);
}

function parseArgs(argv) {
  const args = {
    label: "nix-eval-jobs",
    limit: 16,
    summaryFile: process.env.GITHUB_STEP_SUMMARY || null,
    jsonlPath: null,
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
    } else if (!args.jsonlPath) {
      args.jsonlPath = arg;
    } else {
      throw new Error(`Unexpected argument: ${arg}`);
    }
  }

  if (!args.jsonlPath) {
    throw new Error("Missing JSONL path");
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

function parseJobs(text) {
  const jobs = [];
  const invalid = [];
  for (const [index, line] of text.split(/\r?\n/).entries()) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }
    try {
      const parsed = JSON.parse(trimmed);
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        jobs.push(normalizeJob(parsed));
      }
    } catch (error) {
      invalid.push({ line: index + 1, error: error.message });
    }
  }
  return { jobs, invalid };
}

function normalizeJob(job) {
  return {
    attr: attrName(job),
    cacheStatus: job.cacheStatus || "unknown",
    drvPath: typeof job.drvPath === "string" ? job.drvPath : null,
    system: typeof job.system === "string" ? job.system : "-",
    inputDrvCount: countKeys(job.inputDrvs),
    outputCount: countKeys(job.outputs),
    error: job.error || null,
  };
}

function attrName(job) {
  if (typeof job.attr === "string") {
    return job.attr;
  }
  if (Array.isArray(job.attrPath) && job.attrPath.length > 0) {
    return job.attrPath.join(".");
  }
  if (typeof job.name === "string") {
    return job.name;
  }
  return "(unknown)";
}

function countKeys(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return 0;
  }
  return Object.keys(value).length;
}

function summarize(jobs) {
  const byStatus = new Map();
  const bySystem = new Map();
  let inputDrvCount = 0;
  let outputCount = 0;

  for (const job of jobs) {
    byStatus.set(job.cacheStatus, (byStatus.get(job.cacheStatus) || 0) + 1);
    bySystem.set(job.system, (bySystem.get(job.system) || 0) + 1);
    inputDrvCount += job.inputDrvCount;
    outputCount += job.outputCount;
  }

  return { byStatus, bySystem, inputDrvCount, outputCount };
}

function render({ label, limit, jobs, invalid }) {
  const summary = summarize(jobs);
  const lines = [`### Nix Eval Jobs Cache: ${label}`, ""];

  lines.push(
    `Attrs: ${formatCount(jobs.length)}; direct input derivations: ${formatCount(
      summary.inputDrvCount,
    )}; outputs: ${formatCount(summary.outputCount)}.`,
  );
  lines.push("");
  lines.push(
    "`cacheStatus` is attr-level derivation status from `nix-eval-jobs --check-cache-status`: `local` means present in the current runner store, `cached` means present in a configured substituter, and `notBuilt` means the attr still needs a build on that runner.",
  );

  lines.push("", "#### Cache Status", "");
  lines.push("| Status | Attrs |", "| --- | ---: |");
  for (const [status, count] of sortedMap(summary.byStatus)) {
    lines.push(`| ${markdownCell(status)} | ${formatCount(count)} |`);
  }

  lines.push("", "#### Systems", "");
  lines.push("| System | Attrs |", "| --- | ---: |");
  for (const [system, count] of sortedMap(summary.bySystem)) {
    lines.push(`| ${markdownCell(system)} | ${formatCount(count)} |`);
  }

  lines.push("", "#### Top Attrs By Direct Input Drvs", "");
  lines.push("| Attr | Cache status | System | Direct input drvs | Outputs |", "| --- | --- | --- | ---: | ---: |");
  for (const job of topJobs(jobs, limit)) {
    lines.push(
      `| ${markdownCell(job.attr)} | ${markdownCell(job.cacheStatus)} | ${markdownCell(
        job.system,
      )} | ${formatCount(job.inputDrvCount)} | ${formatCount(job.outputCount)} |`,
    );
  }

  const failures = jobs.filter((job) => job.error);
  if (failures.length > 0) {
    lines.push("", "#### Evaluation Errors", "");
    lines.push("| Attr | Error |", "| --- | --- |");
    for (const job of failures.slice(0, limit)) {
      lines.push(`| ${markdownCell(job.attr)} | ${markdownCell(String(job.error))} |`);
    }
  }

  if (invalid.length > 0) {
    lines.push("", `Invalid JSONL lines ignored: ${formatCount(invalid.length)}.`);
  }

  return `${lines.join("\n")}\n`;
}

function sortedMap(map) {
  return [...map.entries()].sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]));
}

function topJobs(jobs, limit) {
  return [...jobs]
    .sort(
      (left, right) =>
        right.inputDrvCount - left.inputDrvCount ||
        right.outputCount - left.outputCount ||
        left.attr.localeCompare(right.attr),
    )
    .slice(0, limit);
}

function markdownCell(value) {
  return String(value).replace(/\|/g, "\\|").replace(/\r?\n/g, " ");
}

function formatCount(value) {
  return new Intl.NumberFormat("en-US").format(value);
}

try {
  const args = parseArgs(process.argv.slice(2));
  const text = fs.readFileSync(args.jsonlPath, "utf8");
  const parsed = parseJobs(text);
  const markdown = render({ label: args.label, limit: args.limit, ...parsed });

  process.stdout.write(markdown);
  if (args.summaryFile) {
    fs.appendFileSync(args.summaryFile, `\n${markdown}`);
  }
} catch (error) {
  usage();
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
}
