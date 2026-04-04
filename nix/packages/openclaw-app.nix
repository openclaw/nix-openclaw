{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.4.2";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.4.2/OpenClaw-2026.4.2.zip";
    hash = "sha256-srxXVwtRGBunCEnFRfJFEd2+TjB8o5IzDGIh9yphUZE=";
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
