{
  sourceInfo,
  manifest,
  supportedPnpmMajors,
}:

let
  packageManager = manifest.packageManager or null;
  managerMatch =
    if builtins.isString packageManager then
      builtins.match "pnpm@([0-9]+)\\.[0-9]+\\.[0-9]+(\\+[A-Za-z0-9.]+)?" packageManager
    else
      null;
  pnpmMajor =
    if managerMatch == null then
      throw "OpenClaw source package.json must declare an exact pnpm packageManager version."
    else
      builtins.head managerMatch;
  version = manifest.version or null;
  # These profiles cover 7.1-2 source 0790d9f and 9.3 source 1391f7c only.
  # A declared version selects patch context; it does not attest Git provenance.
  ownershipPatches = {
    "2026.7.1" = ../patches/allow-nix-store-plugin-ownership.patch;
    "2026.9.3" = ../patches/allow-nix-store-plugin-ownership-cached.patch;
  };
  ownershipPatch =
    sourceInfo.nixStorePluginOwnershipPatch
      or (ownershipPatches.${version}
        or (throw "Unaudited OpenClaw source version ${version}: supply a reviewed sourceInfo.nixStorePluginOwnershipPatch."));
in
if !builtins.isAttrs manifest then
  throw "OpenClaw source package.json must be an object."
else if !builtins.isString version || version == "" then
  throw "OpenClaw source package.json must declare its version."
else if !builtins.elem pnpmMajor supportedPnpmMajors then
  throw "Unsupported OpenClaw pnpm major ${pnpmMajor}"
else if
  !(builtins.isPath ownershipPatch || (builtins.isString ownershipPatch && ownershipPatch != ""))
then
  throw "OpenClaw source ownership patch must be a nonempty path."
else
  # gatewayPath replaces the source, not only its bytes. Never report the stable
  # revision/hash or reuse its dependency hash for an unrelated local checkout.
  builtins.removeAttrs sourceInfo [
    "owner"
    "repo"
    "rev"
    "hash"
    "pnpmDepsHash"
    "gatewayNpmDepsHash"
    "releaseTag"
  ]
  // (
    if builtins.hasAttr version ownershipPatches then
      {
        applyPublicSurfaceHardlinksPatch = false;
        applySkipPluginAutoEnableNixModePatch = false;
      }
    else
      { }
  )
  // {
    inherit pnpmMajor;
    releaseVersion = version;
    runtimePluginVersion = version;
    applyNixStorePluginOwnershipPatch = true;
    nixStorePluginOwnershipPatch = ownershipPatch;
  }
