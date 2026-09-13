#!/bin/sh
set -e
if [ -f package.json ]; then
  "$REMOVE_PACKAGE_MANAGER_FIELD_SH" package.json
fi

if [ -n "${PATCH_PUBLIC_SURFACE_HARDLINKS:-}" ]; then
  patch -p1 < "$PATCH_PUBLIC_SURFACE_HARDLINKS"
fi

if [ -n "${PATCH_SKIP_PLUGIN_AUTO_ENABLE_NIX_MODE:-}" ]; then
  patch -p1 < "$PATCH_SKIP_PLUGIN_AUTO_ENABLE_NIX_MODE"
fi

if [ -n "${PATCH_NIX_STORE_PLUGIN_OWNERSHIP:-}" ]; then
  patch -p1 < "$PATCH_NIX_STORE_PLUGIN_OWNERSHIP"
fi

if [ -f src/logging/logger.ts ]; then
  if ! grep -q "OPENCLAW_LOG_DIR" src/logging/logger.ts; then
    sed -i 's/export const DEFAULT_LOG_DIR = "\/tmp\/openclaw";/export const DEFAULT_LOG_DIR = process.env.OPENCLAW_LOG_DIR ?? "\/tmp\/openclaw";/' src/logging/logger.ts
  fi
fi

if [ -f src/agents/shell-utils.ts ]; then
  if ! grep -q "envShell" src/agents/shell-utils.ts; then
    awk '
      /import { spawn } from "node:child_process";/ {
        print;
        print "import { existsSync } from \"node:fs\";";
        next;
      }
      /const shell = process.env.SHELL/ {
        print "  const envShell = process.env.SHELL?.trim();";
        print "  const shell =";
        print "    envShell && envShell.startsWith(\"/\") && !existsSync(envShell)";
        print "      ? \"sh\"";
        print "      : envShell || \"sh\";";
        next;
      }
      { print }
    ' src/agents/shell-utils.ts > src/agents/shell-utils.ts.next
    mv src/agents/shell-utils.ts.next src/agents/shell-utils.ts
  fi
fi
