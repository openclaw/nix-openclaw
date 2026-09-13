{ lib, pkgs, helpers }:

let
  inherit (helpers) moduleEval requireNoAssertionFailures requireEvalFailure generatedConfig packageHasQmd defaultEval openclawLib explicitOwnership defaultConfig usesAgentEntries;

  hasLinuxUnit = builtins.hasAttr "openclaw-gateway" defaultEval.config.systemd.user.services;
  hasDarwinAgent = builtins.hasAttr "com.steipete.openclaw.gateway" defaultEval.config.launchd.agents;
  defaultCheck = builtins.deepSeq [
    (requireNoAssertionFailures "default instance" defaultEval)
    defaultEval.config.home.activation
  ] (
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

  implicitRosterCheck =
    name: value:
    if usesAgentEntries then
      if value.agents.entries != { main = { }; } || value.agents ? ownership then
        throw "${name}: implicit roster must contain only main without an ownership marker."
      else
        "ok"
    else if (value.agents or { }) ? entries then
      throw "${name}: old schema must not emit keyed entries."
    else
      "ok";

  unpinnedConfig = generatedConfig (moduleEval {
    workspace.pinAgentDefaults = false;
  }) ".openclaw/openclaw.json";
  unpinnedRosterCheck =
    if usesAgentEntries then
      if unpinnedConfig.agents != { entries.main = { }; } then
        throw "Unpinned implicit roster must not inject agents.defaults.workspace."
      else
        "ok"
    else if unpinnedConfig ? agents then
      throw "Old unpinned config must keep agents absent."
    else
      "ok";

  emptyRosterChecks = lib.optionals usesAgentEntries (map (
    pinAgentDefaults:
    let
      rendered = generatedConfig (moduleEval {
        workspace = { inherit pinAgentDefaults; };
        config.agents.entries = { };
      }) ".openclaw/openclaw.json";
      expected = { entries.main = { }; } // lib.optionalAttrs pinAgentDefaults {
        defaults.workspace = "/tmp/.openclaw/workspace";
      };
    in
    if rendered.agents != expected then
      throw "Empty non-explicit roster must emit main while preserving workspace pinning."
    else
      "ok"
  ) [ true false ]);

  explicitWorkspaceConfig = generatedConfig (moduleEval {
    config.agents.defaults.workspace = "/tmp/authored-workspace";
  }) ".openclaw/openclaw.json";
  explicitWorkspaceCheck =
    if explicitWorkspaceConfig.agents != ({
      defaults.workspace = "/tmp/authored-workspace";
    } // lib.optionalAttrs usesAgentEntries { entries.main = { }; }) then
      throw "Canonical roster emission must preserve an authored default workspace."
    else
      "ok";

  authoredRosterCases = [
    { entries.writer = { }; }
    { entries.Writer = { }; }
    { entries."_worker-1" = { }; }
    { entries."${lib.concatStrings (lib.replicate 64 "a")}" = { }; }
    { ownership = "explicit"; entries = { }; }
    { ownership = "explicit"; }
    { entries = { writer = { }; research = { }; }; }
    (explicitOwnership // { entries = { writer = { }; research = { }; }; })
  ];
  authoredRosterChecks = lib.optionals usesAgentEntries (map (
    agents:
    let
      evaluated = moduleEval {
        workspace.pinAgentDefaults = false;
        config = { inherit agents; };
      };
      rendered = generatedConfig evaluated ".openclaw/openclaw.json";
    in
    builtins.deepSeq evaluated.config.home.activation (
      if rendered.agents != agents then
        throw "Authored roster or ownership was rewritten instead of preserved for upstream validation."
      else
        "ok"
    )
  ) authoredRosterCases);

  # Upstream trims trailing hyphens on its underscore-prefixed fallback,
  # while alphanumeric IDs retain them through the valid-ID fast path.
  canonicalAgentIdCases = [
    { entries."_worker--" = { }; expected = [ "_worker" ]; }
    { entries."_worker-" = { }; expected = [ "_worker" ]; }
    { entries."_Worker--" = { }; expected = [ "_worker" ]; }
    { entries."_worker-1" = { }; expected = [ "_worker-1" ]; }
    { entries."_worker-_" = { }; expected = [ "_worker-_" ]; }
    { entries."_" = { }; expected = [ "_" ]; }
    { entries."__" = { }; expected = [ "__" ]; }
    { entries."_--" = { }; expected = [ "_" ]; }
    { entries."_-" = { }; expected = [ "_" ]; }
    { entries."__--" = { }; expected = [ "__" ]; }
    { entries."_A-B--" = { }; expected = [ "_a-b" ]; }
    { entries = { worker = { }; "worker-" = { }; }; expected = [ "worker" "worker-" ]; }
    { entries."_${lib.concatStrings (lib.replicate 63 "-")}" = { }; expected = [ "_" ]; }
    { entries.Writer = { }; expected = [ "writer" ]; }
    { entries."0--" = { }; expected = [ "0--" ]; }
    { entries = { a = { }; "a--" = { }; }; expected = [ "a" "a--" ]; }
  ];
  canonicalAgentIdChecks = lib.optionals usesAgentEntries (map (
    { entries, expected }:
    let
      agents = explicitOwnership // { inherit entries; };
      rendered = generatedConfig (moduleEval {
        workspace.pinAgentDefaults = false;
        config = { inherit agents; };
      }) ".openclaw/openclaw.json";
      actual = openclawLib.agentIds rendered;
    in
    if rendered.agents != agents then
      throw "Canonical agent ID fixtures must preserve authored entries and ownership."
    else if actual != expected then
      throw "canonical-keyed-agent-ids ${builtins.toJSON (lib.attrNames entries)}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}."
    else
      "ok"
  ) canonicalAgentIdCases);

  invalidRosterChecks = lib.optionals usesAgentEntries (
    map (
      key:
      requireEvalFailure "unsafe agent key" (moduleEval {
        config.agents.entries."${key}" = { };
      }).config.home.activation
    ) [
      ""
      "../outside"
      "nested/agent"
      "-writer"
      "writer.name"
      "writer name"
      "writer\nname"
      (lib.concatStrings (lib.replicate 65 "a"))
    ]
    ++ map (
      keys:
      requireEvalFailure "normalized agent collision ${builtins.toJSON keys}" (moduleEval {
        config.agents = explicitOwnership // { entries = lib.genAttrs keys (_: { }); };
      }).config.home.activation
    ) [
      [ "Writer" "writer" ]
      [ "_worker-" "_worker" ]
      [ "_worker--" "_worker" ]
      [ "_Worker--" "_worker-" ]
      [ "_" "_--" ]
    ]
    ++ [
      (requireEvalFailure "malformed roster value" (generatedConfig (moduleEval {
        config.agents.entries.writer.workspace = 7;
      }) ".openclaw/openclaw.json"))
    ]
  );

  mergedRosterEval = moduleEval {
    config.agents = if usesAgentEntries then {
      entries.writer.workspace = "/tmp/original-writer";
    } else {
      list = [ { id = "writer"; workspace = "/tmp/original-writer"; } ];
    };
    instances.prod = {
      appDefaults.enable = false;
      config.agents = if usesAgentEntries then explicitOwnership // {
        entries = {
          writer.workspace = "/tmp/overridden-writer";
          research = { };
        };
      } else {
        list = [
          { id = "research"; }
          { id = "writer"; workspace = "/tmp/overridden-writer"; }
        ];
      };
    };
  };
  mergedRosterConfig = generatedConfig mergedRosterEval ".openclaw-prod/openclaw.json";
  mergedRosterCheck =
    if mergedRosterConfig.agents != ({
      defaults.workspace = "/tmp/.openclaw-prod/workspace";
    } // (if usesAgentEntries then explicitOwnership // {
      entries = {
        writer.workspace = "/tmp/overridden-writer";
        research = { };
      };
    } else {
      list = [
        { id = "research"; }
        { id = "writer"; workspace = "/tmp/overridden-writer"; }
      ];
    })) then
      throw "Effective instance roster merge changed shape, values, or legacy list order."
    else
      "ok";

in
{
  inherit defaultCheck implicitRosterCheck unpinnedRosterCheck emptyRosterChecks explicitWorkspaceCheck authoredRosterChecks canonicalAgentIdChecks invalidRosterChecks mergedRosterCheck;
}
