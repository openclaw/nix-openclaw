{
  lib,
  stdenv,
  nodejs_24,
  openclawGateway,
}:

stdenv.mkDerivation {
  pname = "openclaw-package-contents";
  version = lib.getVersion openclawGateway;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  env = {
    OPENCLAW_GATEWAY = openclawGateway;
    OPENCLAW_MCP_REDIRECT_CHECK = "${../tests/mcp-redirect/check.mjs}";
    OPENCLAW_MCP_OAUTH_CHECK = "${../tests/mcp-oauth/check.mjs}";
    OPENCLAW_MCP_OAUTH_FLOW_CHECK = "${../tests/mcp-oauth/flow.mjs}";
    OPENCLAW_CONTROL_UI_CHECK = "${../tests/control-ui-assets/check.mjs}";
  };

  doCheck = true;
  nativeCheckInputs = [ nodejs_24 ];
  checkPhase = "${../scripts/check-package-contents.sh}";
  installPhase = "${../scripts/empty-install.sh}";
}
