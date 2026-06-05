{
  lib,
  stdenv,
  buildNpmPackage,
  nodejs_22,
  makeWrapper,
  sourceInfo,
  openclawBundledAcpx ? null,
}:

let
  buildNpmPackageForOpenClaw = buildNpmPackage.override {
    nodejs = nodejs_22;
  };
  wrapperSrc = ../npm/openclaw;
  lock = builtins.fromJSON (builtins.readFile "${wrapperSrc}/package-lock.json");
  lockedVersion = lock.packages."node_modules/openclaw".version or null;
  acpxPackage = openclawBundledAcpx;
in

assert lib.assertMsg (lockedVersion == sourceInfo.releaseVersion)
  "OpenClaw npm lock version ${toString lockedVersion} does not match OpenClaw ${sourceInfo.releaseVersion}";

buildNpmPackageForOpenClaw {
  pname = "openclaw-gateway";
  version = sourceInfo.releaseVersion;

  src = wrapperSrc;
  npmDepsHash = sourceInfo.gatewayNpmDepsHash;
  dontNpmBuild = true;
  makeCacheWritable = true;

  npmInstallFlags = [
    "--omit=dev"
    "--ignore-scripts"
    "--legacy-peer-deps"
  ];

  nativeBuildInputs = [ makeWrapper ];

  env = {
    NODE_BIN = "${nodejs_22}/bin/node";
    OPENCLAW_BUNDLED_ACPX = lib.optionalString (acpxPackage != null) "${acpxPackage}";
    OPENCLAW_NPM_PACKAGE_ROOT = "node_modules/openclaw";
    OPENCLAW_PATCH_NPM_DIST_SCRIPT = "${../scripts/patch-openclaw-npm-dist.mjs}";
    STDENV_SETUP = "${stdenv}/setup";
  };

  installPhase = "${../scripts/openclaw-gateway-npm-install.sh}";

  dontFixup = true;
  dontStrip = true;
  dontPatchShebangs = true;

  passthru = {
    inherit sourceInfo;
    pinnedRev = sourceInfo.rev;
    npmWrapperSrc = wrapperSrc;
    bundledAcpx = acpxPackage;
  };

  meta = with lib; {
    description = "Telegram-first AI gateway (OpenClaw)";
    homepage = "https://github.com/openclaw/openclaw";
    license = licenses.mit;
    platforms = platforms.darwin ++ platforms.linux;
    mainProgram = "openclaw";
  };
}
