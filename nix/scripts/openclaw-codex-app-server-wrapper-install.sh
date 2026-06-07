#!/bin/sh
set -eu

if [ -z "${OPENCLAW_CODEX_APP_SERVER_WRAPPER:-}" ]; then
  echo "OPENCLAW_CODEX_APP_SERVER_WRAPPER is not set" >&2
  exit 1
fi
if [ ! -f "$OPENCLAW_CODEX_APP_SERVER_WRAPPER" ]; then
  echo "OPENCLAW_CODEX_APP_SERVER_WRAPPER not found: $OPENCLAW_CODEX_APP_SERVER_WRAPPER" >&2
  exit 1
fi

mkdir -p "$out/bin"
cp "$OPENCLAW_CODEX_APP_SERVER_WRAPPER" "$out/bin/openclaw-codex-app-server"
chmod +x "$out/bin/openclaw-codex-app-server"
