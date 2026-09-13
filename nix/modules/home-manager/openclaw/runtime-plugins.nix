{ lib, pkgs }:

let
  packageSet = pkgs.openclawRuntimePlugins or { };
  supportedIds = lib.attrNames packageSet;
  supportReportPath = "nix/generated/openclaw-runtime-plugins/report.json";
  buildRuntimePlugin =
    openclawPackage:
    pkgs.callPackage ../../../lib/openclaw-runtime-plugin.nix {
      inherit openclawPackage;
    };

  duplicateIds =
    ids:
    let
      counts = lib.foldl' (acc: id: acc // { "${id}" = (acc.${id} or 0) + 1; }) { } ids;
    in
    lib.attrNames (lib.filterAttrs (_id: count: count > 1) counts);

  sourceSelectedSource =
    source:
    if source.url != null then
      "url"
    else if source.spec != null && lib.hasPrefix "clawhub:" source.spec then
      "clawhub"
    else if source.spec != null && lib.hasPrefix "npm:" source.spec then
      "npm"
    else
      "source";

  sourceLock =
    source:
    {
      id = source.id;
      selectedSource = sourceSelectedSource source;
      nixHash = source.hash;
      dependencyMode = if source.npmDepsHash != null then "shrinkwrap" else "auto";
    }
    // lib.optionalAttrs (source.spec != null) {
      sourceSpec = source.spec;
    }
    // lib.optionalAttrs (source.url != null) {
      sourceUrl = source.url;
    }
    // lib.optionalAttrs (source.npmDepsHash != null) {
      npmDepsHash = source.npmDepsHash;
    };

  sourceLabel =
    source:
    "${source.id} (${
      if source.spec != null then
        source.spec
      else if source.url != null then
        source.url
      else
        "missing source"
    })";

  forInstance =
    {
      name,
      ids,
      sources,
      openclawPackage,
      existingLoadPaths,
      existingAllowList,
      userPluginEntries,
      denyList,
    }:
    let
      sourceIds = map (source: source.id) sources;
      allIds = ids ++ sourceIds;
      duplicates = duplicateIds allIds;
      unknownIds = lib.filter (id: !(builtins.hasAttr id packageSet)) ids;
      disabledIds = lib.filter (id: (((userPluginEntries.${id} or { }).enabled or null) == false)) allIds;
      deniedIds = lib.filter (id: lib.elem id denyList) allIds;
      sourceWithAmbiguousInputs = lib.filter (
        source: (source.spec == null) == (source.url == null)
      ) sources;
      sourceWithInvalidSpec = lib.filter (
        source:
        source.spec != null && !(lib.hasPrefix "npm:" source.spec || lib.hasPrefix "clawhub:" source.spec)
      ) sources;
      sourceWithInvalidUrl = lib.filter (
        source: source.url != null && !(lib.hasPrefix "https://" source.url)
      ) sources;
      sourcePackages = map (source: (buildRuntimePlugin openclawPackage) (sourceLock source)) sources;
      packages =
        if
          unknownIds == [ ]
          && sourceWithAmbiguousInputs == [ ]
          && sourceWithInvalidSpec == [ ]
          && sourceWithInvalidUrl == [ ]
        then
          (map (id: packageSet.${id}) ids) ++ sourcePackages
        else
          [ ];

      entriesConfig = lib.optionalAttrs (allIds != [ ] && unknownIds == [ ]) {
        plugins.entries = lib.listToAttrs (
          map (id: {
            name = id;
            value.enabled = true;
          }) allIds
        );
      };

      allowConfig = lib.optionalAttrs (allIds != [ ] && existingAllowList != null) {
        plugins.allow = lib.unique (existingAllowList ++ allIds);
      };
    in
    {
      inherit packages;
      loadPaths = map toString packages;
      config = lib.recursiveUpdate entriesConfig allowConfig;
      assertions = [
        {
          assertion = duplicates == [ ];
          message = "programs.openclaw.instances.${name}.runtimePlugins/runtimePluginSources contains duplicate ids: ${lib.concatStringsSep ", " duplicates}";
        }
        {
          assertion = unknownIds == [ ];
          message = ''
            programs.openclaw.instances.${name}.runtimePlugins contains unsupported ids: ${lib.concatStringsSep ", " unknownIds}.
            Supported ids in this build: ${lib.concatStringsSep ", " supportedIds}
            Source/install specs such as npm:... or clawhub:... belong in programs.openclaw.runtimePluginSources.
            Maintainers can inspect unsupported-plugin diagnostics in ${supportReportPath}.
          '';
        }
        {
          assertion = sourceWithAmbiguousInputs == [ ];
          message = "programs.openclaw.instances.${name}.runtimePluginSources entries must set exactly one of spec or url: ${lib.concatStringsSep ", " (map sourceLabel sourceWithAmbiguousInputs)}";
        }
        {
          assertion = sourceWithInvalidSpec == [ ];
          message = "programs.openclaw.instances.${name}.runtimePluginSources spec must start with npm: or clawhub:. Bad entries: ${lib.concatStringsSep ", " (map sourceLabel sourceWithInvalidSpec)}";
        }
        {
          assertion = sourceWithInvalidUrl == [ ];
          message = "programs.openclaw.instances.${name}.runtimePluginSources url must start with https://: ${lib.concatStringsSep ", " (map sourceLabel sourceWithInvalidUrl)}";
        }
        {
          assertion = allIds == [ ] || existingLoadPaths == [ ];
          message = "programs.openclaw.instances.${name}.runtimePlugins/runtimePluginSources cannot be mixed with raw programs.openclaw.config.plugins.load.paths.";
        }
        {
          assertion = disabledIds == [ ];
          message = "programs.openclaw.instances.${name}.runtimePlugins/runtimePluginSources selected ids disabled in config.plugins.entries: ${lib.concatStringsSep ", " disabledIds}";
        }
        {
          assertion = deniedIds == [ ];
          message = "programs.openclaw.instances.${name}.runtimePlugins/runtimePluginSources selected ids denied in config.plugins.deny: ${lib.concatStringsSep ", " deniedIds}";
        }
      ];
    };
in
{
  inherit forInstance;
}
