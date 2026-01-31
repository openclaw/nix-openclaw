{ lib, openclawLib }:

{ name, config, ... }:
{
  options = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable this Openclaw instance.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = openclawLib.defaultPackage;
      description = "Openclaw batteries-included package.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = if name == "default"
        then "${openclawLib.homeDir}/.openclaw"
        else "${openclawLib.homeDir}/.openclaw-${name}";
      description = "State directory for this Openclaw instance (logs, sessions, config).";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.stateDir}/workspace";
      description = "Workspace directory for this Openclaw instance.";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.stateDir}/openclaw.json";
      description = "Path to generated Openclaw config JSON.";
    };

    logPath = lib.mkOption {
      type = lib.types.str;
      default = if name == "default"
        then "/tmp/openclaw/openclaw-gateway.log"
        else "/tmp/openclaw/openclaw-gateway-${name}.log";
      description = "Log path for this Openclaw gateway instance.";
    };

    gatewayPort = lib.mkOption {
      type = lib.types.int;
      default = 18789;
      description = "Gateway port used by the Openclaw desktop app.";
    };

    gatewayPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Local path to Openclaw gateway source (dev only).";
    };

    gatewayPnpmDepsHash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = lib.fakeHash;
      description = "pnpmDeps hash for local gateway builds (omit to let Nix suggest the correct hash).";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.str;
            description = "Plugin source pointer (e.g., github:owner/repo or path:/...).";
          };
          config = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Plugin-specific configuration (env/files/etc).";
          };
        };
      });
      default = openclawLib.effectivePlugins;
      description = "Plugins enabled for this instance (includes first-party toggles).";
    };

    config = lib.mkOption {
      type = lib.types.submodule { options = openclawLib.generatedConfigOptions; };
      default = {};
      description = "Openclaw config (schema-typed).";
    };

    launchd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run Openclaw gateway via launchd (macOS).";
    };

    launchd.label = lib.mkOption {
      type = lib.types.str;
      default = if name == "default"
        then "com.steipete.openclaw.gateway"
        else "com.steipete.openclaw.gateway.${name}";
      description = "launchd label for this instance.";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run Openclaw gateway via systemd user service (Linux).";
    };

    systemd.unitName = lib.mkOption {
      type = lib.types.str;
      default = if name == "default"
        then "openclaw-gateway"
        else "openclaw-gateway-${name}";
      description = "systemd user service unit name for this instance.";
    };

    app.install.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install Openclaw.app for this instance.";
    };

    app.install.path = lib.mkOption {
      type = lib.types.str;
      default = "${openclawLib.homeDir}/Applications/Openclaw.app";
      description = "Destination path for this instance's Openclaw.app bundle.";
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
    };
  };
}
