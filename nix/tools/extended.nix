{ pkgs, steipetePkgs ? {} }:
let
  lib = pkgs.lib;
  safe = list: builtins.filter (p: p != null) list;
  pickFrom = scope: name:
    if builtins.hasAttr name scope then
      let pkg = scope.${name}; in
      if lib.meta.availableOn pkgs.stdenv.hostPlatform pkg then pkg else null
    else
      null;
  pick = name:
    let fromSteipete = pickFrom steipetePkgs name; in
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

  extraNames = [
    "go"
    "uv"
    "openai-whisper"
    "spotify-player"
    "gogcli"
    "peekaboo"
    "camsnap"
    "bird"
    "sag"
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    "summarize"
  ]
  ++ [
    "openhue-cli"
    "wacli"
    "sonoscli"
    "ordercli"
    "blucli"
    "eightctl"
    "mcporter"
    "oracle"
    "qmd"
    "nano-pdf"
  ];
  toolNames = baseNames ++ extraNames;

in {
  tools = ensure toolNames;
  toolNames = toolNames;
}
