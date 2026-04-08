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
  if ! grep -q "bundledPluginsDirOverride" src/gateway/test-helpers.server.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/test-helpers.server.ts")
old = """  process.env.OPENCLAW_TEST_MINIMAL_GATEWAY = \"1\";\n  process.env.OPENCLAW_BUNDLED_PLUGINS_DIR = tempHome\n    ? path.join(tempHome, \"openclaw-test-no-bundled-extensions\")\n    : \"openclaw-test-no-bundled-extensions\";\n"""
new = """  process.env.OPENCLAW_TEST_MINIMAL_GATEWAY = \"1\";\n  const bundledPluginsDirOverride = process.env.OPENCLAW_BUNDLED_PLUGINS_DIR?.trim();\n  if (!bundledPluginsDirOverride) {\n    process.env.OPENCLAW_BUNDLED_PLUGINS_DIR = tempHome\n      ? path.join(tempHome, \"openclaw-test-no-bundled-extensions\")\n      : \"openclaw-test-no-bundled-extensions\";\n  }\n"""
text = path.read_text()
if old not in text:
    raise SystemExit("expected OPENCLAW_BUNDLED_PLUGINS_DIR block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/plugins/provider-runtime.ts ]; then
  if ! grep -q "shouldSkipProviderRuntimeForTest" src/plugins/provider-runtime.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/plugins/provider-runtime.ts")
text = path.read_text()

old = """function resolveProviderPluginsForHooks(params: {\n"""
new = """function shouldSkipProviderRuntimeForTest(env: NodeJS.ProcessEnv = process.env): boolean {\n  if (!env.VITEST) {\n    return false;\n  }\n  const raw = env.OPENCLAW_SKIP_PROVIDERS?.trim().toLowerCase();\n  return raw === "1" || raw === "true";\n}\n\nfunction resolveProviderPluginsForHooks(params: {\n"""
if old not in text:
    raise SystemExit("expected resolveProviderPluginsForHooks definition not found")
text = text.replace(old, new, 1)

old = """  const env = params.env ?? process.env;\n  const cacheBucket = resolveHookProviderCacheBucket({\n"""
new = """  const env = params.env ?? process.env;\n  if (shouldSkipProviderRuntimeForTest(env)) {\n    return [];\n  }\n  const cacheBucket = resolveHookProviderCacheBucket({\n"""
if old not in text:
    raise SystemExit("expected resolveProviderPluginsForHooks env block not found")
text = text.replace(old, new, 1)

path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server-methods/send.ts ]; then
  if ! grep -q 'createDefaultDeps, createOutboundSendDeps' src/gateway/server-methods/send.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server-methods/send.ts")
text = path.read_text()
text = text.replace(
    'import { createOutboundSendDeps } from "../../cli/deps.js";\n',
    'import { createDefaultDeps, createOutboundSendDeps } from "../../cli/deps.js";\n',
    1,
)
old = '        const outboundDeps = context.deps ? createOutboundSendDeps(context.deps) : undefined;\n'
new = '        const outboundDeps = createOutboundSendDeps({ ...createDefaultDeps(), ...(context.deps ?? {}) });\n'
if old not in text:
    raise SystemExit("expected outboundDeps line not found")
text = text.replace(old, new, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/test-temp-config.ts ]; then
  if ! grep -q "resetConfigRuntimeState" src/gateway/test-temp-config.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/test-temp-config.ts")
text = path.read_text()
text = text.replace(
    'import path from "node:path";\n',
    'import path from "node:path";\nimport { resetConfigRuntimeState } from "../config/config.js";\n',
    1,
)
old = """  process.env.OPENCLAW_CONFIG_PATH = configPath;\n\n  try {\n    await writeFile(configPath, JSON.stringify(params.cfg, null, 2), "utf-8");\n    await params.run();\n  } finally {\n"""
new = """  process.env.OPENCLAW_CONFIG_PATH = configPath;\n  resetConfigRuntimeState();\n\n  try {\n    await writeFile(configPath, JSON.stringify(params.cfg, null, 2), "utf-8");\n    resetConfigRuntimeState();\n    await params.run();\n  } finally {\n"""
if old not in text:
    raise SystemExit("expected withTempConfig env setup block not found")
text = text.replace(old, new, 1)

old = """    if (prevConfigPath === undefined) {\n      delete process.env.OPENCLAW_CONFIG_PATH;\n    } else {\n      process.env.OPENCLAW_CONFIG_PATH = prevConfigPath;\n    }\n    await rm(dir, { recursive: true, force: true });\n  }\n}\n"""
new = """    if (prevConfigPath === undefined) {\n      delete process.env.OPENCLAW_CONFIG_PATH;\n    } else {\n      process.env.OPENCLAW_CONFIG_PATH = prevConfigPath;\n    }\n    resetConfigRuntimeState();\n    await rm(dir, { recursive: true, force: true });\n  }\n}\n"""
if old not in text:
    raise SystemExit("expected withTempConfig cleanup block not found")
