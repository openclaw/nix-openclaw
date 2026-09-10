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
  # tar --zstd uses libzstd; on some platforms it ends up single-threaded.
  # Use zstd directly, bounded by Nix's build-core budget.
  zstd_threads="${NIX_BUILD_CORES:-2}"
  case "$zstd_threads" in
    ''|*[!0-9]*) zstd_threads=2 ;;
  esac
  log_step "extract pnpm store (fetcherVersion=${fetcherVersion})" sh -c '
    zstd -d --threads="$3" < "$1" | tar -xf - -C "$2"
  ' sh "$PNPM_DEPS/pnpm-store.tar.zst" "$store_path" "$zstd_threads"
else
  log_step "copy pnpm store (fetcherVersion=${fetcherVersion})" cp -Tr "$PNPM_DEPS" "$store_path"
fi

log_step "chmod pnpm store writable" chmod -R +w "$store_path"

# fetchPnpmDeps v4 serializes the index as SQL for reproducibility.
# Restore it before pnpm tries to reuse the offline content store.
if [ -f "$store_path/v11/index.db.sql" ]; then
  sqlite3 "$store_path/v11/index.db" < "$store_path/v11/index.db.sql"
  rm "$store_path/v11/index.db.sql"
fi

# pnpm --ignore-scripts marks tarball deps as "not built" and offline install
# later refuses to use them; if a dep doesn't require build, promote it.
log_step "promote pnpm integrity" "$PROMOTE_PNPM_INTEGRITY_SH" "$store_path"

export REAL_NODE_GYP="$(command -v node-gyp)"
wrapper_dir="$(mktemp -d)"
install -Dm755 "$NODE_GYP_WRAPPER_SH" "$wrapper_dir/node-gyp"
export PATH="$wrapper_dir:$PATH"
