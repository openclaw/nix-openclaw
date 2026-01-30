{ config, lib, pkgs, openclawLib, enabledInstances, plugins }:

let
  cfg = openclawLib.cfg;
  resolvePath = openclawLib.resolvePath;
  toRelative = openclawLib.toRelative;
  toolSets = openclawLib.toolSets;
  documentsEnabled = cfg.documents != null;
  instanceWorkspaceDirs = map (inst: resolvePath inst.workspaceDir) (lib.attrValues enabledInstances);

  renderSkill = skill:
    let
      frontmatterLines = [
        "---"
        "name: ${skill.name}"
        "description: ${skill.description or ""}"
      ]
      ++ lib.optionals (skill ? homepage && skill.homepage != null) [ "homepage: ${skill.homepage}" ]
      ++ lib.optionals (skill ? openclaw && skill.openclaw != null) [
        "openclaw:"
        "  ${builtins.toJSON skill.openclaw}"
      ]
      ++ [ "---" ];
      frontmatter = lib.concatStringsSep "\n" frontmatterLines;
      body = if skill ? body then skill.body else "";
    in
      "${frontmatter}\n\n${body}\n";

  skillAssertions =
    let
      names = map (skill: skill.name) cfg.skills;
      nameCounts = lib.foldl' (acc: name: acc // { "${name}" = (acc.${name} or 0) + 1; }) {} names;
      duplicateNames = lib.attrNames (lib.filterAttrs (_: v: v > 1) nameCounts);
    in
      if duplicateNames == [] then [] else [
        {
          assertion = false;
          message = "programs.openclaw.skills has duplicate names: ${lib.concatStringsSep ", " duplicateNames}";
        }
      ];

  skillFiles =
    let
      entriesForInstance = instName: inst:
        let
          base = "${toRelative (resolvePath inst.workspaceDir)}/skills";
          entryFor = skill:
            let
              mode = skill.mode or "symlink";
              source = if skill ? source && skill.source != null then resolvePath skill.source else null;
            in
              if mode == "inline" then
                {
                  name = "${base}/${skill.name}/SKILL.md";
                  value = { text = renderSkill skill; };
                }
              else if mode == "copy" then
                {
                  name = "${base}/${skill.name}";
                  value = {
                    source = builtins.path {
                      name = "openclaw-skill-${skill.name}";
                      path = source;
                    };
                    recursive = true;
                  };
                }
              else
                {
                  name = "${base}/${skill.name}";
                  value = {
                    source = config.lib.file.mkOutOfStoreSymlink source;
                    recursive = true;
                  };
                };
        in
          map entryFor cfg.skills;
    in
      lib.listToAttrs (lib.flatten (lib.mapAttrsToList entriesForInstance enabledInstances));

  documentsAssertions = lib.optionals documentsEnabled [
    {
      assertion = builtins.pathExists cfg.documents;
      message = "programs.openclaw.documents must point to an existing directory.";
    }
    {
      assertion = builtins.pathExists (cfg.documents + "/AGENTS.md");
      message = "Missing AGENTS.md in programs.openclaw.documents.";
    }
    {
      assertion = builtins.pathExists (cfg.documents + "/SOUL.md");
      message = "Missing SOUL.md in programs.openclaw.documents.";
    }
    {
      assertion = builtins.pathExists (cfg.documents + "/TOOLS.md");
      message = "Missing TOOLS.md in programs.openclaw.documents.";
    }
  ];

  documentsGuard =
    lib.optionalString documentsEnabled (
      let
        guardLine = file: ''
          if [ -e "${file}" ] && [ ! -L "${file}" ]; then
            echo "Openclaw documents are managed by Nix. Please adopt ${file} into your documents directory and re-run." >&2
            exit 1
          fi
        '';
        guardForDir = dir: ''
          ${guardLine "${dir}/AGENTS.md"}
          ${guardLine "${dir}/SOUL.md"}
          ${guardLine "${dir}/TOOLS.md"}
        '';
      in
        lib.concatStringsSep "\n" (map guardForDir instanceWorkspaceDirs)
    );

  toolsReport =
    if documentsEnabled then
      let
          toolNames = toolSets.toolNames or [];
          renderPkgName = pkg:
            if pkg ? pname then pkg.pname else lib.getName pkg;
          renderPlugin = plugin:
            let
              pkgNames = map renderPkgName (lib.filter (p: p != null) plugin.packages);
              pkgSuffix =
                if pkgNames == []
                then ""
                else " — " + (lib.concatStringsSep ", " pkgNames);
            in
              "- " + plugin.name + pkgSuffix + " (" + plugin.source + ")";
          pluginLinesFor = instName: inst:
            let
              pluginsForInstance = plugins.resolvedPluginsByInstance.${instName} or [];
              lines = if pluginsForInstance == [] then [ "- (none)" ] else map renderPlugin pluginsForInstance;
            in
              [
                ""
                "### Instance: ${instName}"
              ] ++ lines;
        reportLines =
          [
            "<!-- BEGIN NIX-REPORT -->"
            ""
            "## Nix-managed tools"
            ""
            "### Built-in toolchain"
          ]
          ++ (if toolNames == [] then [ "- (none)" ] else map (name: "- " + name) toolNames)
          ++ [
            ""
            "## Nix-managed plugin report"
            ""
            "Plugins enabled per instance (last-wins on name collisions):"
          ]
          ++ lib.concatLists (lib.mapAttrsToList pluginLinesFor enabledInstances)
          ++ [
            ""
            "Tools: batteries-included toolchain + plugin-provided CLIs."
            ""
            "<!-- END NIX-REPORT -->"
          ];
        reportText = lib.concatStringsSep "\n" reportLines;
      in
        pkgs.writeText "openclaw-tools-report.md" reportText
    else
      null;

  toolsWithReport =
    if documentsEnabled then
      pkgs.runCommand "openclaw-tools-with-report.md" {} ''
        cat ${cfg.documents + "/TOOLS.md"} > $out
        echo "" >> $out
        cat ${toolsReport} >> $out
      ''
    else
      null;

  documentsFiles =
    if documentsEnabled then
      let
        mkDocFiles = dir: {
          "${toRelative (dir + "/AGENTS.md")}" = {
            source = cfg.documents + "/AGENTS.md";
          };
          "${toRelative (dir + "/SOUL.md")}" = {
            source = cfg.documents + "/SOUL.md";
          };
          "${toRelative (dir + "/TOOLS.md")}" = {
            source = toolsWithReport;
          };
        };
      in
        lib.mkMerge (map mkDocFiles instanceWorkspaceDirs)
    else
      {};

in {
  inherit
    documentsEnabled
    documentsAssertions
    documentsGuard
    documentsFiles
    skillAssertions
    skillFiles;
}
