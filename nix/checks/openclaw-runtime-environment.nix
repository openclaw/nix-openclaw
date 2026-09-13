{
  lib,
  pkgs,
  nodejs_24,
}:
let
  helpers = import ./default-instance/helpers.nix { inherit lib pkgs; };
  fixtures = ../tests/runtime-environment;
  environment = import ../modules/home-manager/openclaw/environment.nix { inherit lib pkgs; };
  guardFor =
    value:
    pkgs.writeShellScript "runtime-environment-guard" (
      environment.renderGuards [
        {
          key = "NIX_TEST_GUARD";
          inherit value;
          plugin = "plugin $(touch unexpected-command)";
          instance = "instance $value";
        }
      ]
    );
  literals = builtins.fromJSON (builtins.readFile (fixtures + "/literals.json"));
  values = literals // {
    NIX_TEST_FILE_VALUE = "${fixtures}/file 'quoted' $value";
    NIX_TEST_PREFIXED = "${fixtures}/prefixed";
    NIX_TEST_OTHER_PREFIX = "${fixtures}/other-prefix";
    NIX_TEST_KEEP_FILE = "${fixtures}/prefixed";
    NIX_TEST_MISSING_FILE = "/nonexistent/nix-openclaw-fixture";
    NIX_TEST_OVERRIDE = "top-level value";
  };
  expected = literals // {
    NIX_TEST_FILE_VALUE = "literal file contents $HOME $(touch unexpected-command)";
    NIX_TEST_PREFIXED = "first=second";
    NIX_TEST_OTHER_PREFIX = "OTHER=preserved";
    NIX_TEST_KEEP_FILE = values.NIX_TEST_KEEP_FILE;
    NIX_TEST_MISSING_FILE = values.NIX_TEST_MISSING_FILE;
    NIX_TEST_OVERRIDE = "instance value";
  };
  evaluated = helpers.moduleEval {
    package = pkgs.writeShellScriptBin "openclaw" (builtins.readFile (fixtures + "/cli.sh"));
    toolNames = [ ];
    installApp = false;
    environment = values;
    instances.default = {
      appDefaults.enable = false;
      environment.NIX_TEST_OVERRIDE = "instance value";
    };
  };
  wrapper =
    if pkgs.stdenv.hostPlatform.isDarwin then
      builtins.head
        evaluated.config.launchd.agents."com.steipete.openclaw.gateway".config.ProgramArguments
    else
      builtins.head (
        lib.splitString " " evaluated.config.systemd.user.services.openclaw-gateway.Service.ExecStart
      );
in
assert helpers.requireNoAssertionFailures "runtime environment" evaluated == "ok";
pkgs.stdenvNoCC.mkDerivation {
  name = "openclaw-runtime-environment";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  doCheck = true;
  nativeBuildInputs = [ nodejs_24 ];
  GATEWAY_WRAPPER = wrapper;
  GUARD_VALID = guardFor values.NIX_TEST_FILE_VALUE;
  GUARD_MISSING = guardFor "/nonexistent/file 'quoted' $value";
  GUARD_EMPTY = guardFor "";
  ENV_EXPORT_HELPER = ../modules/home-manager/openclaw-export-env.sh;
  BASH_BIN = lib.getExe pkgs.bash;
  FALSE_BIN = lib.getExe' pkgs.coreutils "false";
  READ_FAILURE_FILE = values.NIX_TEST_FILE_VALUE;
  EXPECTED_ENV_FILE = pkgs.writeText "runtime-environment-expected.json" (builtins.toJSON expected);
  OPENCLAW_ENV_TEST_PRINTENV = lib.getExe' pkgs.coreutils "printenv";
  checkPhase = "${nodejs_24}/bin/node ${fixtures}/check.mjs";
  installPhase = "${../scripts/empty-install.sh}";
}
