{
  lib,
  pkgs,
  stdenv,
  steipeteToolsInput,
}:

let
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

  eval = lib.evalModules {
    modules = [
      stubModule
      { _module.args.steipeteToolsInput = steipeteToolsInput; }
      ../modules/home-manager/openclaw
      (
        { lib, ... }:
        {
          config = {
            home.homeDirectory = "/tmp";
            programs.git.enable = false;
            lib.file.mkOutOfStoreSymlink = path: path;
            programs.openclaw = {
              enable = true;
              launchd.enable = false;
              systemd.enable = true;
            };
          };
        }
      )
    ];
    specialArgs = { inherit pkgs; };
  };

  hasUnit = builtins.hasAttr "openclaw-gateway" eval.config.systemd.user.services;
  check = if hasUnit then "ok" else throw "Default OpenClaw instance missing systemd.unitName.";
  checkKey = builtins.deepSeq check "ok";

in
stdenv.mkDerivation {
  pname = "openclaw-default-instance";
  version = "1";
  dontUnpack = true;
  env = {
    OPENCLAW_DEFAULT_INSTANCE = checkKey;
  };
  installPhase = "${../scripts/empty-install.sh}";
}
