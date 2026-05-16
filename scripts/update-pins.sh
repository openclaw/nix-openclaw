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

log() {
  printf '>> %s\n' "$*" >&2
}

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/update-pins.sh select
  scripts/update-pins.sh apply <source_tag> <source_sha> <app_tag> <app_url>
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "$1 is required but not installed." >&2
    exit 1
  fi
}

current_field() {
  local file="$1"
  local key="$2"
  awk -F'"' -v key="$key" '$0 ~ key" =" { print $2; exit }' "$file"
}

resolve_release_tag_sha() {
  local tag="$1"
  local tag_refs
  tag_refs=$(git ls-remote https://github.com/openclaw/openclaw.git "refs/tags/${tag}" "refs/tags/${tag}^{}" || true)
  if [[ -z "$tag_refs" ]]; then
    echo ""
    return 0
  fi

  local deref_sha plain_sha
  deref_sha=$(printf '%s\n' "$tag_refs" | awk '/\^\{\}$/ { print $1; exit }')
  if [[ -n "$deref_sha" ]]; then
    printf '%s\n' "$deref_sha"
    return 0
  fi

  plain_sha=$(printf '%s\n' "$tag_refs" | awk '!/\^\{\}$/ { print $1; exit }')
  printf '%s\n' "$plain_sha"
}

prefetch_json() {
  local url="$1"
  nix --extra-experimental-features "nix-command flakes" store prefetch-file --unpack --json "$url"
}

prefetch_file_json() {
  local url="$1"
  nix --extra-experimental-features "nix-command flakes" store prefetch-file --json "$url"
}

unpacked_zip_hash() {
  local url="$1"
  local archive_prefetch archive_path unpack_dir app_list app_count app_path app_hash

  archive_prefetch=$(prefetch_file_json "$url")
  archive_path=$(printf '%s' "$archive_prefetch" | jq -r '.path // .storePath // empty')
  if [[ -z "$archive_path" || ! -f "$archive_path" ]]; then
    echo "Failed to prefetch app archive for $url" >&2
    return 1
  fi

  unpack_dir=$(mktemp -d)
  if ! unzip -q "$archive_path" -d "$unpack_dir"; then
    rm -rf "$unpack_dir"
    echo "Failed to unzip app archive: $archive_path" >&2
    return 1
  fi

  app_list=$(find "$unpack_dir" -maxdepth 3 -type d -name '*.app' -print)
  app_count=$(printf '%s\n' "$app_list" | sed '/^$/d' | wc -l | tr -d ' ')
  if [[ "$app_count" != "1" ]]; then
    rm -rf "$unpack_dir"
    echo "Expected exactly one .app in app archive; found $app_count" >&2
    return 1
  fi

  app_path=$(printf '%s\n' "$app_list" | sed -n '1p')
  if [[ ! -d "$app_path/Contents" ]]; then
    rm -rf "$unpack_dir"
    echo "App archive contains an invalid app bundle: $app_path" >&2
    return 1
  fi

  if ! app_hash=$(nix --extra-experimental-features "nix-command flakes" hash path "$unpack_dir"); then
    rm -rf "$unpack_dir"
    echo "Failed to hash unpacked app archive: $archive_path" >&2
    return 1
  fi
  rm -rf "$unpack_dir"
  printf '%s\n' "$app_hash"
}

refresh_pnpm_hash() {
  local build_log pnpm_hash
  build_log=$(mktemp)
  if ! nix build .#openclaw-gateway --accept-flake-config >"$build_log" 2>&1; then
    pnpm_hash=$(grep -Eo 'got: *sha256-[A-Za-z0-9+/=]+' "$build_log" | head -n 1 | sed 's/.*got: *//' || true)
    if [[ -z "$pnpm_hash" ]]; then
      tail -n 200 "$build_log" >&2 || true
      rm -f "$build_log"
      return 1
    fi
    log "pnpmDepsHash mismatch detected: $pnpm_hash"
    perl -0pi -e "s|pnpmDepsHash = \"[^\"]*\";|pnpmDepsHash = \"${pnpm_hash}\";|" "$source_file"
    nix build .#openclaw-gateway --accept-flake-config >"$build_log" 2>&1 || {
      tail -n 200 "$build_log" >&2 || true
      rm -f "$build_log"
      return 1
    }
  fi
  rm -f "$build_log"
}

source_pnpm_major() {
  local source_path="$1"
  local package_manager major
  package_manager=$(jq -r '.packageManager // empty' "$source_path/package.json")
  if [[ "$package_manager" =~ ^pnpm@([0-9]+)\. ]]; then
    major="${BASH_REMATCH[1]}"
  else
    echo "Failed to resolve pnpm major from packageManager in $source_path/package.json" >&2
    return 1
  fi

  case "$major" in
    10 | 11)
      printf '%s\n' "$major"
      ;;
    *)
      echo "Unsupported OpenClaw pnpm major $major from $package_manager" >&2
      return 1
      ;;
  esac
}

