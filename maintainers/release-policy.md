# Release Policy

`nix-openclaw` publishes one user-facing package, `openclaw`, with component outputs for maintainers and modules.

## Desired State

- `openclaw-gateway` tracks the newest stable upstream OpenClaw source release that satisfies the Nix package contract.
- `openclaw-app` tracks the newest stable upstream release that has a published public `OpenClaw-*.zip` app artifact.
- These tracks are independent. Source and app versions may differ.

## Non-Negotiables

- Do not hold back the source-built gateway because a newer source release lacks public macOS app assets.
- Do not treat source/app version mismatch as a failure.
- Do not make upstream's full Vitest suite a promotion gate; upstream owns source test health.
- Do verify the Nix-owned package contract: source build, generated config options, package contents, gateway smoke startup, module activation, and newest available public macOS app artifact.
- Do prefer the upstream `.zip` app artifact for `openclaw-app`, but verify the unpacked contents contain an `.app`.

## Freshness Check

The package is fresh only when both are true:

- `nix/sources/openclaw-source.nix` matches GitHub's newest stable OpenClaw source tag.
- `nix/packages/openclaw-app.nix` matches the newest stable public `OpenClaw-*.zip` app artifact.

If newer stable source releases lack public app assets, report that as an upstream app publishing miss and keep the app pin on the newest public zip.

## Mirrored Release Tags

A `v<OpenClaw version>` tag in `nix-openclaw` is a user-facing install target
for the complete Nix package state of that upstream OpenClaw version. It points
at a `nix-openclaw` commit, not at the upstream `openclaw/openclaw` commit.

Create a mirrored release tag only when all of these are true:

- `nix/sources/openclaw-source.nix` pins `releaseTag = "v<version>"`.
- `nix/packages/openclaw-app.nix` pins `version = "<version>"`.
- The app URL points at the matching upstream `OpenClaw-<version>.zip` asset.
- The generated config, runtime plugin locks, Nix patches, and package files for
  that package state are committed.
- Repository `CI` has passed on `main` for that exact commit, covering the Linux
  and macOS package contract.

Do not create a mirrored `v<OpenClaw version>` tag while source and app pins
diverge, while release generation is incomplete, or while CI is failing. App lag
can still be reported as upstream release-contract lag, but it is not a tagged
user-facing release.

Automation may create missing mirrored tags and lightweight GitHub Releases after
green `CI` on `main`. Generated release notes must link to the matching upstream
OpenClaw release so users can click through from the Nix package state to the
source release. New annotated tags should include the same upstream release URL
in the tag message.

Automation must not move an existing public tag. If a tag is wrong, a maintainer
decides whether it is still safe to delete/retag immediately or whether to
publish a corrective follow-up tag instead. If an upstream asset disappears or a
hash invalidates after a tag is published, repair the package state first; do
not move the public tag automatically.
