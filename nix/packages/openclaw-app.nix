{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.6.11";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.6.11/OpenClaw-2026.6.11.zip";
    hash = "sha256-FWSbcX6WFvw3tlvGvw4ucTu/Ptn5xootN6QDU1f3dMs=";
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
