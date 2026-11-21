{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.11.5";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.11.5/OpenClaw-2026.11.5.zip";
    hash = "sha256-I7RBJ9gqyA83c5FVUlunkaZHaXQvaVMM2i31CjSDC38=";
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
