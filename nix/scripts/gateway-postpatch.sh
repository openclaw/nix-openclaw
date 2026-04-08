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

path.write_text(text)
PY
  fi
fi

if [ -f src/gateway/server.talk-config.test.ts ]; then
  if ! grep -q "enableRealSpeechProvidersForTalkTests" src/gateway/server.talk-config.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/gateway/server.talk-config.test.ts")
text = path.read_text()
marker = """const TALK_CONFIG_DEVICE = loadOrCreateDeviceIdentity(TALK_CONFIG_DEVICE_PATH);\n"""
insert = """const TALK_CONFIG_DEVICE = loadOrCreateDeviceIdentity(TALK_CONFIG_DEVICE_PATH);\n\nfunction enableRealSpeechProvidersForTalkTests() {\n  const previousRegistry = getActivePluginRegistry();\n  const previousSkipProviders = process.env.OPENCLAW_SKIP_PROVIDERS;\n  const previousBundledPluginsDir = process.env.OPENCLAW_BUNDLED_PLUGINS_DIR;\n  setActivePluginRegistry(createEmptyPluginRegistry());\n  delete process.env.OPENCLAW_SKIP_PROVIDERS;\n  process.env.OPENCLAW_BUNDLED_PLUGINS_DIR = path.join(process.cwd(), \"dist-runtime\", \"extensions\");\n  return () => {\n    setActivePluginRegistry(previousRegistry ?? createEmptyPluginRegistry());\n    if (previousSkipProviders === undefined) {\n      delete process.env.OPENCLAW_SKIP_PROVIDERS;\n    } else {\n      process.env.OPENCLAW_SKIP_PROVIDERS = previousSkipProviders;\n    }\n    if (previousBundledPluginsDir === undefined) {\n      delete process.env.OPENCLAW_BUNDLED_PLUGINS_DIR;\n    } else {\n      process.env.OPENCLAW_BUNDLED_PLUGINS_DIR = previousBundledPluginsDir;\n    }\n  };\n}\n"""
if marker not in text:
    raise SystemExit("expected talk config device marker not found")
text = text.replace(marker, insert, 1)

old_openai = """    try {\n      await withServer(async (ws) => {\n        resetTestPluginRegistry();\n        await connectOperator(ws, [\"operator.read\", \"operator.write\"]);\n        const res = await fetchTalkSpeak(\n          ws,\n          {\n            text: \"Hello from talk mode.\",\n            voiceId: \"nova\",\n            modelId: \"tts-1\",\n            speed: 1.25,\n          },\n          30_000,\n        );\n        expect(res.ok, JSON.stringify(res)).toBe(true);\n        expect(res.payload?.provider).toBe(\"openai\");\n        expect(res.payload?.outputFormat).toBe(\"mp3\");\n        expect(res.payload?.mimeType).toBe(\"audio/mpeg\");\n        expect(res.payload?.fileExtension).toBe(\".mp3\");\n        expect(res.payload?.audioBase64).toBe(Buffer.from([1, 2, 3]).toString(\"base64\"));\n      });\n\n      expect(fetchMock).toHaveBeenCalled();\n      const requestInit = requestInits.find((init) => typeof init.body === \"string\");\n      expect(requestInit).toBeDefined();\n      const body = JSON.parse(requestInit?.body as string) as Record<string, unknown>;\n      expect(body.model).toBe(\"tts-1\");\n      expect(body.voice).toBe(\"nova\");\n      expect(body.speed).toBe(1.25);\n    } finally {\n      globalThis.fetch = originalFetch;\n    }\n"""
new_openai = """    try {\n      await withServer(async (ws) => {\n        resetTestPluginRegistry();\n        const restoreProviders = enableRealSpeechProvidersForTalkTests();\n        try {\n          await connectOperator(ws, [\"operator.read\", \"operator.write\"]);\n          const res = await fetchTalkSpeak(\n            ws,\n            {\n              text: \"Hello from talk mode.\",\n              voiceId: \"nova\",\n              modelId: \"tts-1\",\n              speed: 1.25,\n            },\n            30_000,\n          );\n          expect(res.ok, JSON.stringify(res)).toBe(true);\n          expect(res.payload?.provider).toBe(\"openai\");\n          expect(res.payload?.outputFormat).toBe(\"mp3\");\n          expect(res.payload?.mimeType).toBe(\"audio/mpeg\");\n          expect(res.payload?.fileExtension).toBe(\".mp3\");\n          expect(res.payload?.audioBase64).toBe(Buffer.from([1, 2, 3]).toString(\"base64\"));\n        } finally {\n          restoreProviders();\n        }\n      });\n\n      expect(fetchMock).toHaveBeenCalled();\n      const requestInit = requestInits.find((init) => typeof init.body === \"string\");\n      expect(requestInit).toBeDefined();\n      const body = JSON.parse(requestInit?.body as string) as Record<string, unknown>;\n      expect(body.model).toBe(\"tts-1\");\n      expect(body.voice).toBe(\"nova\");\n      expect(body.speed).toBe(1.25);\n    } finally {\n      globalThis.fetch = originalFetch;\n    }\n"""
if old_openai not in text:
    raise SystemExit("expected openai talk test block not found")
