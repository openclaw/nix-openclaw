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

# Ensure rolldown is found from workspace bins in offline/sandbox builds.
ensure_root_package_link() {
  pkg="$1"
  root_path="node_modules/$pkg"

  if [ -e "$root_path" ]; then
    return 0
  fi

  pkg_dir="$(find node_modules/.pnpm -path "*/node_modules/$pkg" -print | head -n 1)"
  if [ -z "$pkg_dir" ]; then
    return 0
  fi

  mkdir -p "$(dirname "$root_path")"
  ln -s "$pkg_dir" "$root_path"
}

ensure_root_bin_link() {
  bin_name="$1"
  target_rel="$2"
  bin_path="node_modules/.bin/$bin_name"

  mkdir -p "$(dirname "$bin_path")"
  rm -f "$bin_path"
  ln -s "$target_rel" "$bin_path"
}

ensure_root_package_link "tsdown"
ensure_root_package_link "tsx"
ensure_root_package_link "@typescript/native-preview"
ensure_root_bin_link "tsdown" "../tsdown/dist/run.mjs"
ensure_root_bin_link "tsx" "../tsx/dist/cli.mjs"
ensure_root_bin_link "tsgo" "../@typescript/native-preview/bin/tsgo.js"

log_step "patchShebangs node_modules/.bin (root links)" bash -e -c ". \"$STDENV_SETUP\"; patchShebangs node_modules/.bin"

if [ -d "node_modules/.bin" ]; then
  export PATH="$PWD/node_modules/.bin:$PATH"
fi
if [ -d "node_modules/.pnpm/node_modules/.bin" ]; then
  export PATH="$PWD/node_modules/.pnpm/node_modules/.bin:$PATH"
fi

# Break down `pnpm build` (upstream package.json) so we can profile it while
# still using upstream's asset hooks. v2026.5.7 has the older canvas-only helper;
# newer OpenClaw has the generic bundled-plugin asset runner.
if [ -f "scripts/bundled-plugin-assets.mjs" ]; then
  log_step "build: plugins:assets:build" node scripts/bundled-plugin-assets.mjs --phase build
else
  log_step "build: canvas:a2ui:bundle" node scripts/bundle-a2ui.mjs
fi
tsdown_node_options="${NODE_OPTIONS:-}"
case "$tsdown_node_options" in
  *--max-old-space-size*) ;;
  *) tsdown_node_options="${tsdown_node_options:+$tsdown_node_options }--max-old-space-size=${OPENCLAW_NIX_TSDOWN_MAX_OLD_SPACE_MB:-8192}" ;;
esac

tsdown_cli="node_modules/tsdown/dist/run.mjs"
if [ ! -f "$tsdown_cli" ]; then
  tsdown_cli="$(find node_modules -path '*/tsdown/dist/run.mjs' -type f | head -n 1)"
fi
if [ -z "${tsdown_cli:-}" ] || [ ! -f "$tsdown_cli" ]; then
  echo "tsdown CLI not found under ./node_modules" >&2
  exit 1
fi
tsc_cli="node_modules/typescript/bin/tsc"
if [ ! -f "$tsc_cli" ]; then
  tsc_cli="$(find node_modules -path '*/typescript/bin/tsc' -type f | head -n 1)"
fi
if [ -z "${tsc_cli:-}" ] || [ ! -f "$tsc_cli" ]; then
  echo "TypeScript CLI not found under ./node_modules" >&2
  exit 1
fi
log_step "build: tsdown" env NODE_OPTIONS="$tsdown_node_options" node "$tsdown_cli" --config-loader unrun --logLevel warn
log_step "build: runtime-postbuild" node scripts/runtime-postbuild.mjs
if [ -f "scripts/stage-bundled-plugin-runtime.mjs" ]; then
  log_step "build: stage bundled plugin runtime" node scripts/stage-bundled-plugin-runtime.mjs
fi
log_step "build: plugin-sdk dts" node "$tsc_cli" -p tsconfig.plugin-sdk.dts.json
log_step "build: write-plugin-sdk-entry-dts" node --import tsx scripts/write-plugin-sdk-entry-dts.ts
if [ -f "scripts/copy-plugin-sdk-root-alias.mjs" ]; then
  log_step "build: copy-plugin-sdk-root-alias" node scripts/copy-plugin-sdk-root-alias.mjs
fi
if [ -f "scripts/copy-bundled-plugin-metadata.mjs" ]; then
  log_step "build: copy-bundled-plugin-metadata" node scripts/copy-bundled-plugin-metadata.mjs
fi
if [ -f "scripts/bundled-plugin-assets.mjs" ]; then
  log_step "build: plugins:assets:copy" node scripts/bundled-plugin-assets.mjs --phase copy
else
  log_step "build: canvas-a2ui-copy" node --import tsx scripts/canvas-a2ui-copy.ts
fi
log_step "build: copy-hook-metadata" node --import tsx scripts/copy-hook-metadata.ts
log_step "build: write-build-info" node --import tsx scripts/write-build-info.ts
log_step "build: write-cli-compat" node --import tsx scripts/write-cli-compat.ts

vite_cli="ui/node_modules/vite/bin/vite.js"
if [ ! -f "$vite_cli" ]; then
  vite_cli="$(find ui/node_modules node_modules -path '*/vite/bin/vite.js' -type f | head -n 1)"
fi
if [ -z "${vite_cli:-}" ] || [ ! -f "$vite_cli" ]; then
  echo "Vite CLI not found under ./ui/node_modules or ./node_modules" >&2
  exit 1
fi
case "$vite_cli" in
  /*) vite_cli_abs="$vite_cli" ;;
  *) vite_cli_abs="$PWD/$vite_cli" ;;
esac
log_step "ui:build" bash -e -c 'cd ui; node "$1" build' _ "$vite_cli_abs"

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
