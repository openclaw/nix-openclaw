{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3Minimal,
  openclaw-gateway,
  openclaw-app ? null,
  extendedTools ? [ ],
  version ? null,
}:

let
  bundleVersion =
    if version != null && version != "" then version else lib.getVersion openclaw-gateway;
  toolsPath = lib.makeBinPath extendedTools;
in
stdenvNoCC.mkDerivation {
  pname = "openclaw";
  version = bundleVersion;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  env = {
    OPENCLAW_APP_PACKAGE = lib.optionalString (openclaw-app != null) "${openclaw-app}";
    OPENCLAW_GATEWAY_BIN = "${openclaw-gateway}/bin/openclaw";
    OPENCLAW_PINNED_WRITE_PYTHON = "${python3Minimal}/bin/python3";
    OPENCLAW_TOOLS_PATH = toolsPath;
    STDENV_SETUP = "${stdenvNoCC}/setup";
  };

  installPhase = "${../scripts/openclaw-batteries-install.sh}";

  meta = with lib; {
    description = "OpenClaw batteries-included bundle (gateway + app + tools)";
    homepage = "https://github.com/openclaw/openclaw";
    license = licenses.mit;
    platforms = platforms.darwin ++ platforms.linux;
    mainProgram = "openclaw";
  };
}
