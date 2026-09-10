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
  store="$tmp_dir/pnpm-$major/store"
  export PNPM_CONFIG_STORE_DIR="$store"
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

    rm -rf node_modules package
    # pnpm 11 checks local tarball bytes before reusing its cached index.
    # pnpm 12 can prove the stronger offline case with the tarball absent.
    if [ "$major" != 11 ]; then
      rm fixture.tgz
    fi
    export HOME="$tmp_dir/pnpm-$major/intact-home"
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_DATA_HOME="$HOME/data"
    mkdir -p "$HOME"
    "$pnpm" install --frozen-lockfile --offline --ignore-scripts
    "$pnpm" exec node -e 'if (require("openclaw-pnpm-fixture") !== "offline-install-ok") process.exit(1)'
    cmp expected-lock.yaml pnpm-lock.yaml
    rm -rf node_modules
    echo "pnpm $version: intact-index offline control passed"

    index_query='SELECT quote(key), hex(data) FROM package_index ORDER BY key;'
    expected_index="$tmp_dir/pnpm-$major/expected-index"
    sqlite3 "$store/v11/index.db" "$index_query" > "$expected_index"
    test -s "$expected_index"

    # The no-dump case exercises consumer passthrough, not a pnpm 11/12 v3 producer.
    for archive_kind in no-dump sql-dump; do
      deps="$tmp_dir/pnpm-$major/$archive_kind-deps"
      mkdir -p "$deps"
      if [ "$archive_kind" = sql-dump ]; then
        sqlite3 "$store/v11/index.db" .dump > "$store/v11/index.db.sql"
        rm "$store/v11/index.db"
        printf '4\n' > "$deps/.fetcher-version"
      else
        printf '3\n' > "$deps/.fetcher-version"
      fi
      tar -cf "$deps/pnpm-store.tar" -C "$store" .
      zstd -q --rm "$deps/pnpm-store.tar"
    done

    for archive_kind in no-dump sql-dump; do
      case_root="$tmp_dir/pnpm-$major/$archive_kind"
      mkdir -p "$case_root/project" "$case_root/build-top" "$case_root/home"
      cp package.json pnpm-lock.yaml expected-lock.yaml "$case_root/project/"
      if [ -f fixture.tgz ]; then
        cp fixture.tgz "$case_root/project/"
      fi
      (
        export HOME="$case_root/home"
        export XDG_CONFIG_HOME="$HOME/config"
        export XDG_CACHE_HOME="$HOME/cache"
        export XDG_DATA_HOME="$HOME/data"
        export NIX_BUILD_TOP="$case_root/build-top"
        export out="$case_root/out"
        export PNPM_DEPS="$tmp_dir/pnpm-$major/$archive_kind-deps"
        cd "$case_root/project"
        echo "pnpm $version: $archive_kind prebuild roundtrip"
        . "$GATEWAY_PREBUILD_SH"
        test "$PWD" = "$NIX_BUILD_TOP/.openclaw-build"
        store_path="$(cat .pnpm-store-path)"
        export PNPM_CONFIG_STORE_DIR="$store_path"
        test -f "$store_path/v11/index.db"
        sqlite3 "$store_path/v11/index.db" "$index_query" > "$case_root/actual-index"
        cmp "$expected_index" "$case_root/actual-index"
        test ! -f "$store_path/v11/index.db.sql"
        "$pnpm" install --frozen-lockfile --offline --ignore-scripts --store-dir "$store_path"
        "$pnpm" exec node -e 'if (require("openclaw-pnpm-fixture") !== "offline-install-ok") process.exit(1)'
        cmp expected-lock.yaml pnpm-lock.yaml

        node -e 'const fs = require("node:fs"); const p = JSON.parse(fs.readFileSync("package.json")); p.dependencies["missing-from-lock"] = "1.0.0"; fs.writeFileSync("package.json", JSON.stringify(p));'
        if "$pnpm" install --frozen-lockfile --offline --ignore-scripts --store-dir "$store_path" > frozen-failure.log 2>&1; then
          echo "pnpm $version accepted a manifest that disagrees with its frozen lockfile" >&2
          exit 1
        fi
        grep -q 'ERR_PNPM_OUTDATED_LOCKFILE' frozen-failure.log
        cmp expected-lock.yaml pnpm-lock.yaml
        echo "pnpm $version: $archive_kind index, execution, lockfile, and frozen rejection passed"
      )
    done
  )
  echo "pnpm $version: baseline, intact-index control, and both prebuild roundtrips passed"
done

node "$CHECK_PNPM_REGISTRY"
