{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.2.25";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.2.25/OpenClaw-2026.2.25.zip";
    hash = "sha256-mSUImRLgV9lUlzhcYaAPwmCue8nTa7b359vqx1WBgsw=";
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
