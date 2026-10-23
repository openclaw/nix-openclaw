#!/usr/bin/env bash
set -euo pipefail
. "$STDENV_SETUP"

runHook preInstallCheck
"$out/bin/node" "$NODE_RUNTIME_CHECK"
runHook postInstallCheck
