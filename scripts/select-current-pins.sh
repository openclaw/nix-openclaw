#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
metadata=$("$repo_root/scripts/publish-release-tag.sh" check)
field() {
  awk -F= -v key="$1" '$1 == key { print substr($0, length(key) + 2); exit }' <<<"$metadata"
}

# Drive the usual platform validation with the committed pins, without selecting
# a new upstream version or materializing a release update.
printf 'has_update=true\n'
printf 'source_tag=%s\n' "$(field tag)"
printf 'source_sha=%s\n' "$(field source_rev)"
printf 'source_version=%s\n' "$(field source_version)"
printf 'app_tag=v%s\n' "$(field app_version)"
printf 'app_version=%s\n' "$(field app_version)"
printf 'app_url=%s\n' "$(awk -F'"' '/url =/ { print $2; exit }' "$repo_root/nix/packages/openclaw-app.nix")"
