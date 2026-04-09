{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.4.9";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.4.9/OpenClaw-2026.4.9.zip";
    hash = "sha256-/6WwYQz6Cl3AcZNK5Vyn5eqEaJTo8sj+2YdBWvgmYBA=";
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
