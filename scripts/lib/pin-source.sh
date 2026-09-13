# Sourced by update-pins.sh after its repository paths are initialized.

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

unpacked_zip_hash() {
  local url="$1"
  local archive_prefetch archive_path unpack_dir app_list app_count app_path app_hash

  archive_prefetch=$(nix --extra-experimental-features "nix-command flakes" store prefetch-file --json "$url")
  archive_path=$(printf '%s' "$archive_prefetch" | jq -r '.path // .storePath // empty')
  if [[ -z "$archive_path" || ! -f "$archive_path" ]]; then
    echo "Failed to prefetch app archive for $url" >&2
    return 1
  fi

  unpack_dir=$(mktemp -d)
  fail_zip() { rm -rf "$unpack_dir"; echo "$1" >&2; }

  if ! unzip -q "$archive_path" -d "$unpack_dir"; then
    fail_zip "Failed to unzip app archive: $archive_path"
    return 1
  fi

  app_list=$(find "$unpack_dir" -maxdepth 3 -type d -name '*.app' ! -path "$unpack_dir/__MACOSX/*" -print)
  app_count=$(printf '%s\n' "$app_list" | sed '/^$/d' | wc -l | tr -d ' ')
  if [[ "$app_count" != "1" ]]; then
    fail_zip "Expected exactly one .app in app archive; found $app_count"
    return 1
  fi

  app_path=$(printf '%s\n' "$app_list" | sed -n '1p')
  if [[ ! -d "$app_path/Contents" ]]; then
    fail_zip "App archive contains an invalid app bundle: $app_path"
    return 1
  fi

  if ! app_hash=$(nix --extra-experimental-features "nix-command flakes" hash path "$unpack_dir"); then
    fail_zip "Failed to hash unpacked app archive: $archive_path"
    return 1
  fi
  rm -rf "$unpack_dir"
  printf '%s\n' "$app_hash"
}

source_pnpm_major() {
  local source_path="$1"
  local package_manager major
  package_manager=$(jq -r '.packageManager // empty' "$source_path/package.json")

  if [[ ! "$package_manager" =~ ^pnpm@([0-9]+)\. ]]; then
    echo "Failed to resolve pnpm major from packageManager in $source_path/package.json" >&2
    return 1
  fi
  major="${BASH_REMATCH[1]}"

  case "$major" in
    10 | 11 | 12) printf '%s\n' "$major" ;;
    *)
      echo "Unsupported OpenClaw pnpm major $major from $package_manager" >&2
      return 1
      ;;
  esac
}

source_runtime_plugin_version() {
  local source_path="$1"
  local release_version="$2"
  node "$runtime_plugin_version_resolver" "$release_version" "$source_path/package.json"
}

pnpm_shell_package() {
  local major="$1"
  case "$major" in
    10) printf '%s\n' "nixpkgs#pnpm_10" ;;
    11) printf '%s\n' "$repo_root#pnpm_11" ;;
    12) printf '%s\n' "$repo_root#pnpm_12" ;;
    *)
      echo "Unsupported OpenClaw pnpm major $major" >&2
      return 1
      ;;
  esac
}

source_public_surface_hardlinks_patch() {
  local source_path="$1"
  local loader="$source_path/src/plugins/public-surface-loader.ts"

  if [[ -f "$loader" ]] && grep -q 'rejectHardlinks: true' "$loader"; then
    printf '%s\n' "../patches/allow-package-public-surface-hardlinks-open-root.patch"
    return 0
  fi
  printf '%s\n' ""
}

set_source_public_surface_hardlinks_patch() {
  local patch_path="$1"
  perl -0pi -e 's|  applyPublicSurfaceHardlinksPatch = [^;]+;\n||g; s|  publicSurfaceHardlinksPatch = [^;]+;\n||g' "$source_file"

  if [[ -n "$patch_path" ]]; then
    perl -0pi -e "s|pnpmMajor = \"([^\"]+)\";|pnpmMajor = \"\$1\";\n  applyPublicSurfaceHardlinksPatch = true;\n  publicSurfaceHardlinksPatch = ${patch_path};|" "$source_file"
  else
    perl -0pi -e "s|pnpmMajor = \"([^\"]+)\";|pnpmMajor = \"\$1\";\n  applyPublicSurfaceHardlinksPatch = false;|" "$source_file"
  fi
}

source_needs_skip_plugin_auto_enable_nix_mode_patch() {
  local source_path="$1"
  local startup_config="$source_path/src/gateway/server-startup-config.ts"

  if [[ ! -f "$startup_config" ]] || grep -q 'replaceConfigFile' "$startup_config"; then
    printf '%s\n' "true"
  else
    printf '%s\n' "false"
  fi
}

set_source_skip_plugin_auto_enable_nix_mode_patch() {
  local enabled="$1"
  if [[ "$enabled" == "false" ]]; then
    if grep -q 'applySkipPluginAutoEnableNixModePatch = ' "$source_file"; then
      perl -0pi -e 's|applySkipPluginAutoEnableNixModePatch = [^;]+;|applySkipPluginAutoEnableNixModePatch = false;|' "$source_file"
    elif grep -q 'publicSurfaceHardlinksPatch = ' "$source_file"; then
      perl -0pi -e 's|publicSurfaceHardlinksPatch = ([^;]+);|publicSurfaceHardlinksPatch = $1;\n  applySkipPluginAutoEnableNixModePatch = false;|' "$source_file"
    else
      perl -0pi -e 's|pnpmMajor = "([^"]+)";|pnpmMajor = "$1";\n  applySkipPluginAutoEnableNixModePatch = false;|' "$source_file"
    fi
  else
    perl -0pi -e 's|  applySkipPluginAutoEnableNixModePatch = [^;]+;\n||g' "$source_file"
  fi
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
    nixpkgs#nodejs_24 "$pnpm_pkg" -c \
    bash -c "cd '$tmp_src/src' && PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS=false pnpm install --frozen-lockfile --ignore-scripts"

  nix shell --extra-experimental-features "nix-command flakes" --accept-flake-config --inputs-from "$repo_root" \
    nixpkgs#nodejs_24 "$pnpm_pkg" -c \
    bash -c "cd '$tmp_src/src' && PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS=false OPENCLAW_SCHEMA_REV='${selected_sha}' pnpm exec tsx '$repo_root/nix/scripts/generate-config-options.ts' --repo . --out '$config_options_file'"

  rm -rf "$tmp_src"
}
