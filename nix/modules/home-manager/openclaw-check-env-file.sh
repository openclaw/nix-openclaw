#!/usr/bin/env bash
set -euo pipefail

key="$1"
file="$2"
plugin="$3"
instance="$4"
if [[ -z "$file" ]]; then
  printf 'Missing env %s for plugin %s in instance %s.\n' "$key" "$plugin" "$instance" >&2
  exit 1
fi
if [[ ! -f "$file" || ! -s "$file" ]]; then
  printf 'Required file for %s not found or empty: %s (plugin %s, instance %s).\n' "$key" "$file" "$plugin" "$instance" >&2
  exit 1
fi
