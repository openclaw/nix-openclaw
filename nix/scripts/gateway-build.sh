#!/bin/sh
set -e

log_step() {
  if [ "${OPENCLAW_NIX_TIMINGS:-1}" != "1" ]; then
    "$@"
    return
  fi

  name="$1"
  shift

  start=$(date +%s)
  printf '>> [timing] %s...\n' "$name" >&2
  "$@"
  end=$(date +%s)
  printf '>> [timing] %s: %ss\n' "$name" "$((end - start))" >&2
}

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

store_path_file="${PNPM_STORE_PATH_FILE:-.pnpm-store-path}"
if [ ! -f "$store_path_file" ]; then
  echo "pnpm store path file missing: $store_path_file" >&2
  exit 1
fi
store_path="$(cat "$store_path_file")"
export PNPM_STORE_DIR="$store_path"
export PNPM_STORE_PATH="$store_path"
export NPM_CONFIG_STORE_DIR="$store_path"
export NPM_CONFIG_STORE_PATH="$store_path"
export HOME="$(mktemp -d)"

log_step "pnpm install (offline, frozen, ignore-scripts)" env CI=true pnpm install --offline --frozen-lockfile --ignore-scripts --store-dir "$store_path"

log_step "chmod node_modules writable" chmod -R u+w node_modules

# sharp may leave build artifacts around; remove to keep output smaller + avoid stale builds.
rm -rf node_modules/.pnpm/sharp@*/node_modules/sharp/src/build

# Rebuild only native deps (avoid `pnpm rebuild` over the entire workspace).
# node-llama-cpp postinstall attempts to download/compile llama.cpp (network blocked in Nix).
# Also defensively disable other common downloaders.
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
    pnpm rebuild $rebuild_list
else
  log_step "pnpm rebuild (all)" env \
    NODE_LLAMA_CPP_SKIP_DOWNLOAD=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PUPPETEER_SKIP_DOWNLOAD=1 \
    ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    pnpm rebuild
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

# Upstream owns artifact ordering, declarations, Control UI and compiler budgets.
# A package build must not inherit the runtime-only profile used by source updates.
log_step "build: package" env OPENCLAW_RUN_NODE_SKIP_DTS_BUILD=0 pnpm build

log_step "pnpm prune --prod" env \
  CI=true \
  PNPM_CONFIG_OFFLINE=true \
  PNPM_CONFIG_STORE_DIR="$store_path" \
  NPM_CONFIG_STORE_DIR="$store_path" \
  pnpm prune --prod

# Reduce output size (pnpm implementation detail; safe to remove)
rm -rf node_modules/.pnpm/node_modules

# pnpm prune can leave orphaned .bin links behind for removed prod deps.
# Keep install-phase symlink validation strict by dropping only broken links here.
find node_modules -xtype l -delete
