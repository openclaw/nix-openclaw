#!/bin/sh

store_path_file="${PNPM_STORE_PATH_FILE:-.pnpm-store-path}"
store_path="$(cat "$store_path_file")"
export PNPM_CONFIG_STORE_DIR="$store_path"
export PNPM_CONFIG_CACHE_DIR="$PWD/.pnpm-cache"
export PNPM_CONFIG_OFFLINE=true
export NPM_CONFIG_OFFLINE=true
export PNPM_STORE_DIR="$store_path"
export PNPM_STORE_PATH="$store_path"
export NPM_CONFIG_STORE_DIR="$store_path"
export NPM_CONFIG_STORE_PATH="$store_path"
