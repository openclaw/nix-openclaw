{
  callPackage,
  sourceInfo,
  gatewaySrc ? null,
  pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null),
  ...
}:

let
  useNpmPackage =
    gatewaySrc == null && sourceInfo ? gatewayNpmDepsHash && sourceInfo ? acpxNpmDepsHash;
in
if useNpmPackage then
  callPackage ./openclaw-gateway-npm.nix {
    inherit sourceInfo;
  }
else
  callPackage ./openclaw-gateway-source.nix {
    inherit sourceInfo gatewaySrc pnpmDepsHash;
  }
