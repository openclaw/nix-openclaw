#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
app_out=$(nix build --accept-flake-config --no-link --print-out-paths "$repo_root#openclaw-app")
source_out=$(nix build --accept-flake-config --no-link --print-out-paths "$repo_root#openclaw-app.src")
upstream_app=$(find "$source_out" -mindepth 1 -maxdepth 2 -type d -name '*.app' ! -path '*/__MACOSX/*' -print -quit)
if [[ -z "$upstream_app" ]]; then
  echo "OpenClaw.app not found in pinned source: $source_out" >&2
  exit 1
fi
installed_app="$app_out/Applications/OpenClaw.app"

# Nix may normalize metadata, but must preserve signed bytes and symlink targets.
nix shell --option flake-registry '' --inputs-from "$repo_root" nixpkgs#diffutils \
  --command diff --recursive --brief --no-dereference -- "$upstream_app" "$installed_app"
/usr/bin/codesign --verify --deep --strict --all-architectures \
  --test-requirement='=anchor apple generic' "$installed_app"
executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$installed_app/Contents/Info.plist")
/usr/bin/lipo -verify_arch arm64 x86_64 "$installed_app/Contents/MacOS/$executable"

echo "Installed OpenClaw.app preserves the pinned bundle, Apple signature, and arm64/x86_64 slices."
