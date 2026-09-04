# Gates

Use targeted checks while debugging, then run the full relevant gate before handoff.

## Required Checks

- `scripts/check-flake-lock-owners.sh`
- selector tests
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

## CI Verification

After pushing maintainer fixes, verify the GitHub Actions run for the pushed commit.

Never say you will keep polling unless a blocking poll is already running. If reporting a poll, name the active run or local polling session.

If CI fails, inspect the failing run, classify the failure, fix what belongs to `nix-openclaw`, and rerun until green or until the exact external blocker is proven.
