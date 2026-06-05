{
  callPackage,
  sourceInfo,
  openclawBundledAcpx ? null,
  gatewaySrc ? null,
  pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null),
  ...
}:

let
  useNpmPackage = gatewaySrc == null && sourceInfo ? gatewayNpmDepsHash;
in
if useNpmPackage then
  callPackage ./openclaw-gateway-npm.nix {
    inherit sourceInfo openclawBundledAcpx;
  }
else
  callPackage ./openclaw-gateway-source.nix {
    inherit sourceInfo gatewaySrc pnpmDepsHash;
  }
