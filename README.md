# nix-clawdis

> Declarative Clawdis. Bulletproof by default.
>
> macOS only. Linux/Windows are out of scope for now.
>
> <sub>[skip to agent copypasta](#give-this-to-your-ai-agent)</sub>
>
> <sub>Questions? Join the Clawdis Discord and ask in **#nix**.</sub>

![On declarative build systems](docs/images/on-declarative-build-systems.png)

## The Magic

- **One flake, everything works.** Gateway, macOS app, whisper, spotify, camera tools - all wired up and pinned.

- **Plugins are self‑contained.** Each plugin declares its CLI/tools in Nix, you enable it with a repo pointer, and the build/wiring happens automatically (you don’t care where it builds).

- **Agent-first.** Give the copypasta to Claude. It sets you up. You don't read docs, you just talk to your bot.

- **Bulletproof.** Nix locks every dependency. No version drift, no surprises. `home-manager switch` to update, `home-manager generations` to rollback instantly.

## Vision & Strategy

This README is the **single source of truth** for maintainers.


## Why this exists

Clawdis is the right product. An AI assistant that lives in Telegram, controls your Mac, and actually does things.

This repo wraps it in Nix: a pinned, reproducible package that installs the gateway, the macOS app, and all the tools declaratively. Every dependency locked. Every update intentional. Rollback in seconds.

## What it does

```
Me: "what's on my screen?"
Bot: *takes screenshot, describes it*

Me: "play some jazz"
Bot: *opens Spotify, plays jazz*

Me: "transcribe this voice note"
Bot: *runs whisper, sends you text*
```

You talk to Telegram, your Mac does things.

## Give this to your AI agent

Copy this entire block and paste it to Claude, Cursor, or whatever you use:

```text
I want to set up nix-clawdis on my Mac.

Repository: github:joshp123/nix-clawdis

What nix-clawdis is:
- Batteries-included Nix package for Clawdis (AI assistant gateway)
- Installs gateway + macOS app + tools (whisper, spotify, cameras, etc)
- Runs as a launchd service, survives reboots

What I need you to do:
1. Check if Determinate Nix is installed (if not, install it)
2. Create a local flake at ~/code/clawdis-local using templates/agent-first/flake.nix
3. Create a docs dir next to the config (e.g., ~/code/clawdis-local/documents) with AGENTS.md, SOUL.md, TOOLS.md
   - If ~/.clawdis/workspace already has these files, adopt them into the documents dir first
3. Help me create a Telegram bot (@BotFather) and get my chat ID (@userinfobot)
4. Set up secrets (bot token, Anthropic key) - plain files at ~/.secrets/ is fine
5. Fill in the template placeholders and run home-manager switch
6. Verify: launchd running, bot responds to messages

My setup:
- macOS version: [FILL IN]
- CPU: [arm64 / x86_64]
- Home Manager config name: [FILL IN or "I don't have Home Manager yet"]

Reference the README and templates/agent-first/flake.nix in the repo for the module options.
```

## Minimal config (single‑instance)

Use this for the simplest setup. For richer config (per‑group overrides), use
`instances.default` below.

```nix
{
  programs.clawdis = {
    enable = true;
    providers.telegram = {
      enable = true;
      botTokenFile = "/run/agenix/telegram-bot-token"; # any file path works
      allowFrom = [ 12345678 ];  # your Telegram user ID
    };
    providers.anthropic = {
      apiKeyFile = "/run/agenix/anthropic-api-key"; # any file path works
    };

    # No plugin settings needed for hello‑world.
    plugins = [
      { source = "github:acme/hello-world"; }
    ];
  };
}
```

Then: `home-manager switch --flake .#youruser`

## Small but useful config (sensible defaults)

This is still single‑instance, but uses `instances.default` to unlock per‑group mention rules.
If `instances` is set, you don’t need `programs.clawdis.enable`.
Group mention overrides below mirror upstream Clawdis config.
Secrets are shown using `/run/agenix/...` (from a repo with your agenix secrets), but any file path works.
Docs are managed from `./documents` and symlinked into the workspace on each switch.

```nix
{
  programs.clawdis = {
    documents = ./documents;
    instances.default = {
      enable = true;
      package = pkgs.clawdis; # batteries-included
      stateDir = "~/.clawdis";
      workspaceDir = "~/.clawdis/workspace";

      providers.telegram = {
        enable = true;
        botTokenFile = "/run/agenix/telegram-bot-token";
        allowFrom = [
          12345678         # you (DM)
          -1001234567890   # couples group (no @mention required)
          -1002345678901   # noisy group (require @mention)
        ];
        groups = {
          "*" = { requireMention = true; };
          "-1001234567890" = { requireMention = false; }; # couples group
          "-1002345678901" = { requireMention = true; };  # noisy group
        };
      };

      providers.anthropic.apiKeyFile = "/run/agenix/anthropic-api-key";

      launchd.enable = true;

      # Plugins (prod: pinned GitHub). Built‑ins are already included.
      # MVP target: repo pointers resolve to tools + skills automatically.
      plugins = [
        { source = "github:joshp123/xuezh"; }
        {
          source = "github:joshp123/padel-cli";
          config = {
            env = { PADEL_AUTH_FILE = "/run/agenix/padel-auth"; };
            settings = {
              default_location = "CITY_NAME";
              preferred_times = [ "18:00" "20:00" ];
              preferred_duration = 90;
              venues = [
                {
                  id = "VENUE_ID";
                  alias = "VENUE_ALIAS";
                  name = "VENUE_NAME";
                  indoor = true;
                  timezone = "TIMEZONE";
                }
              ];
            };
          };
        }
      ];
    };
  };
}
```

## Minimal dual‑instance (prod + dev)

Use a shared base config and override only what’s different. This should become
a first‑class feature, but plain Nix works today. After changing local plugin or
gateway code, re-run `home-manager switch` to rebuild. POC: the macOS app stays
pinned to a released version (no local app builds yet).

```nix
# flake inputs (pin prod + app)
inputs = {
  nix-clawdis.url = "github:joshp123/nix-clawdis?ref=v0.1.0"; # pins macOS app + gateway bundle
};

let
  prod = {
    enable = true;
    # Prod gateway pin (comes from nix-clawdis input @ v0.1.0 above).
    package = inputs.nix-clawdis.packages.${pkgs.system}.clawdis-gateway;
    providers.telegram.enable = true;
    providers.telegram.botTokenFile = "/run/agenix/telegram-prod";
    providers.telegram.allowFrom = [ 12345678 ];
    providers.anthropic.apiKeyFile = "/run/agenix/anthropic-api-key";
    plugins = [ { source = "github:owner/your-plugin"; } ];
  };
in {
  # Pinned macOS app (POC: no local app builds, uses nix-clawdis @ v0.1.0 above).
  programs.clawdis.appPackage =
    inputs.nix-clawdis.packages.${pkgs.system}.clawdis-app;
  programs.clawdis.documents = ./documents;
  programs.clawdis.instances = {
    prod = prod;
    dev = prod // {
      # Dev uses the same pinned macOS app (from nix-clawdis input),
      # but overrides the gateway package to a local checkout.
      providers.telegram.botTokenFile = "/run/agenix/telegram-dev";
      gatewayPort = 18790;
      # Local gateway checkout (path). App stays pinned.
      gatewayPath = "/Users/you/code/clawdis";
      # Local plugin overrides prod if names collide (last wins).
      plugins = prod.plugins ++ [
        { source = "path:/Users/you/code/your-plugin"; }
        {
          source = "github:joshp123/padel-cli";
          config = {
            env = { PADEL_AUTH_FILE = "/run/agenix/padel-auth-dev"; };
            settings = {
              default_location = "CITY_NAME";
              preferred_times = [ "18:00" ];
              preferred_duration = 90;
              venues = [];
            };
          };
        }
      ];
    };
  };
}
```


## Hello‑world plugin (repo + skill)

**Plugin repo structure (minimum):**

```
your-plugin/
  flake.nix
  skills/
    hello-world/
      SKILL.md
```

Example implementation: `examples/hello-world-plugin`.

**`flake.nix` (minimal `clawdisPlugin`):**

```nix
{
  outputs = { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = builtins.currentSystem; };
    in {
      clawdisPlugin = {
        name = "hello-world";
        skills = [ ./skills/hello-world ];
        packages = [ pkgs.hello ]; # example CLI
        needs = {
          stateDirs = [];
          env = [];
          requiredFiles = [];
        };
      };
    };
}
```

**`skills/hello-world/SKILL.md` (minimal):**

```md
---
name: hello-world
description: Prints hello world.
---

Use the `hello` CLI to print a greeting.
```

**Hello‑world uses no config:** it declares empty `needs` and requires no
per‑plugin `config`.

## Paste this prompt to your coding agent (make your plugin nix‑clawdis‑native)

```text
Goal: Make this repo a nix‑clawdis‑native plugin with the standard contract.

Contract to implement:
1) Add clawdisPlugin output in flake.nix:
   - name
   - skills (paths to SKILL.md dirs)
   - packages (CLI packages to put on PATH)
   - needs (stateDirs + requiredEnv)

Example:
clawdisPlugin = {
  name = "my-plugin";
  skills = [ ./skills/my-plugin ];
  packages = [ self.packages.${system}.default ];
  needs = {
    stateDirs = [ ".config/my-plugin" ];
    requiredEnv = [ "MYPLUGIN_AUTH_FILE" ];
  };
};

2) Make the CLI explicitly configurable by env (no magic defaults):
   - Support an auth file env (e.g., MYPLUGIN_AUTH_FILE)
   - Honor XDG_CONFIG_HOME or a plugin-specific config dir env

3) Provide AGENTS.md in the plugin repo:
   - Plain‑English explanation of knobs + values
   - Generic placeholders only (no real secrets)
   - Explain where credentials live (e.g., /run/agenix/…)

4) Update SKILL.md to call the CLI by its PATH name.

Standard plugin config shape (Nix‑native, no JSON strings):

plugins = [
  {
    source = "github:owner/my-plugin";
    config = {
      env = {
        MYPLUGIN_AUTH_FILE = "/run/agenix/myplugin-auth";
      };
      settings = {
        name = "EXAMPLE_NAME";
        enabled = true;
        retries = 3;
        tags = [ "alpha" "beta" ];
        window = { start = "08:00"; end = "18:00"; };
        options = { mode = "fast"; level = 2; };
      };
    };
  }
];

Config flags the host will use:
- `config.env` for required env vars (e.g., MYPLUGIN_AUTH_FILE)
- `config.settings` for typed config keys (rendered to config.json in the first stateDir)

CI note:
- If the repo uses Garnix, add the plugin build to its `garnix.yaml` (or equivalent) so CI verifies it.

Why: explicit, minimal, fail‑fast, no inline JSON strings.
Deliverables: flake output, env overrides, AGENTS.md, skill update.
```

## How it wires up

- Nix pulls the plugin, reads `clawdisPlugin`, and installs the CLI(s).
- Skills are symlinked into `~/.clawdis/skills/<plugin>/<skill>`.
- Clawdis loads managed skills automatically at runtime.
- Any plugin services run as **user‑level** launchd agents (no sudo).
- MVP scope: tools/skills should come **from plugins only** (no ad‑hoc installs).
- Plugin `settings` are rendered to `config.json` in the plugin’s first `stateDir`.

## What you get

- Launchd keeps the gateway alive (`com.steipete.clawdis.gateway`)
- Logs at `/tmp/clawdis/clawdis-gateway.log`
- Message your bot in Telegram, get a response
- All the tools: whisper, spotify_player, camsnap, peekaboo, and more

## What we manage vs what you manage

| Component | Nix manages | You manage |
| --- | --- | --- |
| Gateway binary | ✓ | |
| macOS app | ✓ | |
| Launchd service | ✓ | |
| Tools (whisper, etc) | ✓ | |
| Telegram bot token | | ✓ |
| Anthropic API key | | ✓ |
| Chat IDs | | ✓ |

## Packages

| Package | Contents |
| --- | --- |
| `clawdis` (default) | Gateway + app + full toolchain |
| `clawdis-gateway` | Gateway CLI only |
| `clawdis-app` | macOS app only |

## Plugin collisions (override policy)

Plugins are keyed by their declared `name`. If two plugins declare the same name,
the **last entry wins** (use this to override a prod plugin with a local dev one).
We should warn on collisions so it’s obvious.

## Included tools (to add soon)

**Core**: nodejs, pnpm, git, curl, jq, python3, ffmpeg, ripgrep

**AI/ML**: openai-whisper, sag (TTS)

**Media**: spotify-player, sox, camsnap

**macOS**: peekaboo, blucli

**Integrations**: gogcli, wacli, bird, mcporter

## Commands

```bash
# Check service
launchctl print gui/$UID/com.steipete.clawdis.gateway | grep state

# View logs
tail -50 /tmp/clawdis/clawdis-gateway.log

# Restart
launchctl kickstart -k gui/$UID/com.steipete.clawdis.gateway

# Rollback
home-manager generations  # list
home-manager switch --rollback  # revert
```

## Upstream

Wraps [Clawdis](https://github.com/steipete/clawdis) by Peter Steinberger.

## Philosophy

The Zen of ~~Python~~ Clawdis, ~~by~~ shamelessly stolen from Tim Peters

Beautiful is better than ugly.  
Explicit is better than implicit.  
Simple is better than complex.  
Complex is better than complicated.  
Flat is better than nested.  
Sparse is better than dense.  
Readability counts.  
Special cases aren't special enough to break the rules.  
Although practicality beats purity.  
Errors should never pass silently.  
Unless explicitly silenced.  
In the face of ambiguity, refuse the temptation to guess.  
There should be one-- and preferably only one --obvious way to do it.  
Although that way may not be obvious at first unless you're Dutch.  
Now is better than never.  
Although never is often better than *right* now.  
If the implementation is hard to explain, it's a bad idea.  
If the implementation is easy to explain, it may be a good idea.  
Namespaces are one honking great idea -- let's do more of those!

## License

AGPL-3.0
