{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.4.10";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.4.10/OpenClaw-2026.4.10.zip";
    hash = "sha256-qzqaZmJJQ+haww4c8MSJ5LPdZEBXBWab3AZ0WlnWhlQ=";
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
