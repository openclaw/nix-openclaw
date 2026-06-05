{
  lib,
  stdenvNoCC,
  fetchurl,
  fetchNpmDeps,
  npmHooks,
  nodejs_22,
  cctools,
  openclawPackage,
}:

lock:

let
  runtimeEntries =
    (lock.runtimeExtensions or [ ])
    ++ lib.optional ((lock.runtimeSetupEntry or null) != null) lock.runtimeSetupEntry;
  runtimeEntriesFile = builtins.toFile "openclaw-runtime-plugin-${lock.id}-runtime-entries" (
    (lib.concatStringsSep "\n" runtimeEntries) + "\n"
  );
  shrinkwrapPathsFile = builtins.toFile "openclaw-runtime-plugin-${lock.id}-shrinkwrap-paths" (
    (lib.concatStringsSep "\n" (lock.bundledPackageRoots or [ ])) + "\n"
  );
  npmHooksForNode = npmHooks.override { nodejs = nodejs_22; };
  pluginSrc = fetchurl {
    url = lock.tarballUrl;
    hash = lock.nixHash;
  };
  dependencyMode = lock.dependencyMode or (if hasRuntimeDependencies then "bundled" else "none");
  isShrinkwrap = dependencyMode == "shrinkwrap";
  hasRuntimeDependencies =
    (lock.dependencies or { }) != { } || (lock.optionalDependencies or { }) != { };
  safeName = lib.replaceStrings [ "@" "/" ":" ] [ "" "-" "-" ] lock.id;
  packageName = "openclaw-runtime-plugin-${safeName}";

  drv = stdenvNoCC.mkDerivation ({
    pname = packageName;
    version = lock.version;

    src = pluginSrc;

    sourceRoot = "package";

    nativeBuildInputs =
      [ nodejs_22 ]
      ++ lib.optionals isShrinkwrap [
        nodejs_22.python
        npmHooksForNode.npmConfigHook
      ]
      ++ lib.optionals (isShrinkwrap && stdenvNoCC.hostPlatform.isDarwin) [ cctools ];

    npmInstallFlags = lib.optionals isShrinkwrap [
      "--omit=dev"
      "--omit=peer"
      "--legacy-peer-deps"
    ];

    npmRebuildFlags = lib.optionals isShrinkwrap [ "--ignore-scripts" ];

    dontConfigure = true;
    dontBuild = true;

    postPatch = lib.optionalString isShrinkwrap ''
      ${nodejs_22}/bin/node ${../scripts/openclaw-runtime-plugin-prepare-npm.mjs}
    '';

    env = {
      OPENCLAW_GATEWAY_PACKAGE = "${openclawPackage}";
      OPENCLAW_RUNTIME_PLUGIN_ID = lock.id;
      OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME = lock.packageName;
      OPENCLAW_RUNTIME_PLUGIN_VERSION = lock.version;
      OPENCLAW_RUNTIME_PLUGIN_RUNTIME_ENTRIES_FILE = runtimeEntriesFile;
      OPENCLAW_RUNTIME_PLUGIN_SHRINKWRAP_PATHS_FILE = shrinkwrapPathsFile;
      OPENCLAW_RUNTIME_PLUGIN_HAS_RUNTIME_DEPENDENCIES = if hasRuntimeDependencies then "1" else "0";
      OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE = dependencyMode;
    }
    // lib.optionalAttrs ((lock.openclawCompat or null) != null) {
      OPENCLAW_RUNTIME_PLUGIN_COMPAT = lock.openclawCompat;
    }
    // lib.optionalAttrs ((lock.peerOpenClaw or null) != null) {
      OPENCLAW_RUNTIME_PLUGIN_PEER_OPENCLAW = lock.peerOpenClaw;
    };

    installPhase = "${nodejs_22}/bin/node ${../scripts/openclaw-runtime-plugin-install.mjs}";

    passthru.openclawRuntimePlugin = {
      inherit (lock)
        id
        packageName
        version
        npmIntegrity
        ;
      source = lock.selectedSource or "npm";
      loadPath = drv;
    };

    meta = with lib; {
      description = "Nix-packaged OpenClaw runtime plugin ${lock.id}";
      homepage = "https://github.com/openclaw/openclaw";
      license = licenses.mit;
      platforms = platforms.darwin ++ platforms.linux;
    };
  } // lib.optionalAttrs isShrinkwrap {
    npmDeps = fetchNpmDeps {
      name = "${packageName}-npm-deps";
      src = pluginSrc;
      sourceRoot = "package";
      hash = lock.npmDepsHash;
      nativeBuildInputs = [ nodejs_22 ];
      OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE = "shrinkwrap";
      OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME = lock.packageName;
      OPENCLAW_RUNTIME_PLUGIN_VERSION = lock.version;
      postPatch = ''
        ${nodejs_22}/bin/node ${../scripts/openclaw-runtime-plugin-prepare-npm.mjs}
      '';
    };
  });
in
drv
