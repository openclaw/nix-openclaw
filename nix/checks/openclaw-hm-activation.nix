{ pkgs, home-manager, steipeteToolsInput }:

let
  openclawModule = {
    _module.args.steipeteToolsInput = steipeteToolsInput;
    imports = [ ../modules/home-manager/openclaw ];
  };
  testScript = builtins.readFile ../tests/hm-activation.py;

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
                "NODE_OPTIONS=--report-on-fatalerror --report-on-signal --report-signal=SIGABRT"
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
