{
  lib,
  pkgs,
  helpers,
}:

let
  inherit (helpers) moduleEval requireNoAssertionFailures generatedConfig;

  sourceOverrideEval = moduleEval {
    instances.dev = {
      enable = true;
      gatewayPath = toString ../../..;
      gatewayPnpmDepsHash = lib.fakeHash;
    };
  };
  sourceOverrideConfig = generatedConfig sourceOverrideEval ".openclaw-dev/openclaw.json";
  sourceOverrideCheck =
    builtins.deepSeq (requireNoAssertionFailures "source override" sourceOverrideEval)
      (
        if (((sourceOverrideConfig.gateway or { }).mode or null) != "local") then
          throw "Source override instance lost gateway.mode."
        else if pkgs.stdenv.hostPlatform.isLinux then
          let
            services = sourceOverrideEval.config.systemd.user.services;
            execStart = services.openclaw-gateway-dev.Service.ExecStart or "";
          in
          if !(builtins.hasAttr "openclaw-gateway-dev" services) then
            throw "Source override instance missing systemd unit."
          else if !(lib.hasInfix "/bin/openclaw-gateway-dev gateway --port " execStart) then
            throw "Source override instance did not wire the dev gateway wrapper."
          else
            "ok"
        else if pkgs.stdenv.hostPlatform.isDarwin then
          let
            agents = sourceOverrideEval.config.launchd.agents;
            programArgs = agents."com.steipete.openclaw.gateway.dev".config.ProgramArguments or [ ];
          in
          if !(builtins.hasAttr "com.steipete.openclaw.gateway.dev" agents) then
            throw "Source override instance missing launchd agent."
          else if !(lib.any (arg: lib.hasSuffix "/bin/openclaw-gateway-dev" arg) programArgs) then
            throw "Source override instance did not wire the dev gateway wrapper."
          else
            "ok"
        else
          "ok"
      );

in
{
  inherit sourceOverrideCheck;
}
