{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.5.12";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.5.12/OpenClaw-2026.5.12.zip";
    hash = "sha256-fj3r3qLNN1XywoIBtC2uziPXF/+S5gFoakuIQZRabqI=";
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
