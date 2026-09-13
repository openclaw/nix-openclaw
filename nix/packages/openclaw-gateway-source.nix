{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  nodejs_24,
  pnpm_10,
  pnpm_11,
  pnpm_12,
  fetchPnpmDeps,
  pkg-config,
  jq,
  python3,
  perl,
  node-gyp,
  makeWrapper,
  vips,
  git,
  zstd,
  sourceInfo,
  gatewaySrc ? null,
  bundledAcpx ? null,
  pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null),
}:

assert gatewaySrc == null || pnpmDepsHash != null;
assert lib.assertMsg (
  bundledAcpx == null
  || (
    (bundledAcpx.openclawRuntimePlugin.id or null) == "acpx"
    && (bundledAcpx.openclawRuntimePlugin.version or null) == sourceInfo.runtimePluginVersion
  )
) "bundledAcpx must match the pinned ACPX runtime plugin";

let
  common =
    import ../lib/openclaw-gateway-common.nix
      {
        inherit
          lib
          stdenv
          fetchFromGitHub
          fetchurl
          nodejs_24
          pnpm_10
          pnpm_11
          pnpm_12
          fetchPnpmDeps
          pkg-config
          jq
          python3
          node-gyp
          git
          zstd
          ;
      }
      {
        pname = "openclaw-gateway";
        sourceInfo = sourceInfo;
        pnpmDepsHash = pnpmDepsHash;
        pnpmDepsPname = "openclaw-gateway";
        gatewaySrc = gatewaySrc;
        enableSharp = true;
        extraNativeBuildInputs = [
          perl
          makeWrapper
        ];
        extraBuildInputs = [ vips ];
        extraEnv = {
          NODE_BIN = "${nodejs_24}/bin/node";
          PATCH_CLIPBOARD_SH = "${../scripts/patch-clipboard.sh}";
          PATCH_CLIPBOARD_WRAPPER = "${../scripts/clipboard-wrapper.cjs}";
        };
      };

in

stdenv.mkDerivation (finalAttrs: {
  pname = "openclaw-gateway";
  inherit (common) version;

  src = common.resolvedSrc;
  pnpmDeps = common.pnpmDeps;

  nativeBuildInputs = common.nativeBuildInputs;
  buildInputs = common.buildInputs;

  env = common.env // {
    # Nix doesn't automatically substitute finalAttrs into env.
    PNPM_DEPS = finalAttrs.pnpmDeps;
    OPENCLAW_BUNDLED_ACPX = if bundledAcpx == null then "" else toString bundledAcpx;
  };

  passthru = common.passthru;

  postPatch = "${../scripts/gateway-postpatch.sh}";
  buildPhase = "${../scripts/gateway-build.sh}";
  installPhase = "${../scripts/gateway-install.sh}";
  dontFixup = true;
  dontStrip = true;
  dontPatchShebangs = true;

  meta = with lib; {
    description = "Telegram-first AI gateway (OpenClaw)";
    homepage = "https://github.com/openclaw/openclaw";
    license = licenses.mit;
    platforms = platforms.darwin ++ platforms.linux;
    mainProgram = "openclaw";
  };
})
