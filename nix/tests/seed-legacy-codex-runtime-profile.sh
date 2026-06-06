#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 LEGACY_PROFILE_BIN" >&2
  exit 2
fi

legacy_profile="$1"
mkdir -p "$(dirname "$legacy_profile")"
ln -sfn /tmp/legacy-openclaw-runtime-profile-bin "$legacy_profile"
