{
  stdenvNoCC,
  nodejs_24,
}:

stdenvNoCC.mkDerivation {
  name = "openclaw-node-runtime";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  nativeCheckInputs = [ nodejs_24 ];
  doCheck = true;
  checkPhase = "${nodejs_24}/bin/node ${../scripts/check-node-runtime.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
