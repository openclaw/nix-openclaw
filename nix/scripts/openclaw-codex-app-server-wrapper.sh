#!/bin/sh
set -eu

if [ -n "${CODEX_HOME:-}" ]; then
  HOME="${CODEX_HOME}/home"
  export HOME
  "@mkdirBin@" -p "$HOME"
  PATH="$HOME/.nix-profile/bin:${PATH:-}"
  export PATH
fi

exec "@codexAppServerBin@" "$@"
