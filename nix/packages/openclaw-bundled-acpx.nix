{
  lib,
  buildNpmPackage,
  nodejs_22,
  sourceInfo,
}:

let
  buildNpmPackageForOpenClaw = buildNpmPackage.override {
    nodejs = nodejs_22;
  };
  wrapperSrc = ../npm/openclaw-runtime-plugins/acpx;
  lock = builtins.fromJSON (builtins.readFile "${wrapperSrc}/package-lock.json");
  lockedVersion = lock.packages."node_modules/@openclaw/acpx".version or null;
in

assert lib.assertMsg (lockedVersion == sourceInfo.releaseVersion)
  "ACPX npm lock version ${toString lockedVersion} does not match OpenClaw ${sourceInfo.releaseVersion}";

buildNpmPackageForOpenClaw {
  pname = "openclaw-bundled-acpx";
  version = sourceInfo.releaseVersion;

  src = wrapperSrc;
  npmDepsHash = sourceInfo.acpxNpmDepsHash;
  dontNpmBuild = true;
  makeCacheWritable = true;

  npmInstallFlags = [
    "--omit=dev"
    "--ignore-scripts"
    "--legacy-peer-deps"
  ];

  dontFixup = true;
  dontStrip = true;
  dontPatchShebangs = true;

  installPhase = "${../scripts/openclaw-bundled-acpx-install.sh}";

  meta = with lib; {
    description = "OpenClaw ACPX runtime plugin from npm shrinkwrap";
    homepage = "https://github.com/openclaw/openclaw";
    license = licenses.mit;
    platforms = platforms.darwin ++ platforms.linux;
  };
}
