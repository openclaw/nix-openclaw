#!/bin/sh
set -eu

# OpenClaw sets CODEX_HOME only for the managed Codex app-server process. When
# this wrapper is run outside that lifecycle, it should behave like plain Codex
# and leave HOME/PATH untouched.
if [ -n "${CODEX_HOME:-}" ]; then
  # Upstream OpenClaw's isolated native home is $CODEX_HOME/home. Point HOME
  # there so Codex-native command/exec reads the same profile that this Nix
  # launcher manages below.
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
          echo "Refusing to replace existing Codex native-home bin symlink: $profile_bin -> $current_target" >&2
          exit 1
          ;;
      esac
    fi
  fi

  if [ -e "$profile_bin" ] && [ ! -L "$profile_bin" ]; then
    echo "Refusing to replace existing non-symlink at Codex native-home bin path: $profile_bin" >&2
    exit 1
  fi

  if [ ! -e "$profile_bin" ]; then
    "@lnBin@" -s "@runtimeProfileBinDir@" "$profile_bin"
  fi

  if [ -n "${PATH:-}" ]; then
    PATH="$profile_bin:$PATH"
  else
    PATH="$profile_bin"
  fi
  export PATH
fi

exec "@codexAppServerBin@" "$@"
