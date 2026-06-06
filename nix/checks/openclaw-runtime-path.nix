{
  lib,
  pkgs,
  stdenv,
  nodejs_22,
  openclawGateway,
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
      specialArgs = { inherit pkgs; };
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

  runtimeSmokePackage = pkgs.openssl;
  runtimeSmokePackageBin = lib.getBin runtimeSmokePackage;
  runtimeSmokeBin = builtins.unsafeDiscardStringContext "${runtimeSmokePackageBin}/bin";
  runtimeSmokeCommand = "openssl";
  normalizePathEntry = entry: builtins.unsafeDiscardStringContext entry;
  pathPrependHasRuntimeSmokePackage =
    entries: lib.any (entry: normalizePathEntry entry == runtimeSmokeBin) entries;
  pathPrependStartsWithStorePath =
    entries:
    entries != [ ] && lib.hasPrefix builtins.storeDir (normalizePathEntry (builtins.head entries));

  runtimePathEval = moduleEval {
    runtimePackages = [ runtimeSmokePackage ];
  };
  runtimePathConfig = generatedConfig runtimePathEval ".openclaw/openclaw.json";
  runtimePathPrepend = ((runtimePathConfig.tools or { }).exec or { }).pathPrepend or [ ];
  runtimePathSmokePathPrepend = lib.concatStringsSep ":" (map normalizePathEntry runtimePathPrepend);
  runtimePathActivation = builtins.toJSON runtimePathEval.config.home.activation;
  runtimePathLegacyCleanupActivation = builtins.toJSON runtimePathEval.config.home.activation.openclawLegacyCodexRuntimeProfiles;
  runtimePathService = builtins.toJSON (
    (runtimePathEval.config.systemd.user.services.openclaw-gateway or { })
    // (runtimePathEval.config.launchd.agents."com.steipete.openclaw.gateway" or { })
  );
  runtimePathCheck = builtins.deepSeq (requireNoAssertionFailures "runtime path" runtimePathEval) (
    if !(pathPrependHasRuntimeSmokePackage runtimePathPrepend) then
      throw "runtimePackages did not render into tools.exec.pathPrepend."
    else if !(lib.hasInfix "openclaw-gateway-default" runtimePathService) then
      throw "runtimePackages did not flow through the gateway wrapper."
    else if
      lib.hasInfix "openclawCodexRuntimeProfiles" runtimePathActivation
      || lib.hasInfix "openclaw-link-codex-runtime-profiles.sh" runtimePathActivation
    then
      throw "runtimePackages must flow through the gateway runtime PATH, not a Codex-home profile activation."
    else if
      !(lib.hasInfix "openclaw-clean-legacy-codex-home-runtime-profile.sh" runtimePathLegacyCleanupActivation)
    then
      throw "runtimePackages did not wire legacy Codex-home runtime profile cleanup."
    else
      "ok"
  );

  runtimePathOverrideEval = moduleEval {
    runtimePackages = [ runtimeSmokePackage ];
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
          !(pathPrependHasRuntimeSmokePackage runtimePathOverrideGlobal)
          || !(pathPrependStartsWithStorePath runtimePathOverrideGlobal)
          || !(lib.elem "/custom/global" runtimePathOverrideGlobal)
        then
          throw "runtimePackages did not prefix the global tools.exec.pathPrepend while preserving user entries."
        else if
          !(pathPrependHasRuntimeSmokePackage runtimePathOverrideAgentPrepend)
          || !(pathPrependStartsWithStorePath runtimePathOverrideAgentPrepend)
          || !(lib.elem "/custom/agent" runtimePathOverrideAgentPrepend)
        then
          throw "runtimePackages did not prefix agent tools.exec.pathPrepend while preserving user entries."
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
    runtimeSmokePackageBin
  ];
  env = {
    OPENCLAW_RUNTIME_PATH_CHECK = checkKey;
    OPENCLAW_GATEWAY = openclawGateway;
    OPENCLAW_RUNTIME_BASE_PATH = "${pkgs.coreutils}/bin:${pkgs.bash}/bin";
    OPENCLAW_RUNTIME_EXPECTED_BIN_DIR = runtimeSmokeBin;
    OPENCLAW_RUNTIME_EXPECTED_COMMAND = runtimeSmokeCommand;
    OPENCLAW_RUNTIME_EXPECTED_OUTPUT_PREFIX = "help:";
    OPENCLAW_RUNTIME_PATH_PREPEND = runtimePathSmokePathPrepend;
    OPENCLAW_RUNTIME_SHELL = "${pkgs.bash}/bin/bash";
  };
  doCheck = true;
  checkPhase = "${nodejs_22}/bin/node ${../scripts/openclaw-runtime-path-smoke.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
