{
  stdenvNoCC,
  nodejs_24,
  yq,
  jq,
  makeWrapper,
  pnpm_10,
  pnpm_11,
  pnpm_12,
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-pnpm-runtime";
  version = "1";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    nodejs_24
    yq
    jq
    makeWrapper
  ];

  env = {
    PNPM_BUILD_ENV_SH = "${../scripts/pnpm-build-env.sh}";
    OPENCLAW_RUNTIME_LAYOUT_SH = "${../scripts/openclaw-stage-runtime.sh}";
    GATEWAY_INSTALL_SH = "${../scripts/gateway-install.sh}";
    OPENCLAW_BUILD_LOG_SH = "${../scripts/build-log.sh}";
    STDENV_SETUP = "${stdenvNoCC}/setup";
    SOURCE_BUILD_TESTS_DIR = "${../tests/source-build}";
    PNPM_WORKSPACE_INTEGRITIES_SH = "${../scripts/list-pnpm-workspace-integrities.sh}";
    PNPM_10_PACKAGE = pnpm_10;
    PNPM_11_PACKAGE = pnpm_11;
    PNPM_12_PACKAGE = pnpm_12;
  };

  doCheck = true;
  checkPhase = "${../scripts/check-openclaw-pnpm-runtime.sh}";
  installPhase = "${../scripts/empty-install.sh}";
}
