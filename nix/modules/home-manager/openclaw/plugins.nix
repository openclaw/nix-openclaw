{ lib, pkgs, openclawLib, enabledInstances }:

let
  resolvePath = openclawLib.resolvePath;
  toRelative = openclawLib.toRelative;

  resolvePlugin = plugin: let
    flake = builtins.getFlake plugin.source;
    system = pkgs.stdenv.hostPlatform.system;
    openclawPluginRaw =
      if flake ? openclawPlugin then flake.openclawPlugin
      else throw "openclawPlugin missing in ${plugin.source}";
    openclawPlugin =
      if builtins.isFunction openclawPluginRaw
      then openclawPluginRaw system
      else openclawPluginRaw;
    resolvedPlugin =
      if openclawPlugin == null
      then throw "openclawPlugin is null in ${plugin.source} for ${system}"
      else openclawPlugin;
    needs = resolvedPlugin.needs or {};
  in {
    source = plugin.source;
    name = resolvedPlugin.name or (throw "openclawPlugin.name missing in ${plugin.source}");
    skills = resolvedPlugin.skills or [];
    packages = resolvedPlugin.packages or [];
    needs = {
      stateDirs = needs.stateDirs or [];
      requiredEnv = needs.requiredEnv or [];
    };
    config = plugin.config or {};
  };

  resolvedPluginsByInstance =
    lib.mapAttrs (instName: inst:
      let
        resolved = map resolvePlugin inst.plugins;
        counts = lib.foldl' (acc: p:
          acc // { "${p.name}" = (acc.${p.name} or 0) + 1; }
        ) {} resolved;
        duplicates = lib.attrNames (lib.filterAttrs (_: v: v > 1) counts);
        byName = lib.foldl' (acc: p: acc // { "${p.name}" = p; }) {} resolved;
        ordered = lib.attrValues byName;
      in
        if duplicates == []
        then ordered
        else lib.warn
          "programs.openclaw.instances.${instName}: duplicate plugin names detected (${lib.concatStringsSep ", " duplicates}); last entry wins."
          ordered
    ) enabledInstances;

  pluginPackagesFor = instName:
    lib.flatten (map (p: p.packages) (resolvedPluginsByInstance.${instName} or []));

  pluginPackagesAll =
    lib.flatten (map pluginPackagesFor (lib.attrNames enabledInstances));

  pluginStateDirsFor = instName:
    let
      dirs = lib.flatten (map (p: p.needs.stateDirs) (resolvedPluginsByInstance.${instName} or []));
    in
      map (dir: resolvePath ("~/" + dir)) dirs;

  pluginStateDirsAll =
    lib.flatten (map pluginStateDirsFor (lib.attrNames enabledInstances));

  pluginEnvFor = instName:
    let
      entries = resolvedPluginsByInstance.${instName} or [];
      toPairs = p:
        let
          env = (p.config.env or {});
          required = p.needs.requiredEnv;
        in
          map (k: { key = k; value = env.${k} or ""; plugin = p.name; }) required;
    in
      lib.flatten (map toPairs entries);

  pluginEnvAllFor = instName:
    let
      entries = resolvedPluginsByInstance.${instName} or [];
      toPairs = p:
        let env = (p.config.env or {});
        in map (k: { key = k; value = env.${k}; plugin = p.name; }) (lib.attrNames env);
    in
      lib.flatten (map toPairs entries);

  pluginAssertions =
    lib.flatten (lib.mapAttrsToList (instName: inst:
      let
        plugins = resolvedPluginsByInstance.${instName} or [];
        envFor = p: (p.config.env or {});
        missingFor = p:
          lib.filter (req: !(builtins.hasAttr req (envFor p))) p.needs.requiredEnv;
        configMissingStateDir = p:
          (p.config.settings or {}) != {} && (p.needs.stateDirs or []) == [];
        mkAssertion = p:
          let
            missing = missingFor p;
          in {
            assertion = missing == [];
            message = "programs.openclaw.instances.${instName}: plugin ${p.name} missing required env: ${lib.concatStringsSep ", " missing}";
          };
        mkConfigAssertion = p: {
          assertion = !(configMissingStateDir p);
          message = "programs.openclaw.instances.${instName}: plugin ${p.name} provides settings but declares no stateDirs (needed for config.json).";
        };
      in
        (map mkAssertion plugins) ++ (map mkConfigAssertion plugins)
    ) enabledInstances);

  pluginSkillsFiles =
    let
      entriesForInstance = instName: inst:
        let
          base = "${toRelative (resolvePath inst.workspaceDir)}/skills";
          skillEntriesFor = p:
            map (skillPath: {
              name = "${base}/${p.name}/${builtins.baseNameOf skillPath}";
              value = { source = skillPath; recursive = true; };
            }) p.skills;
          plugins = resolvedPluginsByInstance.${instName} or [];
        in
          lib.flatten (map skillEntriesFor plugins);
    in
      lib.listToAttrs (lib.flatten (lib.mapAttrsToList entriesForInstance enabledInstances));

  pluginConfigFiles =
    let
      entryFor = instName: inst:
        let
          plugins = resolvedPluginsByInstance.${instName} or [];
          mkEntries = p:
            let
              cfg = p.config.settings or {};
              dir =
                if (p.needs.stateDirs or []) == []
                then null
                else lib.head (p.needs.stateDirs or []);
            in
              if cfg == {} then
                []
              else
                (if dir == null then
                  throw "plugin ${p.name} provides settings but no stateDirs are defined"
                else [
                  {
                    name = toRelative (resolvePath ("~/" + dir + "/config.json"));
                    value = { text = builtins.toJSON cfg; };
                  }
                ]);
        in
          lib.flatten (map mkEntries plugins);
      entries = lib.flatten (lib.mapAttrsToList entryFor enabledInstances);
    in
      lib.listToAttrs entries;

  pluginSkillAssertions =
    let
      skillTargets =
        lib.flatten (lib.concatLists (lib.mapAttrsToList (instName: inst:
          let
            base = "${toRelative (resolvePath inst.workspaceDir)}/skills";
            plugins = resolvedPluginsByInstance.${instName} or [];
          in
            map (p:
              map (skillPath:
                "${base}/${p.name}/${builtins.baseNameOf skillPath}"
              ) p.skills
            ) plugins
        ) enabledInstances));
      counts = lib.foldl' (acc: path:
        acc // { "${path}" = (acc.${path} or 0) + 1; }
      ) {} skillTargets;
      duplicates = lib.attrNames (lib.filterAttrs (_: v: v > 1) counts);
    in
      if duplicates == [] then [] else [
        {
          assertion = false;
          message = "Duplicate skill paths detected: ${lib.concatStringsSep ", " duplicates}";
        }
      ];

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
      entriesForInstance = instName:
        map (entry: entry // { instance = instName; }) (pluginEnvFor instName);
      entries = lib.flatten (map entriesForInstance (lib.attrNames enabledInstances));
    in
      lib.concatStringsSep "\n" (map renderCheck entries);

in {
  inherit
    resolvedPluginsByInstance
    pluginPackagesFor
    pluginPackagesAll
    pluginStateDirsFor
    pluginStateDirsAll
    pluginEnvFor
    pluginEnvAllFor
    pluginAssertions
    pluginSkillsFiles
    pluginConfigFiles
    pluginSkillAssertions
    pluginGuards;
}
