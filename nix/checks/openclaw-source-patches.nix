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
  OWNERSHIP_PATCH = ../patches/allow-nix-store-plugin-ownership.patch;
  doCheck = true;
  checkPhase = "node ${../tests/source-patches/check.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
