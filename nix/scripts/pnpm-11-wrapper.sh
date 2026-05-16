#!/bin/sh
set -eu

case "$0" in
  */pnpm | pnpm)
    if [ "${1:-}" = "config" ] && [ "${2:-}" = "set" ] && [ "${3:-}" = "manage-package-manager-versions" ]; then
      exit 0
    fi
    ;;
esac

exec @node@ @entrypoint@ "$@"
