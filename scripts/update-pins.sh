#!/usr/bin/env bash
set -euo pipefail

if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
  echo "This script is intended to run in GitHub Actions (see .github/workflows/pin-stable-openclaw-version.yml). Refusing to run locally." >&2
  exit 1
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_file="$repo_root/nix/sources/openclaw-source.nix"
app_file="$repo_root/nix/packages/openclaw-app.nix"
config_options_file="$repo_root/nix/generated/openclaw-config-options.nix"
gateway_npm_wrapper_dir="$repo_root/nix/npm/openclaw"
runtime_plugin_lock_rel_dir="nix/generated/openclaw-runtime-plugins"
runtime_plugin_lock_dir="$repo_root/$runtime_plugin_lock_rel_dir"
runtime_plugin_version_resolver="$repo_root/nix/scripts/openclaw-runtime-plugin-version.mjs"
npm_fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
apply_backup_dir=""
apply_success=0

# shellcheck source=scripts/lib/pin-source.sh
. "$repo_root/scripts/lib/pin-source.sh"

log() {
  printf '>> %s\n' "$*" >&2
}

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/update-pins.sh files
  scripts/update-pins.sh select
  scripts/update-pins.sh apply <source_tag> <source_sha> <app_tag> <app_url>
EOF
}

require_cmds() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "$cmd is required but not installed." >&2
      exit 1
    fi
  done
}

current_field() {
  local file="$1"
  local key="$2"
  awk -F'"' -v key="$key" '$0 ~ key" =" { print $2; exit }' "$file"
}

pin_files=(
  "$source_file"
  "$app_file"
  "$config_options_file"
  "$gateway_npm_wrapper_dir/package.json"
  "$gateway_npm_wrapper_dir/package-lock.json"
)

pin_file_paths() {
  local file
  for file in "${pin_files[@]}"; do
    printf '%s\n' "${file#"$repo_root/"}"
  done
  {
    git -C "$repo_root" ls-files -- "$runtime_plugin_lock_rel_dir"
    if [[ -d "$runtime_plugin_lock_dir" ]]; then
      find "$runtime_plugin_lock_dir" -maxdepth 1 -type f \( -name '*.nix' -o -name '*.package-lock.json' -o -name 'report.json' \) -print \
        | sed "s|^$repo_root/||"
    fi
  } | sort -u
}

set_gateway_npm_deps_hash() {
  local hash="$1"

  if grep -q 'gatewayNpmDepsHash = ' "$source_file"; then
    perl -0pi -e "s|gatewayNpmDepsHash = \"[^\"]*\";|gatewayNpmDepsHash = \"${hash}\";|" "$source_file"
  fi
}

update_wrapper_package_version() {
  local package_json="$1"
  local package_name="$2"
  local version="$3"
  local tmp_json
  tmp_json=$(mktemp)

  jq --arg package_name "$package_name" --arg version "$version" \
    '.dependencies[$package_name] = $version' \
    "$package_json" >"$tmp_json"
  mv "$tmp_json" "$package_json"
}

refresh_npm_wrapper_locks() {
  local source_version="$1"

  update_wrapper_package_version "$gateway_npm_wrapper_dir/package.json" "openclaw" "$source_version"

  # Resolve the wrapper lock from scratch. Updating the previous release's lock
  # in place lets npm (10 and 11) keep a stale nested transitive package, such
  # as openclaw/node_modules/p-limit@2.x, as the target of a new direct
  # dependency edge (openclaw -> p-limit@^7) and drop the hoisted package, which
  # then fails `npm ci` with ENOTCACHED inside the Nix sandbox.
  rm -rf "$gateway_npm_wrapper_dir/node_modules" "$gateway_npm_wrapper_dir/package-lock.json"
  nix shell --extra-experimental-features "nix-command flakes" --accept-flake-config --inputs-from "$repo_root" \
    nixpkgs#nodejs_24 -c \
    bash -euo pipefail -c "cd '$gateway_npm_wrapper_dir' && npm install --package-lock-only --ignore-scripts --omit=dev --legacy-peer-deps"
  OPENCLAW_NPM_WRAPPER_DIR="$gateway_npm_wrapper_dir" \
    nix shell --extra-experimental-features "nix-command flakes" --accept-flake-config --inputs-from "$repo_root" \
    nixpkgs#nodejs_24 -c \
    "$repo_root/nix/scripts/check-openclaw-npm-wrapper-lock.sh"
}

