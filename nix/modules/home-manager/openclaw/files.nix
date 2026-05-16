{
  lib,
  pkgs,
  openclawLib,
  enabledInstances,
  plugins,
}:

let
  cfg = openclawLib.cfg;
  resolvePath = openclawLib.resolvePath;
  toRelative = openclawLib.toRelative;
  toolSets = openclawLib.toolSets;
  documentsEnabled = cfg.documents != null;
  instanceWorkspaceDirs = map (inst: resolvePath inst.workspaceDir) (lib.attrValues enabledInstances);

  renderSkill =
    skill:
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

  duplicateSkillAssertion =
    let
      targetsForInstance =
        instName: inst:
        let
          base = "${toRelative (resolvePath inst.workspaceDir)}/skills";
          userTargets = map (skill: "${base}/${skill.name}") cfg.skills;
          pluginsForInstance = plugins.resolvedPluginsByInstance.${instName} or [ ];
          pluginTargets = lib.flatten (
            map (p: map (skillPath: "${base}/${builtins.baseNameOf skillPath}") p.skills) pluginsForInstance
          );
        in
        userTargets ++ pluginTargets;
      skillTargets = lib.flatten (lib.mapAttrsToList targetsForInstance enabledInstances);
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

  skillEntries =
    let
      entriesForInstance =
        instName: inst:
        let
          entryFor =
            skill:
            let
              mode = skill.mode or "symlink";
              source = if skill ? source && skill.source != null then resolvePath skill.source else null;
            in
            if mode == "inline" then
              {
                source = pkgs.writeText "openclaw-skill-${skill.name}.md" (renderSkill skill);
                target = "${resolvePath inst.workspaceDir}/skills/${skill.name}/SKILL.md";
              }
            else if mode == "copy" || mode == "symlink" then
              {
                source = builtins.path {
                  name = "openclaw-skill-${skill.name}";
                  path = source;
                };
                target = "${resolvePath inst.workspaceDir}/skills/${skill.name}";
              }
            else
              throw "Unsupported OpenClaw skill mode: ${mode}";
          pluginEntriesFor =
            p:
            map (skillPath: {
              source = skillPath;
              target = "${resolvePath inst.workspaceDir}/skills/${builtins.baseNameOf skillPath}";
            }) p.skills;
          pluginsForInstance = plugins.resolvedPluginsByInstance.${instName} or [ ];
        in
        (map entryFor cfg.skills) ++ (lib.flatten (map pluginEntriesFor pluginsForInstance));
    in
    lib.flatten (lib.mapAttrsToList entriesForInstance enabledInstances);

  documentsRequiredFiles = [
    "AGENTS.md"
    "SOUL.md"
    "TOOLS.md"
  ];

  documentsOptionalFiles = [
    "IDENTITY.md"
    "USER.md"
    "LORE.md"
    "HEARTBEAT.md"
    "PROMPTING-EXAMPLES.md"
  ];

  documentsFileNames =
    if documentsEnabled then
      let
        extra = lib.filter (file: builtins.pathExists (cfg.documents + "/${file}")) documentsOptionalFiles;
      in
      documentsRequiredFiles ++ extra
    else
      [ ];

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

  toolsReport =
    if documentsEnabled then
      let
        renderPkgName = pkg: if pkg ? pname then pkg.pname else lib.getName pkg;
        renderPkgCommand =
          pkg:
          let
            pkgName = renderPkgName pkg;
            commandName = pkg.meta.mainProgram or pkgName;
          in
          if commandName == pkgName then commandName else "${commandName} (${pkgName})";
        toolPackages = lib.filter (p: p != null) (toolSets.tools or [ ]);
        renderPlugin =
          plugin:
          let
            pkgNames = map renderPkgCommand (lib.filter (p: p != null) plugin.packages);
            pkgSuffix = if pkgNames == [ ] then "" else " — " + (lib.concatStringsSep ", " pkgNames);
          in
          "- " + plugin.name + pkgSuffix + " (" + plugin.source + ")";
        renderPkgList =
          packages:
          let
            actualPackages = lib.filter (p: p != null) packages;
          in
          if actualPackages == [ ] then
            [ "- (none)" ]
          else
            map (pkg: "- " + renderPkgCommand pkg) actualPackages;
        pluginLinesFor =
          instName: inst:
          let
            pluginsForInstance = plugins.resolvedPluginsByInstance.${instName} or [ ];
            pluginLines =
              if pluginsForInstance == [ ] then [ "- (none)" ] else map renderPlugin pluginsForInstance;
            instanceConfig = lib.recursiveUpdate (cfg.config or { }) (inst.config or { });
            qmdEnabled = (((instanceConfig.memory or { }).backend or null) == "qmd");
            runtimePackages = lib.unique (
              (lib.optional (qmdEnabled && openclawLib.qmdPackage != null) openclawLib.qmdPackage)
              ++ (cfg.runtimePackages or [ ])
              ++ (inst.runtimePackages or [ ])
            );
          in
          [
            ""
            "### Instance: ${instName}"
          ]
          ++ [
            ""
            "Plugins:"
          ]
          ++ pluginLines
          ++ [
            ""
            "Runtime packages:"
          ]
          ++ renderPkgList runtimePackages;
        reportLines = [
          "<!-- BEGIN NIX-REPORT -->"
          ""
          "## Nix-managed tools"
          ""
          "### Built-in toolchain"
        ]
        ++ (
          if toolPackages == [ ] then [ "- (none)" ] else map (pkg: "- " + renderPkgCommand pkg) toolPackages
        )
        ++ [
          ""
          "## Nix-managed plugin report"
          ""
          "Plugins enabled per instance (last-wins on name collisions):"
        ]
        ++ lib.concatLists (lib.mapAttrsToList pluginLinesFor enabledInstances)
        ++ [
          ""
          "Tools: batteries-included toolchain + runtime packages + plugin-provided CLIs."
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
      pkgs.runCommand "openclaw-tools-with-report.md" { } ''
        cat ${cfg.documents + "/TOOLS.md"} > $out
        echo "" >> $out
        cat ${toolsReport} >> $out
      ''
    else
      null;

  documentEntries =
    if documentsEnabled then
      let
        mkDocFiles =
          dir:
          let
            mkDoc = name: {
              source = if name == "TOOLS.md" then toolsWithReport else cfg.documents + "/${name}";
              target = dir + "/${name}";
            };
          in
          map mkDoc documentsFileNames;
      in
      lib.flatten (map mkDocFiles instanceWorkspaceDirs)
    else
      [ ];

  materializedEntries = documentEntries ++ skillEntries;
  materializedManifest =
    let
      renderEntry = entry: "${entry.source}\t${entry.target}";
    in
    pkgs.writeText "openclaw-workspace-files.tsv" (
      (lib.concatStringsSep "\n" (map renderEntry materializedEntries)) + "\n"
    );

in
{
  inherit
    documentsEnabled
    documentsAssertions
    materializedManifest
    materializedEntries
    duplicateSkillAssertion
    ;
}
