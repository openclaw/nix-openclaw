# Gates

Use targeted checks while debugging, then run the full relevant gate before handoff.

## Required Checks

- `scripts/check-flake-lock-owners.sh`
- `nix fmt -- --ci`
- JavaScript contracts on the pinned Node 24 runtime: `node --test scripts/*.test.mjs maintainers/scripts/*.test.mjs nix/scripts/*.test.mjs nix/scripts/*.test.js`
- Private pnpm runtime check (`checks.<system>.pnpm-runtime`, included in `package-artifacts`): offline local-tarball install, package execution, and frozen-lockfile rejection for both supported private pnpm majors
- updater shell syntax
- workflow YAML parse
- `nix flake show --accept-flake-config`
- Linux supported surface:
  `checks.x86_64-linux.package-artifacts`, `module-render` including
  `source-override-render`, `runtime-smoke`, `platform-activation`,
  `runtime-plugin-packages`, `runtime-plugin-host`, and `qmd-opt-in`
- Darwin supported surface when available:
  `checks.aarch64-darwin.package-artifacts`, `module-render` including
  `source-override-render`, `runtime-smoke`, `platform-activation`,
  `runtime-plugin-packages`, `runtime-plugin-host`, and `qmd-opt-in`
- `scripts/hm-activation-macos.sh` when a macOS runner is available
- `scripts/check-macos-app.sh`: preserve upstream signed bytes/symlinks and verify the universal app signature

Run contract tests inside `nix develop` to select the pinned Node, Bash, and Git.
CI selects those same packages with `nix shell` on both Linux and macOS.

Gateway smoke checks allow up to 90 seconds for cold startup, including state
worker initialization, and still require a successful authenticated health probe.

The provenance job also gates maintainer and same-repository authorization; the
platform jobs depend on it. Linux and macOS 27 (`xcode-27`) retain all supported-surface
checks. The historical installed-baseline qualification still verifies Node 22
from its pinned historical package; current packaging contracts use Node 24.

## CI Verification

After pushing maintainer fixes, verify the GitHub Actions run for the pushed commit.

Never say you will keep polling unless a blocking poll is already running. If reporting a poll, name the active run or local polling session.

If CI fails, inspect the failing run, classify the failure, fix what belongs to `nix-openclaw`, and rerun until green or until the exact external blocker is proven.

Darwin CI uses Apple Silicon `xcode-27` runners. Nix continues to supply the SDK and deployment targets from the unchanged flake lock; the upstream signed app is copied unchanged. No Intel hardware job or Xcode pin is needed.
