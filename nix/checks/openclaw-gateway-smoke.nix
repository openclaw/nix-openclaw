{
  lib,
  pkgs,
  stdenv,
  nodejs_22,
  openclawGateway,
  includeRuntimePluginSmoke ? false,
}:

stdenv.mkDerivation {
  pname =
    if includeRuntimePluginSmoke then
      "openclaw-runtime-plugin-gateway-smoke"
    else
      "openclaw-gateway-smoke";
  version = lib.getVersion openclawGateway;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ nodejs_22 ];

  env = {
    OPENCLAW_GATEWAY = openclawGateway;
  }
  // lib.optionalAttrs includeRuntimePluginSmoke {
    OPENCLAW_RUNTIME_PLUGIN_SMOKE_ID = "diagnostics-prometheus";
    OPENCLAW_RUNTIME_PLUGIN_SMOKE_ROOT = "${pkgs.openclawRuntimePlugins.diagnostics-prometheus}";
  };

  __darwinAllowLocalNetworking = true;

  doCheck = true;
  checkPhase = "${nodejs_22}/bin/node ${../scripts/gateway-smoke.mjs}";
  installPhase = "${../scripts/empty-install.sh}";
}
