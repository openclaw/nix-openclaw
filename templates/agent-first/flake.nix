{
  description = "Openclaw local";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      # REPLACE: aarch64-darwin (Apple Silicon), x86_64-darwin (Intel), or x86_64-linux
      system = "<system>";
      pkgs = import nixpkgs { inherit system; overlays = [ nix-openclaw.overlays.default ]; };
    in {
      # REPLACE: <user> with your username (run `whoami`)
      homeConfigurations."<user>" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          {
            # Required for Home Manager standalone
            home.username = "<user>";
            # REPLACE: /Users/<user> on macOS or /home/<user> on Linux
            home.homeDirectory = "<homeDir>";
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;

            programs.openclaw = {
              # REPLACE: path to your managed documents directory
              documents = ./documents;

              # Matrix is enabled by default (replaces Telegram)
              matrix = {
                enable = true;
                # REPLACE: Your Matrix homeserver URL (default uses https://matrix.aboutco.ai/)
                homeserverUrl = "https://matrix.aboutco.ai/";
                # REPLACE: Your Matrix bot user ID (e.g., @mybot:aboutco.ai)
                userId = "<matrixUserId>";
                # REPLACE: Path to file containing Matrix access token
                # Get token via: curl -X POST https://matrix.aboutco.ai/_matrix/client/v3/login \
                #   -H 'Content-Type: application/json' \
                #   -d '{"type":"m.login.password","identifier":{"type":"m.id.user","user":"USERNAME"},"password":"PASSWORD"}'
                accessTokenFile = "<accessTokenPath>";
              };

              # Kimi (Moonshot AI) is configured as the default LLM provider
              # Get your API key from: https://www.kimi.com/
              config = {
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
                          contextWindow = 262144;  # 262K context window
                          maxTokens = 8192;
                          input = [ "text" "image" ];  # Multimodal support
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
                      primary = "kimi/kimi-k2p5";
                      fallbacks = [ "anthropic/claude-3-5-sonnet-20241022" ];
                    };
                  };
                };
              };

              instances.default = {
                enable = true;
                # Note: The @openclaw/matrix plugin is loaded automatically when Matrix is enabled
                plugins = [
                  # Example plugin without config:
                  { source = "github:acme/hello-world"; }
                ];
              };
            };

            # Environment variables for API keys
            home.sessionVariables = {
              # REPLACE: Set your Kimi API key here or reference a secrets file
              # Get your API key from: https://www.kimi.com/
              KIMI_API_KEY = "$(cat <kimiApiKeyPath>)";
            };
          }
        ];
      };
    };
}
