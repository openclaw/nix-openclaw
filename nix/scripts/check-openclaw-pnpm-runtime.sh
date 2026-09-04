#!/bin/sh
set -eu

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

for pnpm_package in "$PNPM_11_PACKAGE" "$PNPM_12_PACKAGE"; do
  pnpm="$pnpm_package/bin/pnpm"
  version="$("$pnpm" --version)"
  major="${version%%.*}"
  project="$tmp_dir/pnpm-$major/project with spaces"
  export HOME="$tmp_dir/pnpm-$major/home"
  export XDG_CONFIG_HOME="$HOME/config"
  export XDG_CACHE_HOME="$HOME/cache"
  export XDG_DATA_HOME="$HOME/data"
  mkdir -p "$project/package" "$HOME"

  cat > "$project/package/package.json" <<'JSON'
{"name":"openclaw-pnpm-fixture","version":"1.0.0","main":"index.js"}
JSON
  printf '%s\n' 'module.exports = "offline-install-ok";' > "$project/package/index.js"
  COPYFILE_DISABLE=1 tar -czf "$project/fixture.tgz" -C "$project" package
  cat > "$project/package.json" <<JSON
{"private":true,"packageManager":"pnpm@$major.99.99","dependencies":{"openclaw-pnpm-fixture":"file:fixture.tgz"}}
JSON

  (
    cd "$project"
    "$pnpm" install --lockfile-only --offline --ignore-scripts
    cp pnpm-lock.yaml expected-lock.yaml
    PNPM_CONFIG_OFFLINE=true "$pnpm" fetch
    "$pnpm" install --frozen-lockfile --offline --ignore-scripts
    "$pnpm" exec node -e 'if (require("openclaw-pnpm-fixture") !== "offline-install-ok") process.exit(1)'
    cmp expected-lock.yaml pnpm-lock.yaml

    node -e 'const fs = require("node:fs"); const p = JSON.parse(fs.readFileSync("package.json")); p.dependencies["missing-from-lock"] = "1.0.0"; fs.writeFileSync("package.json", JSON.stringify(p));'
    if "$pnpm" install --frozen-lockfile --offline --ignore-scripts > frozen-failure.log 2>&1; then
      echo "pnpm $version accepted a manifest that disagrees with its frozen lockfile" >&2
      exit 1
    fi
    grep -q 'ERR_PNPM_OUTDATED_LOCKFILE' frozen-failure.log
    cmp expected-lock.yaml pnpm-lock.yaml
  )
  echo "pnpm $version: offline install, execution, and frozen-lockfile rejection passed"
done
