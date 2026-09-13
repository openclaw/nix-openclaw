{ lib, pkgs, helpers }:

let
  inherit (helpers) moduleEval requireNoAssertionFailures requireAssertionFailure requireEvalFailure generatedConfig packageHasQmd openclawLib;

  inherit (import ../../lib/openclaw-config-capabilities.nix { inherit lib; }) supportsQmdBackend;
  retiredQmdConfigs = [
    { memory.backend = "qmd"; }
    { memory.qmd = { }; }
    { memory.search.qmd = { }; }
  ];
  qmdControlConfig = {
    gateway.mode = "local";
    memory.citations = "off";
  };
  qmdControlEval = moduleEval {
    config = qmdControlConfig;
  };
  qmdControlCheck = builtins.deepSeq [
    (requireNoAssertionFailures "QMD valid config control" qmdControlEval)
    qmdControlEval.config.home.activation
  ] (
    if (generatedConfig qmdControlEval ".openclaw/openclaw.json").memory != qmdControlConfig.memory then
      throw "QMD valid config control changed authored memory config."
    else if lib.any packageHasQmd qmdControlEval.config.home.packages then
      throw "Valid memory config without QMD opt-in added an internal QMD wrapper."
    else
      "ok"
  );
  qmdPrewarmEval = moduleEval {
    qmd.prewarmModels.enable = true;
  };
  qmdPrewarmActivation = builtins.toJSON qmdPrewarmEval.config.home.activation.openclawQmdPrewarm;
  qmdPrewarmCheck = builtins.deepSeq (requireNoAssertionFailures "qmd.prewarmModels" qmdPrewarmEval) (
    if
      lib.hasInfix "OPENCLAW_QMD_BIN=" qmdPrewarmActivation
      && lib.hasInfix "openclaw-qmd-prewarm.sh" qmdPrewarmActivation
    then
      "ok"
    else
      throw "qmd.prewarmModels did not wire QMD model-cache prewarm activation."
  );

  qmdMemoryEval = moduleEval {
    config.memory.backend = "qmd";
  };
  qmdMemoryCheck =
    if supportsQmdBackend then
      builtins.deepSeq (requireNoAssertionFailures "memory.backend qmd" qmdMemoryEval) (
        if (generatedConfig qmdMemoryEval ".openclaw/openclaw.json").memory.backend != "qmd" then
          throw "Legacy memory.backend = qmd was not preserved."
        else if !(lib.any packageHasQmd qmdMemoryEval.config.home.packages) then
          throw "memory.backend = qmd did not add QMD to the internal OpenClaw runtime."
        else
          "ok"
      )
    else
      map (
        config:
        requireEvalFailure "retired QMD generated config ${builtins.toJSON config}"
          (moduleEval { inherit config; }).config.home.file
      ) retiredQmdConfigs;
  qmdMemoryPackages =
    if supportsQmdBackend then lib.filter packageHasQmd qmdMemoryEval.config.home.packages else [ ];
  qmdMemoryPackage = if qmdMemoryPackages == [ ] then null else builtins.head qmdMemoryPackages;

  nixosQmdEval =
    gatewayConfig:
    lib.evalModules {
      modules = [
        {
          options = {
            assertions = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [ ];
            };
            users = lib.mkOption { type = lib.types.attrs; default = { }; };
            systemd = lib.mkOption { type = lib.types.attrs; default = { }; };
            environment = lib.mkOption { type = lib.types.attrs; default = { }; };
          };
        }
        ../../modules/nixos/openclaw-gateway.nix
        {
          services.openclaw-gateway = {
            enable = true;
            createUser = false;
          } // gatewayConfig;
        }
      ];
      specialArgs = { inherit pkgs; };
    };
  nixosQmdChecks = map (
    config:
    let
      evaluated = nixosQmdEval { inherit config; };
      rendered = builtins.fromJSON evaluated.config.environment.etc."openclaw/openclaw.json".source.text;
      servicePath = evaluated.config.systemd.services.openclaw-gateway.path;
      expectedQmd = supportsQmdBackend && (config.memory.backend or null) == "qmd";
    in
    builtins.deepSeq (
      if supportsQmdBackend || config == qmdControlConfig then
        requireNoAssertionFailures "NixOS QMD config" evaluated
      else
        requireAssertionFailure "NixOS retired QMD config" "schema retired the QMD backend" evaluated
    ) (
      if rendered != config then
        throw "NixOS QMD handling changed authored config."
      else if lib.elem openclawLib.qmdPackage servicePath != expectedQmd then
        throw "NixOS automatic QMD service PATH disagrees with schema capability and opt-in."
      else
        "ok"
    )
  ) ([ qmdControlConfig ] ++ retiredQmdConfigs);
  nixosQmdExplicitEval = nixosQmdEval {
    configFile = ../../tests/workspace/LORE.md;
    servicePath = [ openclawLib.qmdPackage ];
  };
  nixosQmdExplicitCheck =
    builtins.deepSeq (requireNoAssertionFailures "NixOS explicit QMD tooling" nixosQmdExplicitEval) (
      if nixosQmdExplicitEval.config.environment.etc."openclaw/openclaw.json".source != ../../tests/workspace/LORE.md then
        throw "NixOS QMD handling must leave configFile opaque and unchanged."
      else if !(lib.elem openclawLib.qmdPackage nixosQmdExplicitEval.config.systemd.services.openclaw-gateway.path) then
        throw "NixOS QMD handling removed an explicit servicePath package."
      else
        "ok"
    );

in
{
  inherit qmdControlCheck qmdPrewarmCheck qmdMemoryCheck qmdMemoryPackage nixosQmdChecks nixosQmdExplicitCheck;
}
