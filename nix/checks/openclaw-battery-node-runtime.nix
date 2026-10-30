{
  pkgs,
  stdenvNoCC,
  nodejs_24,
  openclawPackage,
}:
let
  helpers = import ./default-instance/helpers.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  plainPkgs = import pkgs.path { inherit (pkgs.stdenv.hostPlatform) system; };
  explicitHelpers = import ./default-instance/helpers.nix {
    pkgs = plainPkgs;
    inherit (pkgs) lib;
  };
  explicitEval = explicitHelpers.moduleEval {
    package = openclawPackage;
    bundledPlugins.summarize.enable = true;
    exposePluginPackages = true;
  };
  explicitPlugins = builtins.filter (
    package: pkgs.lib.getName package == "summarize"
  ) explicitEval.config.home.packages;
  pluginEval = helpers.moduleEval {
    bundledPlugins.summarize.enable = true;
    exposePluginPackages = true;
  };
  pluginPackages = builtins.filter (
    package: pkgs.lib.getName package == "summarize"
  ) pluginEval.config.home.packages;
in
assert builtins.length pluginPackages == 1;
assert !(plainPkgs ? openclawPackages);
assert explicitEval.config.programs.openclaw.package.drvPath == openclawPackage.drvPath;
assert
  map (package: package.drvPath) explicitPlugins == map (package: package.drvPath) pluginPackages;
stdenvNoCC.mkDerivation {
  name = "openclaw-battery-node-runtime";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  env = {
    OPENCLAW_TOOLS_PATH = openclawPackage.OPENCLAW_TOOLS_PATH;
    EXPOSED_SUMMARIZE_PATH = pkgs.lib.makeBinPath pluginPackages;
    EXPECTED_NODE = "${nodejs_24}/bin/node";
  };
  doCheck = true;
  checkPhase = "${nodejs_24}/bin/node ${../tests/battery-node-runtime}/check.mjs";
  installPhase = "${../scripts/empty-install.sh}";
}
