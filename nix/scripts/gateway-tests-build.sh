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

log_step "pnpm install (tests/config)" pnpm install --offline --frozen-lockfile --ignore-scripts --store-dir "$store_path"

log_step "chmod node_modules writable" chmod -R u+w node_modules

# Rebuild native deps so rolldown (and other native modules) work.
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

# rolldown was removed from upstream direct dependencies (v2026.2.21+) but
# remains in the pnpm store as a transitive dep (via rolldown-plugin-dts).
# Upstream's bundle-a2ui.sh falls back to `pnpm dlx` which needs network.
# Put rolldown on PATH so the script finds it directly.
if ! command -v rolldown >/dev/null 2>&1; then
  _rolldown_pkg="$(find node_modules/.pnpm -maxdepth 4 -path '*/rolldown@*/node_modules/rolldown' -print -quit 2>/dev/null || true)"
  if [ -n "$_rolldown_pkg" ] && [ -f "$_rolldown_pkg/bin/cli.mjs" ]; then
    _rolldown_shim="$(mktemp -d)"
    printf '#!/bin/sh\nexec node "%s/bin/cli.mjs" "$@"\n' "$_rolldown_pkg" > "$_rolldown_shim/rolldown"
    chmod +x "$_rolldown_shim/rolldown"
    export PATH="$_rolldown_shim:$PATH"
  fi
fi

# Build A2UI bundle so gateway tests that exercise canvas auth paths
# can serve real assets instead of returning 503.
log_step "build: canvas:a2ui:bundle" pnpm canvas:a2ui:bundle
