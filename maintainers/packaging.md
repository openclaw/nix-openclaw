# Packaging Invariants

This repo ships a working Nix package for OpenClaw users, not just a pin mirror.

## Product Surface

- The user-facing package is `openclaw`.
- `openclaw-gateway` is the source-built runnable gateway for Linux and macOS.
- `openclaw-app` is the Darwin-only desktop app from upstream's public app artifact.
- Component outputs exist for modules, checks, and debugging. They are not separate product tracks.
- `openclaw-dogfood` and `openclaw-gateway-dogfood` are temporary maintainer
  artifacts for testing a specific upstream commit before the next stable
  release. They must not become the documented consumer default.
- Do not split the repo into separate desktop and server tracks.

## Nix Ownership

- OpenClaw owns product and runtime behavior.
- `nix-openclaw` owns batteries-included Nix packaging, Home Manager/NixOS/Darwin modules, runtime PATH/env injection, launchd/systemd wiring, and package-contract checks.
- `nix-openclaw-tools` owns packaging OpenClaw-adjacent CLI tools and plugin metadata. Consume it here; do not duplicate its package definitions here.
- Downstream system repos should only choose hosts, secrets, accounts, and enabled plugins. If downstream needs bespoke scripts to make a plugin or harness work, prefer fixing this repo or `nix-openclaw-tools`.
- Nix mode means Nix owns `openclaw.json`.
- Runtime config mutation belongs upstream in OpenClaw. Downstream patches here must be small, temporary, and removed after the pinned upstream release contains the fix.
- Generated config options come from the upstream core schema.
- Plugin-owned extension surfaces, such as `channels.<plugin-id>`, must remain accepted by the Home Manager module even when core does not type every plugin key.
- Runtime tool injection belongs here. If a plugin or battery is enabled, the active OpenClaw harness must see its CLI tools and required environment without asking downstream to expose those tools globally on the user PATH.
- OpenClaw plugin roots belong here too. The Home Manager module consumes `openclawPlugin.plugins` declarations from plugin flakes and writes `plugins.load.paths` plus default `plugins.entries.<id>.enabled` values into the generated config.
- Raw npm/ClawHub plugin names are not batteries-included deployment config. Curated plugins packaged here must be exposed through packages/checks so CI/Garnix caches them. Arbitrary user specs need a deterministic lock/hash-backed Nix builder so Nix reuses the user's store/cache and only rebuilds when the spec, lock, or hash changes.

## Build Contract

- The gateway package must include Control UI assets.
- No inline scripts or inline file contents in Nix code. Use repo scripts and explicit file paths.
- Keep runtime tools internal to the `openclaw` wrapper unless they are intentionally part of the public package surface.
- QMD is the Nix-supported batteries-included local memory backend. Keep `qmd` internal to the `openclaw` wrapper PATH; users opt in with upstream config.
- ACPX is the first bundled OpenClaw plugin proof. It is consumed from OpenClaw's built `dist-runtime/extensions/acpx` tree, not installed or repaired by npm at runtime.
- Keep files under 400 lines unless a maintainer explicitly accepts the larger file.

## Investigations

### mcporter and QMD

- `mcporter` is an OpenClaw-owned optional MCP/CLI bridge, not a QMD requirement.
- OpenClaw defaults to direct `qmd` CLI execution. Keep that as the Nix-supported baseline until measured startup or per-query overhead proves otherwise.
- Package `mcporter` in `nix-openclaw-tools` as an optional tool when needed, but do not add it to the default `openclaw` runtime PATH just because QMD is bundled.
- If `memory.qmd.mcporter.enabled = true`, nix-openclaw should make `mcporter` visible to that instance and require the matching mcporter server config for `qmd mcp`.
