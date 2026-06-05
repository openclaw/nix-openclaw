{
  lib,
  pkgs,
  stdenv,
}:

let
  testLib = lib.extend (
    _final: _prev: {
      hm.dag = {
        entryAfter = after: data: {
          inherit after data;
          before = [ ];
        };
      };
    }
  );

  lockedPathFlake =
    name: path: narHash:
    let
      # If a fixture changes, update with: nix hash path --sri nix/tests/plugins/<name>
      storePath = builtins.path {
        inherit name path;
        sha256 = narHash;
      };
    in
    "path:${builtins.unsafeDiscardStringContext (toString storePath)}?narHash=${narHash}";

  alphaPluginSource =
    lockedPathFlake "openclaw-test-plugin-alpha" ../tests/plugins/alpha
      "sha256-FV4UN38sPy2Yp/HhqUxd0HW5l2PcIBBmUz4JzxTAOXY=";
  betaPluginSource =
    lockedPathFlake "openclaw-test-plugin-beta" ../tests/plugins/beta
      "sha256-lDKtQKHZHqOkOprjLZzBEu8cFJhAdyEzsays9hdVeqE=";
  runtimePluginRootSource =
    lockedPathFlake "openclaw-test-plugin-runtime" ../tests/plugins/runtime
      "sha256-S/N5zWbObP8YpB89B8WylYzWORbw5roz9kFApJAbUOU=";
  stubModule =
    { lib, ... }:
    {
      options = {
        assertions = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
        };

        home.homeDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/tmp";
        };

        home.packages = lib.mkOption {
          type = lib.types.listOf lib.types.anything;
          default = [ ];
        };

        home.file = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        home.activation = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        launchd.agents = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        systemd.user.services = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        programs.git.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        lib = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      };
    };

  moduleEval =
    openclawConfig:
    testLib.evalModules {
      modules = [
        stubModule
        ../modules/home-manager/openclaw.nix
        (
          { lib, ... }:
          {
            config = {
              home.homeDirectory = "/tmp";
              programs.git.enable = false;
              lib.file.mkOutOfStoreSymlink = path: path;
              programs.openclaw = {
                enable = true;
                launchd.enable = pkgs.stdenv.hostPlatform.isDarwin;
                systemd.enable = pkgs.stdenv.hostPlatform.isLinux;
              }
              // openclawConfig;
            };
          }
        )
      ];
      specialArgs = { inherit pkgs; };
    };

  failedAssertions =
    eval: lib.filter (assertion: !(assertion.assertion or false)) eval.config.assertions;

  requireNoAssertionFailures =
    name: eval:
    let
      failures = failedAssertions eval;
      messages = map (assertion: assertion.message or "(no message)") failures;
    in
    if failures == [ ] then "ok" else throw "${name}: ${lib.concatStringsSep "; " messages}";

  requireAssertionFailure =
    name: needle: eval:
    let
      failures = failedAssertions eval;
      matching = lib.filter (assertion: lib.hasInfix needle (assertion.message or "")) failures;
    in
    if matching != [ ] then "ok" else throw "${name}: expected assertion containing `${needle}`.";

  requireEvalFailure =
    name: value:
    let
      attempted = builtins.tryEval (builtins.deepSeq value "ok");
    in
    if attempted.success then throw "${name}: expected evaluation failure." else "ok";

  qmdPath =
    if pkgs.openclawPackages ? qmd then
      builtins.unsafeDiscardStringContext "${pkgs.openclawPackages.qmd}/bin"
    else
      null;
  packageHasQmd =
    pkg:
    let
      pathText = builtins.unsafeDiscardStringContext (
        (pkg.OPENCLAW_TOOLS_PATH or "") + ":" + (pkg.OPENCLAW_QMD_PATH or "")
      );
    in
    qmdPath != null && lib.hasInfix qmdPath pathText;

  defaultEval = moduleEval { };
  defaultConfig = builtins.fromJSON defaultEval.config.home.file.".openclaw/openclaw.json".text;
  hasLinuxUnit = builtins.hasAttr "openclaw-gateway" defaultEval.config.systemd.user.services;
  hasDarwinAgent = builtins.hasAttr "com.steipete.openclaw.gateway" defaultEval.config.launchd.agents;
  defaultCheck = builtins.deepSeq (requireNoAssertionFailures "default instance" defaultEval) (
    if pkgs.stdenv.hostPlatform.isLinux && !hasLinuxUnit then
      throw "Default OpenClaw instance missing systemd.unitName."
    else if pkgs.stdenv.hostPlatform.isDarwin && !hasDarwinAgent then
      throw "Default OpenClaw instance missing launchd.label."
    else if (((defaultConfig.gateway or { }).mode or null) != "local") then
      throw "Default OpenClaw instance missing gateway.mode."
    else if lib.any packageHasQmd defaultEval.config.home.packages then
      throw "Default OpenClaw instance unexpectedly includes QMD on its runtime PATH."
    else
      "ok"
  );

  customPluginEval = moduleEval {
    customPlugins = [
      { source = alphaPluginSource; }
    ];
  };
  customPluginConfig = builtins.fromJSON (
    builtins.unsafeDiscardStringContext customPluginEval.config.home.file.".openclaw/openclaw.json".text
  );
  customPluginSkillExtraDirs = ((customPluginConfig.skills or { }).load or { }).extraDirs or [ ];
  customPluginCheck = builtins.deepSeq (requireNoAssertionFailures "customPlugins" customPluginEval) (
    if !(lib.any (path: lib.hasSuffix "/skill" path) customPluginSkillExtraDirs) then
      throw "customPlugins did not wire plugin skills into skills.load.extraDirs."
    else
      "ok"
  );

  multiAgentPluginSkillEval = moduleEval {
    customPlugins = [
      { source = alphaPluginSource; }
    ];
    config.agents.list = [
      {
        id = "writer";
        workspace = "/tmp/openclaw-writer-workspace";
      }
      {
        id = "research";
        workspace = "/tmp/openclaw-research-workspace";
      }
    ];
  };
  multiAgentPluginSkillConfig = builtins.fromJSON (
    builtins.unsafeDiscardStringContext
      multiAgentPluginSkillEval.config.home.file.".openclaw/openclaw.json".text
  );
  multiAgentPluginSkillExtraDirs = (
    ((multiAgentPluginSkillConfig.skills or { }).load or { }).extraDirs or [ ]
  );
  multiAgentWorkspaces = map (agent: agent.workspace) (
    ((multiAgentPluginSkillConfig.agents or { }).list or [ ])
  );
  multiAgentPluginSkillCheck =
    builtins.deepSeq (requireNoAssertionFailures "multi-agent plugin skills" multiAgentPluginSkillEval)
      (
        if !(lib.elem "/tmp/openclaw-writer-workspace" multiAgentWorkspaces) then
          throw "Multi-agent config lost writer workspace."
        else if !(lib.elem "/tmp/openclaw-research-workspace" multiAgentWorkspaces) then
          throw "Multi-agent config lost research workspace."
        else if !(lib.any (path: lib.hasSuffix "/skill" path) multiAgentPluginSkillExtraDirs) then
          throw "Custom plugin skill was not shared through skills.load.extraDirs for separate agent workspaces."
        else
          "ok"
      );

  duplicateSkillEval = moduleEval {
    customPlugins = [
      { source = alphaPluginSource; }
      { source = betaPluginSource; }
    ];
  };
  duplicateSkillCheck =
    requireAssertionFailure "duplicate plugin skills"
      "Duplicate Nix-managed skill names detected: programs.openclaw.instances.default: skill"
      duplicateSkillEval;

  userPluginSkillCollisionEval = moduleEval {
    customPlugins = [
      { source = alphaPluginSource; }
    ];
    skills = [
      {
        name = "skill";
        mode = "inline";
      }
    ];
  };
  userPluginSkillCollisionCheck =
    requireAssertionFailure "user/plugin skill collision"
      "Duplicate Nix-managed skill names detected: programs.openclaw.instances.default: skill"
      userPluginSkillCollisionEval;

  userSkillEval = moduleEval {
    config.skills.load.extraDirs = [ "/tmp/user-skill-root" ];
    skills = [
      {
        name = "inline-skill";
        mode = "inline";
        description = "Inline test skill";
        body = "Use this test skill.";
      }
    ];
  };
  userSkillConfig = builtins.fromJSON (
    builtins.unsafeDiscardStringContext userSkillEval.config.home.file.".openclaw/openclaw.json".text
  );
  userSkillExtraDirs = ((userSkillConfig.skills or { }).load or { }).extraDirs or [ ];
  generatedUserSkillExtraDirs = lib.filter (path: path != "/tmp/user-skill-root") userSkillExtraDirs;
  userSkillCheck = builtins.deepSeq (requireNoAssertionFailures "user skills" userSkillEval) (
    if !(lib.elem "/tmp/user-skill-root" userSkillExtraDirs) then
      throw "User skills.load.extraDirs entry was not preserved."
    else if generatedUserSkillExtraDirs == [ ] then
      throw "Nix-managed raw skill was not added to skills.load.extraDirs."
    else if userSkillExtraDirs != generatedUserSkillExtraDirs ++ [ "/tmp/user-skill-root" ] then
      throw "User skills.load.extraDirs entries should remain after Nix-managed skill dirs."
    else
      "ok"
  );

  bootstrapFiles = {
    agents = ../tests/workspace/AGENTS.md;
    soul = ../tests/workspace/SOUL.md;
    tools = ../tests/workspace/TOOLS.md;
    identity = ../tests/workspace/IDENTITY.md;
    user = ../tests/workspace/USER.md;
    heartbeat = ../tests/workspace/HEARTBEAT.md;
  };

  workspaceBootstrapEval = moduleEval {
    workspace = {
      bootstrapFiles = bootstrapFiles;
      files."LORE.md" = ../tests/workspace/LORE.md;
    };
  };
  workspaceBootstrapConfig = builtins.fromJSON (
    builtins.unsafeDiscardStringContext
      workspaceBootstrapEval.config.home.file.".openclaw/openclaw.json".text
  );
  workspaceBootstrapCheck =
    builtins.deepSeq (requireNoAssertionFailures "workspace bootstrap files" workspaceBootstrapEval)
      (
        if (((workspaceBootstrapConfig.agents or { }).defaults or { }).skipBootstrap or false) != true then
          throw "workspace.bootstrapFiles did not force agents.defaults.skipBootstrap = true."
        else
          "ok"
      );

  documentsRemovedEval = moduleEval {
    documents = ../tests/workspace;
  };
  documentsRemovedCheck = builtins.deepSeq [
    (requireAssertionFailure "removed documents option" "programs.openclaw.documents was removed"
      documentsRemovedEval
    )
    (requireAssertionFailure "removed documents option extras" "LORE.md" documentsRemovedEval)
    (requireAssertionFailure "removed documents option prompting examples" "PROMPTING-EXAMPLES.md"
      documentsRemovedEval
    )
    (requireAssertionFailure "removed documents option heartbeat"
      "programs.openclaw.workspace.bootstrapFiles.heartbeat"
      documentsRemovedEval
    )
  ] "ok";

  bootstrapSeedConflictEval = moduleEval {
    workspace.bootstrapFiles = bootstrapFiles;
    config.agents.defaults.skipBootstrap = false;
  };
  bootstrapSeedConflictCheck =
    requireAssertionFailure "bootstrap seed conflict" "OpenClaw must not seed bootstrap files"
      bootstrapSeedConflictEval;

  workspaceFileCollisionEval = moduleEval {
    workspace = {
      bootstrapFiles = bootstrapFiles;
      files = {
        "AGENTS.md" = ../tests/workspace/LORE.md;
        "AGENTS.md/foo" = ../tests/workspace/LORE.md;
        "BOOTSTRAP.md/foo" = ../tests/workspace/LORE.md;
        "MEMORY.md/foo" = ../tests/workspace/LORE.md;
      };
    };
  };
  workspaceFileCollisionCheck =
    requireAssertionFailure "workspace file reserved collision"
      "workspace.files cannot manage reserved OpenClaw workspace paths"
      workspaceFileCollisionEval;

  workspaceRuntimeFileCollisionEval = moduleEval {
    workspace.files = {
      "memory" = ../tests/workspace/LORE.md;
      "memory/foo" = ../tests/workspace/LORE.md;
    };
  };
  workspaceRuntimeFileCollisionCheck =
    requireAssertionFailure "workspace file runtime collision"
      "workspace.files cannot manage reserved OpenClaw workspace paths"
      workspaceRuntimeFileCollisionEval;

  invalidWorkspaceFileEval = moduleEval {
    workspace.files = {
      "" = ../tests/workspace/LORE.md;
      "." = ../tests/workspace/LORE.md;
      "../outside.md" = ../tests/workspace/LORE.md;
      "nested/." = ../tests/workspace/LORE.md;
      "nested/./LORE.md" = ../tests/workspace/LORE.md;
      "nested/.." = ../tests/workspace/LORE.md;
      "nested//LORE.md" = ../tests/workspace/LORE.md;
      "nested/" = ../tests/workspace/LORE.md;
    };
  };
  invalidWorkspaceFileCheck =
    requireAssertionFailure "invalid workspace file path"
      "workspace.files keys must be relative paths below the workspace without empty, '.', or '..' path segments"
      invalidWorkspaceFileEval;

  secretProviderEval = moduleEval {
    config.secrets.providers.test-file = {
      source = "file";
      path = "/tmp/openclaw-secrets.json";
      mode = "json";
    };
  };
  secretProviderConfig =
    builtins.fromJSON
      secretProviderEval.config.home.file.".openclaw/openclaw.json".text;
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
  secretRefPassthroughConfig =
    builtins.fromJSON
      secretRefPassthroughEval.config.home.file.".openclaw/openclaw.json".text;
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

  qmdPrewarmEval = moduleEval {
    qmd.prewarmModels.enable = true;
  };
  qmdPrewarmActivation = builtins.toJSON qmdPrewarmEval.config.home.activation.openclawQmdPrewarm;
  qmdPrewarmCheck = builtins.deepSeq (requireNoAssertionFailures "qmd.prewarmModels" qmdPrewarmEval) (
    if
      lib.hasInfix "OPENCLAW_QMD_BIN=" qmdPrewarmActivation
      && lib.hasInfix "openclaw-qmd-prewarm.sh" qmdPrewarmActivation
    then
      "ok"
    else
      throw "qmd.prewarmModels did not wire QMD model-cache prewarm activation."
  );

  qmdMemoryEval = moduleEval {
    config.memory.backend = "qmd";
  };
  qmdMemoryCheck = builtins.deepSeq (requireNoAssertionFailures "memory.backend qmd" qmdMemoryEval) (
    if lib.any packageHasQmd qmdMemoryEval.config.home.packages then
      "ok"
    else
      throw "memory.backend = qmd did not add QMD to the internal OpenClaw runtime."
  );
  qmdMemoryPackages = lib.filter packageHasQmd qmdMemoryEval.config.home.packages;
  qmdMemoryPackage = if qmdMemoryPackages == [ ] then null else builtins.head qmdMemoryPackages;

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

  customRuntimePluginRootEval = moduleEval {
    customPlugins = [
      { source = runtimePluginRootSource; }
    ];
  };
  customRuntimePluginRootCheck =
    requireEvalFailure "customPlugins rejects OpenClaw runtime plugin roots"
      customRuntimePluginRootEval.config.home.file;

  runtimePluginEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.allow = [ "memory-core" ];
  };
  runtimePluginConfig = builtins.fromJSON (
    builtins.unsafeDiscardStringContext
      runtimePluginEval.config.home.file.".openclaw/openclaw.json".text
  );
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
  runtimePluginCatalogGeneratedConfig = builtins.fromJSON (
    builtins.unsafeDiscardStringContext
      runtimePluginCatalogGeneratedEval.config.home.file.".openclaw/openclaw.json".text
  );
  runtimePluginCatalogGeneratedLoadPaths =
    ((runtimePluginCatalogGeneratedConfig.plugins or { }).load or { }).paths or [ ];
  runtimePluginCatalogGeneratedEntries =
    ((runtimePluginCatalogGeneratedConfig.plugins or { }).entries or { });
  runtimePluginCatalogGeneratedCheck =
    builtins.deepSeq (requireNoAssertionFailures "runtimePlugins generated catalog ids" runtimePluginCatalogGeneratedEval)
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
  runtimePluginInstanceOneConfig = builtins.fromJSON (
    builtins.unsafeDiscardStringContext
      runtimePluginInstanceEval.config.home.file.".openclaw-one/openclaw.json".text
  );
  runtimePluginInstanceTwoConfig = builtins.fromJSON (
    builtins.unsafeDiscardStringContext
      runtimePluginInstanceEval.config.home.file.".openclaw-two/openclaw.json".text
  );
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
    requireAssertionFailure "duplicate runtimePlugins" "runtimePlugins contains duplicate ids: slack"
      runtimePluginDuplicateEval;

  runtimePluginUnsupportedEval = moduleEval {
    runtimePlugins = [ "codex" ];
  };
  runtimePluginUnsupportedCheck =
    requireAssertionFailure "unsupported runtimePlugins"
      "Maintainers can inspect skipped-catalog diagnostics in nix/generated/openclaw-runtime-plugins/report.json"
      runtimePluginUnsupportedEval;

  runtimePluginRawLoadPathEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.load.paths = [ "/tmp/user-openclaw-runtime-plugin" ];
  };
  runtimePluginRawLoadPathCheck =
    requireAssertionFailure "runtimePlugins raw load path"
      "runtimePlugins cannot be mixed with raw programs.openclaw.config.plugins.load.paths"
      runtimePluginRawLoadPathEval;

  runtimePluginInstallRecordEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.installs.slack = {
      source = "npm";
      spec = "@openclaw/slack";
      installPath = "/tmp/mutable-openclaw-slack";
    };
  };
  runtimePluginInstallRecordCheck =
    requireEvalFailure "runtimePlugins install records are schema-rejected"
      runtimePluginInstallRecordEval.config.assertions;

  runtimePluginDisabledEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.entries.slack.enabled = false;
  };
  runtimePluginDisabledCheck =
    requireAssertionFailure "runtimePlugins disabled entry"
      "runtimePlugins selected ids disabled in config.plugins.entries: slack"
      runtimePluginDisabledEval;

  runtimePluginDeniedEval = moduleEval {
    runtimePlugins = [ "slack" ];
    config.plugins.deny = [ "slack" ];
  };
  runtimePluginDeniedCheck =
    requireAssertionFailure "runtimePlugins denied entry"
      "runtimePlugins selected ids denied in config.plugins.deny: slack"
      runtimePluginDeniedEval;

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

  checkKey = builtins.deepSeq [
    defaultCheck
    customPluginCheck
    multiAgentPluginSkillCheck
    duplicateSkillCheck
    userPluginSkillCollisionCheck
    userSkillCheck
    workspaceBootstrapCheck
    documentsRemovedCheck
    bootstrapSeedConflictCheck
    workspaceFileCollisionCheck
    workspaceRuntimeFileCollisionCheck
    invalidWorkspaceFileCheck
    secretProviderCheck
    secretRefPassthroughCheck
    qmdPrewarmCheck
    qmdMemoryCheck
    runtimeProfileCheck
    customRuntimePluginRootCheck
    runtimePluginCheck
    runtimePluginCatalogGeneratedCheck
    runtimePluginInstanceCheck
    runtimePluginDuplicateCheck
    runtimePluginUnsupportedCheck
    runtimePluginRawLoadPathCheck
    runtimePluginInstallRecordCheck
    runtimePluginDisabledCheck
    runtimePluginDeniedCheck
    npmRuntimePluginCheck
  ] "ok";

in
stdenv.mkDerivation {
  pname = "openclaw-default-instance";
  version = "1";
  dontUnpack = true;
  # Evaluation alone missed installPhase regressions in the QMD wrapper.
  nativeBuildInputs = lib.optional (qmdMemoryPackage != null) qmdMemoryPackage;
  env = {
    OPENCLAW_DEFAULT_INSTANCE = checkKey;
  };
  installPhase = "${../scripts/empty-install.sh}";
}
