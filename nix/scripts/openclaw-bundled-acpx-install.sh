#!/bin/sh
set -eu

if [ -z "${out:-}" ]; then
  echo "out is not set" >&2
  exit 1
fi

package_root="node_modules/@openclaw/acpx"
if [ ! -d "$package_root" ]; then
  echo "ACPX npm package root missing: $package_root" >&2
  exit 1
fi

mkdir -p "$out"
cp -R "$package_root/." "$out/"
