#!/usr/bin/env node
import fs from "node:fs";

function usage() {
  process.stderr.write(`Usage:
  scripts/summarize-nix-build-log.mjs [--label <label>] [--seconds <seconds>] [--summary-file <path>] <log>
  scripts/summarize-nix-build-log.mjs --github-log <log>
`);
}

function parseArgs(argv) {
  const args = {
    githubLog: false,
    label: "nix-build",
    seconds: null,
    summaryFile: process.env.GITHUB_STEP_SUMMARY || null,
    logPath: null,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--github-log") {
      args.githubLog = true;
    } else if (arg === "--label") {
      args.label = requireValue(argv, ++i, arg);
    } else if (arg === "--seconds") {
      args.seconds = Number(requireValue(argv, ++i, arg));
      if (!Number.isFinite(args.seconds) || args.seconds < 0) {
        throw new Error("--seconds must be a non-negative number");
      }
    } else if (arg === "--summary-file") {
      args.summaryFile = requireValue(argv, ++i, arg);
    } else if (arg.startsWith("-")) {
      throw new Error(`Unknown option: ${arg}`);
    } else if (!args.logPath) {
      args.logPath = arg;
    } else {
      throw new Error(`Unexpected argument: ${arg}`);
    }
  }

  if (!args.logPath) {
    throw new Error("Missing log path");
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

function emptyGroup(label) {
  return {
    label,
    firstTimestamp: null,
    lastTimestamp: null,
    elapsedSeconds: null,
    buildPlanCount: 0,
    fetchPlanCount: 0,
    fetchDownloadBytes: 0,
    fetchUnpackedBytes: 0,
    copiedPathLines: 0,
    copiedPaths: new Set(),
    copySources: new Map(),
    copiedNamesBySource: new Map(),
    builtDrvLines: 0,
    builtDrvs: new Set(),
    builtNames: new Map(),
    unpackedInputs: 0,
    warningCount: 0,
    firstSignalTimestamp: null,
    firstFetchPlanTimestamp: null,
    firstBuildPlanTimestamp: null,
    firstCopyTimestamp: null,
    lastCopyTimestamp: null,
    firstBuildTimestamp: null,
    lastBuildTimestamp: null,
    firstInputFetchTimestamp: null,
    evalStatsSection: null,
    evalStats: {
      cpuSeconds: null,
      gcFraction: null,
      waitingSeconds: null,
      expressions: null,
      thunks: null,
      functionCalls: null,
      primOpCalls: null,
      values: null,
      sets: null,
      envs: null,
      lists: null,
      symbols: null,
    },
    internalJson: {
      events: 0,
      starts: 0,
      stops: 0,
      results: 0,
      active: new Map(),
      completed: [],
      startTypes: new Map(),
    },
  };
}

function recordLine(group, rawLine) {
  const { timestamp, message } = splitTimestamp(rawLine);
  if (timestamp) {
    group.firstTimestamp ||= timestamp;
    group.lastTimestamp = timestamp;
  }

  const nixEvent = parseNixJsonEvent(message);
  if (nixEvent) {
    recordNixJsonEvent(group, timestamp, nixEvent);
  }

  const line = nixEvent ? nixEventText(nixEvent, message) : message;
  const plainLine = stripAnsi(line);
  recordEvalStats(group, plainLine);

  const fetchPlan = plainLine.match(
    /these ([0-9]+) paths will be fetched \(([^,]+) download, ([^)]+) unpacked\)/,
  );
  if (fetchPlan) {
    markSignal(group, timestamp);
    group.firstFetchPlanTimestamp ||= timestamp;
    group.fetchPlanCount += Number(fetchPlan[1]);
    group.fetchDownloadBytes += parseSize(fetchPlan[2]);
    group.fetchUnpackedBytes += parseSize(fetchPlan[3]);
  }

  if (/^this derivation will be built:/.test(plainLine)) {
    markSignal(group, timestamp);
    group.firstBuildPlanTimestamp ||= timestamp;
    group.buildPlanCount += 1;
  }
  const buildPlan = plainLine.match(/^these ([0-9]+) derivations will be built:/);
  if (buildPlan) {
    markSignal(group, timestamp);
    group.firstBuildPlanTimestamp ||= timestamp;
    group.buildPlanCount += Number(buildPlan[1]);
  }

  const copied = plainLine.match(/copying path '([^']+)' from '([^']+)'/);
  if (copied) {
    markSignal(group, timestamp);
    group.firstCopyTimestamp ||= timestamp;
    group.lastCopyTimestamp = timestamp || group.lastCopyTimestamp;
    group.copiedPathLines += 1;
    group.copiedPaths.add(copied[1]);
    group.copySources.set(copied[2], (group.copySources.get(copied[2]) || 0) + 1);
    incrementNestedCount(group.copiedNamesBySource, copied[2], storePathName(copied[1]));
  }

  const built = plainLine.match(/building '([^']+\.drv)'/);
  if (built) {
    markSignal(group, timestamp);
    group.firstBuildTimestamp ||= timestamp;
    group.lastBuildTimestamp = timestamp || group.lastBuildTimestamp;
    group.builtDrvLines += 1;
    group.builtDrvs.add(built[1]);
    const name = drvName(built[1]);
    group.builtNames.set(name, (group.builtNames.get(name) || 0) + 1);
  }

  if (/unpacking ['"][^'"]+['"] into the Git cache/.test(plainLine)) {
    markSignal(group, timestamp);
    group.firstInputFetchTimestamp ||= timestamp;
    group.unpackedInputs += 1;
  }

  if (/\bwarning:/.test(plainLine)) {
    markSignal(group, timestamp);
    group.warningCount += 1;
  }
}

