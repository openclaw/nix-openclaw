{ pkgs, home-manager }:

let
  openclawModule = ../modules/home-manager/openclaw.nix;
  testScript = builtins.readFile ../tests/hm-activation.py;

in
pkgs.testers.nixosTest {
  name = "openclaw-hm-activation";

  nodes.machine = { ... }:
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
        users.alice = { lib, ... }:
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
                };
              };
            };

            systemd.user.services."openclaw-gateway".Service.Environment = lib.mkAfter [
              "OPENCLAW_SKIP_BROWSER_CONTROL_SERVER=1"
              "OPENCLAW_SKIP_CANVAS_HOST=1"
              "OPENCLAW_SKIP_CHANNELS=1"
              "OPENCLAW_SKIP_CRON=1"
              "OPENCLAW_SKIP_GMAIL_WATCHER=1"
              "OPENCLAW_DISABLE_BONJOUR=1"
              "NODE_DEBUG=module"
              "NODE_OPTIONS=--report-on-fatalerror --report-on-signal"
              "NODE_REPORT_DIRECTORY=/tmp/openclaw"
              "NODE_REPORT_FILENAME=node-report.%p.json"
              "NODE_REPORT_SIGNAL=SIGABRT"
            ];
          };
      };
    };

  testScript = testScript;
}
