#!/bin/sh
set -e

if [ -z "${GATEWAY_PREBUILD_SH:-}" ]; then
  echo "GATEWAY_PREBUILD_SH is not set" >&2
  exit 1
fi
. "$GATEWAY_PREBUILD_SH"
if [ -z "${STDENV_SETUP:-}" ]; then
  echo "STDENV_SETUP is not set" >&2
  exit 1
fi
if [ ! -f "$STDENV_SETUP" ]; then
  echo "STDENV_SETUP not found: $STDENV_SETUP" >&2
  exit 1
fi

. "$PNPM_BUILD_ENV_SH"
if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
  OPENCLAW_BUILD_TIMESTAMP="$(node -p 'new Date(Number(process.env.SOURCE_DATE_EPOCH) * 1000).toISOString()')"
  export OPENCLAW_BUILD_TIMESTAMP
fi
HOME="$(mktemp -d)"
export HOME

log_step "pnpm install (offline, frozen, ignore-scripts)" env CI=true pnpm install --offline --frozen-lockfile --ignore-scripts --store-dir "$store_path"

log_step "chmod node_modules writable" chmod -R u+w node_modules

# sharp may leave build artifacts around; remove to keep output smaller + avoid stale builds.
rm -rf node_modules/.pnpm/sharp@*/node_modules/sharp/src/build

# Rebuild the package closure, excluding unrelated extension workspaces.
# node-llama-cpp postinstall attempts to download/compile llama.cpp (network blocked in Nix).
# Also defensively disable other common downloaders.
package_name="$(jq -er '.name // empty' package.json)"
rebuild_list="$(jq -r '.pnpm.onlyBuiltDependencies // [] | .[]' package.json 2>/dev/null || true)"
if [ -z "$rebuild_list" ]; then
  allow_builds_json="$(pnpm config get --json allowBuilds 2>/dev/null || true)"
  if [ -n "$allow_builds_json" ] && [ "$allow_builds_json" != "null" ]; then
    rebuild_list="$(printf '%s' "$allow_builds_json" | jq -r 'to_entries[] | select(.value == true) | .key' 2>/dev/null || true)"
  fi
fi
if [ -n "$rebuild_list" ]; then
  log_step "pnpm rebuild (onlyBuiltDependencies)" env \
    NODE_LLAMA_CPP_SKIP_DOWNLOAD=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PUPPETEER_SKIP_DOWNLOAD=1 \
    ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    pnpm --include-workspace-root --filter "$package_name..." rebuild $rebuild_list
else
  log_step "pnpm rebuild (all)" env \
    NODE_LLAMA_CPP_SKIP_DOWNLOAD=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PUPPETEER_SKIP_DOWNLOAD=1 \
    ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    pnpm --include-workspace-root --filter "$package_name..." rebuild
fi

log_step "patchShebangs node_modules/.bin" bash -e -c ". \"$STDENV_SETUP\"; patchShebangs node_modules/.bin"

# Git tarball dependencies do not get their npm prepack output in offline Nix
# builds. OpenClaw currently depends on @openclaw/fs-safe this way.
if [ -n "${OPENCLAW_FS_SAFE_SOURCE:-}" ] && [ ! -d "node_modules/@openclaw/fs-safe/dist" ]; then
  rm -rf node_modules/@openclaw/fs-safe
  mkdir -p node_modules/@openclaw
  cp -R "$OPENCLAW_FS_SAFE_SOURCE" node_modules/@openclaw/fs-safe
  chmod -R u+w node_modules/@openclaw/fs-safe
  log_step "build dependency: @openclaw/fs-safe" pnpm exec tsc -p node_modules/@openclaw/fs-safe/tsconfig.json
fi

# Upstream owns compiler partitioning, runtime staging, SDK declarations and UI assets.
if [ -n "${OPENCLAW_NIX_TSC_MAX_OLD_SPACE_MB:-}" ]; then
  echo "OPENCLAW_NIX_TSC_MAX_OLD_SPACE_MB is retired: upstream no longer has a separate tsc build stage. Use upstream build controls or NODE_OPTIONS." >&2
  exit 1
fi
if [ -n "${OPENCLAW_NIX_TSDOWN_MAX_OLD_SPACE_MB:-}" ]; then
  export OPENCLAW_TSDOWN_MAX_OLD_SPACE_MB="$OPENCLAW_NIX_TSDOWN_MAX_OLD_SPACE_MB"
fi

if [ -n "$(jq -r '.scripts["build:package"] // empty' package.json)" ]; then
  log_step "build:package" pnpm run build:package
else
  # Older source overrides expose build and ui:build as separate public scripts.
  log_step "build" pnpm run build
  log_step "ui:build" pnpm run ui:build
fi
