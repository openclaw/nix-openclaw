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

check_no_broken_symlinks() {
  root="$1"
  if [ ! -d "$root" ]; then
    return 0
  fi

  broken_tmp="$(mktemp)"
  # Portable and faster than `find ... -exec test -e {} \;` on large trees.
  find "$root" -type l -print | while IFS= read -r link; do
    [ -e "$link" ] || printf '%s\n' "$link"
  done > "$broken_tmp"
  if [ -s "$broken_tmp" ]; then
    echo "dangling symlinks found under $root" >&2
    cat "$broken_tmp" >&2
    rm -f "$broken_tmp"
    return 1
  fi
  rm -f "$broken_tmp"
}

mkdir -p "$out/lib/openclaw" "$out/bin"

# Build dir is ephemeral in Nix; moving avoids an expensive deep copy of node_modules.
log_step "move build outputs" mv dist node_modules package.json "$out/lib/openclaw/"
if [ -d extensions ]; then
  log_step "copy extensions" cp -r extensions "$out/lib/openclaw/"
fi
if [ -d assets ]; then
  log_step "copy assets" cp -r assets "$out/lib/openclaw/"
fi

if [ -d docs/reference/templates ]; then
  mkdir -p "$out/lib/openclaw/docs/reference"
  log_step "copy reference templates" cp -r docs/reference/templates "$out/lib/openclaw/docs/reference/"
fi

if [ -z "${STDENV_SETUP:-}" ]; then
  echo "STDENV_SETUP is not set" >&2
  exit 1
fi
if [ ! -f "$STDENV_SETUP" ]; then
  echo "STDENV_SETUP not found: $STDENV_SETUP" >&2
  exit 1
fi

log_step "patchShebangs node_modules/.bin" bash -e -c '. "$STDENV_SETUP"; patchShebangs "$out/lib/openclaw/node_modules/.bin"'

# Work around missing dependency declaration in pi-coding-agent (strip-ansi).
# Ensure it is resolvable at runtime without changing upstream.
pi_pkg="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/@mariozechner/pi-coding-agent" -print | head -n 1)"
strip_ansi_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/strip-ansi" -print | head -n 1)"

if [ -n "$strip_ansi_src" ]; then
  if [ -n "$pi_pkg" ] && [ ! -e "$pi_pkg/node_modules/strip-ansi" ]; then
    mkdir -p "$pi_pkg/node_modules"
    ln -s "$strip_ansi_src" "$pi_pkg/node_modules/strip-ansi"
  fi

  if [ ! -e "$out/lib/openclaw/node_modules/strip-ansi" ]; then
    mkdir -p "$out/lib/openclaw/node_modules"
    ln -s "$strip_ansi_src" "$out/lib/openclaw/node_modules/strip-ansi"
  fi
fi

if [ -n "${PATCH_CLIPBOARD_SH:-}" ]; then
  "$PATCH_CLIPBOARD_SH" "$out/lib/openclaw" "$PATCH_CLIPBOARD_WRAPPER"
fi

# Work around missing combined-stream dependency for form-data in pnpm layout.
combined_stream_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/combined-stream@*/node_modules/combined-stream" -print | head -n 1)"
form_data_pkgs="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/form-data" -print)"
if [ -n "$combined_stream_src" ]; then
  if [ ! -e "$out/lib/openclaw/node_modules/combined-stream" ]; then
    ln -s "$combined_stream_src" "$out/lib/openclaw/node_modules/combined-stream"
  fi
  if [ -n "$form_data_pkgs" ]; then
    for pkg in $form_data_pkgs; do
      if [ ! -e "$pkg/node_modules/combined-stream" ]; then
        mkdir -p "$pkg/node_modules"
        ln -s "$combined_stream_src" "$pkg/node_modules/combined-stream"
      fi
    done
  fi
fi

# Work around missing hasown dependency for form-data in pnpm layout.
hasown_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/hasown@*/node_modules/hasown" -print | head -n 1)"
if [ -n "$hasown_src" ]; then
  if [ ! -e "$out/lib/openclaw/node_modules/hasown" ]; then
    ln -s "$hasown_src" "$out/lib/openclaw/node_modules/hasown"
  fi
  if [ -n "$form_data_pkgs" ]; then
    for pkg in $form_data_pkgs; do
      if [ ! -e "$pkg/node_modules/hasown" ]; then
        mkdir -p "$pkg/node_modules"
        ln -s "$hasown_src" "$pkg/node_modules/hasown"
      fi
    done
  fi
fi

log_step "validate node_modules symlinks" check_no_broken_symlinks "$out/lib/openclaw/node_modules"

bash -e -c '. "$STDENV_SETUP"; makeWrapper "$NODE_BIN" "$out/bin/openclaw" --add-flags "$out/lib/openclaw/dist/index.js" --set-default OPENCLAW_NIX_MODE "1"'