pnpm_shell_package() {
  local major="$1"
  case "$major" in
    10)
      printf '%s\n' "nixpkgs#pnpm_10"
      ;;
    11)
      printf '%s\n' "$repo_root#pnpm_11"
      ;;
    *)
      echo "Unsupported OpenClaw pnpm major $major" >&2
      return 1
      ;;
  esac
}

regenerate_config_options() {
  local selected_sha="$1"
  local source_store_path="$2"
  local pnpm_major="$3"
  local pnpm_pkg
  local tmp_src
  tmp_src=$(mktemp -d)

  if [[ -d "$source_store_path" ]]; then
    cp -R "$source_store_path" "$tmp_src/src"
  elif [[ -f "$source_store_path" ]]; then
    mkdir -p "$tmp_src/src"
    tar -xf "$source_store_path" -C "$tmp_src/src" --strip-components=1
  else
    echo "Source path not found: $source_store_path" >&2
    rm -rf "$tmp_src"
    exit 1
  fi

  chmod -R u+w "$tmp_src/src"
  pnpm_pkg=$(pnpm_shell_package "$pnpm_major")

  nix shell --extra-experimental-features "nix-command flakes" --accept-flake-config --inputs-from "$repo_root" \
    nixpkgs#nodejs_22 "$pnpm_pkg" -c \
    bash -c "cd '$tmp_src/src' && PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS=false pnpm install --frozen-lockfile --ignore-scripts"

  nix shell --extra-experimental-features "nix-command flakes" --accept-flake-config --inputs-from "$repo_root" \
    nixpkgs#nodejs_22 "$pnpm_pkg" -c \
    bash -c "cd '$tmp_src/src' && PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS=false OPENCLAW_SCHEMA_REV='${selected_sha}' pnpm exec tsx '$repo_root/nix/scripts/generate-config-options.ts' --repo . --out '$config_options_file'"

  rm -rf "$tmp_src"
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
  local source_version source_url source_prefetch source_hash source_store_path selected_pnpm_major app_version app_hash
  local backup_dir success

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

  backup_dir=$(mktemp -d)
  success=0
  cp "$source_file" "$backup_dir/source.nix"
  cp "$app_file" "$backup_dir/app.nix"
  cp "$config_options_file" "$backup_dir/config-options.nix"

  cleanup_apply() {
    if [[ "$success" -ne 1 ]]; then
      cp "$backup_dir/source.nix" "$source_file"
      cp "$backup_dir/app.nix" "$app_file"
      cp "$backup_dir/config-options.nix" "$config_options_file"
    fi
    rm -rf "$backup_dir"
  }
  trap cleanup_apply RETURN

  perl -0pi -e 's|  releaseTag = "[^"]+";\n||g; s|  releaseVersion = "[^"]+";\n||g;' "$source_file"
  perl -0pi -e "s|rev = \"[^\"]+\";|releaseTag = \"${source_tag}\";\n  releaseVersion = \"${source_version}\";\n  rev = \"${selected_sha}\";|" "$source_file"
  if grep -q 'pnpmMajor = ' "$source_file"; then
    perl -0pi -e "s|pnpmMajor = \"[^\"]+\";|pnpmMajor = \"${selected_pnpm_major}\";|" "$source_file"
  else
    perl -0pi -e "s|releaseVersion = \"[^\"]+\";|releaseVersion = \"${source_version}\";\n  pnpmMajor = \"${selected_pnpm_major}\";|" "$source_file"
  fi
  perl -0pi -e "s|hash = \"[^\"]+\";|hash = \"${source_hash}\";|" "$source_file"
  perl -0pi -e 's|pnpmDepsHash = "[^"]*";|pnpmDepsHash = "";|' "$source_file"

  if [[ -n "${app_version:-}" ]]; then
    perl -0pi -e "s|version = \"[^\"]+\";|version = \"${app_version}\";|" "$app_file"
    perl -0pi -e "s|url = \"[^\"]+\";|url = \"${app_url}\";|" "$app_file"
    perl -0pi -e "s|hash = \"[^\"]+\";|hash = \"${app_hash}\";|" "$app_file"
  fi

  refresh_pnpm_hash
  regenerate_config_options "$selected_sha" "$source_store_path" "$selected_pnpm_major"

  success=1
}

mode="${1:-}"
case "$mode" in
  select)
    if [[ $# -ne 1 ]]; then
      usage
      exit 1
    fi
    require_cmd jq
    require_cmd gh
    require_cmd node
    select_release
    ;;
  apply)
    if [[ $# -ne 5 ]]; then
      usage
      exit 1
    fi
    require_cmd jq
    require_cmd nix
    require_cmd perl
    require_cmd unzip
    require_cmd find
    apply_release "$2" "$3" "$4" "$5"
    ;;
  *)
    usage
    exit 1
    ;;
esac