text = text.replace(old, new, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server/ws-connection/message-handler.ts ]; then
  if ! grep -q "skipLocalBackendBootstrapPairing" src/gateway/server/ws-connection/message-handler.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server/ws-connection/message-handler.ts")
text = path.read_text()
old = """        const skipPairing =\n          shouldSkipLocalBackendSelfPairing({\n            connectParams,\n            locality: pairingLocality,\n            hasBrowserOriginHeader,\n            sharedAuthOk,\n            authMethod,\n          }) ||\n          shouldSkipControlUiPairing(\n            controlUiAuthPolicy,\n            role,\n            trustedProxyAuthOk,\n            resolvedAuth.mode,\n          );\n        if (device && devicePublicKey && !skipPairing) {\n"""
new = """        const skipLocalBackendBootstrapPairing = shouldSkipLocalBackendSelfPairing({\n          connectParams,\n          locality: pairingLocality,\n          hasBrowserOriginHeader,\n          sharedAuthOk,\n          authMethod,\n        });\n        const skipPairing = shouldSkipControlUiPairing(\n          controlUiAuthPolicy,\n          role,\n          trustedProxyAuthOk,\n          resolvedAuth.mode,\n        );\n        if (device && devicePublicKey && !skipPairing) {\n"""
if old not in text:
    raise SystemExit("expected skipPairing block not found")
text = text.replace(old, new, 1)

old = """          if (!isPaired) {\n            const ok = await requirePairing(\"not-paired\", paired);\n            if (!ok) {\n              return;\n            }\n          } else {\n"""
new = """          if (!isPaired) {\n            if (!skipLocalBackendBootstrapPairing) {\n              const ok = await requirePairing(\"not-paired\", paired);\n              if (!ok) {\n                return;\n              }\n            }\n          } else {\n"""
if old not in text:
    raise SystemExit("expected not-paired branch not found")
text = text.replace(old, new, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.e2e-ws-harness.ts ]; then
  if ! grep -q 'import { testState } from "./test-helpers.mocks.js";' src/gateway/server.e2e-ws-harness.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.e2e-ws-harness.ts")
