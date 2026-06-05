{
  callPackage,
  sourceInfo,
  gatewaySrc ? null,
  pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null),
  bundledAcpx ? null,
  ...
}:

let
  useNpmPackage =
    gatewaySrc == null && sourceInfo ? gatewayNpmDepsHash && bundledAcpx != null;
in
if useNpmPackage then
  callPackage ./openclaw-gateway-npm.nix {
    inherit sourceInfo bundledAcpx;
  }
else
  callPackage ./openclaw-gateway-source.nix {
    inherit sourceInfo gatewaySrc pnpmDepsHash;
  }
