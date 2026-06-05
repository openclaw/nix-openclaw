#!/bin/sh
set -eu

if [ -z "${OPENCLAW_GATEWAY:-}" ]; then
  echo "OPENCLAW_GATEWAY is not set" >&2
  exit 1
fi

root="${OPENCLAW_GATEWAY}/lib/openclaw"

require_path() {
  if [ ! -e "$1" ]; then
    echo "Missing: $1" >&2
    exit 1
  fi
}

require_path "${root}/extensions"
require_path "${root}/extensions/memory-core"
require_path "${root}/extensions/memory-core/openclaw.plugin.json"
require_path "${root}/dist/extensions/memory-core/openclaw.plugin.json"
require_path "${root}/dist-runtime/extensions"
require_path "${root}/dist-runtime/extensions/memory-core/openclaw.plugin.json"
require_path "${root}/dist-runtime/extensions/acpx/openclaw.plugin.json"
require_path "${root}/dist-runtime/extensions/acpx/package.json"
require_path "${root}/dist-runtime/extensions/acpx/index.js"
require_path "${root}/dist-runtime/extensions/acpx/register.runtime.js"
require_path "${root}/dist-runtime/extensions/acpx/runtime-api.js"
require_path "${root}/dist-runtime/extensions/acpx/setup-api.js"
require_path "${root}/dist-runtime/extensions/acpx/skills/acp-router/SKILL.md"
require_path "${root}/docs/reference/templates"
require_path "${root}/docs/reference/templates/AGENTS.md"
require_path "${root}/docs/reference/templates/SOUL.md"
require_path "${root}/docs/reference/templates/TOOLS.md"
if [ "${OPENCLAW_REQUIRE_AGENT_WORKSPACE_TEMPLATES:-1}" = "1" ]; then
  require_path "${root}/src/agents/templates/HEARTBEAT.md"
fi
require_path "${root}/skills"
if find "${root}/node_modules" -path "*/form-data/package.json" -type f -print | grep -q .; then
  require_path "${root}/node_modules/hasown"
  require_path "${root}/node_modules/combined-stream"
fi

public_surface_loader="$(
  find "${root}/dist" -name "*.js" -type f -exec grep -sl "function loadBundledPluginPublicArtifactModuleSync" {} + | head -1
)"
if [ -z "$public_surface_loader" ]; then
  echo "Missing bundled plugin public surface loader" >&2
  exit 1
fi
if grep -q "rejectHardlinks: true" "$public_surface_loader"; then
  echo "Bundled plugin public surface loader still rejects hardlinked package files" >&2
  exit 1
fi

export PUBLIC_SURFACE_LOADER="$public_surface_loader"
node --input-type=module <<'NODE'
import { pathToFileURL } from "node:url";

const loaderPath = process.env.PUBLIC_SURFACE_LOADER;
if (!loaderPath) {
  throw new Error("PUBLIC_SURFACE_LOADER is not set");
}

const loader = await import(pathToFileURL(loaderPath).href);
const loadBundledPluginPublicArtifactModuleSync =
  loader.loadBundledPluginPublicArtifactModuleSync ?? loader.t;

if (typeof loadBundledPluginPublicArtifactModuleSync !== "function") {
  throw new Error("Bundled plugin public surface loader export not found");
}

loadBundledPluginPublicArtifactModuleSync({
  dirName: "openai",
  artifactBasename: "provider-policy-api.js",
});
NODE

require_js_alias_target() {
  alias="$1"
  alias_path="${root}/dist/${alias}"
  require_path "$alias_path"

  target="$(sed -n 's/^export \* from "\.\/\(.*\)";$/\1/p' "$alias_path" | head -1)"
  if [ -z "$target" ]; then
    echo "Alias has no export target: $alias_path" >&2
    exit 1
  fi
  require_path "${root}/dist/${target}"
}

require_js_alias_target "runtime-model-auth.runtime.js"

if ! find "${root}/skills" -name SKILL.md -type f | grep -q .; then
  echo "Missing bundled SKILL.md files under ${root}/skills" >&2
  exit 1
fi

echo "openclaw package contents: ok"
