{
  lib,
  pkgs,
  helpers,
}:

let
  inherit (helpers) moduleEval requireNoAssertionFailures generatedConfig;

  homeRelativeConfigEval = moduleEval {
    instances.default.stateDir = "~/openclaw state";
  };
  homeRelativeConfigCheckFor =
    eval:
    let
      activation = eval.config.home.activation.openclawConfigFiles.data;
      homeFile = eval.config.home.file;
      generated =
        if builtins.hasAttr "openclaw state/openclaw.json" homeFile then
          generatedConfig eval "openclaw state/openclaw.json"
        else
          { };
      systemdService =
        if pkgs.stdenv.hostPlatform.isLinux then
          eval.config.systemd.user.services.openclaw-gateway.Service or { }
        else
          { };
      launchdConfig =
        if pkgs.stdenv.hostPlatform.isDarwin then
          eval.config.launchd.agents."com.steipete.openclaw.gateway".config or { }
        else
          { };
    in
    if !(lib.hasInfix " '/tmp/openclaw state/openclaw.json'" activation) then
      throw "Config activation must resolve home-relative paths before shell escaping."
    else if builtins.hasAttr "~/openclaw state/openclaw.json" homeFile then
      throw "home.file still uses an unresolved ~/ config destination."
    else if !(builtins.hasAttr "openclaw state/openclaw.json" homeFile) then
      throw "home.file must materialize the resolved config path, not a literal ~/ destination."
    else if
      (((generated.agents or { }).defaults or { }).workspace or null) != "/tmp/openclaw state/workspace"
    then
      throw "Workspace pin must resolve home-relative workspaceDir."
    else if
      pkgs.stdenv.hostPlatform.isLinux
      && ((systemdService.WorkingDirectory or "") != "/tmp/openclaw state")
    then
      throw "Systemd WorkingDirectory must resolve home-relative stateDir."
    else if
      pkgs.stdenv.hostPlatform.isLinux
      && !(lib.elem "\"OPENCLAW_STATE_DIR=/tmp/openclaw state\"" (systemdService.Environment or [ ]))
    then
      throw "Systemd OPENCLAW_STATE_DIR must resolve home-relative stateDir."
    else if
      pkgs.stdenv.hostPlatform.isLinux
      && !(lib.elem "\"OPENCLAW_CONFIG_PATH=/tmp/openclaw state/openclaw.json\"" (
        systemdService.Environment or [ ]
      ))
    then
      throw "Systemd OPENCLAW_CONFIG_PATH must resolve home-relative configPath."
    else if
      pkgs.stdenv.hostPlatform.isDarwin
      && ((launchdConfig.WorkingDirectory or "") != "/tmp/openclaw state")
    then
      throw "launchd WorkingDirectory must resolve home-relative stateDir."
    else if
      pkgs.stdenv.hostPlatform.isDarwin
      && (
        ((launchdConfig.EnvironmentVariables or { }).OPENCLAW_STATE_DIR or null) != "/tmp/openclaw state"
      )
    then
      throw "launchd OPENCLAW_STATE_DIR must resolve home-relative stateDir."
    else if
      pkgs.stdenv.hostPlatform.isDarwin
      && (
        ((launchdConfig.EnvironmentVariables or { }).OPENCLAW_CONFIG_PATH or null)
        != "/tmp/openclaw state/openclaw.json"
      )
    then
      throw "launchd OPENCLAW_CONFIG_PATH must resolve home-relative configPath."
    else
      "ok";

  homeRelativeConfigCheck = homeRelativeConfigCheckFor homeRelativeConfigEval;
  topLevelHomeRelativeConfigCheck = homeRelativeConfigCheckFor (moduleEval {
    stateDir = "~/openclaw state";
  });

  spacedConfigEval = moduleEval {
    instances.default.configPath = "/tmp/openclaw state/config 'file'.json";
  };
  spacedConfigEnvironmentCheck =
    if
      pkgs.stdenv.hostPlatform.isLinux
      && !(lib.elem "\"OPENCLAW_CONFIG_PATH=/tmp/openclaw state/config 'file'.json\"" spacedConfigEval.config.systemd.user.services.openclaw-gateway.Service.Environment)
    then
      throw "Systemd config environment must preserve paths containing spaces and quotes."
    else
      "ok";

  reloadHelperText =
    eval:
    let
      file = eval.config.home.file.".local/bin/openclaw-reload" or { };
    in
    if file ? text then file.text else throw "openclaw-reload helper was not installed.";

  reloadHasLine = text: line: lib.hasInfix line text;

  reloadDefaultEval = moduleEval {
    reloadScript.enable = true;
  };
  reloadDefaultText = reloadHelperText reloadDefaultEval;
  reloadDefaultCheck =
    builtins.deepSeq (requireNoAssertionFailures "reload default targets" reloadDefaultEval)
      (
        if reloadHasLine reloadDefaultText "com.steipete.openclaw.gateway.nix" then
          throw "Default reload helper still hardcodes .nix launchd labels."
        else if pkgs.stdenv.hostPlatform.isDarwin then
          if
            !(reloadHasLine reloadDefaultText "  test)\n    launchd_labels=(com.steipete.openclaw.gateway)")
          then
            throw "Default reload helper test target missing module default launchd label."
          else if
            !(reloadHasLine reloadDefaultText "  prod)\n    launchd_labels=(com.steipete.openclaw.gateway)")
          then
            throw "Default reload helper prod target missing module default launchd label."
          else if
            !(reloadHasLine reloadDefaultText "  both)\n    launchd_labels=(com.steipete.openclaw.gateway)")
          then
            throw "Default reload helper both target missing module default launchd label."
          else
            "ok"
        else if pkgs.stdenv.hostPlatform.isLinux then
          if
            !(reloadHasLine reloadDefaultText "  test)\n    launchd_labels=()\n    systemd_units=(openclaw-gateway)")
          then
            throw "Default reload helper test target missing module default systemd unit."
          else if
            !(reloadHasLine reloadDefaultText "  prod)\n    launchd_labels=()\n    systemd_units=(openclaw-gateway)")
          then
            throw "Default reload helper prod target missing module default systemd unit."
          else if
            !(reloadHasLine reloadDefaultText "  both)\n    launchd_labels=()\n    systemd_units=(openclaw-gateway)")
          then
            throw "Default reload helper both target missing module default systemd unit."
          else
            "ok"
        else
          "ok"
      );

  reloadNamedEval = moduleEval {
    reloadScript.enable = true;
    instances.prod.enable = true;
    instances.test.enable = true;
  };
  reloadNamedText = reloadHelperText reloadNamedEval;
  reloadNamedCheck =
    builtins.deepSeq (requireNoAssertionFailures "reload named targets" reloadNamedEval)
      (
        if reloadHasLine reloadNamedText "com.steipete.openclaw.gateway.nix" then
          throw "Named reload helper still hardcodes .nix launchd labels."
        else if pkgs.stdenv.hostPlatform.isDarwin then
          if
            !(reloadHasLine reloadNamedText "  test)\n    launchd_labels=(com.steipete.openclaw.gateway.test)")
          then
            throw "Named reload helper test target missing test instance launchd label."
          else if
            !(reloadHasLine reloadNamedText "  prod)\n    launchd_labels=(com.steipete.openclaw.gateway.prod)")
          then
            throw "Named reload helper prod target missing prod instance launchd label."
          else if
            !(reloadHasLine reloadNamedText "  both)\n    launchd_labels=(com.steipete.openclaw.gateway.prod com.steipete.openclaw.gateway.test)")
          then
            throw "Named reload helper both target missing configured launchd labels."
          else
            "ok"
        else if pkgs.stdenv.hostPlatform.isLinux then
          if
            !(reloadHasLine reloadNamedText "  test)\n    launchd_labels=()\n    systemd_units=(openclaw-gateway-test)")
          then
            throw "Named reload helper test target missing test instance systemd unit."
          else if
            !(reloadHasLine reloadNamedText "  prod)\n    launchd_labels=()\n    systemd_units=(openclaw-gateway-prod)")
          then
            throw "Named reload helper prod target missing prod instance systemd unit."
          else if
            !(reloadHasLine reloadNamedText "  both)\n    launchd_labels=()\n    systemd_units=(openclaw-gateway-prod openclaw-gateway-test)")
          then
            throw "Named reload helper both target missing configured systemd units."
          else
            "ok"
        else
          "ok"
      );

  reloadCustomDefaultEval = moduleEval {
    reloadScript.enable = true;
    launchd.label = "com.example.openclaw.gateway";
    systemd.unitName = "openclaw-example";
  };
  reloadCustomDefaultText = reloadHelperText reloadCustomDefaultEval;
  reloadCustomDefaultCheck =
    builtins.deepSeq
      (requireNoAssertionFailures "reload custom default targets" reloadCustomDefaultEval)
      (
        if pkgs.stdenv.hostPlatform.isDarwin then
          if
            !(reloadHasLine reloadCustomDefaultText "  test)\n    launchd_labels=(com.example.openclaw.gateway)")
          then
            throw "Custom default reload helper test target did not use programs.openclaw.launchd.label."
          else if
            !(reloadHasLine reloadCustomDefaultText "  prod)\n    launchd_labels=(com.example.openclaw.gateway)")
          then
            throw "Custom default reload helper prod target did not use programs.openclaw.launchd.label."
          else
            "ok"
        else if pkgs.stdenv.hostPlatform.isLinux then
          if
            !(reloadHasLine reloadCustomDefaultText "  test)\n    launchd_labels=()\n    systemd_units=(openclaw-example)")
          then
            throw "Custom default reload helper test target did not use programs.openclaw.systemd.unitName."
          else if
            !(reloadHasLine reloadCustomDefaultText "  prod)\n    launchd_labels=()\n    systemd_units=(openclaw-example)")
          then
            throw "Custom default reload helper prod target did not use programs.openclaw.systemd.unitName."
          else
            "ok"
        else
          "ok"
      );

  secretProviderEval = moduleEval {
    config.secrets.providers.test-file = {
      source = "file";
      path = "/tmp/openclaw-secrets.json";
      mode = "json";
    };
  };
  secretProviderConfig = generatedConfig secretProviderEval ".openclaw/openclaw.json";
  secretProviderCheck =
    builtins.deepSeq (requireNoAssertionFailures "secrets.providers" secretProviderEval)
      (
        if
          ((((secretProviderConfig.secrets or { }).providers or { }).test-file or { }).source == "file")
        then
          "ok"
        else
          throw "secrets.providers file variant missing from generated config."
      );

  secretRefPassthroughEval = moduleEval {
    config = {
      secrets.providers = {
        aws_test = {
          source = "exec";
          command = "/usr/bin/aws";
          args = [
            "secretsmanager"
            "get-secret-value"
            "--secret-id"
            "openclaw/groq"
          ];
          jsonOnly = false;
        };
        filemain = {
          source = "file";
          path = "/run/agenix/openclaw-secrets.json";
          mode = "json";
        };
      };

      models.providers = {
        groq = {
          baseUrl = "https://api.groq.com/openai/v1";
          api = "openai-completions";
          apiKey = {
            source = "exec";
            provider = "aws_test";
            id = "value";
          };
          models = [
            {
              id = "llama-3.3-70b-versatile";
              name = "Llama 3.3 70B";
            }
          ];
        };
        filebacked = {
          baseUrl = "https://example.invalid/v1";
          api = "openai-completions";
          apiKey = {
            source = "file";
            provider = "filemain";
            id = "/providers/filebacked/apiKey";
          };
          models = [
            {
              id = "test-model";
              name = "Test model";
            }
          ];
        };
      };
    };
  };
  secretRefPassthroughConfig = generatedConfig secretRefPassthroughEval ".openclaw/openclaw.json";
  secretRefGroqApiKey =
    ((secretRefPassthroughConfig.models or { }).providers or { }).groq.apiKey or { };
  secretRefFileApiKey =
    ((secretRefPassthroughConfig.models or { }).providers or { }).filebacked.apiKey or { };
  secretRefPassthroughCheck =
    builtins.deepSeq (requireNoAssertionFailures "SecretRef passthrough" secretRefPassthroughEval)
      (
        if secretRefGroqApiKey.source != "exec" then
          throw "models.providers.groq.apiKey exec SecretRef was not rendered unchanged."
        else if secretRefGroqApiKey.provider != "aws_test" then
          throw "models.providers.groq.apiKey exec SecretRef provider was not rendered unchanged."
        else if secretRefGroqApiKey.id != "value" then
          throw "models.providers.groq.apiKey exec SecretRef id was not rendered unchanged."
        else if secretRefFileApiKey.source != "file" then
          throw "models.providers.filebacked.apiKey file SecretRef was not rendered unchanged."
        else if secretRefFileApiKey.provider != "filemain" then
          throw "models.providers.filebacked.apiKey file SecretRef provider was not rendered unchanged."
        else if secretRefFileApiKey.id != "/providers/filebacked/apiKey" then
          throw "models.providers.filebacked.apiKey file SecretRef id was not rendered unchanged."
        else
          "ok"
      );

  runtimeProfileEval = moduleEval {
    runtimePackages = [ pkgs.jq ];
    environment.OPENCLAW_TEST_SECRET = "/tmp/openclaw-secret";
  };
  runtimeProfileActivation = builtins.toJSON runtimeProfileEval.config.home.activation.openclawCodexRuntimeProfiles;
  runtimeProfileCheck =
    builtins.deepSeq (requireNoAssertionFailures "runtime profile" runtimeProfileEval)
      (
        if lib.hasInfix "openclaw-link-codex-runtime-profiles.sh" runtimeProfileActivation then
          "ok"
        else
          throw "runtimePackages did not wire the Codex runtime profile activation."
      );

in
{
  inherit
    homeRelativeConfigCheck
    topLevelHomeRelativeConfigCheck
    spacedConfigEnvironmentCheck
    reloadDefaultCheck
    reloadNamedCheck
    reloadCustomDefaultCheck
    secretProviderCheck
    secretRefPassthroughCheck
    runtimeProfileCheck
    ;
}
