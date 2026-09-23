{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.9.4";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.9.4/OpenClaw-2026.9.4.zip";
    hash = "sha256-nDNsn7RBaEycKnaacfD79IeHSpBAH0RzbxVTlQ8gOE8=";
    stripRoot = false;
  };

  dontUnpack = true;
  # Fixups such as shebang rewriting invalidate the upstream bundle signature.
  dontFixup = true;

  installPhase = "${../scripts/openclaw-app-install.sh}";

  meta = with lib; {
    description = "OpenClaw macOS app bundle";
    homepage = "https://github.com/openclaw/openclaw";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
