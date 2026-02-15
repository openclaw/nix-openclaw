{ lib
, stdenv
, fetchFromGitHub
, fetchurl
, nodejs_22
, pnpm_10
, fetchPnpmDeps
, bun
, pkg-config
, jq
, python3
, node-gyp
, vips
, git
, zstd
, sourceInfo
, pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null)
}:

let
  sourceFetch = lib.removeAttrs sourceInfo [ "pnpmDepsHash" ];
  pnpmPlatform = if stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  pnpmArch = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  revShort = lib.substring 0 8 sourceInfo.rev;
  nodeAddonApi = import ../packages/node-addon-api.nix { inherit stdenv fetchurl; };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "openclaw-gateway-tests";
  version = "unstable-${revShort}";

  src = fetchFromGitHub sourceFetch;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    hash = if pnpmDepsHash != null
      then pnpmDepsHash
      else lib.fakeHash;
    fetcherVersion = 2;
    npm_config_arch = pnpmArch;
    npm_config_platform = pnpmPlatform;
    nativeBuildInputs = [ git ];
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm_10
    bun
    pkg-config
    jq
    python3
    node-gyp
    zstd
  ];

  buildInputs = [ vips ];

  env = {
    SHARP_IGNORE_GLOBAL_LIBVIPS = "1";
    npm_config_arch = pnpmArch;
    npm_config_platform = pnpmPlatform;
    PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS = "false";
    npm_config_nodedir = nodejs_22;
    npm_config_python = python3;
    NODE_PATH = "${nodeAddonApi}/lib/node_modules:${node-gyp}/lib/node_modules";
    PNPM_DEPS = finalAttrs.pnpmDeps;
    NODE_GYP_WRAPPER_SH = "${../scripts/node-gyp-wrapper.sh}";
    GATEWAY_PREBUILD_SH = "${../scripts/gateway-prebuild.sh}";
    PROMOTE_PNPM_INTEGRITY_SH = "${../scripts/promote-pnpm-integrity.sh}";
    REMOVE_PACKAGE_MANAGER_FIELD_SH = "${../scripts/remove-package-manager-field.sh}";
    STDENV_SETUP = "${stdenv}/setup";
  };

  postPatch = "${../scripts/gateway-postpatch.sh}";
  buildPhase = "${../scripts/gateway-tests-build.sh}";

  doCheck = true;
  checkPhase = "${../scripts/gateway-tests-check.sh}";

  installPhase = "${../scripts/empty-install.sh}";
  dontPatchShebangs = true;
})
