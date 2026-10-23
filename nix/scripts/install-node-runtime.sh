#!/usr/bin/env bash
set -euo pipefail
. "$STDENV_SETUP"

runHook preInstall
mkdir -p "$out"
cp -a bin include lib share "$out/"
# npm and Corepack must use this runtime, including after Nix patches the ELF loader.
HOST_PATH="$out/bin:${HOST_PATH:-}" patchShebangs --host "$out"
runHook postInstall