function stripAnsi(value) {
  return value.replace(/\x1B\[[0-9;]*m/g, "");
}

function parseNixJsonEvent(line) {
  if (!line.startsWith("@nix ")) {
    return null;
  }

  try {
    return JSON.parse(line.slice(5));
  } catch {
    return null;
  }
}

function nixEventText(event, fallback) {
  return event.text || event.msg || fallback;
}

function recordNixJsonEvent(group, timestamp, event) {
  group.internalJson.events += 1;

  if (event.action === "start") {
    group.internalJson.starts += 1;
    const type = nixActivityTypeName(event.type);
    group.internalJson.startTypes.set(
      type,
      (group.internalJson.startTypes.get(type) || 0) + 1,
    );
    group.internalJson.active.set(event.id, {
      id: event.id,
      type,
      text: event.text || type,
      fields: Array.isArray(event.fields) ? event.fields : [],
      startedAt: timestamp,
      lastPhase: null,
    });
    return;
  }

  if (event.action === "stop") {
    group.internalJson.stops += 1;
    const active = group.internalJson.active.get(event.id);
    if (active) {
      active.stoppedAt = timestamp;
      active.durationSeconds = durationSeconds(active.startedAt, timestamp);
      group.internalJson.completed.push(active);
      group.internalJson.active.delete(event.id);
    }
    return;
  }

  if (event.action === "result") {
    group.internalJson.results += 1;
    const active = group.internalJson.active.get(event.id);
    if (active && event.type === 104 && Array.isArray(event.fields)) {
      active.lastPhase = String(event.fields[0] || "");
    }
  }
}

function nixActivityTypeName(type) {
  const names = {
    0: "Unknown",
    100: "CopyPath",
    101: "FileTransfer",
    102: "Realise",
    103: "CopyPaths",
    104: "Builds",
    105: "Build",
    106: "OptimiseStore",
    107: "VerifyPaths",
    108: "Substitute",
    109: "QueryPathInfo",
    110: "PostBuildHook",
    111: "BuildWaiting",
    112: "FetchTree",
  };
  return names[type] || `Activity${type}`;
}

function durationSeconds(start, end) {
  if (!start || !end) {
    return null;
  }
  const seconds = (Date.parse(end) - Date.parse(start)) / 1000;
  return Number.isFinite(seconds) && seconds >= 0 ? seconds : null;
}

function markSignal(group, timestamp) {
  if (timestamp) {
    group.firstSignalTimestamp ||= timestamp;
  }
}

function recordEvalStats(group, line) {
  const section = line.match(/^\s*"([^"]+)":\s*\{\s*,?$/);
  if (section) {
    group.evalStatsSection = section[1];
    return;
  }
  if (/^\s*}\s*,?\s*$/.test(line)) {
    group.evalStatsSection = null;
    return;
  }

  const topLevelStats = {
    cpuTime: "cpuSeconds",
    nrExprs: "expressions",
    nrFunctionCalls: "functionCalls",
    nrPrimOpCalls: "primOpCalls",
    nrThunks: "thunks",
    waitingTime: "waitingSeconds",
  };
  for (const [key, field] of Object.entries(topLevelStats)) {
    const value = matchJsonNumber(line, key);
    if (value !== null) {
      group.evalStats[field] = value;
    }
  }

  if (group.evalStatsSection === "time") {
    const gcFraction = matchJsonNumber(line, "gcFraction");
    if (gcFraction !== null) {
      group.evalStats.gcFraction = gcFraction;
    }
  }

  const sectionCounts = {
    values: "values",
    sets: "sets",
    envs: "envs",
    list: "lists",
    symbols: "symbols",
  };
  const sectionField = sectionCounts[group.evalStatsSection];
  if (sectionField) {
    const count = matchJsonNumber(line, "number");
    if (count !== null) {
      group.evalStats[sectionField] = count;
    }
  }
}

