{
  lib,
  pkgs,
  stdenv,
  nodejs_22,
  openclawToolPkgs ? { },
}:

let
  testLib = lib.extend (
    _final: _prev: {
      hm.dag = {
        entryAfter = after: data: {
          inherit after data;
          before = [ ];
        };
      };
    }
  );

  stubModule =
    { lib, ... }:
    {
      options = {
        assertions = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
        };

        home.homeDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/tmp";
        };

        home.packages = lib.mkOption {
          type = lib.types.listOf lib.types.anything;
          default = [ ];
        };

        home.file = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        home.activation = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        launchd.agents = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        systemd.user.services = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        programs.git.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        lib = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      };
    };

  moduleEval =
    openclawConfig:
    testLib.evalModules {
      modules = [
        stubModule
        ../modules/home-manager/openclaw.nix
        (
          { ... }:
          {
            config = {
              home.homeDirectory = "/tmp";
              programs.git.enable = false;
              lib.file.mkOutOfStoreSymlink = path: path;
              programs.openclaw = {
                enable = true;
                launchd.enable = pkgs.stdenv.hostPlatform.isDarwin;
                systemd.enable = pkgs.stdenv.hostPlatform.isLinux;
              }
              // openclawConfig;
            };
          }
        )
      ];
      specialArgs = {
        inherit pkgs;
      };
    };

  failedAssertions =
    eval: lib.filter (assertion: !(assertion.assertion or false)) eval.config.assertions;

  requireNoAssertionFailures =
    name: eval:
    let
      failures = failedAssertions eval;
      messages = map (assertion: assertion.message or "(no message)") failures;
    in
    if failures == [ ] then "ok" else throw "${name}: ${lib.concatStringsSep "; " messages}";

  generatedConfig =
    eval: path:
    builtins.fromJSON (builtins.unsafeDiscardStringContext eval.config.home.file."${path}".text);

  runtimePathProbePackage = pkgs.hello;
  runtimePathProbeBin = lib.getBin runtimePathProbePackage;
  runtimePathProbeBinDir = builtins.unsafeDiscardStringContext "${runtimePathProbeBin}/bin";
  runtimePathProbeName = "hello";
  runtimePathProbeOutput = "Hello, world!";
  codexRuntimeProbePackages =
    (import ../tools/extended.nix {
      inherit pkgs openclawToolPkgs;
      toolNamesOverride = [ "gogcli" ];
    }).tools;
  codexRuntimeProbePackage =
    if codexRuntimeProbePackages == [ ] then
      throw "openclaw-runtime-path check requires gogcli from nix-openclaw-tools"
    else
      builtins.head codexRuntimeProbePackages;
  codexRuntimeProbeBinDir = builtins.unsafeDiscardStringContext "${lib.getBin codexRuntimeProbePackage}/bin";
  codexRuntimeProbeName = "gog";
  codexRuntimeProbeVersionPrefix = "v${lib.getVersion codexRuntimeProbePackage}";
  codexRuntimePluginPackage = pkgs.openclawRuntimePlugins.codex;
  codexAppServerCommand = "${codexRuntimePluginPackage}/node_modules/@openai/codex/bin/codex.js";
  normalizePathEntry = entry: builtins.unsafeDiscardStringContext entry;
  pathEntryIndex =
    needle: entries:
    let
      go =
        index: remaining:
        if remaining == [ ] then
          null
        else if normalizePathEntry (builtins.head remaining) == needle then
          index
        else
          go (index + 1) (builtins.tail remaining);
    in
    go 0 entries;
  pathEntryBefore =
    earlier: later: entries:
    let
      earlierIndex = pathEntryIndex earlier entries;
      laterIndex = pathEntryIndex later entries;
    in
    earlierIndex != null && laterIndex != null && earlierIndex < laterIndex;
  pathPrependHasBinDir = binDir: entries: lib.any (entry: normalizePathEntry entry == binDir) entries;
  pathPrependHasRuntimePath = pathPrependHasBinDir runtimePathProbeBinDir;
  pathPrependStartsWithStorePath =
    entries:
    entries != [ ] && lib.hasPrefix builtins.storeDir (normalizePathEntry (builtins.head entries));
  gatewayServiceFor =
    eval:
    (eval.config.systemd.user.services.openclaw-gateway or { })
    // (eval.config.launchd.agents."com.steipete.openclaw.gateway" or { });
  gatewayWrapperFor =
    service:
    if pkgs.stdenv.hostPlatform.isLinux then
      builtins.head (lib.splitString " " service.Service.ExecStart)
    else
      builtins.head service.config.ProgramArguments;

  runtimePathEval = moduleEval {
    runtimePackages = [ runtimePathProbePackage ];
  };
  runtimePathConfig = generatedConfig runtimePathEval ".openclaw/openclaw.json";
  runtimePathPrepend = ((runtimePathConfig.tools or { }).exec or { }).pathPrepend or [ ];
  runtimePathPrependText = lib.concatStringsSep ":" (map normalizePathEntry runtimePathPrepend);
  runtimePathActivation = builtins.toJSON runtimePathEval.config.home.activation;
  runtimePathService = gatewayServiceFor runtimePathEval;
  runtimePathServiceText = builtins.toJSON runtimePathService;
  runtimePathWrapper = gatewayWrapperFor runtimePathService;
  runtimePathCheck = builtins.deepSeq (requireNoAssertionFailures "runtime path" runtimePathEval) (
    if !(pathPrependHasRuntimePath runtimePathPrepend) then
      throw "runtimePackages did not render into tools.exec.pathPrepend."
    else if !(lib.hasInfix "openclaw-gateway-default" runtimePathServiceText) then
      throw "runtimePackages did not flow through the OpenClaw gateway wrapper."
    else if ((runtimePathConfig.plugins or { }).entries or { }) ? codex then
      throw "runtimePackages must not create or enable a Codex plugin entry."
    else if
      lib.hasInfix "OPENCLAW_CODEX_APP_SERVER_ARGS" runtimePathServiceText
      || lib.hasInfix "OPENCLAW_CODEX_APP_SERVER_BIN" runtimePathServiceText
    then
      throw "runtimePackages must not configure Codex app-server launch environment."
    else if lib.hasInfix "openclaw-link-codex-runtime-profiles.sh" runtimePathActivation then
      throw "runtimePackages without the packaged Codex app-server wrapper must not create Codex native-home profiles."
    else
      "ok"
  );

  runtimePathOverrideEval = moduleEval {
    runtimePackages = [ runtimePathProbePackage ];
    config = {
      tools.exec.pathPrepend = [ "/custom/global" ];
      agents.list = [
        {
          id = "worker";
          tools.exec.pathPrepend = [ "/custom/agent" ];
        }
        {
          id = "global-only";
          tools.exec.security = "allowlist";
        }
      ];
    };
  };
  runtimePathOverrideConfig = generatedConfig runtimePathOverrideEval ".openclaw/openclaw.json";
  runtimePathOverrideGlobal = (
    ((runtimePathOverrideConfig.tools or { }).exec or { }).pathPrepend or [ ]
  );
  runtimePathOverrideAgent = builtins.head (((runtimePathOverrideConfig.agents or { }).list or [ ]));
  runtimePathOverrideAgentPrepend = (
    ((runtimePathOverrideAgent.tools or { }).exec or { }).pathPrepend or [ ]
  );
  runtimePathOverrideGlobalOnlyAgent = builtins.elemAt (
    ((runtimePathOverrideConfig.agents or { }).list or [ ])
  ) 1;
  runtimePathOverrideGlobalOnlyExec = ((runtimePathOverrideGlobalOnlyAgent.tools or { }).exec or { });
  runtimePathOverrideCheck =
    builtins.deepSeq (requireNoAssertionFailures "runtime path overrides" runtimePathOverrideEval)
      (
        if
          !(pathPrependHasRuntimePath runtimePathOverrideGlobal)
          || !(pathPrependStartsWithStorePath runtimePathOverrideGlobal)
          || !(pathEntryBefore runtimePathProbeBinDir "/custom/global" runtimePathOverrideGlobal)
          || !(lib.elem "/custom/global" runtimePathOverrideGlobal)
        then
          throw "runtimePackages did not prefix the global runtime path while preserving user entries."
        else if
          !(pathPrependHasRuntimePath runtimePathOverrideAgentPrepend)
          || !(pathPrependStartsWithStorePath runtimePathOverrideAgentPrepend)
          || !(pathEntryBefore runtimePathProbeBinDir "/custom/agent" runtimePathOverrideAgentPrepend)
          || !(lib.elem "/custom/agent" runtimePathOverrideAgentPrepend)
        then
          throw "runtimePackages did not prefix the agent runtime path while preserving user entries."
        else if runtimePathOverrideGlobalOnlyExec ? pathPrepend then
          throw "runtimePackages should not synthesize agent-level pathPrepend for agents that inherit the global exec config."
        else
          "ok"
      );

  # Opt into Codex only for this proof so runtimePackages alone still do not
  # create a Codex plugin entry.
  codexRuntimePathEval = moduleEval {
    excludeTools = [ "gogcli" ];
    runtimePackages = [ codexRuntimeProbePackage ];
    runtimePlugins = [ "codex" ];
  };
  codexRuntimePathConfig = generatedConfig codexRuntimePathEval ".openclaw/openclaw.json";
  codexRuntimePathPrepend = ((codexRuntimePathConfig.tools or { }).exec or { }).pathPrepend or [ ];
  codexRuntimePathPrependText = lib.concatStringsSep ":" (
    map normalizePathEntry codexRuntimePathPrepend
  );
  codexRuntimePluginLoadPaths = (((codexRuntimePathConfig.plugins or { }).load or { }).paths or [ ]);
  codexRuntimePathActivation = builtins.toJSON codexRuntimePathEval.config.home.activation;
  codexRuntimePathService = gatewayServiceFor codexRuntimePathEval;
  codexRuntimePathServiceText = builtins.toJSON codexRuntimePathService;
  codexRuntimePathWrapper = gatewayWrapperFor codexRuntimePathService;
  codexRuntimePathCheck =
    builtins.deepSeq (requireNoAssertionFailures "codex runtime path" codexRuntimePathEval)
      (
        if !(pathPrependHasBinDir codexRuntimeProbeBinDir codexRuntimePathPrepend) then
          throw "gogcli did not render into tools.exec.pathPrepend for the Codex runtime check."
        else if
          !(lib.any (
            path: lib.hasInfix "openclaw-runtime-plugin-codex" (normalizePathEntry path)
          ) codexRuntimePluginLoadPaths)
        then
          throw "Codex runtime plugin was not rendered into plugins.load.paths for the Codex runtime check."
        else if !(((codexRuntimePathConfig.plugins or { }).entries or { }).codex.enabled or false) then
          throw "Codex runtime plugin entry was not enabled for the opt-in Codex runtime check."
        else if lib.hasInfix "OPENCLAW_CODEX_APP_SERVER_ARGS" codexRuntimePathServiceText then
          throw "Codex runtime plugin must not configure Codex app-server launch arguments."
        else if lib.hasInfix "openclaw-link-codex-runtime-profiles.sh" codexRuntimePathActivation then
          throw "Codex runtime path must not create Codex native-home profiles during activation."
        else
          "ok"
      );

  customCodexCommandEval = moduleEval {
    excludeTools = [ "gogcli" ];
    runtimePackages = [ codexRuntimeProbePackage ];
    runtimePlugins = [ "codex" ];
    config.plugins.entries.codex.config.appServer.command = "/custom/codex";
  };
  customCodexCommandActivation = builtins.toJSON customCodexCommandEval.config.home.activation;
  customCodexCommandService = gatewayServiceFor customCodexCommandEval;
  customCodexCommandServiceText = builtins.toJSON customCodexCommandService;
  customCodexCommandWrapper = gatewayWrapperFor customCodexCommandService;
  customCodexCommandCheck =
    builtins.deepSeq (requireNoAssertionFailures "custom Codex command" customCodexCommandEval)
      (
        if
          lib.hasInfix "OPENCLAW_CODEX_APP_SERVER_BIN" customCodexCommandServiceText
          || lib.hasInfix "OPENCLAW_CODEX_APP_SERVER_ARGS" customCodexCommandServiceText
        then
          throw "custom Codex appServer.command must keep Codex app-server launcher ownership out of nix-openclaw."
        else if lib.hasInfix "openclaw-link-codex-runtime-profiles.sh" customCodexCommandActivation then
          throw "custom Codex appServer.command must not create Nix Codex native-home profiles."
        else
          "ok"
      );

  customCodexEnvEval = moduleEval {
    excludeTools = [ "gogcli" ];
    runtimePackages = [ codexRuntimeProbePackage ];
    runtimePlugins = [ "codex" ];
    environment.OPENCLAW_CODEX_APP_SERVER_BIN = "/custom/env-codex";
  };
  customCodexEnvActivation = builtins.toJSON customCodexEnvEval.config.home.activation;
  customCodexEnvService = gatewayServiceFor customCodexEnvEval;
  customCodexEnvServiceText = builtins.toJSON customCodexEnvService;
  customCodexEnvWrapper = gatewayWrapperFor customCodexEnvService;
  customCodexEnvCheck =
    builtins.deepSeq (requireNoAssertionFailures "custom Codex env" customCodexEnvEval)
      (
        if lib.hasInfix "openclaw-link-codex-runtime-profiles.sh" customCodexEnvActivation then
          throw "custom OPENCLAW_CODEX_APP_SERVER_BIN must not create Nix Codex native-home profiles."
        else if lib.hasInfix "openclaw-codex-app-server" customCodexEnvServiceText then
          throw "custom OPENCLAW_CODEX_APP_SERVER_BIN must keep the Nix Codex launcher out of the gateway wrapper."
        else
          "ok"
      );

  websocketCodexEval = moduleEval {
    excludeTools = [ "gogcli" ];
    runtimePackages = [ codexRuntimeProbePackage ];
    runtimePlugins = [ "codex" ];
    config.plugins.entries.codex.config.appServer = {
      transport = "websocket";
      url = "ws://127.0.0.1:12345";
    };
  };
  websocketCodexActivation = builtins.toJSON websocketCodexEval.config.home.activation;
  websocketCodexService = gatewayServiceFor websocketCodexEval;
  websocketCodexServiceText = builtins.toJSON websocketCodexService;
  websocketCodexWrapper = gatewayWrapperFor websocketCodexService;
  websocketCodexCheck =
    builtins.deepSeq (requireNoAssertionFailures "websocket Codex transport" websocketCodexEval)
      (
        if lib.hasInfix "openclaw-link-codex-runtime-profiles.sh" websocketCodexActivation then
          throw "Codex websocket transport must not create Nix Codex native-home profiles."
        else if
          lib.hasInfix "OPENCLAW_CODEX_APP_SERVER_BIN" websocketCodexServiceText
          || lib.hasInfix "OPENCLAW_CODEX_APP_SERVER_ARGS" websocketCodexServiceText
        then
          throw "Codex websocket transport must keep local stdio app-server launch env out of the gateway wrapper."
        else
          "ok"
      );

  checkKey = builtins.deepSeq [
    runtimePathCheck
    runtimePathOverrideCheck
    codexRuntimePathCheck
    customCodexCommandCheck
    customCodexEnvCheck
    websocketCodexCheck
  ] "ok";

