---
written_by: ai
---

# Performance Audit

Commit-tied metrics for packaging and CI changes. Keep this file short: current
snapshot, decision-relevant history, and exact commands. Raw logs belong in
GitHub Actions, local `/tmp` captures, or ignored `.agent/` notes.

## Current Snapshot

- Compared refs:
  - pre-#101 baseline: `d69b1fc1e736bbe78b46bd886fcc1791b5b9d942`
  - current main: `4f0a37d3068f6b98e7da1fa26014b2ba72342d00`
  - PR #100 remote head before this slice:
    `4db66bdb2ced44fcf4e476cb30afdde7e09dc5c1`
  - this slice local head: `416fe6288f74e7e1cfc2607378fea0040601e602`
- PR #100 now merges current `main` so it is mergeable. The #101 overlap is
  intentionally replaced: Garnix no longer references the deleted `ci` aggregate
  and remains a small cache-publication target set.
- Product change: stable `openclaw-gateway` uses the upstream npm package and
  `npm-shrinkwrap.json` through `buildNpmPackage`; source/pnpm remains available
  for explicit `gatewayPath` source overrides.

| Metric | main | PR #100 | Change | Command |
| --- | ---: | ---: | ---: | --- |
| Gateway closure | 2,273,877,888 B | 904,981,328 B | 60.2% smaller | `nix path-info -S "$gateway"` |
| `openclaw` closure | 3,215,431,032 B | 1,846,534,464 B | 42.6% smaller | `nix path-info -S "$openclaw"` |
| Gateway output | 2,169,012,224 B | 339,697,664 B | 84.3% smaller | `du -sk "$gateway"` |
| Package manifests | 1,452 | 541 | 62.7% fewer | `find "$gateway/lib/openclaw" -name package.json \| wc -l` |
| Files under `lib/openclaw` | 97,909 | 32,840 | 66.5% fewer | `find "$gateway/lib/openclaw" -type f \| wc -l` |
| Gateway forced rebuild | 399.37s then Nix determinism failure | 56.27s success | deterministic npm path | `/usr/bin/time -p nix build --rebuild --no-link <ref>#packages.aarch64-darwin.openclaw-gateway` |
| Garnix include targets | 10 | 5 | 50.0% fewer | `ruby -e 'require "yaml"; ...'` |

## CI Proof Shape

GitHub Actions now has three jobs:

| Job | Proves | Notes |
| --- | --- | --- |
| `flake-input-provenance` | `flake.lock` owner policy | Runs before any package build; no Nix build graph. |
| `linux-supported-surface` | Linux package, module, runtime, activation, plugin, and QMD surface | One Nix invocation to avoid repeated setup/substitution work. |
| `macos-supported-surface` | Darwin package, module, runtime, activation, plugin, and QMD surface | Builds the activation package, then applies it through `scripts/hm-activation-macos.sh`. |

Supported-surface attrs:

- `package-artifacts`
- `module-render` including `source-override-render`
- `runtime-smoke`
- `platform-activation`
- `runtime-plugin-packages`
- `runtime-plugin-host`
- `qmd-opt-in`

Deleted surface:

- `checks.<system>.ci`
- `packages.<system>.openclaw-dogfood`
- `packages.<system>.openclaw-gateway-dogfood`
- `checks.<system>.package-contents-dogfood`

## Current Local Proof

| Proof | Result | Notes |
| --- | --- | --- |
| Workflow/Garnix YAML parse | pass | `.github/workflows/ci.yml`, pin workflow, `garnix.yaml` |
| `git diff --check` | pass | No whitespace errors. |
| Darwin supported surface, cold local pass | pass, 288s | 42 planned/built derivations; runtime plugin catalog dominated cost. |
| Darwin supported surface, post-merge warm pass | pass, 28s | 0 planned/built derivations; validates the mergeable head uses the cached supported surface. |
| Darwin `source-override-render` | pass | Catches `gatewayPath` module/source builder wiring. |
| Linux supported surface dry-run | pass | 58 planned derivations, including `openclaw-source-override-instance`. |
| Linux `source-override-render` dry-run | pass | Verifies source-override attr resolves on Linux. |

## Decisions

| Slice | Decision | Evidence |
| --- | --- | --- |
| npm default package | Accepted | Gateway closure 60.2% smaller; output 84.3% smaller; forced rebuild succeeds instead of failing determinism. |
| dogfood outputs | Removed | Dogfood was a temporary maintainer track, not part of the intended product contract. Use explicit source overrides instead. |
| `ci` aggregate | Removed | The name hid unrelated proof obligations. Named attrs expose what is proven. |
| supported-surface CI | Accepted | One platform job per OS builds all supported attrs in one Nix invocation, avoiding matrix/setup duplication. |
| source override | Render proof retained | `gatewayPath` is dev-only; CI proves module/source-builder wiring without reintroducing a full pnpm source build. |
| Garnix | Cache publication only | Garnix is sunset risk. GitHub Actions owns proof; Garnix keeps a small package/cache target set. |
| larger runners / machine images | Excluded | Provider tuning may help cold start, but does not simplify the Nix graph or prove downstream install behavior. |
| Magic Nix Cache | Rejected | Remote experiment made Linux slower and blocked macOS proof startup. |

## Reproduction Commands

```bash
ruby -e 'require "yaml"; ARGV.each { |p| YAML.load_file(p) }; puts "yaml ok"' \
  .github/workflows/ci.yml .github/workflows/pin-stable-openclaw-version.yml garnix.yaml
git diff --check

nix eval --accept-flake-config --json .#checks.aarch64-darwin --apply 'c: builtins.attrNames c'
nix eval --accept-flake-config --json .#checks.x86_64-linux --apply 'c: builtins.attrNames c'

maintainers/scripts/ci-nix-build.sh local-macos-supported-surface-current \
  --accept-flake-config --option max-jobs 2 --no-link \
  .#checks.aarch64-darwin.package-artifacts \
  .#checks.aarch64-darwin.module-render \
  .#checks.aarch64-darwin.runtime-smoke \
  .#checks.aarch64-darwin.platform-activation \
  .#checks.aarch64-darwin.runtime-plugin-packages \
  .#checks.aarch64-darwin.runtime-plugin-host \
  .#checks.aarch64-darwin.qmd-opt-in

nix build --accept-flake-config --dry-run --no-link \
  .#checks.x86_64-linux.package-artifacts \
  .#checks.x86_64-linux.module-render \
  .#checks.x86_64-linux.runtime-smoke \
  .#checks.x86_64-linux.platform-activation \
  .#checks.x86_64-linux.runtime-plugin-packages \
  .#checks.x86_64-linux.runtime-plugin-host \
  .#checks.x86_64-linux.qmd-opt-in
```
