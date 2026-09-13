{ lib, pkgs, helpers }:

let
  inherit (helpers) runtimePluginRootSource moduleEval requireNoAssertionFailures requireAssertionFailure requireEvalFailure generatedConfig;

  customRuntimePluginRootEval = moduleEval {
    customPlugins = [
      { source = runtimePluginRootSource; }
    ];
  };
  customRuntimePluginRootCheck = requireEvalFailure "customPlugins rejects OpenClaw runtime plugin roots" customRuntimePluginRootEval.config.home.file;

  runtimePluginEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.allow = [ "memory-core" ];
  };
  runtimePluginConfig = generatedConfig runtimePluginEval ".openclaw/openclaw.json";
  runtimePluginLoadPaths = ((runtimePluginConfig.plugins or { }).load or { }).paths or [ ];
  runtimePluginEntry = ((runtimePluginConfig.plugins or { }).entries or { }).slack or { };
  runtimePluginAllow = ((runtimePluginConfig.plugins or { }).allow or [ ]);
  runtimePluginLaunchdEnv =
    if pkgs.stdenv.hostPlatform.isDarwin then
      runtimePluginEval.config.launchd.agents."com.steipete.openclaw.gateway".config.EnvironmentVariables
    else
      { };
  runtimePluginSystemdEnv =
    if pkgs.stdenv.hostPlatform.isLinux then
      runtimePluginEval.config.systemd.user.services.openclaw-gateway.Service.Environment
    else
      [ ];
  runtimePluginCheck =
    builtins.deepSeq (requireNoAssertionFailures "runtimePlugins" runtimePluginEval)
      (
        if !(lib.any (path: lib.hasInfix "openclaw-runtime-plugin-slack" path) runtimePluginLoadPaths) then
          throw "runtimePlugins did not add Slack to plugins.load.paths."
        else if (runtimePluginEntry.enabled or false) != true then
          throw "runtimePlugins did not enable the Slack plugin entry."
        else if
          runtimePluginAllow != [
            "memory-core"
            "slack"
          ]
        then
          throw "runtimePlugins did not merge Slack into an existing plugins.allow list."
        else if ((runtimePluginConfig.plugins or { }) ? installs) then
          throw "runtimePlugins wrote plugins.installs into generated config."
        else if
          pkgs.stdenv.hostPlatform.isDarwin
          && ((runtimePluginLaunchdEnv.OPENCLAW_DISABLE_PERSISTED_PLUGIN_REGISTRY or null) != "1")
        then
          throw "runtimePlugins did not disable persisted plugin registry reads for launchd."
        else if
          pkgs.stdenv.hostPlatform.isLinux
          && !(lib.elem "OPENCLAW_DISABLE_PERSISTED_PLUGIN_REGISTRY=1" runtimePluginSystemdEnv)
        then
          throw "runtimePlugins did not disable persisted plugin registry reads for systemd."
        else
          "ok"
      );

  runtimePluginCatalogGeneratedEval = moduleEval {
    runtimePlugins = [
      "amazon-bedrock"
      "discord"
    ];
  };
  runtimePluginCatalogGeneratedConfig = generatedConfig runtimePluginCatalogGeneratedEval ".openclaw/openclaw.json";
  runtimePluginCatalogGeneratedLoadPaths =
    ((runtimePluginCatalogGeneratedConfig.plugins or { }).load or { }).paths or [ ];
  runtimePluginCatalogGeneratedEntries = (
    (runtimePluginCatalogGeneratedConfig.plugins or { }).entries or { }
  );
  runtimePluginCatalogGeneratedCheck =
    builtins.deepSeq
      (requireNoAssertionFailures "runtimePlugins generated catalog ids" runtimePluginCatalogGeneratedEval)
      (
        if
          !(lib.any (
            path: lib.hasInfix "openclaw-runtime-plugin-amazon-bedrock" path
          ) runtimePluginCatalogGeneratedLoadPaths)
        then
          throw "runtimePlugins did not accept generated provider plugin ids."
        else if
          !(lib.any (
            path: lib.hasInfix "openclaw-runtime-plugin-discord" path
          ) runtimePluginCatalogGeneratedLoadPaths)
        then
          throw "runtimePlugins did not accept generated channel plugin ids."
        else if ((runtimePluginCatalogGeneratedEntries.amazon-bedrock or { }).enabled or false) != true then
          throw "runtimePlugins did not enable generated provider plugin entry."
        else if ((runtimePluginCatalogGeneratedEntries.discord or { }).enabled or false) != true then
          throw "runtimePlugins did not enable generated channel plugin entry."
        else
          "ok"
      );

  runtimePluginInstanceEval = moduleEval {
    runtimePlugins = [ "slack" ];
    instances.one.runtimePlugins = [ ];
    instances.two.runtimePlugins = [
      "discord"
      "diagnostics-prometheus"
    ];
  };
  runtimePluginInstanceOneConfig = generatedConfig runtimePluginInstanceEval ".openclaw-one/openclaw.json";
  runtimePluginInstanceTwoConfig = generatedConfig runtimePluginInstanceEval ".openclaw-two/openclaw.json";
  runtimePluginInstanceOneLoadPaths =
    ((runtimePluginInstanceOneConfig.plugins or { }).load or { }).paths or [ ];
  runtimePluginInstanceTwoLoadPaths =
    ((runtimePluginInstanceTwoConfig.plugins or { }).load or { }).paths or [ ];
  runtimePluginInstanceCheck =
    builtins.deepSeq (requireNoAssertionFailures "runtimePlugins instances" runtimePluginInstanceEval)
      (
        if runtimePluginInstanceOneLoadPaths != [ ] then
          throw "Instance runtimePlugins = [] did not override top-level runtimePlugins."
        else if
          !(lib.any (
            path: lib.hasInfix "openclaw-runtime-plugin-discord" path
          ) runtimePluginInstanceTwoLoadPaths)
        then
          throw "Instance runtimePlugins did not render its selected plugin."
        else if
          !(lib.any (
            path: lib.hasInfix "openclaw-runtime-plugin-diagnostics-prometheus" path
          ) runtimePluginInstanceTwoLoadPaths)
        then
          throw "Instance runtimePlugins did not support hyphenated plugin ids."
        else
          "ok"
      );

  runtimePluginDuplicateEval = moduleEval {
    runtimePlugins = [
      "slack"
      "slack"
    ];
  };
  runtimePluginDuplicateCheck =
    requireAssertionFailure "duplicate runtimePlugins"
      "runtimePlugins/runtimePluginSources contains duplicate ids: slack"
      runtimePluginDuplicateEval;

  runtimePluginUnsupportedEval = moduleEval {
    runtimePlugins = [ "not-a-real-openclaw-plugin" ];
  };
  runtimePluginUnsupportedCheck =
    requireAssertionFailure "unsupported runtimePlugins"
      "Maintainers can inspect unsupported-plugin diagnostics in nix/generated/openclaw-runtime-plugins/report.json"
      runtimePluginUnsupportedEval;

  runtimePluginRawLoadPathEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.load.paths = [ "/tmp/user-openclaw-runtime-plugin" ];
  };
  runtimePluginRawLoadPathCheck =
    requireAssertionFailure "runtimePlugins raw load path"
      "runtimePlugins/runtimePluginSources cannot be mixed with raw programs.openclaw.config.plugins.load.paths"
      runtimePluginRawLoadPathEval;

  runtimePluginInstallRecordEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.installs.slack = {
      source = "npm";
      spec = "@openclaw/slack";
      installPath = "/tmp/mutable-openclaw-slack";
    };
  };
  runtimePluginInstallRecordCheck = requireEvalFailure "runtimePlugins install records are schema-rejected" runtimePluginInstallRecordEval.config.assertions;

  runtimePluginDisabledEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.entries.slack.enabled = false;
  };
  runtimePluginDisabledCheck =
    requireAssertionFailure "runtimePlugins disabled entry"
      "runtimePlugins/runtimePluginSources selected ids disabled in config.plugins.entries: slack"
      runtimePluginDisabledEval;

  runtimePluginDeniedEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.deny = [ "slack" ];
  };
  runtimePluginDeniedCheck =
    requireAssertionFailure "runtimePlugins denied entry"
      "runtimePlugins/runtimePluginSources selected ids denied in config.plugins.deny: slack"
      runtimePluginDeniedEval;

  runtimePluginSourceEval = moduleEval {
    runtimePluginSources = [
      {
        id = "diagnostics-prometheus";
        spec = "npm:@openclaw/diagnostics-prometheus@2026.6.1";
        hash = "sha256-nXDuWe72bgnuinoZFZDPwKowYml/5lturHD+sKti4AA=";
      }
    ];
    config.plugins.allow = [ "memory-core" ];
  };
  runtimePluginSourceConfig = generatedConfig runtimePluginSourceEval ".openclaw/openclaw.json";
  runtimePluginSourceLoadPaths =
    ((runtimePluginSourceConfig.plugins or { }).load or { }).paths or [ ];
  runtimePluginSourceEntry =
    ((runtimePluginSourceConfig.plugins or { }).entries or { }).diagnostics-prometheus or { };
  runtimePluginSourceAllow = ((runtimePluginSourceConfig.plugins or { }).allow or [ ]);
  runtimePluginSourceCheck =
    builtins.deepSeq
      (requireNoAssertionFailures "runtimePluginSources npm source" runtimePluginSourceEval)
      (
        if
          !(lib.any (
            path: lib.hasInfix "openclaw-runtime-plugin-diagnostics-prometheus" path
          ) runtimePluginSourceLoadPaths)
        then
          throw "runtimePluginSources did not add the npm source plugin to plugins.load.paths."
        else if (runtimePluginSourceEntry.enabled or false) != true then
          throw "runtimePluginSources did not enable the source plugin entry."
        else if
          runtimePluginSourceAllow != [
            "memory-core"
            "diagnostics-prometheus"
          ]
        then
          throw "runtimePluginSources did not merge source plugin id into an existing plugins.allow list."
        else
          "ok"
      );

  runtimePluginSourceDuplicateEval = moduleEval {
    runtimePlugins = [ "diagnostics-prometheus" ];
    runtimePluginSources = [
      {
        id = "diagnostics-prometheus";
        spec = "npm:@openclaw/diagnostics-prometheus@2026.6.1";
      }
    ];
  };
  runtimePluginSourceDuplicateCheck =
    requireAssertionFailure "duplicate runtimePluginSources"
      "runtimePlugins/runtimePluginSources contains duplicate ids: diagnostics-prometheus"
      runtimePluginSourceDuplicateEval;

  runtimePluginSourceAmbiguousEval = moduleEval {
    runtimePluginSources = [
      {
        id = "bad-source";
      }
    ];
  };
  runtimePluginSourceAmbiguousCheck =
    requireAssertionFailure "runtimePluginSources ambiguous source"
      "runtimePluginSources entries must set exactly one of spec or url"
      runtimePluginSourceAmbiguousEval;

  runtimePluginSourceInvalidSpecEval = moduleEval {
    runtimePluginSources = [
      {
        id = "bad-source";
        spec = "git:github.com/acme/openclaw-plugin@v1.0.0";
      }
    ];
  };
  runtimePluginSourceInvalidSpecCheck =
    requireAssertionFailure "runtimePluginSources invalid spec"
      "runtimePluginSources spec must start with npm: or clawhub:"
      runtimePluginSourceInvalidSpecEval;

  runtimePluginSourceInvalidUrlEval = moduleEval {
    runtimePluginSources = [
      {
        id = "bad-url";
        url = "http://example.invalid/plugin.tgz";
      }
    ];
  };
  runtimePluginSourceInvalidUrlCheck =
    requireAssertionFailure "runtimePluginSources invalid url"
      "runtimePluginSources url must start with https://: bad-url"
      runtimePluginSourceInvalidUrlEval;

  runtimePluginSourceRawLoadPathEval = moduleEval {
    runtimePluginSources = [
      {
        id = "diagnostics-prometheus";
        spec = "npm:@openclaw/diagnostics-prometheus@2026.6.1";
      }
    ];
    config.plugins.load.paths = [ "/tmp/user-openclaw-runtime-plugin" ];
  };
  runtimePluginSourceRawLoadPathCheck =
    requireAssertionFailure "runtimePluginSources raw load path"
      "runtimePlugins/runtimePluginSources cannot be mixed with raw programs.openclaw.config.plugins.load.paths"
      runtimePluginSourceRawLoadPathEval;

  npmRuntimePluginEval = moduleEval {
    customPlugins = [
      {
        source = "npm:@tencent-weixin/openclaw-weixin@2.4.2";
        id = "openclaw-weixin";
        hash = lib.fakeHash;
      }
    ];
  };
  npmRuntimePluginCheck = requireEvalFailure "npm customPlugins bridge" (
    npmRuntimePluginEval.config.home.file.".openclaw/openclaw.json".text
  );

in
{
  inherit customRuntimePluginRootCheck runtimePluginCheck runtimePluginCatalogGeneratedCheck runtimePluginInstanceCheck runtimePluginDuplicateCheck runtimePluginUnsupportedCheck runtimePluginRawLoadPathCheck runtimePluginInstallRecordCheck runtimePluginDisabledCheck runtimePluginDeniedCheck runtimePluginSourceCheck runtimePluginSourceDuplicateCheck runtimePluginSourceAmbiguousCheck runtimePluginSourceInvalidSpecCheck runtimePluginSourceInvalidUrlCheck runtimePluginSourceRawLoadPathCheck npmRuntimePluginCheck;
}
