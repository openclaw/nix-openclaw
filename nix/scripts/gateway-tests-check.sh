#!/bin/sh
set -e

store_path_file="${PNPM_STORE_PATH_FILE:-.pnpm-store-path}"
if [ -f "$store_path_file" ]; then
  store_path="$(cat "$store_path_file")"
  export PNPM_STORE_DIR="$store_path"
  export PNPM_STORE_PATH="$store_path"
  export NPM_CONFIG_STORE_DIR="$store_path"
  export NPM_CONFIG_STORE_PATH="$store_path"
fi
export HOME="$(mktemp -d)"
export TMPDIR="${HOME}/tmp"
mkdir -p "$TMPDIR"
export OPENCLAW_LOG_DIR="${TMPDIR}/openclaw-logs"
mkdir -p "$OPENCLAW_LOG_DIR"
mkdir -p /tmp/openclaw || true
chmod 700 /tmp/openclaw || true
unset OPENCLAW_BUNDLED_PLUGINS_DIR
PATH="$PWD/node_modules/.bin:$PATH"
vitest_cli="$PWD/node_modules/vitest/vitest.mjs"
if [ ! -f "$vitest_cli" ]; then
  vitest_cli="$(find "$PWD/node_modules" -path '*/vitest/vitest.mjs' -type f | head -n 1)"
fi

if [ -z "${vitest_cli:-}" ] || [ ! -f "$vitest_cli" ]; then
  echo "vitest CLI not found under $PWD/node_modules" >&2
  exit 1
fi

exec node "$vitest_cli" run --config vitest.gateway.config.ts --testTimeout=20000
