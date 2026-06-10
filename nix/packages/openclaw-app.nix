{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.6.5";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.6.5/OpenClaw-2026.6.5.zip";
    hash = "sha256-YfwNueL8u9m28M2RbGv0FoZjhITL7oe5DRwK9gnJnDc=";
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
