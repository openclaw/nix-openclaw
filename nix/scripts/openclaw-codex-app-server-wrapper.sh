#!/bin/sh
set -eu

if [ -n "${CODEX_HOME:-}" ]; then
  HOME="${CODEX_HOME}/home"
  export HOME
  profile_dir="$HOME/.nix-profile"
  profile_bin="$profile_dir/bin"
  "@mkdirBin@" -p "$profile_dir"

  if [ -L "$profile_bin" ]; then
    current_target=$("@readlinkBin@" "$profile_bin")
    if [ "$current_target" != "@runtimeProfileBinDir@" ]; then
      case "$current_target" in
        # The Nix Codex launcher owns only store-backed profile-bin symlinks in
        # this isolated native HOME. Anything else may be user-managed state.
        /nix/store/*)
          "@rmBin@" "$profile_bin"
          ;;
        *)
          echo "Refusing to replace non-Nix Codex runtime profile: $profile_bin -> $current_target" >&2
          exit 1
          ;;
      esac
    fi
  fi

  if [ -e "$profile_bin" ] && [ ! -L "$profile_bin" ]; then
    echo "Refusing to replace non-symlink Codex runtime profile: $profile_bin" >&2
    exit 1
  fi

  if [ ! -e "$profile_bin" ]; then
    "@lnBin@" -s "@runtimeProfileBinDir@" "$profile_bin"
  fi

  PATH="$profile_bin:${PATH:-}"
  export PATH
fi

exec "@codexAppServerBin@" "$@"
