{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  nodejs_22,
  pnpm_10,
  pnpm_11,
  fetchPnpmDeps,
  pkg-config,
  jq,
  python3,
  node-gyp,
  git,
  zstd,
}:

# Shared build plumbing for OpenClaw gateway-related derivations.
#
# Goals:
# - one source of truth for pnpm deps fetch + common env
# - keep the individual derivations small/boring

{
  pname,
  sourceInfo,
  pnpmDepsPname ? "openclaw-gateway",
  gatewaySrc ? null,
  src ? null,
  enableSharp ? false,
  extraNativeBuildInputs ? [ ],
  extraBuildInputs ? [ ],
  extraEnv ? { },
  pnpmDepsHash ? (
    sourceInfo.pnpmDepsHashBySystem.${stdenv.hostPlatform.system} or (sourceInfo.pnpmDepsHash or null)
  ),
}:

let
  sourceFetch = lib.removeAttrs sourceInfo [
    "pnpmDepsHash"
    "pnpmDepsHashBySystem"
    "pnpmMajor"
    "releaseTag"
    "releaseVersion"
    "applyPublicSurfaceHardlinksPatch"
    "applySkipPluginAutoEnableNixModePatch"
    "publicSurfaceHardlinksPatch"
    "fsSafeSource"
  ];

  # Prefer nixpkgs' platform mapping instead of hand-rolled arch/platform.
  pnpmPlatform = stdenv.hostPlatform.node.platform;
  pnpmArch = stdenv.hostPlatform.node.arch;

  revShort = lib.substring 0 8 sourceInfo.rev;
  version = "unstable-${revShort}";

  resolvedSrc =
    if src != null then
      src
    else if gatewaySrc != null then
      gatewaySrc
    else
      fetchFromGitHub sourceFetch;

  fsSafeSource = if sourceInfo ? fsSafeSource then fetchFromGitHub sourceInfo.fsSafeSource else null;
  publicSurfaceHardlinksPatch =
    sourceInfo.publicSurfaceHardlinksPatch or ../patches/allow-package-public-surface-hardlinks.patch;

  nodeAddonApi = import ../packages/node-addon-api.nix { inherit stdenv fetchurl; };
  pnpmMajor = toString (sourceInfo.pnpmMajor or "10");
  pnpmByMajor = {
    "10" = pnpm_10;
    "11" = pnpm_11;
  };
  selectedPnpm = pnpmByMajor.${pnpmMajor} or (throw "Unsupported OpenClaw pnpm major ${pnpmMajor}");

  pnpmDeps = fetchPnpmDeps {
    pname = pnpmDepsPname;
    inherit version;
    src = resolvedSrc;
    pnpm = selectedPnpm;
    hash = if pnpmDepsHash != null then pnpmDepsHash else lib.fakeHash;
    fetcherVersion = 3;
    preFixup = lib.optionalString (pnpmMajor == "11") ''
      ${nodejs_22}/bin/node --no-warnings ${../scripts/normalize-pnpm-store-index.js} "$storePath"
    '';
    npm_config_arch = pnpmArch;
    npm_config_platform = pnpmPlatform;
    nativeBuildInputs = [
      git
      nodejs_22
    ];
  };

  envBase = {
    npm_config_arch = pnpmArch;
    npm_config_platform = pnpmPlatform;
    PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS = "false";
    npm_config_nodedir = nodejs_22;
    npm_config_python = python3;
    NODE_PATH = "${nodeAddonApi}/lib/node_modules:${node-gyp}/lib/node_modules";
    PNPM_DEPS = pnpmDeps;
    OPENCLAW_BUILD_ROOT_SH = "${../scripts/build-root.sh}";
    NODE_GYP_WRAPPER_SH = "${../scripts/node-gyp-wrapper.sh}";
    GATEWAY_PREBUILD_SH = "${../scripts/gateway-prebuild.sh}";
    PATCH_BUNDLED_RUNTIME_DEPS_SCRIPT = "${../patches/stage-bundled-plugin-runtime-deps.mjs}";
    PATCH_PUBLIC_SURFACE_HARDLINKS =
      if sourceInfo.applyPublicSurfaceHardlinksPatch or true then
        "${publicSurfaceHardlinksPatch}"
      else
        "";
    PATCH_SKIP_PLUGIN_AUTO_ENABLE_NIX_MODE =
      if sourceInfo.applySkipPluginAutoEnableNixModePatch or true then
        "${../patches/skip-plugin-auto-enable-persist-in-nix-mode.patch}"
      else
        "";
    PROMOTE_PNPM_INTEGRITY_SH = "${../scripts/promote-pnpm-integrity.sh}";
    REMOVE_PACKAGE_MANAGER_FIELD_SH = "${../scripts/remove-package-manager-field.sh}";
    STDENV_SETUP = "${stdenv}/setup";
  }
  // lib.optionalAttrs (fsSafeSource != null) {
    OPENCLAW_FS_SAFE_SOURCE = fsSafeSource;
  };

in
{
  inherit
    version
    pnpmDeps
    pnpmMajor
    resolvedSrc
    pnpmPlatform
    pnpmArch
    nodeAddonApi
    selectedPnpm
    ;

  nativeBuildInputs = [
    nodejs_22
    selectedPnpm
    pkg-config
    jq
    python3
    node-gyp
    zstd
  ]
  ++ extraNativeBuildInputs;

  buildInputs = extraBuildInputs;

  env = envBase // (lib.optionalAttrs enableSharp { SHARP_IGNORE_GLOBAL_LIBVIPS = "1"; }) // extraEnv;

  passthru = {
    inherit
      sourceInfo
      pnpmDeps
      pnpmMajor
      selectedPnpm
      ;
    pinnedRev = sourceInfo.rev;
  };
}
