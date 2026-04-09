{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.4.8";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.4.8/OpenClaw-2026.4.8.zip";
    hash = "sha256-MD7cL0ONDyiU17DB1RDbkuBKBJw36NlQemoFRwxbcfA=";
    stripRoot = false;
  };

  dontUnpack = true;

  installPhase = "${../scripts/openclaw-app-install.sh}";

  meta = with lib; {
    description = "OpenClaw macOS app bundle";
    homepage = "https://github.com/openclaw/openclaw";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