text = text.replace(old_openai, new_openai, 1)

old_eleven = """    try {\n      await withServer(async (ws) => {\n        resetTestPluginRegistry();\n        await connectOperator(ws, [\"operator.read\", \"operator.write\"]);\n        const res = await fetchTalkSpeak(ws, {\n          text: \"Hello from talk mode.\",\n          voiceId: \"clawd\",\n          outputFormat: \"pcm_44100\",\n        });\n        expect(res.ok, JSON.stringify(res)).toBe(true);\n        expect(res.payload?.provider).toBe(\"elevenlabs\");\n        expect(res.payload?.outputFormat).toBe(\"pcm_44100\");\n        expect(res.payload?.audioBase64).toBe(Buffer.from([4, 5, 6]).toString(\"base64\"));\n      });\n\n      expect(fetchMock).toHaveBeenCalled();\n      expect(fetchUrl).toContain(\"/v1/text-to-speech/EXAVITQu4vr4xnSDxMaL\");\n      expect(fetchUrl).toContain(\"output_format=pcm_44100\");\n    } finally {\n      globalThis.fetch = originalFetch;\n    }\n"""
new_eleven = """    try {\n      await withServer(async (ws) => {\n        resetTestPluginRegistry();\n        const restoreProviders = enableRealSpeechProvidersForTalkTests();\n        try {\n          await connectOperator(ws, [\"operator.read\", \"operator.write\"]);\n          const res = await fetchTalkSpeak(ws, {\n            text: \"Hello from talk mode.\",\n            voiceId: \"clawd\",\n            outputFormat: \"pcm_44100\",\n          });\n          expect(res.ok, JSON.stringify(res)).toBe(true);\n          expect(res.payload?.provider).toBe(\"elevenlabs\");\n          expect(res.payload?.outputFormat).toBe(\"pcm_44100\");\n          expect(res.payload?.audioBase64).toBe(Buffer.from([4, 5, 6]).toString(\"base64\"));\n        } finally {\n          restoreProviders();\n        }\n      });\n\n      expect(fetchMock).toHaveBeenCalled();\n      expect(fetchUrl).toContain(\"/v1/text-to-speech/EXAVITQu4vr4xnSDxMaL\");\n      expect(fetchUrl).toContain(\"output_format=pcm_44100\");\n    } finally {\n      globalThis.fetch = originalFetch;\n    }\n"""
if old_eleven not in text:
    raise SystemExit("expected elevenlabs talk test block not found")
text = text.replace(old_eleven, new_eleven, 1)

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
