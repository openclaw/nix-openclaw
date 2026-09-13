{
  lib,
  pkgs,
  helpers,
}:

let
  inherit (helpers)
    alphaPluginSource
    betaPluginSource
    moduleEval
    requireNoAssertionFailures
    requireAssertionFailure
    generatedConfig
    isPluginSkillPath
    explicitOwnership
    usesAgentEntries
    ;

  customPluginEval = moduleEval {
    customPlugins = [
      { source = alphaPluginSource; }
    ];
  };
  customPluginConfig = generatedConfig customPluginEval ".openclaw/openclaw.json";
  customPluginSkillExtraDirs = ((customPluginConfig.skills or { }).load or { }).extraDirs or [ ];
  customPluginCheck = builtins.deepSeq (requireNoAssertionFailures "customPlugins" customPluginEval) (
    if !(lib.any isPluginSkillPath customPluginSkillExtraDirs) then
      throw "customPlugins did not wire plugin skills into skills.load.extraDirs."
    else
      "ok"
  );

  multiAgentPluginSkillEval = moduleEval {
    customPlugins = [
      { source = alphaPluginSource; }
    ];
    config.agents =
      if usesAgentEntries then
        explicitOwnership
        // {
          entries = {
            writer.workspace = "/tmp/openclaw-writer-workspace";
            research.workspace = "/tmp/openclaw-research-workspace";
          };
        }
      else
        {
          list = [
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
  };
  multiAgentPluginSkillConfig = generatedConfig multiAgentPluginSkillEval ".openclaw/openclaw.json";
  multiAgentPluginSkillExtraDirs = (
    ((multiAgentPluginSkillConfig.skills or { }).load or { }).extraDirs or [ ]
  );
  multiAgentWorkspaces = map (agent: agent.workspace) (
    if usesAgentEntries then
      lib.attrValues multiAgentPluginSkillConfig.agents.entries
    else
      multiAgentPluginSkillConfig.agents.list
  );
  multiAgentPluginSkillCheck =
    builtins.deepSeq (requireNoAssertionFailures "multi-agent plugin skills" multiAgentPluginSkillEval)
      (
        if !(lib.elem "/tmp/openclaw-writer-workspace" multiAgentWorkspaces) then
          throw "Multi-agent config lost writer workspace."
        else if !(lib.elem "/tmp/openclaw-research-workspace" multiAgentWorkspaces) then
          throw "Multi-agent config lost research workspace."
        else if !(lib.any isPluginSkillPath multiAgentPluginSkillExtraDirs) then
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
  userSkillConfig = generatedConfig userSkillEval ".openclaw/openclaw.json";
  userSkillExtraDirs = ((userSkillConfig.skills or { }).load or { }).extraDirs or [ ];
  generatedUserSkillExtraDirs = lib.filter (path: path != "/tmp/user-skill-root") userSkillExtraDirs;
  userSkillCheck = builtins.deepSeq (requireNoAssertionFailures "user skills" userSkillEval) (
    if !(lib.elem "/tmp/user-skill-root" userSkillExtraDirs) then
      throw "User skills.load.extraDirs entry was not preserved."
    else if
      !(lib.elem "/tmp/.local/share/nix-openclaw/skills/default/inline-skill" generatedUserSkillExtraDirs)
    then
      throw "Nix-managed raw skill did not use its per-instance runtime copy."
    else if
      !(lib.all (lib.hasPrefix "/tmp/.local/share/nix-openclaw/skills/default/") generatedUserSkillExtraDirs)
    then
      throw "A default plugin skill escaped the instance runtime root."
    else if userSkillExtraDirs != generatedUserSkillExtraDirs ++ [ "/tmp/user-skill-root" ] then
      throw "User skills.load.extraDirs entries should remain after Nix-managed skill dirs."
    else
      "ok"
  );

  namedSkillEval = moduleEval {
    skills = [
      {
        name = "inline-skill";
        mode = "inline";
      }
    ];
    instances = {
      prod = {
        enable = true;
        appDefaults.enable = false;
      };
      test = {
        enable = true;
        appDefaults.enable = false;
      };
    };
  };
  namedSkillConfigs = map (name: generatedConfig namedSkillEval ".openclaw-${name}/openclaw.json") [
    "prod"
    "test"
  ];
  namedSkillCheck =
    builtins.deepSeq (requireNoAssertionFailures "named instance skills" namedSkillEval)
      (
        if
          map (
            value: lib.filter (lib.hasSuffix "/inline-skill") value.skills.load.extraDirs
          ) namedSkillConfigs != [
            [ "/tmp/.local/share/nix-openclaw/skills/prod/inline-skill" ]
            [ "/tmp/.local/share/nix-openclaw/skills/test/inline-skill" ]
          ]
        then
          throw "Named instances did not isolate their runtime skill copies."
        else
          "ok"
      );

  caseSkillEval = moduleEval {
    skills =
      map
        (name: {
          inherit name;
          mode = "inline";
        })
        [
          "Case"
          "case"
        ];
  };
  caseSkillConfig = generatedConfig caseSkillEval ".openclaw/openclaw.json";
  caseSkillCheck =
    if
      lib.length (lib.unique (map lib.toLower caseSkillConfig.skills.load.extraDirs))
      != lib.length caseSkillConfig.skills.load.extraDirs
    then
      throw "Case-distinct skills collide on case-insensitive home filesystems."
    else
      "ok";

  bootstrapFiles = {
    agents = ../../tests/workspace/AGENTS.md;
    soul = ../../tests/workspace/SOUL.md;
    tools = ../../tests/workspace/TOOLS.md;
    identity = ../../tests/workspace/IDENTITY.md;
    user = ../../tests/workspace/USER.md;
    heartbeat = ../../tests/workspace/HEARTBEAT.md;
  };

  workspaceBootstrapEval = moduleEval {
    workspace = {
      bootstrapFiles = bootstrapFiles;
      files."LORE.md" = ../../tests/workspace/LORE.md;
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
    documents = ../../tests/workspace;
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
        "AGENTS.md" = ../../tests/workspace/LORE.md;
        "AGENTS.md/foo" = ../../tests/workspace/LORE.md;
        "BOOTSTRAP.md/foo" = ../../tests/workspace/LORE.md;
        "MEMORY.md/foo" = ../../tests/workspace/LORE.md;
      };
    };
  };
  workspaceFileCollisionCheck =
    requireAssertionFailure "workspace file reserved collision"
      "workspace.files cannot manage reserved OpenClaw workspace paths"
      workspaceFileCollisionEval;

  workspaceRuntimeFileCollisionEval = moduleEval {
    workspace.files = {
      "memory" = ../../tests/workspace/LORE.md;
      "memory/foo" = ../../tests/workspace/LORE.md;
    };
  };
  workspaceRuntimeFileCollisionCheck =
    requireAssertionFailure "workspace file runtime collision"
      "workspace.files cannot manage reserved OpenClaw workspace paths"
      workspaceRuntimeFileCollisionEval;

  invalidWorkspaceFileEval = moduleEval {
    workspace.files = {
      "" = ../../tests/workspace/LORE.md;
      "." = ../../tests/workspace/LORE.md;
      "../outside.md" = ../../tests/workspace/LORE.md;
      "nested/." = ../../tests/workspace/LORE.md;
      "nested/./LORE.md" = ../../tests/workspace/LORE.md;
      "nested/.." = ../../tests/workspace/LORE.md;
      "nested//LORE.md" = ../../tests/workspace/LORE.md;
      "nested/" = ../../tests/workspace/LORE.md;
    };
  };
  invalidWorkspaceFileCheck =
    requireAssertionFailure "invalid workspace file path"
      "workspace.files keys must be relative paths below the workspace without empty, '.', or '..' path segments"
      invalidWorkspaceFileEval;

in
{
  inherit
    customPluginCheck
    multiAgentPluginSkillCheck
    duplicateSkillCheck
    userPluginSkillCollisionCheck
    userSkillCheck
    namedSkillConfigs
    namedSkillCheck
    caseSkillCheck
    workspaceBootstrapConfig
    workspaceBootstrapCheck
    documentsRemovedCheck
    bootstrapSeedConflictCheck
    workspaceFileCollisionCheck
    workspaceRuntimeFileCollisionCheck
    invalidWorkspaceFileCheck
    ;
}
