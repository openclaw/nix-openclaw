{ pkgs, home-manager }:

let
  openclawModule = ../modules/home-manager/openclaw.nix;
  testScript = builtins.readFile ../tests/hm-activation.py;
  lockedPathFlake =
    name: path: narHash:
    let
      storePath = builtins.path {
        inherit name path;
        sha256 = narHash;
      };
    in
    "path:${builtins.unsafeDiscardStringContext (toString storePath)}?narHash=${narHash}";
  alphaPluginSource =
    lockedPathFlake "openclaw-test-plugin-alpha" ../tests/plugins/alpha
      "sha256-FV4UN38sPy2Yp/HhqUxd0HW5l2PcIBBmUz4JzxTAOXY=";

in
pkgs.testers.nixosTest {
  name = "openclaw-hm-activation";

  nodes.machine =
    { ... }:
    {
      imports = [ home-manager.nixosModules.home-manager ];

      networking.firewall.allowedTCPPorts = [ 18999 ];

      users.users.alice = {
        isNormalUser = true;
        home = "/home/alice";
        extraGroups = [ "wheel" ];
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.alice =
          { lib, ... }:
          {
            imports = [ openclawModule ];

            home = {
              username = "alice";
              homeDirectory = "/home/alice";
              stateVersion = "23.11";
            };

            programs.openclaw = {
              enable = true;
              workspace = {
                bootstrapFiles = {
                  agents = ../tests/workspace/AGENTS.md;
                  soul = ../tests/workspace/SOUL.md;
                  tools = ../tests/workspace/TOOLS.md;
                  identity = ../tests/workspace/IDENTITY.md;
                  user = ../tests/workspace/USER.md;
                  heartbeat = ../tests/workspace/HEARTBEAT.md;
                };
                files."LORE.md" = ../tests/workspace/LORE.md;
              };
              customPlugins = [
                { source = alphaPluginSource; }
              ];
              installApp = false;
              launchd.enable = false;
              instances.default = {
                gatewayPort = 18999;
                config = {
                  logging = {
                    level = "debug";
                    file = "/tmp/openclaw/openclaw-gateway.log";
                  };
                  gateway = {
                    mode = "local";
                    auth = {
                      token = "hm-activation-test-token";
                    };
                  };
                  plugins = {
                    enabled = false;
                  };
                };
              };
            };

            systemd.user.services."openclaw-gateway".Service = {
              Environment = lib.mkAfter [
                "OPENCLAW_SKIP_BROWSER_CONTROL_SERVER=1"
                "OPENCLAW_SKIP_CANVAS_HOST=1"
                "OPENCLAW_SKIP_CHANNELS=1"
                "OPENCLAW_SKIP_CRON=1"
                "OPENCLAW_SKIP_GMAIL_WATCHER=1"
                "OPENCLAW_DISABLE_BONJOUR=1"
                "NODE_OPTIONS=--report-on-fatalerror"
                "NODE_REPORT_DIRECTORY=/tmp/openclaw"
                "NODE_REPORT_FILENAME=node-report.%p.json"
              ];
              Restart = lib.mkForce "no";
              RestartSec = lib.mkForce "0";
              StandardOutput = lib.mkForce "journal";
              StandardError = lib.mkForce "journal";
            };
          };
      };
    };

  testScript = testScript;
}
