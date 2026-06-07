{
  lib,
  pkgs,
  openclawLib,
  qmdPackage,
}:

# Generic OpenClaw command tool environment.
#
# This file owns the Nix side of upstream OpenClaw command lookup:
# - the gateway wrapper's process PATH;
# - rendered `tools.exec.pathPrepend`;
# - per-agent `agents.list[].tools.exec.pathPrepend` entries that would
#   otherwise replace the global exec path.
#
# It deliberately does not know about Codex app-server `command/exec`, ACP,
# Claude, or other plugin-specific command execution. Plugin-specific adapters
# must opt into the generated runtime bin directory explicitly so
# `runtimePackages` does not create plugin-specific state by accident.
#
# Before changing this file, re-check these upstream OpenClaw contracts:
# - docs/tools/exec.md, "tools.exec.pathPrepend" and "PATH handling";
# - src/agents/agent-tools.ts, where agent-level tools.exec overrides global;
# - src/agents/bash-tools.exec-runtime.ts, where POSIX exec re-prepends PATH
#   after shell startup.
{
  forInstance =
    {
      name,
      cfg,
      inst,
      pluginPackages,
      qmdEnabled,
    }:
    let
      # runtimePackages are command tools for OpenClaw-owned processes. They
      # feed the gateway process PATH and upstream OpenClaw's tools.exec PATH
      # config. They are not user shell packages and they do not enable runtime
      # plugins or choose app-server commands by themselves.
      packages = lib.unique (
        openclawLib.toolSets.tools
        ++ (lib.optional (qmdEnabled && qmdPackage != null) qmdPackage)
        ++ pluginPackages
        ++ cfg.runtimePackages
        ++ inst.runtimePackages
      );
      profile = pkgs.symlinkJoin {
        name = "openclaw-runtime-${name}";
        paths = packages;
      };
      pathEntries = map (package: "${lib.getBin package}/bin") packages;
      path = lib.concatStringsSep ":" pathEntries;
      prefixPathEntries = entries: lib.unique (pathEntries ++ (if entries == null then [ ] else entries));
      addPathToExec =
        execConfig:
        execConfig
        // {
          pathPrepend = prefixPathEntries (execConfig.pathPrepend or [ ]);
        };
      addPathToAgent =
        agent:
        let
          tools = agent.tools or { };
          exec = tools.exec or { };
        in
        # Upstream OpenClaw gives agents.list[].tools.exec.pathPrepend priority
        # over tools.exec.pathPrepend. Prefix only agents that already override
        # it, so an agent-specific PATH does not hide Nix runtimePackages.
        if exec ? pathPrepend then
          agent
          // {
            tools = tools // {
              exec = addPathToExec exec;
            };
          }
        else
          agent;
      addPathToConfig =
        value:
        let
          tools = value.tools or { };
          exec = tools.exec or { };
          agents = value.agents or { };
          agentList = agents.list or [ ];
        in
        if pathEntries == [ ] then
          value
        else
          value
          // {
            tools = tools // {
              exec = addPathToExec exec;
            };
          }
          // lib.optionalAttrs (agentList != [ ]) {
            agents = agents // {
              list = map addPathToAgent agentList;
            };
          };
    in
    {
      inherit
        packages
        profile
        pathEntries
        path
        addPathToConfig
        ;
    };
}
