#!/bin/sh
set -eu

if [ -z "${out:-}" ]; then
  echo "out is not set" >&2
  exit 1
fi
if [ -z "${STDENV_SETUP:-}" ] || [ ! -f "$STDENV_SETUP" ]; then
  echo "STDENV_SETUP is not set or missing" >&2
  exit 1
fi
if [ -z "${NODE_BIN:-}" ] || [ ! -x "$NODE_BIN" ]; then
  echo "NODE_BIN is not set or missing" >&2
  exit 1
fi
if [ -z "${OPENCLAW_PATCH_NPM_DIST_SCRIPT:-}" ] || [ ! -f "$OPENCLAW_PATCH_NPM_DIST_SCRIPT" ]; then
  echo "OPENCLAW_PATCH_NPM_DIST_SCRIPT is not set or missing" >&2
  exit 1
fi

package_root="${OPENCLAW_NPM_PACKAGE_ROOT:-node_modules/openclaw}"
if [ ! -d "$package_root" ]; then
  echo "OpenClaw npm package root missing: $package_root" >&2
  exit 1
fi

root="$out/lib/openclaw"
modules_root="$out/lib/node_modules"
mkdir -p "$modules_root" "$out/bin"

log_step() {
  printf 'openclaw npm install: %s\n' "$1"
}

log_step "copy installed dependency tree"
# npm hoists dependencies beside openclaw; keep that locked tree and its realpaths.
cp -R node_modules/. "$modules_root/"
ln -s node_modules/openclaw "$root"
log_step "patch npm dist"
OPENCLAW_PACKAGE_ROOT="$root" "$NODE_BIN" "$OPENCLAW_PATCH_NPM_DIST_SCRIPT"

check_no_broken_symlinks() {
  check_root="$1"
  if [ ! -d "$check_root" ]; then
    return 0
  fi

  broken_tmp="$(mktemp)"
  find "$check_root" -type l -print | while IFS= read -r link; do
    [ -e "$link" ] || printf '%s\n' "$link"
  done > "$broken_tmp"
  if [ -s "$broken_tmp" ]; then
    echo "dangling symlinks found under $check_root" >&2
    cat "$broken_tmp" >&2
    rm -f "$broken_tmp"
    return 1
  fi
  rm -f "$broken_tmp"
}

ensure_legacy_node_module_entry() {
  package="$1"
  if [ -e "$root/node_modules/$package" ] || [ -e "$modules_root/$package" ] || [ ! -d "$root/node_modules" ]; then
    return 0
  fi

  package_dir="$(find "$root/node_modules" -path "*/node_modules/$package" -type d -print | head -n 1)"
  if [ -n "$package_dir" ]; then
    ln -s "$package_dir" "$root/node_modules/$package"
  fi
}

log_step "stage Nix runtime layout"
"$OPENCLAW_RUNTIME_LAYOUT_SH" "$root"
log_step "restore legacy dependency entries"
ensure_legacy_node_module_entry combined-stream
ensure_legacy_node_module_entry hasown

log_step "check symlinks"
check_no_broken_symlinks "$out/lib"

log_step "wrap openclaw"
export root
bash -e -c '. "$STDENV_SETUP"; makeWrapper "$NODE_BIN" "$out/bin/openclaw" --add-flags "$root/dist/index.js" --prefix PATH : "$(dirname "$NODE_BIN")" --set-default OPENCLAW_NIX_MODE "1" --set-default OPENCLAW_DISABLE_PERSISTED_PLUGIN_REGISTRY "1"'
