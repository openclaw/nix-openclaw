# Kimi.com (Moonshot AI) Provider Example

This example demonstrates how to configure kimi.com (Moonshot AI) as an LLM provider in nix-openclaw.

## Files

- `flake.nix` - Complete production-ready configuration
- `test-flake.nix` - Minimal test configuration
- `documents/` - Required documentation files (AGENTS.md, SOUL.md, TOOLS.md)

## Quick Start

1. **Set your API key**:
   ```bash
   export KIMI_API_KEY="sk-your-actual-api-key"
   ```

2. **Review the configuration**:
   - Edit `flake.nix` to set your system type (`aarch64-darwin`, `x86_64-darwin`, or `x86_64-linux`)
   - Update the Matrix configuration (or disable it for testing)
   - Adjust the username and home directory

3. **Apply the configuration**:
   ```bash
   home-manager switch --flake .#kimi-user
   ```

## Configuration Highlights

### Provider Setup

```nix
models.providers.kimi = {
  api = "openai-completions";  # OpenAI-compatible API
  baseUrl = "https://api.kimi.com/coding/v1";
  apiKey = "\${KIMI_API_KEY}";
  auth = "api-key";
  models = [
    {
      id = "kimi-k2p5";
      name = "Kimi K2.5";
      contextWindow = 262144;  # 262K context
      maxTokens = 8192;
      input = [ "text" "image" ];  # Multimodal
      reasoning = true;
      # ... see flake.nix for full configuration
    }
  ];
};
```

### Model Selection

```nix
agents.defaults.model = {
  primary = "kimi-k2p5";
  fallbacks = [ "kimi-k2-thinking" ];
};
```

## Testing

The configuration has been validated with:

```bash
nix flake check --impure
```

## API Key

Get your API key from:
- https://www.kimi.com/ (International)
- https://platform.moonshot.ai/ (Alternative)

## Documentation

For detailed documentation, see:
- [Kimi Provider Documentation](../../docs/kimi-provider.md)
- [Openclaw README](../../README.md)
