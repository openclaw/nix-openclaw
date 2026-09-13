{
  pkgs,
  nixpkgs,
  flake-utils,
}:
let
  example = (import ../../examples/hello-world-plugin/flake.nix).outputs {
    self = example;
    inherit nixpkgs flake-utils;
  };
  system = pkgs.stdenv.hostPlatform.system;
  plugin = example.openclawPlugin system;
  package = example.packages.${system}.default;
in
assert builtins.isFunction example.openclawPlugin;
assert plugin.name == "hello-world";
assert plugin.packages == [ package ];
assert plugin.skills == [ ../../examples/hello-world-plugin/skills/hello-world ];
assert example.apps.${system}.default.program == "${package}/bin/hello-world";
pkgs.stdenvNoCC.mkDerivation {
  name = "openclaw-example-plugin";
  dontUnpack = true;
  dontBuild = true;
  doCheck = true;
  nativeBuildInputs = plugin.packages;
  checkPhase = "${../tests/example-plugin.sh}";
  installPhase = "${../scripts/empty-install.sh}";
}
