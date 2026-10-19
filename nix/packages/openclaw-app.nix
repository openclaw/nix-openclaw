{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.10.4";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.10.4/OpenClaw-2026.10.4.zip";
    hash = "sha256-Hpt99xYL5fP1CPV1mdEOXIuMx3aMamK5P8CYy4UbwYA=";
    stripRoot = false;
  };

  dontUnpack = true;
  # Shebang fixups would invalidate the signed upstream app bundle.
  dontFixup = true;

  installPhase = "${../scripts/openclaw-app-install.sh}";

  meta = with lib; {
    description = "OpenClaw macOS app bundle";
    homepage = "https://github.com/openclaw/openclaw";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
