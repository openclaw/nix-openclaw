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
  # The version test outputs a file; keep it out of directory-only symlinkJoin paths.
  env.NODE_VERSION_CHECK = nodejs_24.tests.version;
  doCheck = true;
  checkPhase = "${nodejs_24}/bin/node ${../scripts/check-node-runtime.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
