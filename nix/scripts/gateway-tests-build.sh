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

log_step "pnpm install (tests/config)" pnpm install --offline --frozen-lockfile --ignore-scripts --prod=false --store-dir "$store_path"

ensure_root_package_link() {
  pkg="$1"
  root_path="node_modules/$pkg"

  if [ -e "$root_path" ]; then
    return 0
  fi

  pkg_dir="$(find node_modules/.pnpm -path "*/node_modules/$pkg" -type d | head -n 1)"
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
ensure_root_package_link "vitest"
ensure_root_bin_link "tsdown" "../tsdown/dist/run.mjs"
ensure_root_bin_link "tsx" "../tsx/dist/cli.mjs"
ensure_root_bin_link "vitest" "../vitest/vitest.mjs"

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

if [ -z "${STDENV_SETUP:-}" ]; then
  echo "STDENV_SETUP is not set" >&2
  exit 1
fi
if [ ! -f "$STDENV_SETUP" ]; then
  echo "STDENV_SETUP not found: $STDENV_SETUP" >&2
  exit 1
fi

log_step "patchShebangs node_modules/.bin" bash -e -c ". \"$STDENV_SETUP\"; patchShebangs node_modules/.bin"

log_step "node $tsdown_cli" node "$tsdown_cli" --config-loader unrun --logLevel warn
log_step "node scripts/build-stamp.mjs" node scripts/build-stamp.mjs
log_step "node $tsc_cli" node "$tsc_cli" -p tsconfig.plugin-sdk.dts.json
log_step "node --import tsx scripts/write-plugin-sdk-entry-dts.ts" node --import tsx scripts/write-plugin-sdk-entry-dts.ts
if [ -f "scripts/copy-plugin-sdk-root-alias.mjs" ]; then
  log_step "node scripts/copy-plugin-sdk-root-alias.mjs" node scripts/copy-plugin-sdk-root-alias.mjs
fi
log_step "node scripts/check-plugin-sdk-exports.mjs" node scripts/check-plugin-sdk-exports.mjs
