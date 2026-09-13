{
  config,
  lib,
  pkgs,
  ...
}:

let
  openclawLib = import ./lib.nix { inherit config lib pkgs; };
  cfg = openclawLib.cfg;
  homeDir = openclawLib.homeDir;
  appPackage = openclawLib.appPackage;
  qmdPackage = openclawLib.qmdPackage;

  defaultInstance = {
    enable = cfg.enable;
    package = openclawLib.defaultPackage;
    stateDir = cfg.stateDir;
    workspaceDir = cfg.workspaceDir;
    configPath = "${cfg.stateDir}/openclaw.json";
    logPath = "/tmp/openclaw/openclaw-gateway.log";
    gatewayPort = 18789;
    gatewayPath = null;
    gatewayPnpmDepsHash = lib.fakeHash;
    runtimePackages = [ ];
    environment = { };
    launchd = cfg.launchd;
    systemd = cfg.systemd;
    plugins = openclawLib.effectivePlugins;
    runtimePlugins = cfg.runtimePlugins;
    runtimePluginSources = cfg.runtimePluginSources;
    config = { };
    appDefaults = {
      enable = true;
      attachExistingOnly = true;
      nixMode = true;
    };
    app = {
      install = {
        enable = false;
        path = "${homeDir}/Applications/OpenClaw.app";
      };
    };
  };

  instances =
    if cfg.instances != { } then
      cfg.instances
    else
      lib.optionalAttrs cfg.enable { default = defaultInstance; };

  enabledInstances = lib.filterAttrs (_: inst: inst.enable) instances;

  plugins = import ./plugins.nix {
    inherit
      lib
      pkgs
      openclawLib
      enabledInstances
      ;
  };

  files = import ./files.nix {
    inherit
      lib
      pkgs
      openclawLib
      enabledInstances
      plugins
      ;
  };
  skills = import ./skills.nix {
    inherit
      lib
      pkgs
      openclawLib
      enabledInstances
      plugins
      ;
  };

  mkInstanceConfig = import ./instance.nix {
    inherit lib pkgs openclawLib plugins files skills;
  };

  instanceConfigs = lib.mapAttrsToList mkInstanceConfig enabledInstances;
  codexRuntimeProfileEntries = lib.flatten (
    map (
      item:
      map (profileDir: {
        inherit profileDir;
        binDir = "${item.runtimeProfile}/bin";
      }) item.codexRuntimeProfiles
    ) instanceConfigs
  );
  codexRuntimeProfilesManifest = pkgs.writeText "openclaw-codex-runtime-profiles.tsv" (
    (lib.concatStringsSep "\n" (
      map (entry: "${entry.profileDir}\t${entry.binDir}") codexRuntimeProfileEntries
    ))
    + "\n"
  );
  appInstalls = lib.filter (item: item != null) (map (item: item.appInstall) instanceConfigs);
  launchdLabels = lib.filter (label: label != null) (map (item: item.launchdLabel) instanceConfigs);
  launchdLabelArgs = lib.concatStringsSep " " (map lib.escapeShellArg launchdLabels);
  systemdUnitNames = lib.filter (unitName: unitName != null) (
    map (item: item.systemdUnitName) instanceConfigs
  );
  reloadTargetsByName =
    targetAttr:
    lib.listToAttrs (
      map (item: {
        name = item.name;
        value = item.${targetAttr};
      }) (lib.filter (item: item.${targetAttr} != null) instanceConfigs)
    );
  launchdLabelsByName = reloadTargetsByName "launchdLabel";
  systemdUnitNamesByName = reloadTargetsByName "systemdUnitName";
  reloadTargetsForName =
    targetsByName: targetName:
    if builtins.hasAttr targetName targetsByName then
      [ targetsByName.${targetName} ]
    else if builtins.hasAttr "default" targetsByName then
      [ targetsByName.default ]
    else
      [ ];
  reloadShellArray = values: lib.concatStringsSep " " (map lib.escapeShellArg values);
  reloadScriptText =
    builtins.replaceStrings
      [
        "@openclawReloadTestLaunchdLabels@"
        "@openclawReloadTestSystemdUnits@"
        "@openclawReloadProdLaunchdLabels@"
        "@openclawReloadProdSystemdUnits@"
        "@openclawReloadBothLaunchdLabels@"
        "@openclawReloadBothSystemdUnits@"
      ]
      [
        (reloadShellArray (reloadTargetsForName launchdLabelsByName "test"))
        (reloadShellArray (reloadTargetsForName systemdUnitNamesByName "test"))
        (reloadShellArray (reloadTargetsForName launchdLabelsByName "prod"))
        (reloadShellArray (reloadTargetsForName systemdUnitNamesByName "prod"))
        (reloadShellArray launchdLabels)
        (reloadShellArray systemdUnitNames)
      ]
      (builtins.readFile ../openclaw-reload.sh);
  runtimePluginPackagesAll = lib.unique (
    lib.flatten (map (item: item.runtimePluginPackages) instanceConfigs)
  );

  appDefaults = lib.foldl' (acc: item: lib.recursiveUpdate acc item.appDefaults) { } instanceConfigs;
  appDefaultsEnabled = lib.filterAttrs (_: inst: inst.appDefaults.enable) enabledInstances;
  qmdEnabledInstances = lib.filter (item: item.qmdEnabled) instanceConfigs;

