#!/bin/sh
set -eu
# pnpm 11+ prepends a separate toolchain lock; the workspace lock is last.
exec yq -rs 'last | (.packages // {}) | to_entries[] | select(.value.resolution.integrity) | [.key, .value.resolution.integrity] | @tsv' "${1:-pnpm-lock.yaml}"
