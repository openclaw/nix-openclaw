#!/bin/sh
# Sourced by fetchPnpmDeps under set -e; keep getter failures fatal.
# pnpm 12 treats the fetcher's empty --registry argument as "/".
NIX_NPM_REGISTRY="${NIX_NPM_REGISTRY:-$(pnpm config get registry)}"