in
{
  config = lib.mkIf (cfg.enable || cfg.instances != { }) {
    assertions = [
      {
        assertion = lib.length (lib.attrNames appDefaultsEnabled) <= 1;
        message = "Only one OpenClaw instance may enable appDefaults.";
      }
      {
        assertion = qmdEnabledInstances == [ ] || qmdPackage != null;
        message = "OpenClaw config memory.backend = \"qmd\" requires a qmd package in openclawPackages.";
      }
    ]
    ++ files.workspaceAssertions
    ++ skills.duplicateSkillAssertion
    ++ plugins.pluginAssertions
    ++ lib.flatten (map (item: item.assertions) instanceConfigs)
    ++ [
      {
        assertion = !cfg.qmd.prewarmModels.enable || qmdPackage != null;
        message = "programs.openclaw.qmd.prewarmModels.enable requires a qmd package in openclawPackages.";
      }
    ];

    home.packages = lib.unique (
      (map (item: item.package) instanceConfigs)
      ++ (lib.optionals cfg.exposePluginPackages plugins.pluginPackagesAll)
    );

    home.file = lib.mkMerge [
      (lib.listToAttrs (map (item: item.homeFile) instanceConfigs))
      (lib.optionalAttrs (pkgs.stdenv.hostPlatform.isDarwin && appPackage != null && cfg.installApp) {
        "Applications/OpenClaw.app" = {
          source = "${appPackage}/Applications/OpenClaw.app";
          recursive = true;
          force = true;
        };
      })
      (lib.listToAttrs appInstalls)
      plugins.pluginConfigFiles
      (lib.optionalAttrs cfg.reloadScript.enable {
        ".local/bin/openclaw-reload" = {
          executable = true;
          text = reloadScriptText;
        };
      })
    ];

    home.activation.openclawDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p -- ${
        lib.escapeShellArgs (
          map openclawLib.resolvePath (lib.concatMap (item: item.dirs) instanceConfigs)
        )
      }
      ${lib.optionalString (plugins.pluginStateDirsAll != [ ])
        "run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p -- ${lib.escapeShellArgs plugins.pluginStateDirsAll}"
      }
    '';

    home.activation.openclawWorkspaceFiles = lib.hm.dag.entryAfter [ "openclawDirs" ] ''
      run --quiet ${../openclaw-materialize-workspace-files.sh} ${lib.escapeShellArg "${homeDir}/.local/state/nix-openclaw/managed-workspace-files"} ${files.materializedManifest} ${files.workspaceRootsManifest}
    '';

    home.activation.openclawSkills = lib.hm.dag.entryAfter [ "openclawDirs" ] ''
      ${lib.optionalString (skills.roots != [ ])
        "run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p -- ${lib.escapeShellArgs skills.roots}"
      }
      run --quiet ${../openclaw-materialize-workspace-files.sh} ${lib.escapeShellArg "${homeDir}/.local/state/nix-openclaw/managed-skill-files"} ${skills.materializedManifest} ${skills.rootsManifest}
    '';

    home.activation.openclawConfigFiles = lib.hm.dag.entryAfter [ "openclawDirs" ] ''
      ${lib.concatStringsSep "\n" (
        map (
          item:
          "run --quiet ${lib.getExe' pkgs.coreutils "ln"} -sfn ${lib.escapeShellArg item.configFile} ${lib.escapeShellArg (openclawLib.resolvePath item.configPath)}"
        ) instanceConfigs
      )}
    '';

    home.activation.openclawRuntimePlugins = lib.mkIf (runtimePluginPackagesAll != [ ]) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${lib.concatStringsSep "\n" (
          map (
            package: "run --quiet ${lib.getExe' pkgs.coreutils "test"} -f ${package}/openclaw.plugin.json"
          ) runtimePluginPackagesAll
        )}
      ''
    );

    home.activation.openclawCodexRuntimeProfiles = lib.mkIf (codexRuntimeProfileEntries != [ ]) (
      lib.hm.dag.entryAfter [ "openclawDirs" ] ''
        run --quiet ${pkgs.bash}/bin/bash ${../openclaw-link-codex-runtime-profiles.sh} ${codexRuntimeProfilesManifest}
      ''
    );

    home.activation.openclawPluginGuard = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      ${plugins.pluginGuards}
    '';

    home.activation.openclawQmdPrewarm = lib.mkIf (cfg.qmd.prewarmModels.enable && qmdPackage != null) (
      lib.hm.dag.entryAfter [ "openclawDirs" ] ''
        run --quiet ${lib.getExe' pkgs.coreutils "env"} \
          HOME=${lib.escapeShellArg homeDir} \
          XDG_CACHE_HOME=${lib.escapeShellArg "${homeDir}/.cache"} \
          XDG_CONFIG_HOME=${lib.escapeShellArg "${homeDir}/.config"} \
          XDG_DATA_HOME=${lib.escapeShellArg "${homeDir}/.local/share"} \
          OPENCLAW_QMD_BIN=${lib.escapeShellArg "${qmdPackage}/bin/qmd"} \
          ${pkgs.bash}/bin/bash ${../../../scripts/openclaw-qmd-prewarm.sh}
      ''
    );

    home.activation.openclawAppDefaults =
      lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && appDefaults != { })
        (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            # Nix mode + app defaults (OpenClaw.app)
            /usr/bin/defaults write ai.openclaw.mac openclaw.nixMode -bool ${
              lib.boolToString (appDefaults.nixMode or true)
            }
            /usr/bin/defaults write ai.openclaw.mac openclaw.gateway.attachExistingOnly -bool ${
              lib.boolToString (appDefaults.attachExistingOnly or true)
            }
            /usr/bin/defaults write ai.openclaw.mac gatewayPort -int ${
              toString (appDefaults.gatewayPort or 18789)
            }
          ''
        );

    home.activation.openclawLaunchdRelink = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        /usr/bin/env bash ${../openclaw-launchd-relink.sh} ${launchdLabelArgs}
      ''
    );

    systemd.user.services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
      lib.mkMerge (map (item: item.systemdService) instanceConfigs)
    );

    launchd.agents = lib.mkMerge (map (item: item.launchdAgent) instanceConfigs);
  };
}
