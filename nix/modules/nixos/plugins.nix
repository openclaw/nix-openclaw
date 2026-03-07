# Plugin resolution for NixOS module
#
# Parallel implementation to home-manager/openclaw/plugins.nix.
# TODO: Consolidate with home-manager once patterns stabilize.
#
# Key differences from home-manager:
# - State dirs resolve to ${inst.stateDir}/${dir} (not ~/${dir})
# - Skills/configs use tmpfiles C rules (not home.file)
# - Packages added to service path (not home.packages)
# - Guards are per-instance for gateway wrappers

{
  lib,
  pkgs,
  cfg,
  enabledInstances,
}:

let
  resolvePlugin =
    plugin:
    let
      flake = builtins.getFlake plugin.source;
      system = pkgs.stdenv.hostPlatform.system;
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
      needs = resolvedPlugin.needs or { };
    in
    {
      source = plugin.source;
      name = resolvedPlugin.name or (throw "openclawPlugin.name missing in ${plugin.source}");
      skills = resolvedPlugin.skills or [ ];
      packages = resolvedPlugin.packages or [ ];
      needs = {
        stateDirs = needs.stateDirs or [ ];
        requiredEnv = needs.requiredEnv or [ ];
      };
      config = plugin.config or { };
    };

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
      lib.warn "services.openclaw.instances.${instName}: duplicate plugin names detected (${lib.concatStringsSep ", " duplicates}); last entry wins." ordered
  ) enabledInstances;

  pluginPackagesFor =
    instName: lib.flatten (map (p: p.packages) (resolvedPluginsByInstance.${instName} or [ ]));

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
            message = "services.openclaw.instances.${instName}: plugin ${p.name} missing required env: ${lib.concatStringsSep ", " missing}";
          };
        mkConfigAssertion = p: {
          assertion = !(configMissingStateDir p);
          message = "services.openclaw.instances.${instName}: plugin ${p.name} provides settings but declares no stateDirs (needed for config.json).";
        };
      in
      (map mkAssertion plugins) ++ (map mkConfigAssertion plugins)
    ) enabledInstances
  );

  pluginSkillAssertions =
    let
      skillTargets = lib.flatten (
        lib.mapAttrsToList (
          instName: inst:
          let
            plugins = resolvedPluginsByInstance.${instName} or [ ];
          in
          map (
            p: map (skillPath: "${inst.workspaceDir}/skills/${builtins.baseNameOf skillPath}") p.skills
          ) plugins
        ) enabledInstances
      );
      counts = lib.foldl' (acc: path: acc // { "${path}" = (acc.${path} or 0) + 1; }) { } skillTargets;
      duplicates = lib.attrNames (lib.filterAttrs (_: v: v > 1) counts);
    in
    if duplicates == [ ] then
      [ ]
    else
      [
        {
          assertion = false;
          message = "Duplicate skill paths detected: ${lib.concatStringsSep ", " duplicates}";
        }
      ];

  pluginTmpfilesRules =
    let
      rulesForInstance =
        instName: inst:
        let
          plugins = resolvedPluginsByInstance.${instName} or [ ];

          # State directory rules
          stateDirRules = map (
            dir: "d ${inst.stateDir}/${dir} 0750 ${cfg.user} ${cfg.group} -"
          ) (lib.flatten (map (p: p.needs.stateDirs) plugins));

          # Skill rules
          skillRules = lib.flatten (
            map (
              p:
              map (
                skillPath:
                "C ${inst.workspaceDir}/skills/${builtins.baseNameOf skillPath} 0750 ${cfg.user} ${cfg.group} - ${skillPath}"
              ) p.skills
            ) plugins
          );

          # Config file rules
          configRules = lib.flatten (
            map (
              p:
              let
                settings = p.config.settings or { };
                dir =
                  if (p.needs.stateDirs or [ ]) == [ ] then null else lib.head p.needs.stateDirs;
                configDrv = pkgs.writeText "openclaw-plugin-${p.name}-config.json" (
                  builtins.toJSON settings
                );
              in
              if settings == { } || dir == null then
                [ ]
              else
                [ "C ${inst.stateDir}/${dir}/config.json 0640 ${cfg.user} ${cfg.group} - ${configDrv}" ]
            ) plugins
          );
        in
        stateDirRules ++ skillRules ++ configRules;
    in
    lib.flatten (lib.mapAttrsToList rulesForInstance enabledInstances);

  pluginGuardsFor =
    instName:
    let
      renderCheck = entry: ''
        if [ -z "${entry.value}" ]; then
          echo "Missing env ${entry.key} for plugin ${entry.plugin} in instance ${instName}." >&2
          exit 1
        fi
        if [ ! -f "${entry.value}" ] || [ ! -s "${entry.value}" ]; then
          echo "Required file for ${entry.key} not found or empty: ${entry.value} (plugin ${entry.plugin}, instance ${instName})." >&2
          exit 1
        fi
      '';
      entries = pluginEnvFor instName;
    in
    lib.concatStringsSep "\n" (map renderCheck entries);

in
{
  inherit
    pluginPackagesFor
    pluginEnvAllFor
    pluginAssertions
    pluginSkillAssertions
    pluginTmpfilesRules
    pluginGuardsFor
    ;
}
