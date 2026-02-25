{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.2.24";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.2.24/OpenClaw-2026.2.24.zip";
    hash = "sha256-Gzc+3b2ooxu3AFk7lTiXyoPA/djkYDozxna9w4409ds=";
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
