{
  description = "Test Openclaw with Kimi.com Provider";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Use local path for testing
    nix-openclaw.url = "path:/home/clauderun/gitrepos/nix-openclaw";
  };

  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      system = "x86_64-linux";  # Change to your system
      pkgs = import nixpkgs { inherit system; overlays = [ nix-openclaw.overlays.default ]; };
    in {
      homeConfigurations."test-kimi" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          {
            home.username = "test-kimi";
            home.homeDirectory = "/home/test-kimi";
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;

            programs.openclaw = {
              enable = true;
              documents = ./documents;

              # Minimal Matrix config (disable for testing)
              matrix = {
                enable = false;
              };

              # Test configuration with kimi provider
              config = {
                gateway = {
                  mode = "local";
                  auth = {
                    token = "test-token";
                  };
                };

                models = {
                  providers = {
                    kimi = {
                      api = "openai-completions";
                      baseUrl = "https://api.kimi.com/coding/v1";
                      apiKey = "\${KIMI_API_KEY}";
                      auth = "api-key";
                      models = [
                        {
                          id = "kimi-k2p5";
                          name = "Kimi K2.5";
                          api = "openai-completions";
                          contextWindow = 262144;
                          maxTokens = 8192;
                          input = [ "text" "image" ];
                          reasoning = true;
                          compat = {
                            maxTokensField = "max_tokens";
                            supportsDeveloperRole = false;
                            supportsReasoningEffort = true;
                            supportsStore = false;
                          };
                          cost = {
                            input = 0.002;
                            output = 0.008;
                          };
                        }
                      ];
                    };
                  };
                };

                agents = {
                  defaults = {
                    model = {
                      primary = "kimi-k2p5";
                    };
                  };
                };
              };

              instances.default = {
                enable = true;
                plugins = [];
              };
            };

            # Test environment variable
            home.sessionVariables = {
              KIMI_API_KEY = "sk-test-key";
            };
          }
        ];
      };
    };
}
