{
  pkgs,
  sourceInfo ? import ../sources/openclaw-source.nix,
  openclawToolPkgs ? { },
  qmdPackage ? null,
  toolNamesOverride ? null,
  excludeToolNames ? [ ],
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  pnpm_11 = pkgs.callPackage ./pnpm-11.nix { };
  pnpmForOpenClaw = if toString (sourceInfo.pnpmMajor or "10") == "11" then pnpm_11 else pkgs.pnpm_10;
  toolPkgs = openclawToolPkgs // {
    pnpm = pnpmForOpenClaw;
    inherit pnpm_11;
  };
  toolSets = import ../tools/extended.nix {
    pkgs = pkgs;
    openclawToolPkgs = toolPkgs;
    inherit toolNamesOverride excludeToolNames;
  };
  openclawGateway = pkgs.callPackage ./openclaw-gateway.nix {
    inherit sourceInfo;
    inherit pnpm_11;
  };
  runtimePluginLocks = import ../generated/openclaw-runtime-plugins;
  buildOpenClawRuntimePlugin = pkgs.callPackage ../lib/openclaw-runtime-plugin.nix {
    openclawPackage = openclawGateway;
  };
  openclawRuntimePlugins = pkgs.lib.mapAttrs (
    _name: lock: buildOpenClawRuntimePlugin lock
  ) runtimePluginLocks;
  openclawApp = if isDarwin then pkgs.callPackage ./openclaw-app.nix { } else null;
  openclawBundle = pkgs.callPackage ./openclaw-batteries.nix {
    openclaw-gateway = openclawGateway;
    openclaw-app = openclawApp;
    extendedTools = toolSets.tools;
    version = sourceInfo.releaseVersion or null;
  };
in
{
  inherit pnpm_11;
  inherit openclawRuntimePlugins;
  openclaw-gateway = openclawGateway;
  openclaw = openclawBundle;
}
// (if qmdPackage != null then { qmd = qmdPackage; } else { })
// (if isDarwin then { openclaw-app = openclawApp; } else { })
