# Kimi.com (Moonshot AI) Provider Configuration

This document describes how to configure kimi.com (Moonshot AI) as an LLM provider in nix-openclaw.

## Overview

Kimi.com (Moonshot AI) provides an OpenAI-compatible API endpoint that can be used with nix-openclaw. The K2.5 model (`kimi-k2p5`) is a powerful multimodal model with a 262K context window.

## API Endpoints

| Region | Base URL |
|--------|----------|
| **Kimi.com (International)** | `https://api.kimi.com/coding/v1` |
| **Moonshot AI (China)** | `https://api.moonshot.cn/v1` |
| **Moonshot AI (International)** | `https://api.moonshot.ai/v1` |

> **Note**: This configuration uses `https://api.kimi.com/coding/v1` as specified for kimi.com integration.

## Supported Models

- `kimi-k2p5` / `kimi-k2.5` - Kimi K2.5 (262K context, vision support, prompt caching)
- `kimi-k2-0711-preview` - Preview version
- `kimi-k2-thinking` / `kimi-k2-thinking-turbo` - Reasoning models
- `kimi-latest` - Always points to latest model

## Configuration Example

Add the following to your `flake.nix` or Home Manager configuration:

```nix
{
  programs.openclaw = {
    enable = true;
    documents = ./documents;
    
    config = {
      models = {
        providers = {
          kimi = {
            api = "openai-completions";
            baseUrl = "https://api.kimi.com/coding/v1";
            apiKey = "sk-your-kimi-api-key";  # Or use environment variable
            auth = "api-key";
            models = [
              {
                id = "kimi-k2p5";
                name = "Kimi K2.5";
                api = "openai-completions";
                contextWindow = 262144;  # 262K context window
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
                  input = 0.002;   # $0.002 per 1K tokens (example pricing)
                  output = 0.008;  # $0.008 per 1K tokens (example pricing)
                };
              }
            ];
          };
        };
      };
      
      # Set kimi as the default model
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
      plugins = [
        # Your plugins here
      ];
    };
  };
}
```

## Using Environment Variables for API Key

For better security, use an environment variable instead of hardcoding the API key:

```nix
{
  # In your Home Manager configuration
  home.sessionVariables = {
    KIMI_API_KEY = "$(cat /run/agenix/kimi-api-key)";  # Or path to your secrets
  };
  
  programs.openclaw.config.models.providers.kimi.apiKey = "\${KIMI_API_KEY}";
}
```

Or use a secrets file:

```nix
{
  programs.openclaw.config.models.providers.kimi.apiKeyFile = "/run/agenix/kimi-api-key";
}
```

## Model Aliases

You can create model aliases for easier reference:

```nix
{
  programs.openclaw.config.agents.defaults.modelAliases = {
    "k2" = "kimi-k2p5";
    "k2-thinking" = "kimi-k2-thinking";
  };
}
```

## Compatibility Notes

1. **OpenAI Compatibility**: Kimi.com API is fully OpenAI-compatible, so `openai-completions` API type works seamlessly
2. **Authentication**: Uses `Authorization: Bearer <api_key>` header format
3. **Streaming**: Supports Server-Sent Events (SSE) for streaming responses
4. **Vision**: K2.5 model supports image input
5. **Function Calling**: Supported on kimi-k2.5 and kimi-thinking models
6. **Reasoning**: K2.5 supports reasoning with `supportsReasoningEffort = true`

## Getting an API Key

1. Visit https://www.kimi.com/ or https://platform.moonshot.ai/
2. Create an account
3. Navigate to the API keys section
4. Generate a new API key (starts with `sk-`)

## Testing the Configuration

After applying the configuration with `home-manager switch`, test the provider:

```bash
# Check if the gateway is running
launchctl print gui/$UID/com.steipete.openclaw.gateway | grep state  # macOS
systemctl --user status openclaw-gateway                              # Linux

# View logs
tail -f /tmp/openclaw/openclaw-gateway.log
```

## Troubleshooting

### API Key Issues
- Ensure your API key starts with `sk-`
- Verify the key has not expired
- Check that the key has sufficient quota/credits

### Connection Issues
- Verify the base URL is correct: `https://api.kimi.com/coding/v1`
- Check network connectivity to kimi.com
- Ensure no firewall is blocking the connection

### Model Not Found
- Verify the model ID is exactly `kimi-k2p5` (or the correct variant)
- Check that your API key has access to the specified model

## References

- [Kimi Code Documentation](https://www.kimi.com/code/docs/en/)
- [Moonshot AI API Docs](https://platform.moonshot.ai/docs/api/chat)
- [Openclaw Configuration Reference](../README.md#configuration)
