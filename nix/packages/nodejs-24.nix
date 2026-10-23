{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  testers,
  nodejs_24,
}:

# Keep the fallback private until the consumer's Nixpkgs has the required patch.
if lib.versionAtLeast nodejs_24.version "24.22.1" then
  nodejs_24
else
  let
    platform =
      {
        aarch64-darwin = {
          archive = "darwin-arm64";
          hash = "654ba79de6155647e22321932b45f2a1ccb705976cc337c9b8e278beb085a628";
        };
        x86_64-linux = {
          archive = "linux-x64";
          hash = "6c172a9ab6718f7b801fb5a7bd486af2ee5e32758086a04b84fcce2aa77095e6";
        };
      }
      .${stdenvNoCC.hostPlatform.system}
        or (throw "Unsupported OpenClaw Node platform ${stdenvNoCC.hostPlatform.system}");
  in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "nodejs";
    version = "24.22.1";
    src = fetchurl {
      url = "https://nodejs.org/dist/v${finalAttrs.version}/node-v${finalAttrs.version}-${platform.archive}.tar.xz";
      sha256 = platform.hash;
    };
    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    dontPatchShebangs = true;
    installPhase = "${../scripts/install-node-runtime.sh}";
    env = {
      NODE_RUNTIME_CHECK = "${../scripts/check-node-runtime.mjs}";
      STDENV_SETUP = "${stdenvNoCC}/setup";
    };
    doInstallCheck = true;
    installCheckPhase = "${../scripts/check-installed-node-runtime.sh}";
    passthru = {
      inherit (nodejs_24) python;
      npm = finalAttrs.finalPackage;
      tests.version = testers.testVersion {
        package = finalAttrs.finalPackage;
        version = "v${finalAttrs.version}";
      };
    };
    meta = nodejs_24.meta // {
      platforms = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    };
  })
