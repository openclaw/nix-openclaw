{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.10.10";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.10.10/OpenClaw-2026.10.10.zip";
    hash = "sha256-shj4e6u73jk89LMYrW3U/rzfgbZCUNotuN+Hn6Mtp/c=";
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
