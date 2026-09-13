#!/bin/sh
set -e

. "$OPENCLAW_BUILD_LOG_SH"

store_path_file="${PNPM_STORE_PATH_FILE:-.pnpm-store-path}"

if [ -n "${OPENCLAW_BUILD_ROOT_SH:-}" ]; then
  . "$OPENCLAW_BUILD_ROOT_SH"
  openclaw_init_output_build_root
fi

if [ -n "${out:-}" ]; then
  store_path="$PWD/.pnpm-store"
  rm -rf "$store_path"
  mkdir -p "$store_path"
else
  store_path="$(mktemp -d)"
fi

printf "%s" "$store_path" > "$store_path_file"

verified_lockfile_cache="$PNPM_DEPS/pnpm-lockfile-verified.jsonl"
if [ -f "$verified_lockfile_cache" ]; then
  if [ -n "${out:-}" ]; then
    pnpm_cache_dir="$PWD/.pnpm-cache"
    rm -rf "$pnpm_cache_dir"
    mkdir -p "$pnpm_cache_dir"
  else
    pnpm_cache_dir="$(mktemp -d)"
  fi
  cp "$verified_lockfile_cache" "$pnpm_cache_dir/lockfile-verified.jsonl"
  export PNPM_CONFIG_CACHE_DIR="$pnpm_cache_dir"
fi

fetcherVersion=$(cat "$PNPM_DEPS/.fetcher-version" 2>/dev/null || echo 1)
if [ "$fetcherVersion" -ge 3 ]; then
  log_step "extract pnpm store (fetcherVersion=${fetcherVersion})" tar --zstd -xf "$PNPM_DEPS/pnpm-store.tar.zst" -C "$store_path"
else
  log_step "copy pnpm store (fetcherVersion=${fetcherVersion})" cp -Tr "$PNPM_DEPS" "$store_path"
fi

log_step "chmod pnpm store writable" chmod -R +w "$store_path"
log_step "restore pnpm store index" "$NODE_BIN" "$RESTORE_PNPM_STORE_SCRIPT" "$store_path"

# pnpm --ignore-scripts marks tarball deps as "not built" and offline install
# later refuses to use them; if a dep doesn't require build, promote it.
log_step "promote pnpm integrity" "$PROMOTE_PNPM_INTEGRITY_SH" "$store_path"

REAL_NODE_GYP="$(command -v node-gyp)"
export REAL_NODE_GYP
wrapper_dir="$(mktemp -d)"
install -Dm755 "$NODE_GYP_WRAPPER_SH" "$wrapper_dir/node-gyp"
export PATH="$wrapper_dir:$PATH"
