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
  pnpm_12 = pkgs.callPackage ./pnpm-12.nix { };
  pnpmByMajor = {
    "10" = pkgs.pnpm_10;
    "11" = pnpm_11;
    "12" = pnpm_12;
  };
  pnpmMajor = toString (sourceInfo.pnpmMajor or "10");
  pnpmForOpenClaw =
    pnpmByMajor.${pnpmMajor} or (throw "Unsupported OpenClaw pnpm major ${pnpmMajor}");
  toolPkgs = openclawToolPkgs // {
    pnpm = pnpmForOpenClaw;
    inherit pnpm_11 pnpm_12;
  };
  toolSets = import ../tools/extended.nix {
    pkgs = pkgs;
    openclawToolPkgs = toolPkgs;
    inherit toolNamesOverride excludeToolNames;
  };
  runtimePluginLocks = import ../generated/openclaw-runtime-plugins;
  buildBundledRuntimePlugin = pkgs.callPackage ../lib/openclaw-runtime-plugin.nix {
    linkOpenClawPeer = false;
  };
  bundledAcpx = buildBundledRuntimePlugin runtimePluginLocks.acpx;
  openclawGateway = pkgs.callPackage ./openclaw-gateway.nix {
    inherit sourceInfo;
    inherit pnpm_11 pnpm_12;
    inherit bundledAcpx;
  };
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
  inherit pnpm_11 pnpm_12;
  node-semver = pkgs.callPackage ./node-semver.nix { };
  inherit openclawRuntimePlugins;
  qmd = qmdPackage;
  openclaw-gateway = openclawGateway;
  openclaw = openclawBundle;
}
// (if isDarwin then { openclaw-app = openclawApp; } else { })
