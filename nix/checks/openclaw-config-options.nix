{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  steipeteToolsInput,
  fetchurl,
  nodejs_22,
  pnpm_10,
  fetchPnpmDeps,
  pkg-config,
  jq,
  python3,
  node-gyp,
  git,
  zstd,
  sourceInfo,
  pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null),
}:

let
  pluginCatalog = import ../modules/home-manager/openclaw/plugin-catalog.nix;
  linuxBundledPlugins = builtins.attrNames (lib.filterAttrs (_: plugin: plugin.linux or false) pluginCatalog);
  enableBundledPlugin = name: stdenv.hostPlatform.isDarwin || lib.elem name linuxBundledPlugins;

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

  pluginEval = lib.evalModules {
    modules = [
      stubModule
      { _module.args.steipeteToolsInput = steipeteToolsInput; }
      ../modules/home-manager/openclaw
      (
        { lib, options, ... }:
        {
          config = {
            home.homeDirectory = "/tmp";
            programs.git.enable = false;
            lib.file.mkOutOfStoreSymlink = path: path;
            programs.openclaw = {
              enable = true;
              launchd.enable = false;
              systemd.enable = false;
              instances.default = { };
              bundledPlugins = lib.mapAttrs (name: _: {
                enable = enableBundledPlugin name;
              }) options.programs.openclaw.bundledPlugins;
            };
          };
        }
      )
    ];
    specialArgs = { inherit pkgs; };
  };

  pluginEvalKey = builtins.deepSeq pluginEval.config.assertions "ok";

  common =
    import ../lib/openclaw-gateway-common.nix
      {
        inherit
          lib
          stdenv
          fetchFromGitHub
          fetchurl
          nodejs_22
          pnpm_10
          fetchPnpmDeps
          pkg-config
          jq
          python3
          node-gyp
          git
          zstd
          ;
      }
      {
        pname = "openclaw-config-options";
        sourceInfo = sourceInfo;
        pnpmDepsHash = pnpmDepsHash;
        pnpmDepsPname = "openclaw-gateway";
      };

in

stdenv.mkDerivation (finalAttrs: {
  pname = "openclaw-config-options";
  inherit (common) version;

  src = common.resolvedSrc;
  pnpmDeps = common.pnpmDeps;

  nativeBuildInputs = common.nativeBuildInputs;

  env = common.env // {
    PNPM_DEPS = finalAttrs.pnpmDeps;
    CONFIG_OPTIONS_GENERATOR = "${../scripts/generate-config-options.ts}";
    CONFIG_OPTIONS_GOLDEN = "${../generated/openclaw-config-options.nix}";
    NODE_ENGINE_CHECK = "${../scripts/check-node-engine.ts}";
    OPENCLAW_PLUGIN_EVAL = pluginEvalKey;
    OPENCLAW_SCHEMA_REV = sourceInfo.rev;
  };

  passthru = common.passthru;

  buildPhase = "${../scripts/gateway-tests-build.sh}";
  postPatch = "${../scripts/gateway-postpatch.sh}";

  doCheck = true;
  checkPhase = "${../scripts/config-options-check.sh}";

  installPhase = "${../scripts/empty-install.sh}";
  dontPatchShebangs = true;
})
