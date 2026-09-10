{
  callPackage,
  writeShellScript,
  writeText,
  bash,
  stdenvNoCC,
  nodejs_24,
  pnpm_11,
  pnpm_12,
  gnutar,
  zstd,
  sqlite,
  jq,
  yq,
  node-gyp,
}:

let
  common = callPackage ../lib/openclaw-gateway-common.nix { inherit pnpm_11 pnpm_12; };
  contracts = map (
    major:
    let
      package = common {
        pname = "openclaw-pnpm-runtime";
        sourceInfo = (import ../sources/openclaw-source.nix) // {
          pnpmMajor = major;
        };
      };
    in
    {
      inherit major;
      pnpm = "${package.selectedPnpm}/bin/pnpm";
      version = package.selectedPnpm.version;
      prePnpmInstall = writeShellScript "pnpm-${major}-pre-install" (
        package.pnpmDeps.prePnpmInstall or ""
      );
      preFixup = writeShellScript "pnpm-${major}-pre-fixup" package.pnpmDeps.preFixup;
      postInstall = writeShellScript "pnpm-${major}-post-install" (
        package.pnpmDeps.postInstall or ""
      );
      consumerEnv = builtins.intersectAttrs {
        pnpm_config_trust_lockfile = null;
      } package.env;
    }
  ) [
    "11"
    "12"
  ];
in
stdenvNoCC.mkDerivation {
  pname = "openclaw-pnpm-runtime";
  version = "1";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    bash
    nodejs_24
    gnutar
    zstd
    sqlite
    jq
    yq
    node-gyp
  ];

  env = {
    BASH = "${bash}/bin/bash";
    PNPM_11_PACKAGE = pnpm_11;
    PNPM_12_PACKAGE = pnpm_12;
    GATEWAY_PREBUILD_SH = "${../scripts/gateway-prebuild.sh}";
    OPENCLAW_BUILD_ROOT_SH = "${../scripts/build-root.sh}";
    PROMOTE_PNPM_INTEGRITY_SH = "${../scripts/promote-pnpm-integrity.sh}";
    NODE_GYP_WRAPPER_SH = "${../scripts/node-gyp-wrapper.sh}";
    REMOVE_PACKAGE_MANAGER_FIELD_SH = "${../scripts/remove-package-manager-field.sh}";
    PNPM_REGISTRY_CONTRACTS = writeText "pnpm-registry-contracts.json" (builtins.toJSON contracts);
    CHECK_PNPM_REGISTRY = "${../scripts/check-openclaw-pnpm-registry.mjs}";
  };

  __darwinAllowLocalNetworking = true;

  doCheck = true;
  checkPhase = "${../scripts/check-openclaw-pnpm-runtime.sh}";
  installPhase = "${../scripts/empty-install.sh}";
}
