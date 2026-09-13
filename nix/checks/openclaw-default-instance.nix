{
  lib,
  pkgs,
  stdenv,
  nodejs_22,
  includePluginChecks ? false,
  includeQmdChecks ? false,
  includeSourceOverrideChecks ? false,
}:

let
  helpers = import ./default-instance/helpers.nix { inherit lib pkgs; };
  agents = import ./default-instance/agents.nix { inherit lib pkgs helpers; };
  services = import ./default-instance/services.nix { inherit lib pkgs helpers; };
  source = import ./default-instance/source.nix { inherit lib pkgs helpers; };
  workspace = import ./default-instance/workspace.nix { inherit lib pkgs helpers; };
  qmd = import ./default-instance/qmd.nix { inherit lib pkgs helpers; };
  plugins = import ./default-instance/plugins.nix { inherit lib pkgs helpers; };

  checkKey = builtins.deepSeq (
    [
      agents.defaultCheck
      (agents.implicitRosterCheck "default instance" helpers.defaultConfig)
      (agents.implicitRosterCheck "bootstrap defaults" workspace.workspaceBootstrapConfig)
      (map (agents.implicitRosterCheck "named instance") workspace.namedSkillConfigs)
      agents.unpinnedRosterCheck
      agents.emptyRosterChecks
      agents.explicitWorkspaceCheck
      agents.mergedRosterCheck
      agents.authoredRosterChecks
      agents.canonicalAgentIdChecks
      agents.invalidRosterChecks
      services.homeRelativeConfigCheck
      services.topLevelHomeRelativeConfigCheck
      services.spacedConfigEnvironmentCheck
      services.reloadDefaultCheck
      services.reloadNamedCheck
      services.reloadCustomDefaultCheck
      workspace.userSkillCheck
      workspace.namedSkillCheck
      workspace.caseSkillCheck
      workspace.workspaceBootstrapCheck
      workspace.documentsRemovedCheck
      workspace.bootstrapSeedConflictCheck
      workspace.workspaceFileCollisionCheck
      workspace.workspaceRuntimeFileCollisionCheck
      workspace.invalidWorkspaceFileCheck
      services.secretProviderCheck
      services.secretRefPassthroughCheck
    ]
    ++ lib.optionals includePluginChecks [
      workspace.customPluginCheck
      workspace.multiAgentPluginSkillCheck
      workspace.duplicateSkillCheck
      workspace.userPluginSkillCollisionCheck
    ]
    ++ lib.optionals includeQmdChecks [
      qmd.qmdControlCheck
      qmd.qmdPrewarmCheck
      qmd.qmdMemoryCheck
      qmd.nixosQmdChecks
      qmd.nixosQmdExplicitCheck
    ]
    ++ lib.optionals includeSourceOverrideChecks [
      source.sourceOverrideCheck
    ]
    ++ [
      services.runtimeProfileCheck
    ]
    ++ lib.optionals includePluginChecks [
      plugins.customRuntimePluginRootCheck
      plugins.runtimePluginCheck
      plugins.runtimePluginCatalogGeneratedCheck
      plugins.runtimePluginInstanceCheck
      plugins.runtimePluginDuplicateCheck
      plugins.runtimePluginUnsupportedCheck
      plugins.runtimePluginRawLoadPathCheck
      plugins.runtimePluginInstallRecordCheck
      plugins.runtimePluginDisabledCheck
      plugins.runtimePluginDeniedCheck
      plugins.runtimePluginSourceCheck
      plugins.runtimePluginSourceDuplicateCheck
      plugins.runtimePluginSourceAmbiguousCheck
      plugins.runtimePluginSourceInvalidSpecCheck
      plugins.runtimePluginSourceInvalidUrlCheck
      plugins.runtimePluginSourceRawLoadPathCheck
      plugins.npmRuntimePluginCheck
    ]
  ) "ok";

in
stdenv.mkDerivation {
  pname =
    if includePluginChecks then
      "openclaw-plugin-instance"
    else if includeQmdChecks then
      "openclaw-qmd-instance"
    else if includeSourceOverrideChecks then
      "openclaw-source-override-instance"
    else
      "openclaw-default-instance";
  version = "1";
  dontUnpack = true;
  # Evaluation alone missed installPhase regressions in helper scripts.
  nativeBuildInputs =
    lib.optionals includePluginChecks [
      nodejs_22
    ]
    ++ lib.optional (includeQmdChecks && qmd.qmdMemoryPackage != null) qmd.qmdMemoryPackage;
  env = {
    OPENCLAW_DEFAULT_INSTANCE = checkKey;
  };
  installPhase =
    lib.optionalString includePluginChecks "${nodejs_22}/bin/node ${../scripts/check-openclaw-runtime-plugin-installer.mjs} ${../scripts/openclaw-runtime-plugin-install.mjs} && "
    + "${../scripts/empty-install.sh}";
}
