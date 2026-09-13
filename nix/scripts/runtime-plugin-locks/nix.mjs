import path from "node:path";
import { renderPackageLockProbeEnv } from "../openclaw-runtime-plugin-package-locks.mjs";
import { attrNameForId } from "./catalog.mjs";
import { run, runWithRetries } from "./io.mjs";
import { nixString, toNix } from "./output.mjs";

export function createNixTools({ repoRoot, sourceInfoPath, prepareNpmScriptPath }) {
  let prefetchNpmDepsBin = null;

  function resolveOpenClawSourcePath() {
    const strippedAttrs = [
      "pnpmDepsHash",
      "gatewayNpmDepsHash",
      "pnpmMajor",
      "releaseTag",
      "releaseVersion",
      "runtimePluginVersion",
      "applyPublicSurfaceHardlinksPatch",
      "applySkipPluginAutoEnableNixModePatch",
      "applyNixStorePluginOwnershipPatch",
      "publicSurfaceHardlinksPatch",
      "fsSafeSource",
    ];
    const expr = `
      let
        flake = builtins.getFlake ${nixString(repoRoot)};
        pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
        sourceInfo = import (/. + ${nixString(sourceInfoPath)});
        sourceFetch = builtins.removeAttrs sourceInfo ${toNix(strippedAttrs)};
      in
        pkgs.fetchFromGitHub sourceFetch
    `;
    return run("nix", [
      "build",
      "--no-link",
      "--print-out-paths",
      "--impure",
      "--expr",
      expr,
    ]).trim().split(/\r?\n/).pop();
  }

  function resolvePrefetchNpmDepsBin() {
    if (prefetchNpmDepsBin) {
      return prefetchNpmDepsBin;
    }
    const expr = `
      let
        flake = builtins.getFlake ${nixString(repoRoot)};
        pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
      in
        pkgs.prefetch-npm-deps
    `;
    const outPath = run("nix", [
      "build",
      "--no-link",
      "--print-out-paths",
      "--impure",
      "--expr",
      expr,
    ]).trim().split(/\r?\n/).pop();
    prefetchNpmDepsBin = path.join(outPath, "bin/prefetch-npm-deps");
    return prefetchNpmDepsBin;
  }

  function computeNpmDepsHash(shrinkwrapPath) {
    const output = runWithRetries(
      resolvePrefetchNpmDepsBin(),
      [shrinkwrapPath],
      { attempts: 3, retryDelayMs: 1000 },
    ).trim();
    const hash = output.split(/\r?\n/).findLast((line) => line.startsWith("sha256-"));
    if (!hash) {
      throw new Error(`prefetch-npm-deps did not return an SRI hash for ${shrinkwrapPath}`);
    }
    return hash;
  }

  function prepareLockedPackage(packageRoot, artifact, dependencyMode = "shrinkwrap", packageLockFile = "") {
    run(process.execPath, [prepareNpmScriptPath], {
      cwd: packageRoot,
      env: {
        ...process.env,
        OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE: dependencyMode,
        OPENCLAW_RUNTIME_PLUGIN_PACKAGE_LOCK_FILE: packageLockFile,
        OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME: artifact.packageName,
        OPENCLAW_RUNTIME_PLUGIN_VERSION: artifact.version,
      },
    });
  }

  function probeLockMaterialization(row, artifact, npmDepsHash, dependencyMode = "shrinkwrap", packageLockFile = "") {
    const packageLockEnv = renderPackageLockProbeEnv(packageLockFile);
    const safeProbeName = attrNameForId(row.id);
    const expr = `
      let
        flake = builtins.getFlake ${nixString(repoRoot)};
        pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
        npmHooksForNode = pkgs.npmHooks.override { nodejs = pkgs.nodejs_24; };
        prepareNpmScript = /. + ${nixString(prepareNpmScriptPath)};
        pluginSrc = pkgs.fetchurl {
          url = ${nixString(artifact.tarballUrl)};
          hash = ${nixString(artifact.nixHash)};
        };
      in
        pkgs.stdenvNoCC.mkDerivation {
          pname = ${nixString(`openclaw-runtime-plugin-${safeProbeName}-materialization-probe`)};
          version = ${nixString(artifact.version)};
          src = pluginSrc;
          sourceRoot = "package";
          nativeBuildInputs = [
            pkgs.nodejs_24
            pkgs.nodejs_24.python
            npmHooksForNode.npmConfigHook
          ] ++ pkgs.lib.optionals pkgs.stdenvNoCC.hostPlatform.isDarwin [
            pkgs.cctools
          ];
          npmDeps = pkgs.fetchNpmDeps {
            name = ${nixString(`openclaw-runtime-plugin-${safeProbeName}-npm-deps`)};
            src = pluginSrc;
            sourceRoot = "package";
            hash = ${nixString(npmDepsHash)};
            nativeBuildInputs = [ pkgs.nodejs_24 ];
            OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE = ${nixString(dependencyMode)};
            ${packageLockEnv}
            OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME = ${nixString(artifact.packageName)};
            OPENCLAW_RUNTIME_PLUGIN_VERSION = ${nixString(artifact.version)};
            postPatch = ''
              ${"\${pkgs.nodejs_24}"}/bin/node ${"\${prepareNpmScript}"}
            '';
          };
          npmInstallFlags = [
            "--omit=dev"
            "--omit=peer"
            "--legacy-peer-deps"
          ];
          npmRebuildFlags = [ "--ignore-scripts" ];
          dontConfigure = true;
          dontBuild = true;
          env = {
            OPENCLAW_RUNTIME_PLUGIN_ID = ${nixString(row.id)};
            OPENCLAW_RUNTIME_PLUGIN_PACKAGE_NAME = ${nixString(artifact.packageName)};
            OPENCLAW_RUNTIME_PLUGIN_VERSION = ${nixString(artifact.version)};
            OPENCLAW_RUNTIME_PLUGIN_DEPENDENCY_MODE = ${nixString(dependencyMode)};
            ${packageLockEnv}
          };
          postPatch = ''
            ${"\${pkgs.nodejs_24}"}/bin/node ${"\${prepareNpmScript}"}
          '';
          installPhase = ''
            mkdir -p "$out"
            cp package.json ${dependencyMode === "package-lock" ? "package-lock.json" : "npm-shrinkwrap.json"} "$out"/
          '';
        }
    `;
    run("nix", [
      "build",
      "--no-link",
      "--print-out-paths",
      "--impure",
      "--expr",
      expr,
    ]);
  }

  return { resolveOpenClawSourcePath, computeNpmDepsHash, prepareLockedPackage, probeLockMaterialization };
}