text = path.read_text()
text = text.replace(
    'import { captureEnv } from "../test-utils/env.js";\n',
    'import { captureEnv } from "../test-utils/env.js";\nimport { testState } from "./test-helpers.mocks.js";\n',
    1,
)
old = """export async function startGatewayServerHarness(): Promise<GatewayServerHarness> {\n  const envSnapshot = captureEnv([\"OPENCLAW_GATEWAY_TOKEN\"]);\n  delete process.env.OPENCLAW_GATEWAY_TOKEN;\n  const port = await getFreePort();\n  const server = await startGatewayServer(port);\n"""
new = """export async function startGatewayServerHarness(): Promise<GatewayServerHarness> {\n  const envSnapshot = captureEnv([\"OPENCLAW_GATEWAY_TOKEN\"]);\n  const gatewayToken =\n    typeof (testState.gatewayAuth as { token?: unknown } | undefined)?.token === \"string\"\n      ? ((testState.gatewayAuth as { token?: string }).token ?? undefined)\n      : undefined;\n  if (gatewayToken) {\n    process.env.OPENCLAW_GATEWAY_TOKEN = gatewayToken;\n  } else {\n    delete process.env.OPENCLAW_GATEWAY_TOKEN;\n  }\n  const port = await getFreePort();\n  const server = await startGatewayServer(port);\n"""
if old not in text:
    raise SystemExit("expected gateway harness block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/gateway/server.shared-auth-rotation.test.ts ]; then
  if ! grep -q 'process.env.OPENCLAW_GATEWAY_TOKEN = OLD_TOKEN;' src/gateway/server.shared-auth-rotation.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.shared-auth-rotation.test.ts")
text = path.read_text()
old = """beforeAll(async () => {\n  port = await getFreePort();\n  testState.gatewayAuth = { mode: \"token\", token: OLD_TOKEN };\n  server = await startGatewayServer(port, { controlUiEnabled: true });\n});\n"""
new = """beforeAll(async () => {\n  port = await getFreePort();\n  testState.gatewayAuth = { mode: \"token\", token: OLD_TOKEN };\n  process.env.OPENCLAW_GATEWAY_TOKEN = OLD_TOKEN;\n  server = await startGatewayServer(port, { controlUiEnabled: true });\n});\n"""
if old not in text:
    raise SystemExit("expected shared auth beforeAll block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/gateway/server.models-voicewake-misc.test.ts ]; then
  if ! grep -q 'augmentModelCatalogWithProviderPlugins: async () => \[\]' src/gateway/server.models-voicewake-misc.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.models-voicewake-misc.test.ts")
text = path.read_text()
text = text.replace(
    'import { afterAll, beforeAll, describe, expect, test } from "vitest";\n',
    'import { afterAll, beforeAll, describe, expect, test, vi } from "vitest";\n',
    1,
)
old = 'installGatewayTestHooks({ scope: "suite" });\n'
new = """vi.mock("../plugins/provider-runtime.runtime.js", async () => {\n  const actual = await vi.importActual<typeof import("../plugins/provider-runtime.runtime.js")>(\n    "../plugins/provider-runtime.runtime.js",\n  );\n  return {\n    ...actual,\n    augmentModelCatalogWithProviderPlugins: async () => [],\n  };\n});\n\ninstallGatewayTestHooks({ scope: "suite" });\n"""
if old not in text:
    raise SystemExit("expected installGatewayTestHooks block not found")
text = text.replace(old, new, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/test-helpers.mocks.ts ]; then
  if ! grep -q "DEFAULT_MODEL" src/gateway/test-helpers.mocks.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/test-helpers.mocks.ts")
text = path.read_text()
text = text.replace(
    'import type { AgentBinding } from "../config/types.agents.js";\n',
    'import { DEFAULT_MODEL, DEFAULT_PROVIDER } from "../agents/defaults.js";\nimport type { AgentBinding } from "../config/types.agents.js";\n',
    1,
)
old = '      model: { primary: "anthropic/claude-opus-4-6" },\n'
new = '      model: { primary: `${DEFAULT_PROVIDER}/${DEFAULT_MODEL}` },\n'
if old not in text:
    raise SystemExit("expected test helper default model not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/gateway/test-helpers.mocks.ts ]; then
  if ! grep -q 'vi.mock("/src/commands/agent.js"' src/gateway/test-helpers.mocks.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/test-helpers.mocks.ts")
text = path.read_text()
old = """vi.mock("../commands/agent.js", () => ({\n  agentCommand,\n  agentCommandFromIngress: agentCommand,\n}));\n"""
new = """vi.mock("../commands/agent.js", () => ({\n  agentCommand,\n  agentCommandFromIngress: agentCommand,\n}));\nvi.mock("/src/commands/agent.js", () => ({\n  agentCommand,\n  agentCommandFromIngress: agentCommand,\n}));\nvi.mock("/src/gateway/server-node-events.runtime.js", () => ({\n  agentCommandFromIngress: agentCommand,\n}));\n"""
if old not in text:
    raise SystemExit("expected commands/agent mock block not found")
text = text.replace(old, new, 1)

old = """vi.mock(buildBundledPluginModuleId("whatsapp", "runtime-api.js"), () => ({\n  sendMessageWhatsApp: (...args: unknown[]) =>\n    (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n  sendPollWhatsApp: (...args: unknown[]) =>\n    (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n}));\n"""
new = """vi.mock(buildBundledPluginModuleId("whatsapp", "runtime-api.js"), () => ({\n  sendMessageWhatsApp: (...args: unknown[]) =>\n    (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n  sendPollWhatsApp: (...args: unknown[]) =>\n    (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n}));\nvi.mock("/src/extensions/whatsapp/runtime-api.js", () => ({\n  sendMessageWhatsApp: (...args: unknown[]) =>\n    (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n  sendPollWhatsApp: (...args: unknown[]) =>\n    (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n}));\n"""
if old not in text:
    raise SystemExit("expected bundled whatsapp runtime-api mock block not found")
text = text.replace(old, new, 1)

old = """vi.mock("../channels/web/index.js", async () => {\n  const actual = await vi.importActual<typeof import("../channels/web/index.js")>(\n    "../channels/web/index.js",\n  );\n  return {\n    ...actual,\n    sendMessageWhatsApp: (...args: unknown[]) =>\n      (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n  };\n});\n"""
new = """vi.mock("../channels/web/index.js", async () => {\n  const actual = await vi.importActual<typeof import("../channels/web/index.js")>(\n    "../channels/web/index.js",\n  );\n  return {\n    ...actual,\n    sendMessageWhatsApp: (...args: unknown[]) =>\n      (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n  };\n});\nvi.mock("/src/channels/web/index.js", async () => {\n  const actual = await vi.importActual<typeof import("../channels/web/index.js")>(\n    "../channels/web/index.js",\n  );\n  return {\n    ...actual,\n    sendMessageWhatsApp: (...args: unknown[]) =>\n      (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n  };\n});\n"""
if old not in text:
    raise SystemExit("expected channels/web mock block not found")
text = text.replace(old, new, 1)

old = """vi.mock("../plugins/loader.js", async () => {\n  const actual =\n    await vi.importActual<typeof import("../plugins/loader.js")>(\"../plugins/loader.js\");\n  return {\n    ...actual,\n    loadOpenClawPlugins: () => pluginRegistryState.registry,\n  };\n});\n"""
new = """vi.mock("../plugins/loader.js", async () => {\n  const actual =\n    await vi.importActual<typeof import("../plugins/loader.js")>(\"../plugins/loader.js\");\n  return {\n    ...actual,\n    loadOpenClawPlugins: () => pluginRegistryState.registry,\n  };\n});\nvi.mock("/src/plugins/loader.js", async () => {\n  const actual =\n    await vi.importActual<typeof import("../plugins/loader.js")>(\"../plugins/loader.js\");\n  return {\n    ...actual,\n    loadOpenClawPlugins: () => pluginRegistryState.registry,\n  };\n});\n"""
if old not in text:
    raise SystemExit("expected plugins/loader mock block not found")
text = text.replace(old, new, 1)

old = """vi.mock("../cli/deps.js", async () => {\n  const actual = await vi.importActual<typeof import("../cli/deps.js")>("../cli/deps.js");\n  const base = actual.createDefaultDeps();\n  return {\n    ...actual,\n    createDefaultDeps: () => ({\n      ...base,\n      sendMessageWhatsApp: (...args: unknown[]) =>\n        (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n    }),\n  };\n});\n"""
new = """vi.mock("../cli/deps.js", async () => {\n  const actual = await vi.importActual<typeof import("../cli/deps.js")>("../cli/deps.js");\n  const base = actual.createDefaultDeps();\n  return {\n    ...actual,\n    createDefaultDeps: () => ({\n      ...base,\n      whatsapp: (...args: unknown[]) =>\n        (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n      sendMessageWhatsApp: (...args: unknown[]) =>\n        (hoisted.sendWhatsAppMock as (...args: unknown[]) => unknown)(...args),\n    }),\n  };\n});\n"""
if old not in text:
    raise SystemExit("expected cli/deps mock block not found")
text = text.replace(old, new, 1)

path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.talk-config.test.ts ]; then
  if ! grep -q "withPatchedSpeechProvidersForTalkTests" src/gateway/server.talk-config.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.talk-config.test.ts")
text = path.read_text()
marker = """const TALK_CONFIG_DEVICE = loadOrCreateDeviceIdentity(TALK_CONFIG_DEVICE_PATH);\n"""
insert = """const TALK_CONFIG_DEVICE = loadOrCreateDeviceIdentity(TALK_CONFIG_DEVICE_PATH);\n\nasync function withPatchedSpeechProvidersForTalkTests(run: () => Promise<void>) {\n  const previousRegistry = getActivePluginRegistry() ?? createEmptyPluginRegistry();\n  setActivePluginRegistry({\n    ...previousRegistry,\n    speechProviders: [\n      {\n        pluginId: \"openai\",\n        source: \"test\",\n        provider: {\n          id: \"openai\",\n          label: \"OpenAI\",\n          voices: [\"alloy\", \"nova\"],\n          isConfigured: () => true,\n          synthesize: async (req) => {\n            const providerConfig = (req.providerConfig ?? {}) as Record<string, unknown>;\n            const providerOverrides = (req.providerOverrides ?? {}) as Record<string, unknown>;\n            const model =\n              typeof providerOverrides.modelId === \"string\"\n                ? providerOverrides.modelId\n                : typeof providerConfig.modelId === \"string\"\n                  ? providerConfig.modelId\n                  : \"gpt-4o-mini-tts\";\n            const voice =\n              typeof providerOverrides.voiceId === \"string\"\n                ? providerOverrides.voiceId\n                : typeof providerConfig.voiceId === \"string\"\n                  ? providerConfig.voiceId\n                  : \"alloy\";\n            const speed =\n              typeof providerOverrides.speed === \"number\" ? providerOverrides.speed : undefined;\n            const response = await globalThis.fetch(\"https://api.openai.com/v1/audio/speech\", {\n              method: \"POST\",\n              headers: {\n                \"content-type\": \"application/json\",\n                authorization: `Bearer ${String(providerConfig.apiKey ?? \"\")}`,\n              },\n              body: JSON.stringify({\n                input: req.text,\n                model,\n                voice,\n                ...(speed === undefined ? {} : { speed }),\n              }),\n            });\n            return {\n              audioBuffer: Buffer.from(await response.arrayBuffer()),\n              outputFormat: \"mp3\",\n              fileExtension: \".mp3\",\n              voiceCompatible: false,\n            };\n          },\n        },\n      },\n      {\n        pluginId: \"elevenlabs\",\n        source: \"test\",\n        provider: {\n          id: \"elevenlabs\",\n          label: \"ElevenLabs\",\n          voices: [\"EXAVITQu4vr4xnSDxMaL\", \"voice-default\"],\n          isConfigured: () => true,\n          synthesize: async (req) => {\n            const providerConfig = (req.providerConfig ?? {}) as Record<string, unknown>;\n            const providerOverrides = (req.providerOverrides ?? {}) as Record<string, unknown>;\n            const voiceId =\n              typeof providerOverrides.voiceId === \"string\"\n                ? providerOverrides.voiceId\n                : typeof providerConfig.voiceId === \"string\"\n                  ? providerConfig.voiceId\n                  : \"voice-default\";\n            const outputFormat =\n              typeof providerOverrides.outputFormat === \"string\"\n                ? providerOverrides.outputFormat\n                : typeof providerConfig.outputFormat === \"string\"\n                  ? providerConfig.outputFormat\n                  : \"mp3_44100_128\";\n            const query = new URLSearchParams({ output_format: outputFormat }).toString();\n            const response = await globalThis.fetch(\n              `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voiceId)}?${query}`,\n              {\n                method: \"POST\",\n                headers: {\n                  \"content-type\": \"application/json\",\n                  \"xi-api-key\": String(providerConfig.apiKey ?? \"\"),\n                },\n                body: JSON.stringify({ text: req.text }),\n              },\n            );\n            return {\n              audioBuffer: Buffer.from(await response.arrayBuffer()),\n              outputFormat,\n              fileExtension: outputFormat.startsWith(\"pcm_\") ? \".pcm\" : \".mp3\",\n              voiceCompatible: false,\n            };\n          },\n        },\n      },\n    ],\n  });\n  try {\n    await run();\n  } finally {\n    setActivePluginRegistry(previousRegistry);\n  }\n}\n"""
if marker not in text:
    raise SystemExit("expected talk config device marker not found")
text = text.replace(marker, insert, 1)

old_openai = """    try {\n      await withServer(async (ws) => {\n        resetTestPluginRegistry();\n        await connectOperator(ws, [\"operator.read\", \"operator.write\"]);\n        const res = await fetchTalkSpeak(\n          ws,\n          {\n            text: \"Hello from talk mode.\",\n            voiceId: \"nova\",\n            modelId: \"tts-1\",\n            speed: 1.25,\n          },\n          30_000,\n        );\n        expect(res.ok, JSON.stringify(res)).toBe(true);\n        expect(res.payload?.provider).toBe(\"openai\");\n        expect(res.payload?.outputFormat).toBe(\"mp3\");\n        expect(res.payload?.mimeType).toBe(\"audio/mpeg\");\n        expect(res.payload?.fileExtension).toBe(\".mp3\");\n        expect(res.payload?.audioBase64).toBe(Buffer.from([1, 2, 3]).toString(\"base64\"));\n      });\n\n      expect(fetchMock).toHaveBeenCalled();\n      const requestInit = requestInits.find((init) => typeof init.body === \"string\");\n      expect(requestInit).toBeDefined();\n      const body = JSON.parse(requestInit?.body as string) as Record<string, unknown>;\n      expect(body.model).toBe(\"tts-1\");\n      expect(body.voice).toBe(\"nova\");\n      expect(body.speed).toBe(1.25);\n    } finally {\n      globalThis.fetch = originalFetch;\n    }\n"""
new_openai = """    try {\n      await withServer(async (ws) => {\n        resetTestPluginRegistry();\n        await withPatchedSpeechProvidersForTalkTests(async () => {\n          await connectOperator(ws, [\"operator.read\", \"operator.write\"]);\n          const res = await fetchTalkSpeak(\n            ws,\n            {\n              text: \"Hello from talk mode.\",\n              voiceId: \"nova\",\n              modelId: \"tts-1\",\n              speed: 1.25,\n            },\n            30_000,\n          );\n          expect(res.ok, JSON.stringify(res)).toBe(true);\n          expect(res.payload?.provider).toBe(\"openai\");\n          expect(res.payload?.outputFormat).toBe(\"mp3\");\n          expect(res.payload?.mimeType).toBe(\"audio/mpeg\");\n          expect(res.payload?.fileExtension).toBe(\".mp3\");\n          expect(res.payload?.audioBase64).toBe(Buffer.from([1, 2, 3]).toString(\"base64\"));\n        });\n      });\n\n      expect(fetchMock).toHaveBeenCalled();\n      const requestInit = requestInits.find((init) => typeof init.body === \"string\");\n      expect(requestInit).toBeDefined();\n      const body = JSON.parse(requestInit?.body as string) as Record<string, unknown>;\n      expect(body.model).toBe(\"tts-1\");\n      expect(body.voice).toBe(\"nova\");\n      expect(body.speed).toBe(1.25);\n    } finally {\n      globalThis.fetch = originalFetch;\n    }\n"""
if old_openai not in text:
    raise SystemExit("expected openai talk test block not found")
text = text.replace(old_openai, new_openai, 1)

old_eleven = """    try {\n      await withServer(async (ws) => {\n        resetTestPluginRegistry();\n        await connectOperator(ws, [\"operator.read\", \"operator.write\"]);\n        const res = await fetchTalkSpeak(ws, {\n          text: \"Hello from talk mode.\",\n          voiceId: \"clawd\",\n          outputFormat: \"pcm_44100\",\n        });\n        expect(res.ok, JSON.stringify(res)).toBe(true);\n        expect(res.payload?.provider).toBe(\"elevenlabs\");\n        expect(res.payload?.outputFormat).toBe(\"pcm_44100\");\n        expect(res.payload?.audioBase64).toBe(Buffer.from([4, 5, 6]).toString(\"base64\"));\n      });\n\n      expect(fetchMock).toHaveBeenCalled();\n      expect(fetchUrl).toContain(\"/v1/text-to-speech/EXAVITQu4vr4xnSDxMaL\");\n      expect(fetchUrl).toContain(\"output_format=pcm_44100\");\n    } finally {\n      globalThis.fetch = originalFetch;\n    }\n"""
new_eleven = """    try {\n      await withServer(async (ws) => {\n        resetTestPluginRegistry();\n        await withPatchedSpeechProvidersForTalkTests(async () => {\n          await connectOperator(ws, [\"operator.read\", \"operator.write\"]);\n          const res = await fetchTalkSpeak(ws, {\n            text: \"Hello from talk mode.\",\n            voiceId: \"clawd\",\n            outputFormat: \"pcm_44100\",\n          });\n          expect(res.ok, JSON.stringify(res)).toBe(true);\n          expect(res.payload?.provider).toBe(\"elevenlabs\");\n          expect(res.payload?.outputFormat).toBe(\"pcm_44100\");\n          expect(res.payload?.audioBase64).toBe(Buffer.from([4, 5, 6]).toString(\"base64\"));\n        });\n      });\n\n      expect(fetchMock).toHaveBeenCalled();\n      expect(fetchUrl).toContain(\"/v1/text-to-speech/EXAVITQu4vr4xnSDxMaL\");\n      expect(fetchUrl).toContain(\"output_format=pcm_44100\");\n    } finally {\n      globalThis.fetch = originalFetch;\n    }\n"""
if old_eleven not in text:
    raise SystemExit("expected elevenlabs talk test block not found")
text = text.replace(old_eleven, new_eleven, 1)

path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/test-helpers.mocks.ts ]; then
  if ! grep -q 'resetConfigRuntimeState' src/gateway/test-helpers.mocks.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/test-helpers.mocks.ts")
text = path.read_text()
text = text.replace(
    'import type { OpenClawConfig } from "../config/config.js";\n',
    'import { resetConfigRuntimeState, type OpenClawConfig } from "../config/config.js";\n',
    1,
)
old_env = '  process.env.OPENCLAW_CONFIG_PATH = path.join(root, "openclaw.json");\n'
new_env = '  process.env.OPENCLAW_CONFIG_PATH = path.join(root, "openclaw.json");\n  resetConfigRuntimeState();\n'
if old_env not in text:
    raise SystemExit("expected test-helpers.mocks setTestConfigRoot block not found")
text = text.replace(old_env, new_env, 1)

old_write = '    await fs.writeFile(configPath, raw, "utf-8");\n'
new_write = '    await fs.writeFile(configPath, raw, "utf-8");\n    resetConfigRuntimeState();\n'
if old_write not in text:
    raise SystemExit("expected test-helpers.mocks writeConfigFile block not found")
text = text.replace(old_write, new_write, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.reload.test.ts ]; then
  if ! grep -q 'allowInsecurePath: true,' src/gateway/server.reload.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.reload.test.ts")
text = path.read_text()
old1 = """          vault: {\n            source: \"exec\",\n            command: process.execPath,\n            allowSymlinkCommand: true,\n            args: [params.resolverScriptPath, params.modePath, params.tokenValue],\n          },\n"""
new1 = """          vault: {\n            source: \"exec\",\n            command: process.execPath,\n            allowSymlinkCommand: true,\n            allowInsecurePath: true,\n            args: [params.resolverScriptPath, params.modePath, params.tokenValue],\n          },\n"""
old2 = """          vault: {\n            source: \"exec\",\n            command: process.execPath,\n            allowSymlinkCommand: true,\n            args: [resolverScriptPath, tokenPath],\n          },\n"""
new2 = """          vault: {\n            source: \"exec\",\n            command: process.execPath,\n            allowSymlinkCommand: true,\n            allowInsecurePath: true,\n            args: [resolverScriptPath, tokenPath],\n          },\n"""
if old1 not in text:
    raise SystemExit("expected gateway token exec ref config block not found")
if old2 not in text:
    raise SystemExit("expected keep-last-known-good auth config block not found")
text = text.replace(old1, new1, 1)
text = text.replace(old2, new2, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.reload.test.ts ]; then
  if ! grep -q 'resetConfigRuntimeState();' src/gateway/server.reload.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.reload.test.ts")
text = path.read_text()
text = text.replace(
    'import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";\n',
    'import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";\nimport { resetConfigRuntimeState } from "../config/config.js";\n',
    1,
)
old = '    await fs.writeFile(configPath, `${JSON.stringify(config, null, 2)}\\n`, "utf8");\n'
new = '    await fs.writeFile(configPath, `${JSON.stringify(config, null, 2)}\\n`, "utf8");\n    resetConfigRuntimeState();\n'
if old not in text:
    raise SystemExit("expected server.reload writeConfigFile block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/gateway/server.sessions.gateway-server-sessions-a.test.ts ]; then
  if ! grep -q "DEFAULT_MODEL" src/gateway/server.sessions.gateway-server-sessions-a.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.sessions.gateway-server-sessions-a.test.ts")
text = path.read_text()
text = text.replace(
    'import { DEFAULT_PROVIDER } from "../agents/defaults.js";\n',
    'import { DEFAULT_MODEL, DEFAULT_PROVIDER } from "../agents/defaults.js";\n',
    1,
)
old = """    expect(patched.payload?.resolved).toEqual({\n      modelProvider: \"anthropic\",\n      model: \"claude-opus-4-6\",\n    });\n"""
new = """    expect(patched.payload?.resolved).toEqual({\n      modelProvider: DEFAULT_PROVIDER,\n      model: DEFAULT_MODEL,\n    });\n"""
if old not in text:
    raise SystemExit("expected session resolved default assertion not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/gateway/server.chat.gateway-server-chat.test.ts ]; then
  if ! grep -q 'collectHistoryTextValues(historyRes.payload?.messages ?? \[\])' src/gateway/server.chat.gateway-server-chat.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.chat.gateway-server-chat.test.ts")
text = path.read_text()
old = """      const historyRes = await rpcReq<{ messages?: unknown[] }>(ws, \"chat.history\", {\n        sessionKey: \"main\",\n      });\n      expect(historyRes.ok).toBe(true);\n      expect(historyRes.payload?.messages ?? []).toEqual([]);\n"""
new = """      const historyRes = await rpcReq<{ messages?: unknown[] }>(ws, \"chat.history\", {\n        sessionKey: \"main\",\n      });\n      expect(historyRes.ok).toBe(true);\n      expect(collectHistoryTextValues(historyRes.payload?.messages ?? [])).toEqual([\n        \"/btw what is 17 * 19?\",\n      ]);\n"""
if old not in text:
    raise SystemExit("expected /btw history assertion block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/gateway/openai-http.test.ts ]; then
  if ! grep -q 'resetConfigRuntimeState();' src/gateway/openai-http.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/openai-http.test.ts")
text = path.read_text()
text = text.replace(
    'import { afterAll, beforeAll, describe, expect, it } from "vitest";\n',
    'import { afterAll, beforeAll, describe, expect, it } from "vitest";\nimport { resetConfigRuntimeState } from "../config/config.js";\n',
    1,
)
old = '  await fs.writeFile(configPath, JSON.stringify(config, null, 2), "utf-8");\n'
new = '  await fs.writeFile(configPath, JSON.stringify(config, null, 2), "utf-8");\n  resetConfigRuntimeState();\n'
if old not in text:
    raise SystemExit("expected openai-http writeGatewayConfig block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/gateway/openresponses-http.test.ts ]; then
  if ! grep -q 'resetConfigRuntimeState();' src/gateway/openresponses-http.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/openresponses-http.test.ts")
text = path.read_text()
text = text.replace(
    'import { HISTORY_CONTEXT_MARKER } from "../auto-reply/reply/history.js";\n',
    'import { HISTORY_CONTEXT_MARKER } from "../auto-reply/reply/history.js";\nimport { resetConfigRuntimeState } from "../config/config.js";\n',
    1,
)
old = '  await fs.writeFile(configPath, JSON.stringify(config, null, 2), "utf-8");\n'
new = '  await fs.writeFile(configPath, JSON.stringify(config, null, 2), "utf-8");\n  resetConfigRuntimeState();\n'
if old not in text:
    raise SystemExit("expected openresponses-http writeGatewayConfig block not found")
text = text.replace(old, new, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.cron.test.ts ]; then
  if ! grep -q 'resetConfigRuntimeState();' src/gateway/server.cron.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.cron.test.ts")
text = path.read_text()
text = text.replace(
    'import { afterAll, beforeEach, describe, expect, test, vi } from "vitest";\n',
    'import { afterAll, beforeEach, describe, expect, test, vi } from "vitest";\nimport { resetConfigRuntimeState } from "../config/config.js";\n',
    1,
)
old = '  await fs.writeFile(configPath as string, JSON.stringify(config, null, 2), "utf-8");\n'
new = '  await fs.writeFile(configPath as string, JSON.stringify(config, null, 2), "utf-8");\n  resetConfigRuntimeState();\n'
if old not in text:
    raise SystemExit("expected server.cron writeCronConfig block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/gateway/server.hooks.test.ts ]; then
  if ! grep -q 'resetConfigRuntimeState' src/gateway/server.hooks.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.hooks.test.ts")
text = path.read_text()
text = text.replace(
    'import { resolveMainSessionKeyFromConfig } from "../config/sessions.js";\n',
    'import { resetConfigRuntimeState } from "../config/config.js";\nimport { resolveMainSessionKeyFromConfig } from "../config/sessions.js";\n',
    1,
)
old = """    await fs.writeFile(
      configPath!,
      JSON.stringify({ gateway: { trustedProxies: ["127.0.0.1"] } }, null, 2),
      "utf-8",
    );
"""
new = """    await fs.writeFile(
      configPath!,
      JSON.stringify({ gateway: { trustedProxies: ["127.0.0.1"] } }, null, 2),
      "utf-8",
    );
    resetConfigRuntimeState();
"""
if old not in text:
    raise SystemExit("expected server.hooks trusted proxy config block not found")
text = text.replace(old, new, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.roles-allowlist-update.test.ts ]; then
  if ! grep -q 'resetConfigRuntimeState' src/gateway/server.roles-allowlist-update.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.roles-allowlist-update.test.ts")
text = path.read_text()
text = text.replace(
    'import type { DeviceIdentity } from "../infra/device-identity.js";\n',
    'import { resetConfigRuntimeState } from "../config/config.js";\nimport type { DeviceIdentity } from "../infra/device-identity.js";\n',
    1,
)
old = '      await fs.writeFile(configPath, JSON.stringify({ update: { channel: "beta" } }, null, 2));\n'
new = '      await fs.writeFile(configPath, JSON.stringify({ update: { channel: "beta" } }, null, 2));\n      resetConfigRuntimeState();\n'
if old not in text:
    raise SystemExit("expected roles allowlist update config write block not found")
text = text.replace(old, new, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.sessions-send.test.ts ]; then
  if ! grep -q 'resetConfigRuntimeState' src/gateway/server.sessions-send.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.sessions-send.test.ts")
text = path.read_text()
text = text.replace(
    'import { resolveSessionTranscriptPath } from "../config/sessions.js";\n',
    'import { resetConfigRuntimeState } from "../config/config.js";\nimport { resolveSessionTranscriptPath } from "../config/sessions.js";\n',
    1,
)
old = """      await fs.writeFile(
        configPath,
        JSON.stringify({ tools: { sessions: { visibility: "all" } } }, null, 2) + "\\n",
        "utf-8",
      );
"""
new = """      await fs.writeFile(
        configPath,
        JSON.stringify({ tools: { sessions: { visibility: "all" } } }, null, 2) + "\\n",
        "utf-8",
      );
      resetConfigRuntimeState();
"""
if old not in text:
    raise SystemExit("expected server.sessions-send config write block not found")
text = text.replace(old, new, 1)
path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.sessions.gateway-server-sessions-a.test.ts ]; then
  if ! grep -q 'vi.mock("/src/extensions/browser/runtime-api.js"' src/gateway/server.sessions.gateway-server-sessions-a.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.sessions.gateway-server-sessions-a.test.ts")
text = path.read_text()
old = """vi.mock(\"../plugin-sdk/browser-maintenance.js\", () => ({\n  closeTrackedBrowserTabsForSessions: browserSessionTabMocks.closeTrackedBrowserTabsForSessions,\n  movePathToTrash: vi.fn(async () => {}),\n}));\n"""
new = """vi.mock(\"../plugin-sdk/browser-maintenance.js\", () => ({\n  closeTrackedBrowserTabsForSessions: browserSessionTabMocks.closeTrackedBrowserTabsForSessions,\n  movePathToTrash: vi.fn(async () => {}),\n}));\nvi.mock(\"/src/plugin-sdk/browser-maintenance.js\", () => ({\n  closeTrackedBrowserTabsForSessions: browserSessionTabMocks.closeTrackedBrowserTabsForSessions,\n  movePathToTrash: vi.fn(async () => {}),\n}));\nvi.mock(\"../../extensions/browser/runtime-api.js\", () => ({\n  closeTrackedBrowserTabsForSessions: browserSessionTabMocks.closeTrackedBrowserTabsForSessions,\n  movePathToTrash: vi.fn(async () => {}),\n}));\nvi.mock(\"/src/extensions/browser/runtime-api.js\", () => ({\n  closeTrackedBrowserTabsForSessions: browserSessionTabMocks.closeTrackedBrowserTabsForSessions,\n  movePathToTrash: vi.fn(async () => {}),\n}));\n"""
if old not in text:
    raise SystemExit("expected browser-maintenance mock block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi

if [ -f src/agents/tools/sessions-send-tool.ts ]; then
  if grep -q 'const start = await startAgentRun' src/agents/tools/sessions-send-tool.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/agents/tools/sessions-send-tool.ts")
text = path.read_text()
old = """      const start = await startAgentRun({\n        callGateway: gatewayCall,\n        runId,\n        sendParams,\n        sessionKey: displayKey,\n      });\n      if (!start.ok) {\n        return start.result;\n      }\n      runId = start.runId;\n\n      const baselineReply = await readLatestAssistantReplySnapshot({\n        sessionKey: resolvedKey,\n        limit: SESSIONS_SEND_REPLY_HISTORY_LIMIT,\n        callGateway: gatewayCall,\n      });\n"""
new = """      const baselineReply = await readLatestAssistantReplySnapshot({\n        sessionKey: resolvedKey,\n        limit: SESSIONS_SEND_REPLY_HISTORY_LIMIT,\n        callGateway: gatewayCall,\n      });\n\n      const start = await startAgentRun({\n        callGateway: gatewayCall,\n        runId,\n        sendParams,\n        sessionKey: displayKey,\n      });\n      if (!start.ok) {\n        return start.result;\n      }\n      runId = start.runId;\n"""
if old not in text:
    raise SystemExit("expected sessions_send start/baseline block not found")
path.write_text(text.replace(old, new, 1))
PY
  fi
fi
