{
  lib,
  pkgs,
  stdenv,
  nodejs_22,
  openclawGateway,
  openclawCodexRuntimePlugin,
}:

let
  modulePkgs = pkgs // {
    openclawRuntimePlugins = {
      codex = openclawCodexRuntimePlugin;
    };
  };

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
                launchd.enable = modulePkgs.stdenv.hostPlatform.isDarwin;
                systemd.enable = modulePkgs.stdenv.hostPlatform.isLinux;
              }
              // openclawConfig;
            };
          }
        )
      ];
      specialArgs = {
        pkgs = modulePkgs;
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

  runtimePathProbe = pkgs.writeShellApplication {
    name = "openclaw-runtime-path-probe";
    text = builtins.readFile ../tests/openclaw-runtime-path-probe.sh;
  };
  runtimePathProbeBin = lib.getBin runtimePathProbe;
  runtimePathProbeBinDir = builtins.unsafeDiscardStringContext "${runtimePathProbeBin}/bin";
  runtimePathProbeName = "openclaw-runtime-path-probe";
  runtimePathProbeOutput = "openclaw-runtime-path-probe-ok";
  normalizePathEntry = entry: builtins.unsafeDiscardStringContext entry;
  pathPrependHasRuntimePath =
    entries: lib.any (entry: normalizePathEntry entry == runtimePathProbeBinDir) entries;
  pathPrependStartsWithStorePath =
    entries:
    entries != [ ] && lib.hasPrefix builtins.storeDir (normalizePathEntry (builtins.head entries));

  runtimePathEval = moduleEval {
    runtimePackages = [ runtimePathProbe ];
  };
  runtimePathConfig = generatedConfig runtimePathEval ".openclaw/openclaw.json";
  runtimePathPrepend = ((runtimePathConfig.tools or { }).exec or { }).pathPrepend or [ ];
  runtimePathPrependText = lib.concatStringsSep ":" (map normalizePathEntry runtimePathPrepend);
  runtimePathActivation = builtins.toJSON runtimePathEval.config.home.activation;
  runtimePathService =
    (runtimePathEval.config.systemd.user.services.openclaw-gateway or { })
    // (runtimePathEval.config.launchd.agents."com.steipete.openclaw.gateway" or { });
  runtimePathServiceText = builtins.toJSON runtimePathService;
  runtimePathWrapper =
    if pkgs.stdenv.hostPlatform.isLinux then
      builtins.head (lib.splitString " " runtimePathService.Service.ExecStart)
    else
      builtins.head runtimePathService.config.ProgramArguments;
  runtimePathCheck = builtins.deepSeq (requireNoAssertionFailures "runtime path" runtimePathEval) (
    if !(pathPrependHasRuntimePath runtimePathPrepend) then
      throw "runtimePackages did not render into tools.exec.pathPrepend."
    else if !(lib.hasInfix "openclaw-gateway-default" runtimePathServiceText) then
      throw "runtimePackages did not flow through the OpenClaw gateway wrapper."
    else if ((runtimePathConfig.plugins or { }).entries or { }) ? codex then
      throw "runtimePackages must not create or enable a Codex plugin entry."
    else if
      lib.hasInfix "openclawCodexRuntimeProfiles" runtimePathActivation
      || lib.hasInfix "openclaw-link-codex-runtime-profiles.sh" runtimePathActivation
      || lib.hasInfix "openclaw-clean-legacy-codex-home-runtime-profile.sh" runtimePathActivation
    then
      throw "runtimePackages must flow through runtime paths, not Codex-home profile activation."
    else
      "ok"
  );

  runtimePathOverrideEval = moduleEval {
    runtimePackages = [ runtimePathProbe ];
    config = {
      tools.exec.pathPrepend = [ "/custom/global" ];
      agents.list = [
        {
          id = "worker";
          tools.exec.pathPrepend = [ "/custom/agent" ];
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
  runtimePathOverrideCheck =
    builtins.deepSeq (requireNoAssertionFailures "runtime path overrides" runtimePathOverrideEval)
      (
        if
          !(pathPrependHasRuntimePath runtimePathOverrideGlobal)
          || !(pathPrependStartsWithStorePath runtimePathOverrideGlobal)
          || !(lib.elem "/custom/global" runtimePathOverrideGlobal)
        then
          throw "runtimePackages did not prefix the global runtime path while preserving user entries."
        else if
          !(pathPrependHasRuntimePath runtimePathOverrideAgentPrepend)
          || !(pathPrependStartsWithStorePath runtimePathOverrideAgentPrepend)
          || !(lib.elem "/custom/agent" runtimePathOverrideAgentPrepend)
        then
          throw "runtimePackages did not prefix the agent runtime path while preserving user entries."
        else
          "ok"
      );

  checkKey = builtins.deepSeq [
    runtimePathCheck
    runtimePathOverrideCheck
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
    OPENCLAW_GATEWAY = openclawGateway;
    OPENCLAW_GATEWAY_WRAPPER = runtimePathWrapper;
    OPENCLAW_RUNTIME_PATH_CODEX_PLUGIN_ROOT = openclawCodexRuntimePlugin;
    OPENCLAW_RUNTIME_PATH_BASE_PATH = "${nodejs_22}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin";
    OPENCLAW_RUNTIME_PATH_EXPECTED_BIN_DIR = runtimePathProbeBinDir;
    OPENCLAW_RUNTIME_PATH_EXPECTED_COMMAND = runtimePathProbeName;
    OPENCLAW_RUNTIME_PATH_EXPECTED_OUTPUT = runtimePathProbeOutput;
    OPENCLAW_RUNTIME_PATH_PREPEND = runtimePathPrependText;
    OPENCLAW_RUNTIME_PATH_SHELL = "${pkgs.bash}/bin/bash";
  };
  doCheck = true;
  checkPhase = "${nodejs_22}/bin/node ${../scripts/openclaw-runtime-path-smoke.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
