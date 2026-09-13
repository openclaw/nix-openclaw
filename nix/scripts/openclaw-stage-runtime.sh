#!/bin/sh
set -eu
root="$1"
source_extensions="${2:-$root/extensions}"

if [ -d "$root/dist/extensions" ]; then
  # Older source builds leave manifests outside the compiled extension tree.
  for manifest in "$source_extensions"/*/openclaw.plugin.json; do
    [ -f "$manifest" ] || continue
    name="$(basename "$(dirname "$manifest")")"
    dist_extension="$root/dist/extensions/$name"
    if [ -d "$dist_extension" ] && [ ! -f "$dist_extension/openclaw.plugin.json" ]; then
      cp "$manifest" "$dist_extension/openclaw.plugin.json"
    fi
  done
  mkdir -p "$root/extensions"
  find "$root/dist/extensions" -mindepth 2 -maxdepth 2 -name openclaw.plugin.json -type f -print |
    while IFS= read -r manifest; do
      name="$(basename "$(dirname "$manifest")")"
      mkdir -p "$root/extensions/$name"
      cp "$manifest" "$root/extensions/$name/openclaw.plugin.json"
    done

  # Relative imports and module identity must use the canonical dist graph.
  rm -rf "$root/dist-runtime"
  ln -s dist "$root/dist-runtime"
fi

if [ -n "${OPENCLAW_BUNDLED_ACPX:-}" ]; then
  if [ ! -d "$OPENCLAW_BUNDLED_ACPX" ]; then
    echo "OPENCLAW_BUNDLED_ACPX missing: $OPENCLAW_BUNDLED_ACPX" >&2
    exit 1
  fi
  acpx_root="$root/dist/extensions/acpx"
  rm -rf "$acpx_root"
  # Discovery requires physical containment, not a link to another store root.
  mkdir -p "$acpx_root"
  cp -R "$OPENCLAW_BUNDLED_ACPX/." "$acpx_root/"
fi
