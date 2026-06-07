{
  lib,
  openclawLib,
  pluginOptionType,
  runtimePluginSourceType,
}:

{ name, config, ... }:
{
  options = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable this OpenClaw instance.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = openclawLib.defaultPackage;
      description = "OpenClaw batteries-included package.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default =
        if name == "default" then
          "${openclawLib.homeDir}/.openclaw"
        else
          "${openclawLib.homeDir}/.openclaw-${name}";
      description = "State directory for this OpenClaw instance (logs, sessions, config).";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.stateDir}/workspace";
      description = "Workspace directory for this OpenClaw instance.";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.stateDir}/openclaw.json";
      description = "Path to generated OpenClaw config JSON.";
    };

    logPath = lib.mkOption {
      type = lib.types.str;
      default =
        if name == "default" then
          "/tmp/openclaw/openclaw-gateway.log"
        else
          "/tmp/openclaw/openclaw-gateway-${name}.log";
      description = "Log path for this OpenClaw gateway instance.";
    };

    gatewayPort = lib.mkOption {
      type = lib.types.int;
      default = 18789;
      description = "Gateway port used by the OpenClaw desktop app.";
    };

    gatewayPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Local path to OpenClaw gateway source (dev only).";
    };

    gatewayPnpmDepsHash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = lib.fakeHash;
      description = "pnpmDeps hash for local gateway builds (omit to let Nix suggest the correct hash).";
    };

    runtimePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra command-line packages available to this OpenClaw instance's gateway wrapper and generated tools.exec.pathPrepend. When this instance also uses the Nix-packaged Codex runtime plugin with the managed app-server launcher, that launcher links the same packages into its native HOME profile. This does not enable Codex or add packages to the user's shell PATH.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra runtime environment for this OpenClaw gateway wrapper. Values that point to files are read at runtime unless the variable name ends in _FILE.";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf pluginOptionType;
      default = openclawLib.effectivePlugins;
      description = "Plugins enabled for this instance (includes bundled plugin toggles).";
    };

    runtimePlugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = openclawLib.cfg.runtimePlugins;
      description = "Supported OpenClaw runtime plugin ids for this instance. Overrides the top-level runtimePlugins list when set.";
    };

    runtimePluginSources = lib.mkOption {
      type = lib.types.listOf runtimePluginSourceType;
      default = openclawLib.cfg.runtimePluginSources;
      description = "Locked OpenClaw runtime plugin sources for this instance. Overrides the top-level runtimePluginSources list when set.";
    };

    config = lib.mkOption {
      type = lib.types.submodule { options = openclawLib.generatedConfigOptions; };
      default = { };
      description = "OpenClaw config (schema-typed).";
    };

    launchd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run OpenClaw gateway via launchd (macOS).";
    };

    launchd.label = lib.mkOption {
      type = lib.types.str;
      default =
        if name == "default" then
          "com.steipete.openclaw.gateway"
        else
          "com.steipete.openclaw.gateway.${name}";
      description = "launchd label for this instance.";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run OpenClaw gateway via systemd user service (Linux).";
    };

    systemd.unitName = lib.mkOption {
      type = lib.types.str;
      default = if name == "default" then "openclaw-gateway" else "openclaw-gateway-${name}";
      description = "systemd user service unit name for this instance.";
    };

    app.install.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install OpenClaw.app for this instance.";
    };

    app.install.path = lib.mkOption {
      type = lib.types.str;
      default = "${openclawLib.homeDir}/Applications/OpenClaw.app";
      description = "Destination path for this instance's OpenClaw.app bundle.";
    };

    appDefaults = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = name == "default";
        description = "Configure macOS app defaults for this instance.";
      };

      attachExistingOnly = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Attach existing gateway only (macOS).";
      };

      nixMode = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable OpenClaw Nix mode in the macOS app via defaults (openclaw.nixMode).";
      };
    };
  };
}
