{
  stdenvNoCC,
  nodejs_24,
  patch,
  openclawSource,
}:
stdenvNoCC.mkDerivation {
  name = "openclaw-source-patches";
  dontUnpack = true;
  dontBuild = true;
  nativeBuildInputs = [
    nodejs_24
    patch
  ];
  OPENCLAW_SOURCE = openclawSource;
  PATCH_NIX_STORE_PLUGIN_OWNERSHIP = ../patches/allow-nix-store-plugin-ownership.patch;
  PATCH_NIX_STORE_PLUGIN_OWNERSHIP_DIRECT = ../patches/allow-nix-store-plugin-ownership-direct.patch;
  PATCH_NIX_STORE_PLUGIN_CONTROL_UI = ../patches/allow-nix-store-plugin-control-ui.patch;
  PATCH_SOURCE_OWNERSHIP_SCRIPT = ../scripts/patch-openclaw-source-ownership.mjs;
  doCheck = true;
  checkPhase = "node ${../tests/source-patches/check.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
