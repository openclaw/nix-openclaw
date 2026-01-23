#!/bin/sh
set -e
mkdir -p "$out/lib/clawdbot" "$out/bin"

# Copy core files and bundled extensions (memory-core, etc.)
cp -r dist node_modules package.json ui "$out/lib/clawdbot/"
# Copy docs (includes workspace templates like AGENTS.md)
if [ -d "docs" ]; then
  cp -r docs "$out/lib/clawdbot/"
fi
if [ -d "extensions" ]; then
  cp -r extensions "$out/lib/clawdbot/"
fi

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
# Patch shebangs in extensions node_modules if present
if [ -d "$out/lib/clawdbot/extensions" ]; then
  for ext_bin in "$out/lib/clawdbot/extensions"/*/node_modules/.bin; do
    if [ -d "$ext_bin" ]; then
      bash -e -c '. "$STDENV_SETUP"; patchShebangs "'"$ext_bin"'"'
    fi
  done
fi

# Work around missing dependency declaration in pi-coding-agent (strip-ansi).
# Ensure it is resolvable at runtime without changing upstream.
pi_pkg="$(find "$out/lib/clawdbot/node_modules/.pnpm" -path "*/node_modules/@mariozechner/pi-coding-agent" -print | head -n 1)"
strip_ansi_src="$(find "$out/lib/clawdbot/node_modules/.pnpm" -path "*/node_modules/strip-ansi" -print | head -n 1)"

if [ -n "$strip_ansi_src" ]; then
  if [ -n "$pi_pkg" ] && [ ! -e "$pi_pkg/node_modules/strip-ansi" ]; then
    mkdir -p "$pi_pkg/node_modules"
    ln -s "$strip_ansi_src" "$pi_pkg/node_modules/strip-ansi"
  fi

  if [ ! -e "$out/lib/clawdbot/node_modules/strip-ansi" ]; then
    mkdir -p "$out/lib/clawdbot/node_modules"
    ln -s "$strip_ansi_src" "$out/lib/clawdbot/node_modules/strip-ansi"
  fi
fi
bash -e -c '. "$STDENV_SETUP"; makeWrapper "$NODE_BIN" "$out/bin/clawdbot" --add-flags "$out/lib/clawdbot/dist/index.js" --set-default CLAWDBOT_NIX_MODE "1"'
