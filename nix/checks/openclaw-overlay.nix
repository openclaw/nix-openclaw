{
  lib,
  stdenvNoCC,
  nixpkgs,
  system,
  overlay,
  packagingPkgs,
}:

let
  base = import nixpkgs { inherit system; };
  overlaid = import nixpkgs {
    inherit system;
    overlays = [ overlay ];
  };
  privateNames = [
    "nodejs_24"
    "pnpm_11"
    "pnpm_12"
  ];
  runtimeNames = [
    "nodejs"
    "nodejs-slim"
    "nodejs-slim_24"
    "pnpm"
    "pnpm_10"
  ]
  ++ privateNames;
  unchanged =
    name:
    builtins.hasAttr name base == builtins.hasAttr name overlaid
    && (!(builtins.hasAttr name base) || base.${name}.drvPath == overlaid.${name}.drvPath);
  privatePackages = import ../packages { pkgs = base; };
  scopedCallPackage = base.newScope { inherit (privatePackages) nodejs_24; };
  scopedVips = scopedCallPackage ({ vips }: vips) { };
  scopedNode = scopedCallPackage ({ nodejs_24 }: nodejs_24) { };
  namespaced =
    name:
    overlaid.openclawPackages.${name}.drvPath == privatePackages.${name}.drvPath
    && (overlaid.openclawPackages.withTools { }).${name}.drvPath == privatePackages.${name}.drvPath;
in
assert lib.assertMsg (lib.all unchanged runtimeNames)
  "The OpenClaw overlay must not change consumer Node or pnpm attributes.";
assert lib.assertMsg (
  packagingPkgs.libadwaita.drvPath == base.libadwaita.drvPath
  && packagingPkgs.ffmpeg.drvPath == base.ffmpeg.drvPath
) "OpenClaw packaging must retain cached Nixpkgs GTK and FFmpeg derivations.";
assert lib.assertMsg (
  scopedVips.drvPath == base.vips.drvPath && scopedNode.drvPath == privatePackages.nodejs_24.drvPath
) "The private runtime scope must preserve unrelated Nixpkgs dependencies.";
assert lib.assertMsg (lib.all namespaced privateNames)
  "Private Node and pnpm packages must remain available under openclawPackages and withTools.";
stdenvNoCC.mkDerivation {
  name = "openclaw-overlay";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = "${../scripts/empty-install.sh}";
}
