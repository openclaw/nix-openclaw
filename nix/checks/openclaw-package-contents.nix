{
  lib,
  stdenv,
  nodejs_22,
  openclawGateway,
  requireAgentWorkspaceTemplates ? true,
}:

stdenv.mkDerivation {
  pname = "openclaw-package-contents";
  version = lib.getVersion openclawGateway;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  env = {
    OPENCLAW_GATEWAY = openclawGateway;
  }
  // lib.optionalAttrs (!requireAgentWorkspaceTemplates) {
    OPENCLAW_REQUIRE_AGENT_WORKSPACE_TEMPLATES = "0";
  };

  doCheck = true;
  nativeCheckInputs = [ nodejs_22 ];
  checkPhase = "${../scripts/check-package-contents.sh}";
  installPhase = "${../scripts/empty-install.sh}";
}
