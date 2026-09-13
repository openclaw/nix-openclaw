{ lib, pkgs }:

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

  lockedPathFlake =
    name: path: narHash:
    let
      # If a fixture changes, update with: nix hash path --sri nix/tests/plugins/<name>
      storePath = builtins.path {
        inherit name path;
        sha256 = narHash;
      };
    in
    "path:${builtins.unsafeDiscardStringContext (toString storePath)}?narHash=${narHash}";

  alphaPluginSource =
    lockedPathFlake "openclaw-test-plugin-alpha" ../../tests/plugins/alpha
      "sha256-FV4UN38sPy2Yp/HhqUxd0HW5l2PcIBBmUz4JzxTAOXY=";
  betaPluginSource =
    lockedPathFlake "openclaw-test-plugin-beta" ../../tests/plugins/beta
      "sha256-lDKtQKHZHqOkOprjLZzBEu8cFJhAdyEzsays9hdVeqE=";
  runtimePluginRootSource =
    lockedPathFlake "openclaw-test-plugin-runtime" ../../tests/plugins/runtime
      "sha256-S/N5zWbObP8YpB89B8WylYzWORbw5roz9kFApJAbUOU=";
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
        ../../modules/home-manager/openclaw.nix
        (
          { lib, ... }:
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

  requireAssertionFailure =
    name: needle: eval:
    let
      failures = failedAssertions eval;
      matching = lib.filter (assertion: lib.hasInfix needle (assertion.message or "")) failures;
    in
    if matching != [ ] then "ok" else throw "${name}: expected assertion containing `${needle}`.";

  requireEvalFailure =
    name: value:
    let
      attempted = builtins.tryEval (builtins.deepSeq value "ok");
    in
    if attempted.success then throw "${name}: expected evaluation failure." else "ok";
  generatedConfig = eval: path: builtins.fromJSON eval.config.home.file."${path}".text;

  packageHasQmd =
    pkg:
    let
      qmdPath = builtins.unsafeDiscardStringContext (pkg.OPENCLAW_QMD_PATH or "");
    in
    qmdPath != "";
  isPluginSkillPath = path: path == "/tmp/.local/share/nix-openclaw/skills/default/skill";

  defaultEval = moduleEval { };
  openclawLib = import ../../modules/home-manager/openclaw/lib.nix {
    inherit lib pkgs;
    config = defaultEval.config;
  };
  inherit (openclawLib) usesAgentEntries;
  explicitOwnership = lib.optionalAttrs openclawLib.hasAgentOwnership {
    ownership = "explicit";
  };
  defaultConfig = generatedConfig defaultEval ".openclaw/openclaw.json";
in
{
  inherit
    alphaPluginSource
    betaPluginSource
    defaultConfig
    defaultEval
    explicitOwnership
    generatedConfig
    isPluginSkillPath
    moduleEval
    openclawLib
    packageHasQmd
    requireAssertionFailure
    requireEvalFailure
    requireNoAssertionFailures
    runtimePluginRootSource
    usesAgentEntries
    ;
}
