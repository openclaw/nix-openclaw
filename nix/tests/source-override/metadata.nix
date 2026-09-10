{ lib }:
let
  stable = import ../../sources/openclaw-source.nix;
  manifest = builtins.fromJSON (builtins.readFile ./fixture/package.json);
  select =
    package: extra:
    import ../../lib/openclaw-gateway-source-info.nix {
      sourceInfo = stable // extra;
      manifest = package;
      supportedPnpmMajors = [
        "10"
        "11"
        "12"
      ];
    };
  expectFailure =
    value:
    !(builtins.tryEval (builtins.deepSeq value true)).success;
  customPatch = ../../patches/allow-nix-store-plugin-ownership-cached.patch;
  tool = major: {
    __toString = _: "pnpm-${major}";
    version = "${major}.0.0";
  };
  common = import ../../lib/openclaw-gateway-common.nix {
    inherit lib;
    stdenv.hostPlatform.node = {
      platform = "linux";
      arch = "x64";
    };
    fetchFromGitHub = args: args;
    fetchurl = _: throw "metadata must not fetch dependencies";
    fetchPnpmDeps = args: args;
    nodejs_24 = "node";
    pnpm_10 = tool "10";
    pnpm_11 = tool "11";
    pnpm_12 = tool "12";
    pkg-config = null;
    jq = null;
    python3 = null;
    node-gyp = null;
    git = null;
    zstd = null;
  };
  sourcePackage = common {
    pname = "openclaw-gateway";
    sourceInfo = stable;
    gatewaySrc = ./fixture;
  };
  stablePackage = common {
    pname = "openclaw-gateway";
    sourceInfo = stable // {
      nixStorePluginOwnershipPatch = customPatch;
    };
  };
  npmDispatch = import ../../packages/openclaw-gateway.nix {
    sourceInfo = stable;
    bundledAcpx = "fixture-acpx";
    gatewaySrc = null;
    callPackage =
      file: _:
      if file == ../../packages/openclaw-gateway-npm.nix then
        "npm"
      else
        throw "default package forced the source builder";
  };
  cases = [
    (npmDispatch == "npm")
    (stablePackage.pnpmMajor == stable.pnpmMajor)
    (!(stablePackage.resolvedSrc ? nixStorePluginOwnershipPatch))
    (sourcePackage.pnpmMajor == "12")
    (sourcePackage.version == "2026.9.3")
    (sourcePackage.passthru.pinnedRev == null)
    (!(sourcePackage.passthru.sourceInfo ? rev))
    (!(sourcePackage.passthru.sourceInfo ? hash))
    (sourcePackage.env.PATCH_NIX_STORE_PLUGIN_OWNERSHIP == toString customPatch)
    (sourcePackage.pnpmDeps.pnpm.version == "12.0.0")
    (sourcePackage.pnpmDeps.src == ./fixture)
    (
      (select {
        version = "2026.7.1";
        packageManager = "pnpm@11.2.2+sha512.fixture";
      } { }).nixStorePluginOwnershipPatch
      == ../../patches/allow-nix-store-plugin-ownership.patch
    )
    (expectFailure (select null { }))
    (expectFailure (select { version = "2026.9.3"; } { }))
    (expectFailure (select (manifest // { version = null; }) { }))
    (expectFailure (select (manifest // { version = "unaudited"; }) { }))
    (expectFailure (select manifest { nixStorePluginOwnershipPatch = ""; }))
    (
      (select (manifest // { version = "unaudited"; }) {
        nixStorePluginOwnershipPatch = customPatch;
        applyNixStorePluginOwnershipPatch = false;
        applyPublicSurfaceHardlinksPatch = true;
      }).applyNixStorePluginOwnershipPatch
    )
  ]
  ++ lib.concatMap
    (
      public:
      map
        (
          autoEnable:
          let
            selected = select (manifest // { version = "unaudited"; }) {
              nixStorePluginOwnershipPatch = customPatch;
              applyPublicSurfaceHardlinksPatch = public;
              applySkipPluginAutoEnableNixModePatch = autoEnable;
            };
          in
          selected.applyPublicSurfaceHardlinksPatch == public
          && selected.applySkipPluginAutoEnableNixModePatch == autoEnable
        )
        [
          false
          true
        ]
    )
    [
      false
      true
    ]
  ++ map
    (manager: expectFailure (select (manifest // { packageManager = manager; }) { }))
    [
      null
      12
      ""
      "npm@12.3.4"
      "pnpm@12"
      "pnpm@12.3"
      "pnpm@^12.3.4"
      "pnpm@13.0.0"
    ]
  ++ map
    (major: (select (manifest // { packageManager = "pnpm@${major}.0.0"; }) { }).pnpmMajor == major)
    [
      "10"
      "11"
      "12"
    ];
in
assert builtins.all (value: value) cases;
"ok"
