#!/bin/sh
set -e
if [ -f package.json ]; then
  "$REMOVE_PACKAGE_MANAGER_FIELD_SH" package.json
fi

if [ -n "${PATCH_BUNDLED_RUNTIME_DEPS_SCRIPT:-}" ] && [ -f scripts/stage-bundled-plugin-runtime-deps.mjs ]; then
  cp "$PATCH_BUNDLED_RUNTIME_DEPS_SCRIPT" scripts/stage-bundled-plugin-runtime-deps.mjs
  chmod u+w scripts/stage-bundled-plugin-runtime-deps.mjs
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

if [ -f src/docker-setup.test.ts ]; then
  if ! grep -q "#!/bin/sh" src/docker-setup.test.ts; then
    sed -i 's|#!/usr/bin/env bash|#!/bin/sh|' src/docker-setup.test.ts
    sed -i 's/set -euo pipefail/set -eu/' src/docker-setup.test.ts
    sed -i 's|if \[\[ "${1:-}" == "compose" && "${2:-}" == "version" \]\]; then|if [ "${1:-}" = "compose" ] && [ "${2:-}" = "version" ]; then|' src/docker-setup.test.ts
    sed -i 's|if \[\[ "${1:-}" == "build" \]\]; then|if [ "${1:-}" = "build" ]; then|' src/docker-setup.test.ts
    sed -i 's|if \[\[ "${1:-}" == "compose" \]\]; then|if [ "${1:-}" = "compose" ]; then|' src/docker-setup.test.ts
  fi
fi

if [ -f src/gateway/test-helpers.server.ts ]; then
  if ! grep -q 'OPENCLAW_DISABLE_BUNDLED_PLUGINS = "1"' src/gateway/test-helpers.server.ts; then
    python3 - <<'PY'
from pathlib import Path
path = Path("src/gateway/test-helpers.server.ts")
text = path.read_text()
needle = '  process.env.OPENCLAW_SKIP_PROVIDERS = "1";\n'
replacement = (
    '  process.env.OPENCLAW_SKIP_PROVIDERS = "1";\n'
    '  process.env.OPENCLAW_DISABLE_BUNDLED_PLUGINS = "1";\n'
    '  process.env.OPENCLAW_DISABLE_PLUGIN_DISCOVERY_CACHE = "1";\n'
    '  process.env.OPENCLAW_DISABLE_PLUGIN_MANIFEST_CACHE = "1";\n'
)
if needle not in text:
    raise SystemExit("gateway test skip env marker not found")
path.write_text(text.replace(needle, replacement, 1))
PY
  fi
fi
