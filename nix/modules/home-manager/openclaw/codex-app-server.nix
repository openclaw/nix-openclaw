{
  lib,
  pkgs,
}:

# Nix adapter for the packaged upstream Codex runtime plugin.
#
# Upstream OpenClaw's Codex app-server contract is intentionally narrow:
# - OpenClaw sets per-agent CODEX_HOME to `<agentDir>/codex-home`;
# - OpenClaw normally inherits HOME from the gateway process;
# - appServer.command or OPENCLAW_CODEX_APP_SERVER_BIN means the operator chose
#   the executable OpenClaw should spawn.
#
# nix-openclaw needs one extra behavior for the packaged Codex plugin: Codex
# command/exec should see Nix runtimePackages. The adapter does that by
# selecting a Nix launcher. That launcher runs only after OpenClaw has chosen
# the app-server command and set CODEX_HOME for one agent, so it is the narrow
# place that may create/update $CODEX_HOME/home/.nix-profile/bin and set
# HOME=$CODEX_HOME/home. Setting HOME is intentional here because Codex
# command/exec rebuilds command PATH around $HOME/.nix-profile/bin.
#
# Home Manager activation must not create or update
# $CODEX_HOME/home/.nix-profile/bin. Activation cannot see inherited process
# environment, and upstream lets
# OPENCLAW_CODEX_APP_SERVER_BIN override the managed command at runtime. If the
# user selects WebSocket transport, appServer.command, or
# OPENCLAW_CODEX_APP_SERVER_BIN, this module must step back.
#
# Before changing this file, re-check these upstream OpenClaw contracts:
# - extensions/codex/src/app-server/auth-bridge.ts:
#   resolveCodexAppServerHomeDir(), resolveCodexAppServerNativeHomeDir(), and
#   withAgentCodexHomeEnvironment();
# - extensions/codex/src/app-server/config.ts:
#   resolveCodexAppServerRuntimeOptions() command/env override precedence;
# - docs/plugins/codex-harness-reference.md: "App-server auth and isolated
#   state" and supported appServer fields.
let
  nonEmptyString = value: builtins.isString value && lib.trim value != "";
in
{
  forInstance =
    {
      inst,
      runtimeProfile,
      runtimeEnvAll,
      userPluginEntries,
    }:
    let
      enabled = lib.elem "codex" inst.runtimePlugins;
      userAppServerConfig = (((userPluginEntries.codex or { }).config or { }).appServer or { });
      userAppServerCommand = userAppServerConfig.command or null;
      # Upstream defaults appServer.transport to stdio. WebSocket transport
      # connects to an already-running app-server, so nix-openclaw must not
      # offer a local stdio launcher for that mode.
      appServerUsesLocalStdio = (userAppServerConfig.transport or "stdio") != "websocket";
      appServerBinEnvEntries = lib.filter (
        entry: entry.key == "OPENCLAW_CODEX_APP_SERVER_BIN"
      ) runtimeEnvAll;
      # runtimeEnvAll is exported in order by the gateway wrapper; the final
      # value is what OpenClaw's process environment sees.
      configuredAppServerBinEnv =
        if appServerBinEnvEntries == [ ] then null else (lib.last appServerBinEnvEntries).value;
      # Configured env is static, so omit the Nix fallback entirely. Inherited
      # env is only visible when the gateway starts; the shell guard below keeps
      # that local-testing override ahead of the Nix launcher.
      #
      # appServer.args and OPENCLAW_CODEX_APP_SERVER_ARGS are not checked here:
      # upstream OpenClaw resolves args separately from the executable. When
      # nix-openclaw selects the packaged launcher, those args still flow to the
      # wrapper and then to upstream Codex.
      shouldOfferNixManagedCodexLauncher =
        enabled
        && appServerUsesLocalStdio
        && !(nonEmptyString userAppServerCommand)
        && !(nonEmptyString configuredAppServerBinEnv);
      codexAppServerBin = "${pkgs.openclawRuntimePlugins.codex}/node_modules/@openai/codex/bin/codex.js";
      appServerWrapperScript = pkgs.replaceVars ../../../scripts/openclaw-codex-app-server-wrapper.sh {
        inherit codexAppServerBin;
        mkdirBin = lib.getExe' pkgs.coreutils "mkdir";
        lnBin = lib.getExe' pkgs.coreutils "ln";
        readlinkBin = lib.getExe' pkgs.coreutils "readlink";
        rmBin = lib.getExe' pkgs.coreutils "rm";
        runtimeProfileBinDir = "${runtimeProfile}/bin";
      };
      appServerWrapper = pkgs.stdenvNoCC.mkDerivation {
        name = "openclaw-codex-app-server";
        dontUnpack = true;
        OPENCLAW_CODEX_APP_SERVER_WRAPPER = appServerWrapperScript;
        installPhase = "${../../../scripts/openclaw-codex-app-server-wrapper-install.sh}";
      };
      # OpenClaw's Codex plugin owns app-server lifecycle and sets CODEX_HOME
      # per agent. This wrapper is only selected for the packaged Nix Codex
      # runtime plugin's local stdio transport when the user has not set
      # appServer.command. It sets HOME=$CODEX_HOME/home, links
      # $HOME/.nix-profile/bin to the Nix runtime bin directory, and prepends it
      # so Codex command/exec can resolve runtimePackages. The guard preserves
      # inherited OPENCLAW_CODEX_APP_SERVER_BIN, matching upstream's env override.
      gatewayEnvironmentScript = lib.optionalString shouldOfferNixManagedCodexLauncher ''
        if [ -z "''${OPENCLAW_CODEX_APP_SERVER_BIN:-}" ]; then
          export OPENCLAW_CODEX_APP_SERVER_BIN="${appServerWrapper}/bin/openclaw-codex-app-server"
        fi
      '';
    in
    {
      inherit gatewayEnvironmentScript;
    };
}
