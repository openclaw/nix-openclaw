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

if [ -n "${OPENCLAW_BUILD_ROOT_SH:-}" ]; then
  . "$OPENCLAW_BUILD_ROOT_SH"
  openclaw_enter_build_root
fi

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

copy_extension_manifests() {
  if [ ! -d extensions ]; then
    return 0
  fi

  mkdir -p "$out/lib/openclaw/extensions"
  find extensions -mindepth 2 -maxdepth 2 -name openclaw.plugin.json -type f -print | while IFS= read -r manifest; do
    name="$(basename "$(dirname "$manifest")")"
    mkdir -p "$out/lib/openclaw/extensions/$name"
    cp "$manifest" "$out/lib/openclaw/extensions/$name/openclaw.plugin.json"
  done
}

mkdir -p "$out/lib/openclaw" "$out/bin"

set -- dist node_modules package.json openclaw.mjs
# Older launchers inline this helper; declared runtime files must not be silently omitted.
node_version_file="$(jq -r '.files[] | select(. == "node-version.mjs")' package.json)"
if [ -n "$node_version_file" ]; then
  set -- "$@" "$node_version_file"
fi
if [ -d dist-runtime ]; then
  set -- "$@" dist-runtime
fi
log_step "copy build outputs" cp -R "$@" "$out/lib/openclaw/"
if [ -d extensions ]; then
  log_step "copy extension manifests" copy_extension_manifests
fi
if [ -d skills ]; then
  log_step "copy bundled skills" cp -r skills "$out/lib/openclaw/"
fi
if [ -d src/agents/templates ]; then
  mkdir -p "$out/lib/openclaw/src/agents"
  log_step "copy agent workspace templates" cp -r src/agents/templates "$out/lib/openclaw/src/agents/"
fi

# Gateway plugin discovery looks under dist/extensions/*/openclaw.plugin.json.
# Upstream's build emits JS into dist/extensions but leaves manifests in extensions/.
if [ -d "$out/lib/openclaw/extensions" ] && [ -d "$out/lib/openclaw/dist/extensions" ]; then
  for manifest in "$out/lib/openclaw/extensions"/*/openclaw.plugin.json; do
    [ -f "$manifest" ] || continue
    name="$(basename "$(dirname "$manifest")")"
    dist_ext="$out/lib/openclaw/dist/extensions/$name"
    if [ -d "$dist_ext" ] && [ ! -f "$dist_ext/openclaw.plugin.json" ]; then
      cp "$manifest" "$dist_ext/openclaw.plugin.json"
    fi
  done
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

if [ -n "${OPENCLAW_BUILD_ROOT_SH:-}" ]; then
  openclaw_cleanup_output_pnpm_store
fi

log_step "validate node_modules symlinks" check_no_broken_symlinks "$out/lib/openclaw/node_modules"
if [ -d "$out/lib/openclaw/dist-runtime" ]; then
  log_step "validate dist-runtime symlinks" check_no_broken_symlinks "$out/lib/openclaw/dist-runtime"
fi

log_step "wrap openclaw" bash -e -c '. "$STDENV_SETUP"; makeWrapper "$NODE_BIN" "$out/bin/openclaw" --add-flags "$out/lib/openclaw/dist/index.js" --prefix PATH : "$(dirname "$NODE_BIN")" --set-default OPENCLAW_NIX_MODE "1" --set-default OPENCLAW_DISABLE_PERSISTED_PLUGIN_REGISTRY "1"'
