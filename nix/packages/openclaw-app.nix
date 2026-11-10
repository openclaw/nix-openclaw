{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.11.3";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.11.3/OpenClaw-2026.11.3.zip";
    hash = "sha256-JZ8Q+t8WnQu937BgDDZEPWe8M6coW4gRs8BRSJtnD7Y=";
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
