#!/bin/sh
set -e
mkdir -p "$out/lib/clawdbot" "$out/bin"

cp -r dist node_modules package.json ui "$out/lib/clawdbot/"

if [ -z "${STDENV_SETUP:-}" ]; then
  echo "STDENV_SETUP is not set" >&2
  exit 1
fi
if [ ! -f "$STDENV_SETUP" ]; then
  echo "STDENV_SETUP not found: $STDENV_SETUP" >&2
  exit 1
fi

bash -e -c '. "$STDENV_SETUP"; patchShebangs "$out/lib/clawdbot/node_modules/.bin"'
if [ -d "$out/lib/clawdbot/ui/node_modules/.bin" ]; then
  bash -e -c '. "$STDENV_SETUP"; patchShebangs "$out/lib/clawdbot/ui/node_modules/.bin"'
fi
bash -e -c '. "$STDENV_SETUP"; makeWrapper "$NODE_BIN" "$out/bin/clawdbot" --add-flags "$out/lib/clawdbot/dist/index.js" --set-default CLAWDBOT_NIX_MODE "1"'
