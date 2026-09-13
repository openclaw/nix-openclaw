#!/bin/sh
set -e

. "$OPENCLAW_BUILD_LOG_SH"

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

. "$PNPM_BUILD_ENV_SH"
package_name="$(jq -er '.name // empty' package.json)"
mkdir -p "$out/lib" "$out/bin"
# Deploy from the shared lock without resolving registry metadata again.
log_step "deploy production package" pnpm --config.inject-workspace-packages=true --filter "$package_name" deploy --prod --ignore-scripts "$out/lib/openclaw"

log_step "stage Nix runtime layout" "$OPENCLAW_RUNTIME_LAYOUT_SH" "$out/lib/openclaw" "$PWD/extensions"

if [ -n "${PATCH_CLIPBOARD_SH:-}" ]; then
  "$PATCH_CLIPBOARD_SH" "$out/lib/openclaw" "$PATCH_CLIPBOARD_WRAPPER"
fi

if [ -n "${OPENCLAW_BUILD_ROOT_SH:-}" ]; then
  openclaw_cleanup_output_pnpm_store
fi
log_step "validate package symlinks" check_no_broken_symlinks "$out/lib/openclaw"

entrypoint="$(jq -er 'if (.bin | type) == "string" then .bin else .bin.openclaw end' "$out/lib/openclaw/package.json")"
test -f "$out/lib/openclaw/$entrypoint"
log_step "wrap openclaw" bash -e -c '. "$STDENV_SETUP"; makeWrapper "$NODE_BIN" "$out/bin/openclaw" --add-flags "$1" --prefix PATH : "$(dirname "$NODE_BIN")" --set-default OPENCLAW_NIX_MODE "1" --set-default OPENCLAW_DISABLE_PERSISTED_PLUGIN_REGISTRY "1"' sh "$out/lib/openclaw/$entrypoint"