function matchJsonNumber(line, key) {
  const pattern = new RegExp(`^\\s*"${escapeRegExp(key)}":\\s*([0-9]+(?:\\.[0-9]+)?)\\s*,?\\s*$`);
  const match = line.match(pattern);
  return match ? Number(match[1]) : null;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function splitTimestamp(line) {
  const match = line.match(/^(20[0-9]{2}-[0-9]{2}-[0-9]{2}T[^ ]+Z) (.*)$/);
  if (!match) {
    return { timestamp: null, message: line };
  }
  return { timestamp: match[1], message: match[2] };
}

function parseSize(value) {
  const match = value.trim().match(/^([0-9]+(?:\.[0-9]+)?)\s*([KMGT]i?B|B)$/i);
  if (!match) {
    return 0;
  }

  const unit = match[2].toLowerCase();
  const multipliers = {
    b: 1,
    kb: 1000,
    mb: 1000 ** 2,
    gb: 1000 ** 3,
    tb: 1000 ** 4,
    kib: 1024,
    mib: 1024 ** 2,
    gib: 1024 ** 3,
    tib: 1024 ** 4,
  };
  return Number(match[1]) * (multipliers[unit] || 0);
}

function drvName(path) {
  return path
    .replace(/^.*\//, "")
    .replace(/\.drv$/, "")
    .replace(/^[0-9a-z]{32}-/, "");
}

function storePathName(path) {
  return path.replace(/^.*\//, "").replace(/^[0-9a-z]{32}-/, "");
}

function incrementNestedCount(map, outerKey, innerKey) {
  if (!map.has(outerKey)) {
    map.set(outerKey, new Map());
  }
  const inner = map.get(outerKey);
  inner.set(innerKey, (inner.get(innerKey) || 0) + 1);
}

function parseRawLog(label, seconds, text) {
  const group = emptyGroup(label);
  group.elapsedSeconds = seconds;
  for (const line of text.split(/\r?\n/)) {
    recordLine(group, line);
  }
  return [group];
}

function parseGithubLog(text) {
  const groups = new Map();
  for (const line of text.split(/\r?\n/)) {
    const parts = line.split("\t");
    if (parts.length < 3) {
      continue;
    }
    const [job, step, ...rest] = parts;
    const key = `${job}\t${step}`;
    if (!groups.has(key)) {
      groups.set(key, emptyGroup(`${job} / ${step}`));
    }
    recordLine(groups.get(key), rest.join("\t"));
  }
  return [...groups.values()].filter(hasSignal);
}

function hasSignal(group) {
  return (
    group.fetchPlanCount > 0 ||
    group.copiedPathLines > 0 ||
    group.builtDrvLines > 0 ||
    group.unpackedInputs > 0 ||
    group.warningCount > 0 ||
    group.internalJson.events > 0
  );
}

function finishGroup(group) {
  if (group.elapsedSeconds === null && group.firstTimestamp && group.lastTimestamp) {
    group.elapsedSeconds =
      (Date.parse(group.lastTimestamp) - Date.parse(group.firstTimestamp)) / 1000;
  }
  return group;
}

function render(groups, title) {
  const finished = groups.map(finishGroup);
  const lines = [`### ${title}`, ""];

  lines.push(
    "| Step | Seconds | Fetch plan | Planned builds | Copied paths | Built drvs | Input fetches | Warnings |",
    "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
  );
  for (const group of finished) {
    lines.push(
      [
        markdownCell(group.label),
        formatSeconds(group.elapsedSeconds),
        formatFetchPlan(group),
        group.buildPlanCount === 0 ? "-" : String(group.buildPlanCount),
        `${group.copiedPaths.size} unique / ${group.copiedPathLines} lines`,
        `${group.builtDrvs.size} unique / ${group.builtDrvLines} lines`,
        String(group.unpackedInputs),
        String(group.warningCount),
      ].join(" | ").replace(/^/, "| ").replace(/$/, " |"),
    );
  }

  const details = finished.filter(
    (group) =>
      group.builtNames.size > 0 ||
      group.copySources.size > 0 ||
      hasPhaseHints(group) ||
      hasEvalStats(group) ||
      hasNixJsonActivity(group),
  );
  for (const group of details) {
    lines.push("", `#### ${group.label}`, "");
    if (hasPhaseHints(group)) {
      lines.push(`Phase hints: ${formatPhaseHints(group)}`);
    }
    if (hasEvalStats(group)) {
      lines.push(`Eval stats: ${formatEvalStats(group.evalStats)}`);
    }
    if (hasNixJsonActivity(group)) {
      lines.push(`Structured Nix events: ${formatNixJsonActivity(group)}`);
    }
    if (group.copySources.size > 0) {
      lines.push(`Copy sources: ${formatTopMap(group.copySources, 4)}`);
      for (const sourceLine of formatCustomCopySourceNames(group.copiedNamesBySource)) {
        lines.push(sourceLine);
      }
    }
    if (group.builtNames.size > 0) {
      lines.push(`Built derivations: ${formatTopMap(group.builtNames, 20)}`);
    }
  }

  return `${lines.join("\n")}\n`;
}

function markdownCell(value) {
  return value.replace(/\|/g, "\\|");
}

function formatSeconds(seconds) {
  if (seconds === null || !Number.isFinite(seconds)) {
    return "-";
  }
  return seconds.toFixed(seconds >= 10 ? 0 : 2);
}

function formatFetchPlan(group) {
  if (group.fetchPlanCount === 0) {
    return "-";
  }
  return `${group.fetchPlanCount} paths, ${formatBytes(group.fetchDownloadBytes)} download, ${formatBytes(
    group.fetchUnpackedBytes,
  )} unpacked`;
}

function formatBytes(bytes) {
  if (!Number.isFinite(bytes) || bytes <= 0) {
    return "unknown";
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

function formatTopMap(map, limit) {
  const entries = [...map.entries()].sort((left, right) => {
    return right[1] - left[1] || left[0].localeCompare(right[0]);
  });
  const shown = entries.slice(0, limit).map(([name, count]) => `${name} (${count})`);
  const hidden = entries.length - shown.length;
  if (hidden > 0) {
    shown.push(`and ${hidden} more`);
  }
  return shown.join(", ");
}

function formatCustomCopySourceNames(copiedNamesBySource) {
  return [...copiedNamesBySource.entries()]
    .filter(([source]) => isCustomCopySource(source))
    .sort((left, right) => left[0].localeCompare(right[0]))
    .map(([source, names]) => `Copied from ${source}: ${formatTopMap(names, 50)}`);
}

function isCustomCopySource(source) {
  return ![
    "https://cache.nixos.org",
    "https://install.determinate.systems",
  ].includes(source);
}

function hasPhaseHints(group) {
  return Boolean(
    group.firstTimestamp &&
      (group.firstInputFetchTimestamp ||
        group.firstFetchPlanTimestamp ||
        group.firstBuildPlanTimestamp ||
        group.firstCopyTimestamp ||
        group.firstBuildTimestamp),
  );
}

function formatPhaseHints(group) {
  const base = group.firstTimestamp;
  const hints = [];
  pushOffset(hints, "input fetch", base, group.firstInputFetchTimestamp);
  pushOffset(hints, "fetch plan", base, group.firstFetchPlanTimestamp);
  pushOffset(hints, "build plan", base, group.firstBuildPlanTimestamp);
  pushWindow(hints, "copy", base, group.firstCopyTimestamp, group.lastCopyTimestamp);
  pushWindow(hints, "build", base, group.firstBuildTimestamp, group.lastBuildTimestamp);
  return hints.join(", ");
}

function pushOffset(hints, label, base, timestamp) {
  if (timestamp) {
    hints.push(`${label} +${formatOffset(base, timestamp)}`);
  }
}

function pushWindow(hints, label, base, start, end) {
  if (!start) {
    return;
  }
  const startOffset = formatOffset(base, start);
  if (!end || end === start) {
    hints.push(`${label} +${startOffset}`);
    return;
  }
  hints.push(`${label} +${startOffset}..+${formatOffset(base, end)}`);
}

function formatOffset(base, timestamp) {
  const seconds = (Date.parse(timestamp) - Date.parse(base)) / 1000;
  if (!Number.isFinite(seconds) || seconds < 0) {
    return "?s";
  }
  return formatSeconds(seconds);
}

function hasEvalStats(group) {
  return Object.values(group.evalStats).some((value) => value !== null);
}

function formatEvalStats(stats) {
  const fields = [];
  if (stats.cpuSeconds !== null) {
    fields.push(`cpu ${formatSeconds(stats.cpuSeconds)}s`);
  }
  if (stats.gcFraction !== null) {
    fields.push(`gc ${(stats.gcFraction * 100).toFixed(1)}%`);
  }
  if (stats.thunks !== null) {
    fields.push(`thunks ${formatCount(stats.thunks)}`);
  }
  if (stats.values !== null) {
    fields.push(`values ${formatCount(stats.values)}`);
  }
  if (stats.functionCalls !== null) {
    fields.push(`calls ${formatCount(stats.functionCalls)}`);
  }
  if (stats.primOpCalls !== null) {
    fields.push(`primops ${formatCount(stats.primOpCalls)}`);
  }
  if (stats.waitingSeconds !== null) {
    fields.push(`waiting ${formatSeconds(stats.waitingSeconds)}s`);
  }
  return fields.join(", ");
}

function formatCount(value) {
  return new Intl.NumberFormat("en-US").format(value);
}

function hasNixJsonActivity(group) {
  return group.internalJson.events > 0;
}

function formatNixJsonActivity(group) {
  const parts = [
    `${formatCount(group.internalJson.events)} events`,
    `${formatCount(group.internalJson.starts)} starts`,
    `${formatCount(group.internalJson.stops)} stops`,
    `${formatCount(group.internalJson.results)} results`,
  ];
  if (group.internalJson.startTypes.size > 0) {
    parts.push(`start types ${formatTopMap(group.internalJson.startTypes, 6)}`);
  }

  const timed = group.internalJson.completed
    .filter((activity) => activity.durationSeconds !== null)
    .sort((left, right) => {
      return right.durationSeconds - left.durationSeconds || left.text.localeCompare(right.text);
    })
    .slice(0, 6);
  if (timed.length > 0) {
    parts.push(`top spans ${timed.map(formatNixJsonSpan).join("; ")}`);
  } else if (group.internalJson.completed.length > 0) {
    parts.push("top spans unavailable without timestamped internal-json lines");
  }

  return parts.join(", ");
}

function formatNixJsonSpan(activity) {
  const phase = activity.lastPhase ? `, last phase ${activity.lastPhase}` : "";
  const label =
    activity.text === activity.type
      ? activity.type
      : `${activity.type} ${shorten(activity.text, 110)}`;
  return `${label} (${formatSeconds(activity.durationSeconds)}s${phase})`;
}

function shorten(value, limit) {
  if (value.length <= limit) {
    return value;
  }
  return `${value.slice(0, limit - 3)}...`;
}

try {
  const args = parseArgs(process.argv.slice(2));
  const text = fs.readFileSync(args.logPath, "utf8");
  const groups = args.githubLog
    ? parseGithubLog(text)
    : parseRawLog(args.label, args.seconds, text);
  const markdown = render(
    groups,
    args.githubLog ? "Nix CI Log Summary" : `Nix Build Meter: ${args.label}`,
  );

  process.stdout.write(markdown);
  if (args.summaryFile) {
    fs.appendFileSync(args.summaryFile, `\n${markdown}`);
  }
} catch (error) {
  usage();
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
}
