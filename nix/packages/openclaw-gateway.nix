{
  callPackage,
  sourceInfo,
  gatewaySrc ? null,
  pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null),
  pnpm_11 ? callPackage ./pnpm-11.nix { },
  pnpm_12 ? callPackage ./pnpm-12.nix { },
  bundledAcpx ? null,
  ...
}:

let
  useNpmPackage = gatewaySrc == null && sourceInfo ? gatewayNpmDepsHash && bundledAcpx != null;
in
if useNpmPackage then
  callPackage ./openclaw-gateway-npm.nix {
    inherit sourceInfo bundledAcpx;
  }
else
  callPackage ./openclaw-gateway-source.nix {
    inherit
      sourceInfo
      gatewaySrc
      bundledAcpx
      pnpmDepsHash
      pnpm_11
      pnpm_12
      ;
  }