refresh_runtime_plugin_locks() {
  nix shell --extra-experimental-features "nix-command flakes" --accept-flake-config --inputs-from "$repo_root" \
    nixpkgs#nodejs_24 nixpkgs#unzip "$repo_root#node-semver" -c \
    node "$repo_root/nix/scripts/update-openclaw-runtime-plugin-locks.mjs"
  track_new_runtime_plugin_locks
}

# Flake builds later in apply (gateway, plugin probes) copy only Git-tracked
# files, so freshly generated lock sidecars must be registered with the index
# before the first build reads them. The workflow repeats this for all pin files.
track_new_runtime_plugin_locks() {
  local -a new_files=()
  while IFS= read -r file; do
    new_files+=("$file")
  done < <(git -C "$repo_root" ls-files --others --exclude-standard -- "$runtime_plugin_lock_rel_dir")
  if [[ ${#new_files[@]} -gt 0 ]]; then
    git -C "$repo_root" add --intent-to-add -- "${new_files[@]}"
  fi
}

validate_runtime_plugin_locks() {
  local locks_json
  locks_json=$(mktemp)
  if ! nix --extra-experimental-features "nix-command flakes" eval --json --impure --expr "import ${runtime_plugin_lock_dir}/default.nix" >"$locks_json"; then
    rm -f "$locks_json"
    return 1
  fi
  if ! OPENCLAW_RUNTIME_PLUGIN_LOCK_DIR="$runtime_plugin_lock_dir" \
    OPENCLAW_RUNTIME_PLUGIN_LOCKS_JSON="$locks_json" \
    OPENCLAW_SOURCE_INFO_PATH="$source_file" \
    OPENCLAW_RUNTIME_PLUGIN_VERIFY_EVIDENCE_ASSET=1 \
    nix shell --extra-experimental-features "nix-command flakes" --accept-flake-config --inputs-from "$repo_root" \
    nixpkgs#nodejs_24 nixpkgs#unzip "$repo_root#node-semver" -c \
    node "$repo_root/nix/scripts/check-openclaw-runtime-plugin-locks.mjs"; then
    rm -f "$locks_json"
    return 1
  fi
  rm -f "$locks_json"
}

refresh_npm_hash() {
  local attr="$1"
  local setter="$2"
  local label="$3"
  local build_log npm_hash

  build_log=$(mktemp)
  if ! nix --extra-experimental-features "nix-command flakes" build ".#${attr}" --accept-flake-config >"$build_log" 2>&1; then
    npm_hash=$(grep -Eo 'got: *sha256-[A-Za-z0-9+/=]+' "$build_log" | head -n 1 | sed 's/.*got: *//' || true)
    if [[ -z "$npm_hash" ]]; then
      tail -n 200 "$build_log" >&2 || true
      rm -f "$build_log"
      return 1
    fi
    log "${label} npmDepsHash mismatch detected: $npm_hash"
    "$setter" "$npm_hash"
    nix --extra-experimental-features "nix-command flakes" build ".#${attr}" --accept-flake-config >"$build_log" 2>&1 || {
      tail -n 200 "$build_log" >&2 || true
      rm -f "$build_log"
      return 1
    }
  fi
  rm -f "$build_log"
}

select_release() {
  local release_json selection_json current_rev current_app_version source_tag source_version selected_sha
  local app_tag app_version app_url latest_stable_tag app_lag_releases has_update
  current_rev=$(current_field "$source_file" "rev")
  current_app_version=$(current_field "$app_file" "version")

  log "Fetching OpenClaw stable release metadata"
  release_json=$(gh api '/repos/openclaw/openclaw/releases?per_page=100')
  selection_json=$(printf '%s' "$release_json" | node "$repo_root/scripts/select-openclaw-release.mjs")

  latest_stable_tag=$(printf '%s' "$selection_json" | jq -r '.latestStableSource.tagName // empty')
  source_tag=$(printf '%s' "$selection_json" | jq -r '.latestStableSource.tagName // empty')
  source_version=$(printf '%s' "$selection_json" | jq -r '.latestStableSource.releaseVersion // empty')
  app_tag=$(printf '%s' "$selection_json" | jq -r '.latestMacAppStable.tagName // empty')
  app_version=$(printf '%s' "$selection_json" | jq -r '.latestMacAppStable.releaseVersion // empty')
  app_url=$(printf '%s' "$selection_json" | jq -r '.latestMacAppStable.appUrl // empty')
  app_lag_releases=$(printf '%s' "$selection_json" | jq -r '[.appLagStableReleases[]?.tagName | select(. != null)] | join(",")')

  if [[ -z "$source_tag" || -z "$source_version" ]]; then
    echo "Failed to resolve an OpenClaw stable source release" >&2
    if [[ -n "$latest_stable_tag" ]]; then
      echo "Latest stable release: $latest_stable_tag" >&2
    fi
    exit 1
  fi

  selected_sha=$(resolve_release_tag_sha "$source_tag")
  if [[ -z "$selected_sha" ]]; then
    echo "Failed to resolve tag SHA for $source_tag" >&2
    exit 1
  fi

  log "Selected latest stable source release: $source_tag ($selected_sha)"
  if [[ -n "$app_tag" ]]; then
    log "Selected latest public macOS app release: $app_tag"
  else
    log "No public macOS app asset found; preserving existing app pin"
  fi
  if [[ -n "$app_lag_releases" ]]; then
    log "macOS app asset lags source release(s): $app_lag_releases"
  fi

  if [[ "$current_rev" == "$selected_sha" && ( -z "$app_version" || "$current_app_version" == "$app_version" ) ]]; then
    has_update=false
  else
    has_update=true
  fi

  printf 'has_update=%s\n' "$has_update"
  printf 'source_tag=%s\n' "$source_tag"
  printf 'source_sha=%s\n' "$selected_sha"
  printf 'source_version=%s\n' "$source_version"
  printf 'app_tag=%s\n' "$app_tag"
  printf 'app_url=%s\n' "$app_url"
  printf 'app_version=%s\n' "$app_version"
  printf 'latest_stable_tag=%s\n' "$latest_stable_tag"
  printf 'app_lag_releases=%s\n' "$app_lag_releases"
}

apply_release() {
  local source_tag="$1"
  local selected_sha="$2"
  local app_tag="$3"
  local app_url="$4"
  local source_version source_url source_prefetch source_hash source_store_path selected_pnpm_major runtime_plugin_version public_surface_hardlinks_patch apply_skip_plugin_auto_enable_patch app_version app_hash

  source_version="${source_tag#v}"
  source_url="https://github.com/openclaw/openclaw/archive/${selected_sha}.tar.gz"

  source_prefetch=$(prefetch_json "$source_url")
  source_hash=$(printf '%s' "$source_prefetch" | jq -r '.hash // empty')
  source_store_path=$(printf '%s' "$source_prefetch" | jq -r '.path // .storePath // empty')
  if [[ -z "$source_hash" || -z "$source_store_path" ]]; then
    echo "Failed to resolve source hash/path for $selected_sha" >&2
    exit 1
  fi
  selected_pnpm_major=$(source_pnpm_major "$source_store_path")
  runtime_plugin_version=$(source_runtime_plugin_version "$source_store_path" "$source_version")
  public_surface_hardlinks_patch=$(source_public_surface_hardlinks_patch "$source_store_path")
  apply_skip_plugin_auto_enable_patch=$(source_needs_skip_plugin_auto_enable_nix_mode_patch "$source_store_path")

  if [[ -n "$app_tag" || -n "$app_url" ]]; then
    if [[ -z "$app_tag" || -z "$app_url" ]]; then
      echo "app_tag and app_url must either both be set or both be empty" >&2
      exit 1
    fi

    app_version="${app_tag#v}"
    app_hash=$(unpacked_zip_hash "$app_url")
    if [[ -z "$app_hash" ]]; then
      echo "Failed to resolve app hash for $app_tag" >&2
      exit 1
    fi
  fi

  apply_backup_dir=$(mktemp -d)
  apply_success=0
  for file in "${pin_files[@]}"; do
    mkdir -p "$apply_backup_dir/$(dirname "${file#"$repo_root/"}")"
    cp "$file" "$apply_backup_dir/${file#"$repo_root/"}"
  done
  mkdir -p "$apply_backup_dir/$runtime_plugin_lock_rel_dir"
  cp -R "$runtime_plugin_lock_dir/." "$apply_backup_dir/$runtime_plugin_lock_rel_dir/"

  cleanup_apply() {
    local file
    if [[ -z "${apply_backup_dir:-}" || ! -d "$apply_backup_dir" ]]; then
      return
    fi
    if [[ "$apply_success" -ne 1 ]]; then
      for file in "${pin_files[@]}"; do
        cp "$apply_backup_dir/${file#"$repo_root/"}" "$file"
      done
      rm -rf "$runtime_plugin_lock_dir"
      mkdir -p "$runtime_plugin_lock_dir"
      cp -R "$apply_backup_dir/$runtime_plugin_lock_rel_dir/." "$runtime_plugin_lock_dir/"
    fi
    rm -rf "$apply_backup_dir"
    apply_backup_dir=""
  }
  trap cleanup_apply EXIT

  perl -0pi -e 's|  releaseTag = "[^"]+";\n||g; s|  releaseVersion = "[^"]+";\n||g; s|  runtimePluginVersion = "[^"]+";\n||g;' "$source_file"
  perl -0pi -e "s|rev = \"[^\"]+\";|releaseTag = \"${source_tag}\";\n  releaseVersion = \"${source_version}\";\n  runtimePluginVersion = \"${runtime_plugin_version}\";\n  rev = \"${selected_sha}\";|" "$source_file"
  if grep -q 'pnpmMajor = ' "$source_file"; then
    perl -0pi -e "s|pnpmMajor = \"[^\"]+\";|pnpmMajor = \"${selected_pnpm_major}\";|" "$source_file"
  else
    perl -0pi -e "s|releaseVersion = \"[^\"]+\";|releaseVersion = \"${source_version}\";\n  pnpmMajor = \"${selected_pnpm_major}\";|" "$source_file"
  fi
  set_source_public_surface_hardlinks_patch "$public_surface_hardlinks_patch"
  set_source_skip_plugin_auto_enable_nix_mode_patch "$apply_skip_plugin_auto_enable_patch"
  perl -0pi -e "s|hash = \"[^\"]+\";|hash = \"${source_hash}\";|" "$source_file"
  set_gateway_npm_deps_hash "$npm_fake_hash"

  if [[ -n "${app_version:-}" ]]; then
    perl -0pi -e "s|version = \"[^\"]+\";|version = \"${app_version}\";|" "$app_file"
    perl -0pi -e "s|url = \"[^\"]+\";|url = \"${app_url}\";|" "$app_file"
    perl -0pi -e "s|hash = \"[^\"]+\";|hash = \"${app_hash}\";|" "$app_file"
  fi

  refresh_npm_wrapper_locks "$source_version"
  refresh_runtime_plugin_locks
  validate_runtime_plugin_locks
  refresh_npm_hash "openclaw-gateway" set_gateway_npm_deps_hash "OpenClaw gateway"
  regenerate_config_options "$selected_sha" "$source_store_path" "$selected_pnpm_major"

  apply_success=1
}

mode="${1:-}"
case "$mode" in
  files)
    [[ $# -eq 1 ]] || { usage; exit 1; }
    pin_file_paths
    ;;
  select)
    [[ $# -eq 1 ]] || { usage; exit 1; }
    require_cmds jq gh node
    select_release
    ;;
  apply)
    [[ $# -eq 5 ]] || { usage; exit 1; }
    require_cmds jq nix node perl unzip find
    apply_release "$2" "$3" "$4" "$5"
    ;;
  *) usage; exit 1 ;;
esac
