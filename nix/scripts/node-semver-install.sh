#!/bin/sh
set -eu
mkdir -p "$out/lib/node_modules/semver" "$out/bin"
cp -R . "$out/lib/node_modules/semver/"
bash -e -c '. "$stdenv/setup"; makeWrapper "$NODE_BIN" "$out/bin/node-semver" --add-flags "$out/lib/node_modules/semver/bin/semver.js"'
