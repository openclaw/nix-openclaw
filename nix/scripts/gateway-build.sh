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

log_step "pnpm install (offline, frozen, ignore-scripts)" pnpm install --offline --frozen-lockfile --ignore-scripts --store-dir "$store_path"

log_step "chmod node_modules writable" chmod -R u+w node_modules

# sharp may leave build artifacts around; remove to keep output smaller + avoid stale builds.
rm -rf node_modules/.pnpm/sharp@*/node_modules/sharp/src/build

# Rebuild only native deps (avoid `pnpm rebuild` over the entire workspace).
# node-llama-cpp postinstall attempts to download/compile llama.cpp (network blocked in Nix).
# Also defensively disable other common downloaders.
rebuild_list="$(jq -r '.pnpm.onlyBuiltDependencies // [] | .[]' package.json 2>/dev/null || true)"
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

# Ensure rolldown is found from workspace bins in offline/sandbox builds.
if [ -d "node_modules/.pnpm/node_modules/.bin" ]; then
  export PATH="$PWD/node_modules/.pnpm/node_modules/.bin:$PATH"
fi

# Break down `pnpm build` (upstream package.json) so we can profile it.
# Upstream's bundle-a2ui script shells back out through pnpm-runner.
# In Nix builds that nested spawn can fail silently, so run the same steps directly.
log_step "build: canvas:a2ui:tsc" pnpm exec tsc -p vendor/a2ui/renderers/lit/tsconfig.json
log_step "build: canvas:a2ui:rolldown" node node_modules/rolldown/bin/cli.mjs -c apps/shared/OpenClawKit/Tools/CanvasA2UI/rolldown.config.mjs
log_step "build: tsdown" pnpm exec tsdown
log_step "build: plugin-sdk dts" pnpm build:plugin-sdk:dts
log_step "build: write-plugin-sdk-entry-dts" node --import tsx scripts/write-plugin-sdk-entry-dts.ts
if [ -f "scripts/copy-plugin-sdk-root-alias.mjs" ]; then
  log_step "build: copy-plugin-sdk-root-alias" node scripts/copy-plugin-sdk-root-alias.mjs
fi
if [ -f "scripts/copy-bundled-plugin-metadata.mjs" ]; then
  log_step "build: copy-bundled-plugin-metadata" node scripts/copy-bundled-plugin-metadata.mjs
fi
log_step "build: canvas-a2ui-copy" node --import tsx scripts/canvas-a2ui-copy.ts
log_step "build: copy-hook-metadata" node --import tsx scripts/copy-hook-metadata.ts
log_step "build: write-build-info" node --import tsx scripts/write-build-info.ts
log_step "build: write-cli-compat" node --import tsx scripts/write-cli-compat.ts

log_step "ui:build" pnpm ui:build

log_step "pnpm prune --prod" env CI=true pnpm prune --prod

# Reduce output size (pnpm implementation detail; safe to remove)
rm -rf node_modules/.pnpm/node_modules

# pnpm prune can leave orphaned .bin links behind for removed prod deps.
# Keep install-phase symlink validation strict by dropping only broken links here.
find node_modules -xtype l -delete
