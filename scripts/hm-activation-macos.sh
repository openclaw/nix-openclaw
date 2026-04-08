#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir="$repo_root/nix/tests/hm-activation-macos"
home_dir="/tmp/hm-activation-home"
root_metadata_json="$(mktemp)"

rm -rf "$home_dir"
mkdir -p "$home_dir"

export HOME="$home_dir"
export USER="runner"
export LOGNAME="runner"

mkdir -p "$HOME/Library/LaunchAgents"

# Free the rooted result from the prior Darwin build before the activation build.
rm -f "$repo_root/result" "$test_dir/result"
nix store gc >/dev/null 2>&1 || true

cd "$test_dir"

trap 'rm -f "$root_metadata_json"' EXIT
nix flake metadata --json "$repo_root" >"$root_metadata_json"

nixpkgs_ref="$(
  jq -r '.locks.nodes.nixpkgs.locked | "github:\(.owner)/\(.repo)/\(.rev)"' "$root_metadata_json"
)"
home_manager_ref="$(
  jq -r '.locks.nodes["home-manager"].locked | "github:\(.owner)/\(.repo)/\(.rev)"' "$root_metadata_json"
)"

nix build --accept-flake-config --impure \
  --override-input nixpkgs "$nixpkgs_ref" \
  --override-input home-manager "$home_manager_ref" \
  --override-input nix-openclaw "path:$repo_root" \
  .#homeConfigurations.hm-test.activationPackage

./result/activate

test -f "$HOME/.openclaw/openclaw.json"

if command -v launchctl >/dev/null 2>&1; then
  launchctl print "gui/$UID/com.steipete.openclaw.gateway" >/dev/null 2>&1
fi
