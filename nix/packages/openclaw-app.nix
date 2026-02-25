{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.2.23";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.2.23/OpenClaw-2026.2.23.zip";
    hash = "sha256-J1L67xiPkPB+56tBM8r6Q/bQyEi4qtXdePDcDM67h5s=";
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
