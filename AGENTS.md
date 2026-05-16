# AGENTS.md - nix-openclaw

## PRs

We are not accepting PRs from non-maintainers. If your handle is not in the Maintainers list below or on https://github.com/orgs/openclaw/people, do not open a PR.

Describe your problem and talk with a maintainer human-to-human on Discord instead. Join https://discord.gg/clawd and use `#golden-path-deployments`.

## Maintainers

Source: https://github.com/orgs/openclaw/people

- @Asleep123
- @badlogic
- @bjesuiter
- @christianklotz
- @cpojer
- @Evizero
- @gumadeiras
- @joshp123
- @mbelinky
- @mukhtharcm
- @obviyus
- @onutc
- @pasogott
- @sebslight
- @sergiopesch
- @shakkernerd
- @steipete
- @Takhoffman
- @thewilloftheshadow
- @tyler6204
- @vignesh07

## Audience Routing

- Consumer agents installing or configuring OpenClaw: start with `README.md` and `templates/agent-first/flake.nix`.
- Maintainer agents changing packaging, release automation, pins, or CI: read `maintainers/AGENTS.md` first.
- Plugin authors: read `docs/plugins-maintainers.md` and `examples/hello-world-plugin/`.
- Private deployments, bots, hosts, local worktrees, tokens, and personal automation details do not belong in this public repo.

## Public Repo Rules

- `README.md` is the source of truth for product direction and user-facing behavior.
- Keep documentation surface area small. Update `README.md` first, then adjust references.
- Keep committed guidance about public `nix-openclaw` behavior, public upstream OpenClaw releases, public artifacts, and public CI.
- Keep consumer setup docs in `README.md`, templates, and module docs.
- Keep maintainer runbooks in `maintainers/`.
- Never add internal ExecPlans or agent scratch history to this repo. `.agent/` is ignored for this reason.
- If a private deployment exposes a public packaging bug, fix the public package here and keep deployment-specific repair elsewhere.
- OpenClaw plugin loading belongs here: package curated runtime plugin roots as Nix artifacts, expose curated outputs through package/check outputs for Garnix, and let host repos only enable/configure them.
- Do not make host config run npm/ClawHub installs at runtime for the batteries-included path. `customPlugins.source = "npm:..."` is allowed only when nix-openclaw turns it into an immutable, hash-backed store path and wires it through OpenClaw's normal `plugins.load.paths`.

## Packaging Defaults

- Nix-first, no sudo.
- Declarative config only.
- Batteries-included install is the baseline.
- Breaking changes are acceptable pre-1.0.0; no deprecations.
- No inline scripts or inline file contents in Nix code. Use repo scripts and explicit file paths.
- The gateway package must include Control UI assets.
- User-facing docs should lead with one package: `openclaw`. Treat `openclaw-gateway` and `openclaw-app` as component outputs for modules, checks, and debugging.
- QMD is the Nix-supported local memory backend. Keep `qmd` internal to the OpenClaw runtime PATH, and pull it into the closure only when users opt in with upstream config.

## Safety

- Never send messages, email, SMS, or other external communications without explicit confirmation showing the full message text.
- No force push. No destructive git operations unless explicitly requested.
- Before deleting tracked files, list them in the summary so maintainers can verify.
