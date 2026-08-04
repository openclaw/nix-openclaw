{
  lib,
  stdenvNoCC,
  nodejs_22,
}:

let
  scriptsDir = ../scripts;
  generatedLocks = import ../generated/openclaw-runtime-plugins/default.nix;
  generatedLocksJson = builtins.toFile "openclaw-runtime-plugin-locks.json" (builtins.toJSON generatedLocks);
in
stdenvNoCC.mkDerivation {
  pname = "openclaw-runtime-plugin-locks";
  version = "1";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ nodejs_22 ];

  env = {
    OPENCLAW_RUNTIME_PLUGIN_LOCK_DIR = "${../generated/openclaw-runtime-plugins}";
    OPENCLAW_RUNTIME_PLUGIN_LOCKS_JSON = "${generatedLocksJson}";
    OPENCLAW_SOURCE_INFO_PATH = "${../sources/openclaw-source.nix}";
  };

  doCheck = true;
  checkPhase = ''
    ${nodejs_22}/bin/node --test ${scriptsDir}/openclaw-runtime-plugin-version.test.mjs
    ${nodejs_22}/bin/node ${scriptsDir}/check-openclaw-runtime-plugin-locks.mjs
  '';
  installPhase = "${../scripts/empty-install.sh}";

  meta.description = "Validate generated OpenClaw runtime plugin locks and support report";
}
