{
  pkgs,
  steipetePkgs ? { },
  toolNamesOverride ? null,
  excludeToolNames ? [ ],
}:
let
  lib = pkgs.lib;
  safe = list: builtins.filter (p: p != null) list;
  pickFrom =
    scope: name:
    if builtins.hasAttr name scope then
      let
        pkg = scope.${name};
      in
      if lib.meta.availableOn pkgs.stdenv.hostPlatform pkg then pkg else null
    else
      null;
  pick =
    name:
    let
      fromSteipete = pickFrom steipetePkgs name;
    in
    if fromSteipete != null then fromSteipete else pickFrom pkgs name;
  ensure = names: safe (map pick names);

  baseNames = [
    "nodejs_22"
    "pnpm_10"
    "git"
    "curl"
    "jq"
    "python3"
    "ffmpeg"
    "sox"
    "ripgrep"
  ];

  pluginCatalog = import ../modules/home-manager/openclaw/plugin-catalog.nix;
  bundledToolNames = lib.unique (
    builtins.filter (name: name != "bird")
      (map (plugin: plugin.tool) (builtins.attrValues pluginCatalog))
  );

  extraNames = [
    "go"
    "uv"
    "openai-whisper"
    "spotify-player"
    "openhue-cli"
    "wacli"
    "ordercli"
    "blucli"
    "eightctl"
    "mcporter"
    "qmd"
    "nano-pdf"
  ] ++ bundledToolNames;
  toolNamesBase = if toolNamesOverride != null then toolNamesOverride else baseNames ++ extraNames;
  toolNames = builtins.filter (name: !builtins.elem name excludeToolNames) toolNamesBase;

in
{
  tools = ensure toolNames;
  toolNames = toolNames;
}
