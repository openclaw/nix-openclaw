{
  stdenvNoCC,
  nodejs_24,
  pnpm_11,
  pnpm_12,
  gnutar,
  zstd,
  sqlite,
  jq,
  node-gyp,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-pnpm-runtime";
  version = "1";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    nodejs_24
    gnutar
    zstd
    sqlite
    jq
    node-gyp
  ];

  env = {
    PNPM_11_PACKAGE = pnpm_11;
    PNPM_12_PACKAGE = pnpm_12;
    GATEWAY_PREBUILD_SH = "${../scripts/gateway-prebuild.sh}";
    OPENCLAW_BUILD_ROOT_SH = "${../scripts/build-root.sh}";
    PROMOTE_PNPM_INTEGRITY_SH = "${../scripts/promote-pnpm-integrity.sh}";
    NODE_GYP_WRAPPER_SH = "${../scripts/node-gyp-wrapper.sh}";
  };

  doCheck = true;
  checkPhase = "${../scripts/check-openclaw-pnpm-runtime.sh}";
  installPhase = "${../scripts/empty-install.sh}";
}
