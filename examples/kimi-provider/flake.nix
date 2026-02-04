{
  description = "Openclaw with Kimi.com (Moonshot AI) Provider";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      # Adjust for your system: aarch64-darwin (Apple Silicon), x86_64-darwin (Intel), or x86_64-linux
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; overlays = [ nix-openclaw.overlays.default ]; };
    in {
      homeConfigurations."kimi-user" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          ({ config, lib, ... }: {
            home.username = "kimi-user";
            home.homeDirectory = "/Users/kimi-user";  # Change to /home/kimi-user on Linux
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;

            programs.openclaw = {
              enable = true;
              documents = ./documents;

              # Matrix configuration (required for messaging)
              matrix = {
                enable = true;
                homeserverUrl = "https://matrix.aboutco.ai/";
                userId = "@your-bot:aboutco.ai";  # Replace with your bot's Matrix ID
                accessTokenFile = "\${config.home.homeDirectory}/.secrets/matrix-token";
              };

              # Kimi.com (Moonshot AI) Provider Configuration
              config = {
                gateway = {
                  mode = "local";
                  auth = {
                    token = "your-gateway-token-here";  # Or set OPENCLAW_GATEWAY_TOKEN env var
                  };
                };

                # Model providers configuration
                models = {
                  providers = {
                    # Kimi.com provider configuration
                    kimi = {
                      # Use OpenAI-compatible API
                      api = "openai-completions";
                      
                      # Kimi.com API endpoint
                      baseUrl = "https://api.kimi.com/coding/v1";
                      
                      # API key (better to use environment variable or secrets file)
                      apiKey = "\${KIMI_API_KEY}";
                      
                      # Authentication method
                      auth = "api-key";
                      
                      # Custom headers if needed
                      headers = {
                        # "Custom-Header" = "value";
                      };

                      # Model definitions
                      models = [
                        {
                          id = "kimi-k2p5";
                          name = "Kimi K2.5";
                          api = "openai-completions";
                          contextWindow = 262144;  # 262K context window
                          maxTokens = 8192;
                          input = [ "text" "image" ];  # Supports both text and images
                          reasoning = true;  # Supports reasoning
                          
                          # Compatibility settings
                          compat = {
                            maxTokensField = "max_tokens";
                            supportsDeveloperRole = false;
                            supportsReasoningEffort = true;
                            supportsStore = false;
                          };
                          
                          # Cost configuration (update with actual pricing)
                          cost = {
                            input = 0.002;   # $0.002 per 1K tokens
                            output = 0.008;  # $0.008 per 1K tokens
                          };
                        }
                        {
                          id = "kimi-k2-thinking";
                          name = "Kimi K2 Thinking";
                          api = "openai-completions";
                          contextWindow = 262144;
                          maxTokens = 8192;
                          input = [ "text" ];
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

                # Agent configuration with kimi as default
                agents = {
                  defaults = {
                    model = {
                      primary = "kimi-k2p5";
                      fallbacks = [ "kimi-k2-thinking" ];
                    };
                    
                    # Model aliases for convenience
                    modelAliases = {
                      "k2" = "kimi-k2p5";
                      "k2-thinking" = "kimi-k2-thinking";
                    };

                    # Subagents also use kimi
                    subagents = {
                      model = "kimi-k2p5";
                      thinking = "minimal";
                    };
                  };

                  # Define specific agents if needed
                  list = [
                    {
                      id = "kimi-assistant";
                      name = "Kimi Assistant";
                      model = {
                        primary = "kimi-k2p5";
                      };
                    }
                  ];
                };
              };

              instances.default = {
                enable = true;
                
                # Plugins configuration
                plugins = [
                  # Example plugins - add your own
                  { source = "github:openclaw/nix-steipete-tools?dir=tools/summarize"; }
                  { source = "github:openclaw/nix-steipete-tools?dir=tools/peekaboo"; }
                ];
              };
            };

            # Environment variables for API keys
            home.sessionVariables = {
              # Set your Kimi API key here or reference a secrets file
              KIMI_API_KEY = "$(cat \${config.home.homeDirectory}/.secrets/kimi-api-key)";
            };
          })
        ];
      };
    };
}
