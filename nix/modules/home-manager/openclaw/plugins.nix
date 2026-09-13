{
  lib,
  pkgs,
  openclawLib,
  enabledInstances,
}:

let
  resolvePath = openclawLib.resolvePath;
  toRelative = openclawLib.toRelative;
  toJSONWithContext = import ../../../lib/json-with-context.nix { inherit lib; };

  resolveFlakePlugin =
    plugin:
    let
      _ =
        if (plugin.id or null) != null then
          throw "Plugin ${plugin.source}: id is not valid for customPlugins; OpenClaw runtime plugins use programs.openclaw.runtimePlugins or runtimePluginSources"
        else if (plugin.hash or lib.fakeHash) != lib.fakeHash then
          throw "Plugin ${plugin.source}: hash is not valid for customPlugins; OpenClaw runtime plugins use programs.openclaw.runtimePlugins or runtimePluginSources"
        else if (plugin.enabled or true) != true then
          throw "Plugin ${plugin.source}: enabled is not valid for customPlugins; OpenClaw runtime plugins use programs.openclaw.runtimePlugins or runtimePluginSources"
        else
          null;
      system = pkgs.stdenv.hostPlatform.system;
      flake = builtins.getFlake plugin.source;
      openclawPluginRaw =
        if flake ? openclawPlugin then
          flake.openclawPlugin
        else
          throw "openclawPlugin missing in ${plugin.source}";
      openclawPlugin =
        if builtins.isFunction openclawPluginRaw then openclawPluginRaw system else openclawPluginRaw;
      resolvedPlugin =
        if openclawPlugin == null then
          throw "openclawPlugin is null in ${plugin.source} for ${system}"
        else
          openclawPlugin;
      name = resolvedPlugin.name or (throw "openclawPlugin.name missing in ${plugin.source}");
      needs = resolvedPlugin.needs or { };
      _noRuntimePlugins =
        if resolvedPlugin ? plugins then
          throw "openclawPlugin.plugins is not supported in ${plugin.source}; OpenClaw runtime plugins use programs.openclaw.runtimePlugins or runtimePluginSources"
        else
          null;
    in
    builtins.seq _ (
      builtins.seq _noRuntimePlugins {
        source = plugin.source;
        inherit name;
        skills = resolvedPlugin.skills or [ ];
        packages = resolvedPlugin.packages or [ ];
        needs = {
          stateDirs = needs.stateDirs or [ ];
          requiredEnv = needs.requiredEnv or [ ];
        };
        config = plugin.config or { };
      }
    );

  resolvePlugin =
    plugin:
    if lib.hasPrefix "npm:" plugin.source then
      throw "customPlugins.source = \"${plugin.source}\" is not supported for OpenClaw npm runtime plugins. Use programs.openclaw.runtimePlugins for generated official ids or programs.openclaw.runtimePluginSources for locked npm/ClawHub sources instead."
    else
      resolveFlakePlugin plugin;

  resolvedPluginsByInstance = lib.mapAttrs (
    instName: inst:
    let
      resolved = map resolvePlugin inst.plugins;
      counts = lib.foldl' (acc: p: acc // { "${p.name}" = (acc.${p.name} or 0) + 1; }) { } resolved;
      duplicates = lib.attrNames (lib.filterAttrs (_: v: v > 1) counts);
      byName = lib.foldl' (acc: p: acc // { "${p.name}" = p; }) { } resolved;
      ordered = lib.attrValues byName;
    in
    if duplicates == [ ] then
      ordered
    else
      lib.warn "programs.openclaw.instances.${instName}: duplicate plugin names detected (${lib.concatStringsSep ", " duplicates}); last entry wins." ordered
  ) enabledInstances;

  pluginPackagesFor =
    instName: lib.flatten (map (p: p.packages) (resolvedPluginsByInstance.${instName} or [ ]));

  pluginPackagesAll = lib.flatten (map pluginPackagesFor (lib.attrNames enabledInstances));

  pluginStateDirsFor =
    instName:
    let
      dirs = lib.flatten (map (p: p.needs.stateDirs) (resolvedPluginsByInstance.${instName} or [ ]));
    in
    map (dir: resolvePath ("~/" + dir)) dirs;

  pluginStateDirsAll = lib.flatten (map pluginStateDirsFor (lib.attrNames enabledInstances));

  pluginEnvFor =
    instName:
    let
      entries = resolvedPluginsByInstance.${instName} or [ ];
      toPairs =
        p:
        let
          env = (p.config.env or { });
          required = p.needs.requiredEnv;
        in
        map (k: {
          key = k;
          value = env.${k} or "";
          plugin = p.name;
        }) required;
    in
    lib.flatten (map toPairs entries);

  pluginEnvAllFor =
    instName:
    let
      entries = resolvedPluginsByInstance.${instName} or [ ];
      toPairs =
        p:
        let
          env = (p.config.env or { });
        in
        map (k: {
          key = k;
          value = env.${k};
          plugin = p.name;
        }) (lib.attrNames env);
    in
    lib.flatten (map toPairs entries);

  pluginAssertions = lib.flatten (
    lib.mapAttrsToList (
      instName: inst:
      let
        plugins = resolvedPluginsByInstance.${instName} or [ ];
        envFor = p: (p.config.env or { });
        missingFor = p: lib.filter (req: !(builtins.hasAttr req (envFor p))) p.needs.requiredEnv;
        configMissingStateDir = p: (p.config.settings or { }) != { } && (p.needs.stateDirs or [ ]) == [ ];
        mkAssertion =
          p:
          let
            missing = missingFor p;
          in
          {
            assertion = missing == [ ];
            message = "programs.openclaw.instances.${instName}: plugin ${p.name} missing required env: ${lib.concatStringsSep ", " missing}";
          };
        mkConfigAssertion = p: {
          assertion = !(configMissingStateDir p);
          message = "programs.openclaw.instances.${instName}: plugin ${p.name} provides settings but declares no stateDirs (needed for config.json).";
        };
      in
      (map mkAssertion plugins) ++ (map mkConfigAssertion plugins)
    ) enabledInstances
  );

  pluginConfigFiles =
    let
      entryFor =
        instName: inst:
        let
          plugins = resolvedPluginsByInstance.${instName} or [ ];
          mkEntries =
            p:
            let
              cfg = p.config.settings or { };
              dir = if (p.needs.stateDirs or [ ]) == [ ] then null else lib.head (p.needs.stateDirs or [ ]);
            in
            if cfg == { } then
              [ ]
            else
              (
                if dir == null then
                  throw "plugin ${p.name} provides settings but no stateDirs are defined"
                else
                  [
                    {
                      name = toRelative (resolvePath ("~/" + dir + "/config.json"));
                      value = {
                        source = pkgs.writeText "openclaw-plugin-${p.name}-config.json" (toJSONWithContext cfg);
                      };
                    }
                  ]
              );
        in
        lib.flatten (map mkEntries plugins);
      entries = lib.flatten (lib.mapAttrsToList entryFor enabledInstances);
    in
    lib.listToAttrs entries;

  pluginGuards =
    let
      renderCheck = entry: ''
        if [ -z "${entry.value}" ]; then
          echo "Missing env ${entry.key} for plugin ${entry.plugin} in instance ${entry.instance}." >&2
          exit 1
        fi
        if [ ! -f "${entry.value}" ] || [ ! -s "${entry.value}" ]; then
          echo "Required file for ${entry.key} not found or empty: ${entry.value} (plugin ${entry.plugin}, instance ${entry.instance})." >&2
          exit 1
        fi
      '';
      entriesForInstance =
        instName: map (entry: entry // { instance = instName; }) (pluginEnvFor instName);
      entries = lib.flatten (map entriesForInstance (lib.attrNames enabledInstances));
    in
    lib.concatStringsSep "\n" (map renderCheck entries);

in
{
  inherit
    resolvedPluginsByInstance
    pluginPackagesFor
    pluginPackagesAll
    pluginStateDirsFor
    pluginStateDirsAll
    pluginEnvFor
    pluginEnvAllFor
    pluginAssertions
    pluginConfigFiles
    pluginGuards
    ;
}
