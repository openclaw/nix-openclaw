#!/usr/bin/env bash
set -euo pipefail

manifest=$1

while IFS=$'\t' read -r profile_dir bin_dir; do
  [ -n "$profile_dir" ] || continue

  mkdir -p "$profile_dir"

  link="$profile_dir/bin"
  if [ -L "$link" ]; then
    rm "$link"
  fi

  if [ -e "$link" ]; then
    echo "Refusing to replace non-symlink Codex runtime bin: $link" >&2
    exit 1
  fi

  ln -s "$bin_dir" "$link"
done < "$manifest"
