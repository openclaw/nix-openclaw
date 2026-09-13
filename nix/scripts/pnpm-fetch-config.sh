#!/bin/sh
# Nixpkgs passes an empty registry override unless the operator supplies one.
# pnpm 12 treats that as an invalid relative URL instead of using npm's registry.
NIX_NPM_REGISTRY="${NIX_NPM_REGISTRY:-https://registry.npmjs.org/}"
export NIX_NPM_REGISTRY