in
stdenv.mkDerivation {
  pname = "openclaw-runtime-path";
  version = "1";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  nativeBuildInputs = [
    nodejs_22
    pkgs.bash
    pkgs.coreutils
  ];
  env = {
    OPENCLAW_RUNTIME_PATH_CHECK = checkKey;
    OPENCLAW_GATEWAY_WRAPPER = runtimePathWrapper;
    OPENCLAW_CODEX_GATEWAY_WRAPPER = codexRuntimePathWrapper;
    OPENCLAW_CUSTOM_CODEX_GATEWAY_WRAPPER = customCodexCommandWrapper;
    OPENCLAW_CUSTOM_CODEX_ENV_GATEWAY_WRAPPER = customCodexEnvWrapper;
    OPENCLAW_CUSTOM_CODEX_ENV_EXPECTED_BIN = "/custom/env-codex";
    OPENCLAW_WEBSOCKET_CODEX_GATEWAY_WRAPPER = websocketCodexWrapper;
    OPENCLAW_RUNTIME_PATH_BASE_PATH = "${nodejs_22}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin";
    OPENCLAW_RUNTIME_PATH_EXPECTED_BIN_DIR = runtimePathProbeBinDir;
    OPENCLAW_RUNTIME_PATH_EXPECTED_COMMAND = runtimePathProbeName;
    OPENCLAW_RUNTIME_PATH_EXPECTED_OUTPUT = runtimePathProbeOutput;
    OPENCLAW_RUNTIME_PATH_PREPEND = runtimePathPrependText;
    OPENCLAW_RUNTIME_PATH_SHELL = "${pkgs.bash}/bin/bash";
    OPENCLAW_CODEX_APP_SERVER_COMMAND = codexAppServerCommand;
    OPENCLAW_CODEX_RUNTIME_EXPECTED_BIN_DIR = codexRuntimeProbeBinDir;
    OPENCLAW_CODEX_RUNTIME_EXPECTED_COMMAND = codexRuntimeProbeName;
    OPENCLAW_CODEX_RUNTIME_EXPECTED_VERSION_PREFIX = codexRuntimeProbeVersionPrefix;
    OPENCLAW_CODEX_RUNTIME_PATH_PREPEND = codexRuntimePathPrependText;
  };
  doCheck = true;
  checkPhase = "${nodejs_22}/bin/node ${../scripts/openclaw-runtime-path-smoke.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
