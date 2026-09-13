{
  lib,
  pkgs,
  openclawLib,
  plugins,
  files,
  skills,
}:

let
  inherit (openclawLib)
    cfg
    homeDir
    appPackage
    qmdPackage
    ;
  toJSONWithContext = import ../../../lib/json-with-context.nix { inherit lib; };
  runtimePlugins = import ./runtime-plugins.nix { inherit lib pkgs; };
  environment = import ./environment.nix { inherit lib pkgs; };

  stripNulls =
    value:
    if value == null then
      null
    else if builtins.isAttrs value then
      lib.filterAttrs (_: v: v != null) (builtins.mapAttrs (_: stripNulls) value)
    else if builtins.isList value then
      builtins.filter (v: v != null) (map stripNulls value)
    else
      value;

  execSecretFlowDocsUrl = "https://github.com/openclaw/nix-openclaw#secrets-and-openclaw-exec-secretrefs";

  containsExecSecretFlow =
    value:
    if builtins.isAttrs value then
      ((value.source or null) == "exec" && ((value ? command) || ((value ? provider) && (value ? id))))
      || lib.any containsExecSecretFlow (builtins.attrValues value)
    else if builtins.isList value then
      lib.any containsExecSecretFlow value
    else
      false;

  baseConfig = {
    gateway = {
      mode = "local";
    };
  };

  mkInstanceConfig =
    name: inst:
    let
      stateDir = openclawLib.resolvePath inst.stateDir;
      workspaceDir = openclawLib.resolvePath inst.workspaceDir;
      configPath = openclawLib.resolvePath inst.configPath;
      gatewayPackage =
        if inst.gatewayPath != null then
          pkgs.callPackage ../../../packages/openclaw-gateway.nix {
            sourceInfo = import ../../../sources/openclaw-source.nix;
            gatewaySrc = builtins.path {
              path = inst.gatewayPath;
              name = "openclaw-gateway-src";
            };
            pnpmDepsHash = inst.gatewayPnpmDepsHash;
          }
        else
          inst.package;
      pluginPackages = plugins.pluginPackagesFor name;
      runtimePackages = lib.unique (
        openclawLib.toolSets.tools
        ++ (lib.optional (qmdEnabled && qmdPackage != null) qmdPackage)
        ++ pluginPackages
        ++ cfg.runtimePackages
        ++ inst.runtimePackages
      );
      runtimeProfile = pkgs.symlinkJoin {
        name = "openclaw-runtime-${name}";
        paths = runtimePackages;
      };
      runtimePath = lib.makeBinPath runtimePackages;
      runtimeEnvAll =
        (plugins.pluginEnvAllFor name)
        ++ (lib.mapAttrsToList (key: value: {
          inherit key value;
          plugin = "runtime";
        }) (cfg.environment // inst.environment));
      userConfig = stripNulls (lib.recursiveUpdate (stripNulls cfg.config) (stripNulls inst.config));
      nixSkillLoadDirs = skills.skillLoadDirsForInstance name;
      mergedConfigWithoutLoadPaths = stripNulls (lib.recursiveUpdate baseConfig userConfig);
      existingOpenClawPluginLoadPaths = (
        ((mergedConfigWithoutLoadPaths.plugins or { }).load or { }).paths or [ ]
      );
      existingSkillLoadDirs = (
        ((mergedConfigWithoutLoadPaths.skills or { }).load or { }).extraDirs or [ ]
      );
      existingAllowList = ((mergedConfigWithoutLoadPaths.plugins or { }).allow or null);
      existingDenyList = ((userConfig.plugins or { }).deny or [ ]);
      userPluginEntries = ((userConfig.plugins or { }).entries or { });
      runtimePluginConfig = runtimePlugins.forInstance {
        inherit
          name
          existingAllowList
          userPluginEntries
          ;
        openclawPackage = gatewayPackage;
        ids = inst.runtimePlugins;
        sources = inst.runtimePluginSources;
        existingLoadPaths = existingOpenClawPluginLoadPaths;
        denyList = existingDenyList;
      };
      disablePersistedPluginRegistry = runtimePluginConfig.loadPaths != [ ];
      generatedPluginConfig = lib.recursiveUpdate (lib.optionalAttrs
        (runtimePluginConfig.loadPaths != [ ])
        {
          plugins = {
            load = {
              paths = lib.unique (runtimePluginConfig.loadPaths ++ existingOpenClawPluginLoadPaths);
            };
          };
        }
      ) runtimePluginConfig.config;
      generatedSkillLoadConfig = lib.optionalAttrs (nixSkillLoadDirs != [ ]) {
        skills = {
          load = {
            extraDirs = lib.unique (nixSkillLoadDirs ++ existingSkillLoadDirs);
          };
        };
      };
      generatedBootstrapConfig = lib.optionalAttrs files.bootstrapFilesEnabled {
        agents = {
          defaults = {
            skipBootstrap = true;
          };
        };
      };
      generatedLoadConfig = lib.foldl' lib.recursiveUpdate { } [
        generatedPluginConfig
        generatedSkillLoadConfig
        generatedBootstrapConfig
      ];
      userSkipBootstrap = (
        ((mergedConfigWithoutLoadPaths.agents or { }).defaults or { }).skipBootstrap or null
      );
      bootstrapAssertions = lib.optionals (files.bootstrapFilesEnabled && userSkipBootstrap == false) [
        {
          assertion = false;
          message = "programs.openclaw.workspace.bootstrapFiles requires agents.defaults.skipBootstrap to stay true. Remove programs.openclaw.config.agents.defaults.skipBootstrap = false; OpenClaw must not seed bootstrap files in Nix-managed workspaces.";
        }
      ];
      mergedConfig0 = lib.recursiveUpdate mergedConfigWithoutLoadPaths generatedLoadConfig;
      existingWorkspace = (((mergedConfig0.agents or { }).defaults or { }).workspace or null);
      workspaceConfig =
        if (cfg.workspace.pinAgentDefaults or true) && existingWorkspace == null then
          lib.recursiveUpdate mergedConfig0 {
            agents = {
              defaults = {
                workspace = workspaceDir;
              };
            };
          }
        else
          mergedConfig0;
      workspaceAgents = workspaceConfig.agents or { };
      # Canonicalize upstream's implicit main before the keys-only profile reader.
      mergedConfig =
        if
          openclawLib.usesAgentEntries
          && (workspaceAgents.entries or { }) == { }
          && (workspaceAgents.ownership or null) != "explicit"
        then
          lib.recursiveUpdate workspaceConfig { agents.entries.main = { }; }
        else
          workspaceConfig;
      hasExecSecretFlow = containsExecSecretFlow mergedConfig;
      execSecretFlowWarning = "programs.openclaw.instances.${name}.config uses OpenClaw exec secrets. nix-openclaw passes this through, but does not support or verify runtime command-based secret resolution. Prefer host-managed secrets with env/file SecretRefs: ${execSecretFlowDocsUrl}";
      qmdEnabled = (((mergedConfig.memory or { }).backend or null) == "qmd");
      gatewayRuntimePackage =
        if qmdEnabled && qmdPackage != null then
          let
            qmdPath = lib.makeBinPath [ qmdPackage ];
          in
          pkgs.stdenvNoCC.mkDerivation {
            name = "${lib.getName gatewayPackage}-qmd";
            dontUnpack = true;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            OPENCLAW_GATEWAY_PACKAGE = "${gatewayPackage}";
            OPENCLAW_GATEWAY_BIN = "${gatewayPackage}/bin/openclaw";
            OPENCLAW_QMD_PATH = qmdPath;
            STDENV_SETUP = "${pkgs.stdenvNoCC}/setup";
            installPhase = "${../../../scripts/openclaw-qmd-wrapper-install.sh}";
          }
        else
          gatewayPackage;
      rawConfigJson = toJSONWithContext mergedConfig;
      configJson =
        if hasExecSecretFlow then lib.warn execSecretFlowWarning rawConfigJson else rawConfigJson;
      configFile = pkgs.writeText "openclaw-${name}.json" configJson;
      agentIds = openclawLib.agentIds mergedConfig;
      codexRuntimeProfiles = map (
        agentId: "${stateDir}/agents/${agentId}/agent/codex-home/home/.nix-profile"
      ) agentIds;
      gatewayWrapper = pkgs.writeShellScriptBin "openclaw-gateway-${name}" ''
        set -euo pipefail

        if [ -n "${runtimePath}" ]; then
          export PATH="${runtimePath}:$PATH"
        fi

        ${environment.renderExports runtimeEnvAll}

        exec "${gatewayRuntimePackage}/bin/openclaw" "$@"
      '';
      appDefaults = lib.optionalAttrs (pkgs.stdenv.hostPlatform.isDarwin && inst.appDefaults.enable) {
        attachExistingOnly = inst.appDefaults.attachExistingOnly;
        gatewayPort = inst.gatewayPort;
        nixMode = inst.appDefaults.nixMode;
      };

      appInstall =
        if !(pkgs.stdenv.hostPlatform.isDarwin && inst.app.install.enable && appPackage != null) then
          null
        else
          {
            name = lib.removePrefix "${homeDir}/" inst.app.install.path;
            value = {
              source = "${appPackage}/Applications/OpenClaw.app";
              recursive = true;
              force = true;
            };
          };

      package = gatewayRuntimePackage;
    in
    {
      name = name;
      homeFile = {
        name = openclawLib.toRelative configPath;
        value = {
          source = configFile;
          text = builtins.unsafeDiscardStringContext configJson;
          force = true;
        };
      };
      configFile = configFile;
      configPath = configPath;
      codexRuntimeProfiles = codexRuntimeProfiles;
      runtimeProfile = runtimeProfile;

      dirs = [
        stateDir
        workspaceDir
        (builtins.dirOf inst.logPath)
      ];

      launchdAgent = lib.optionalAttrs (pkgs.stdenv.hostPlatform.isDarwin && inst.launchd.enable) {
        "${inst.launchd.label}" = {
          enable = true;
          config = {
            Label = inst.launchd.label;
            ProgramArguments = [
              "${gatewayWrapper}/bin/openclaw-gateway-${name}"
              "gateway"
              "--port"
              "${toString inst.gatewayPort}"
            ];
            RunAtLoad = true;
            KeepAlive = true;
            WorkingDirectory = stateDir;
            StandardOutPath = inst.logPath;
            StandardErrorPath = inst.logPath;
            EnvironmentVariables = {
              HOME = homeDir;
              OPENCLAW_CONFIG_PATH = configPath;
              OPENCLAW_STATE_DIR = stateDir;
              OPENCLAW_IMAGE_BACKEND = "sips";
              OPENCLAW_NIX_MODE = "1";
            }
            // lib.optionalAttrs disablePersistedPluginRegistry {
              OPENCLAW_DISABLE_PERSISTED_PLUGIN_REGISTRY = "1";
            };
          };
        };
      };

      systemdService = lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux && inst.systemd.enable) {
        "${inst.systemd.unitName}" = {
          Unit = {
            Description = "OpenClaw gateway (${name})";
          };
          Service = {
            ExecStart = "${gatewayWrapper}/bin/openclaw-gateway-${name} gateway --port ${toString inst.gatewayPort}";
            WorkingDirectory = stateDir;
            Restart = "always";
            RestartSec = "1s";
            # Systemd needs whole quoted items, not shell quote concatenation.
            Environment =
              map builtins.toJSON [
                "HOME=${homeDir}"
                "OPENCLAW_CONFIG_PATH=${configPath}"
                "OPENCLAW_STATE_DIR=${stateDir}"
                "OPENCLAW_NIX_MODE=1"
              ]
              ++ lib.optional disablePersistedPluginRegistry "OPENCLAW_DISABLE_PERSISTED_PLUGIN_REGISTRY=1";
            StandardOutput = "append:${inst.logPath}";
            StandardError = "append:${inst.logPath}";
          };
        };
      };

      appDefaults = appDefaults;
      appInstall = appInstall;
      package = package;
      qmdEnabled = qmdEnabled;
      runtimePluginPackages = runtimePluginConfig.packages;
      assertions = runtimePluginConfig.assertions ++ bootstrapAssertions;
      launchdLabel =
        if pkgs.stdenv.hostPlatform.isDarwin && inst.launchd.enable then inst.launchd.label else null;
      systemdUnitName =
        if pkgs.stdenv.hostPlatform.isLinux && inst.systemd.enable then inst.systemd.unitName else null;
    };

in
mkInstanceConfig
