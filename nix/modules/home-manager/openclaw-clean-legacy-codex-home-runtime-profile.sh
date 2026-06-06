#!/usr/bin/env bash
set -euo pipefail

for state_dir in "$@"; do
  if [ ! -d "$state_dir/agents" ]; then
    continue
  fi

  for bin_path in "$state_dir"/agents/*/agent/codex-home/home/.nix-profile/bin; do
    if [ ! -e "$bin_path" ] && [ ! -L "$bin_path" ]; then
      continue
    fi

    if [ -L "$bin_path" ]; then
      rm -f "$bin_path"
    fi
  done
done
