#!/bin/sh
set -eu

if [ -z "${OPENCLAW_GATEWAY_PACKAGE:-}" ]; then
  echo "OPENCLAW_GATEWAY_PACKAGE is not set" >&2
  exit 1
fi
if [ -z "${OPENCLAW_GATEWAY_BIN:-}" ]; then
  echo "OPENCLAW_GATEWAY_BIN is not set" >&2
  exit 1
fi
if [ ! -x "$OPENCLAW_GATEWAY_BIN" ]; then
  echo "OPENCLAW_GATEWAY_BIN is not executable: $OPENCLAW_GATEWAY_BIN" >&2
  exit 1
fi
if [ -z "${OPENCLAW_QMD_PATH:-}" ]; then
  echo "OPENCLAW_QMD_PATH is not set" >&2
  exit 1
fi

mkdir -p "$out/bin"
makeWrapper "$OPENCLAW_GATEWAY_BIN" "$out/bin/openclaw" \
  --prefix PATH : "$OPENCLAW_QMD_PATH"

if [ -d "${OPENCLAW_GATEWAY_PACKAGE}/Applications" ]; then
  ln -s "${OPENCLAW_GATEWAY_PACKAGE}/Applications" "$out/Applications"
fi
