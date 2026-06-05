# RFC 1: OpenClaw Catalog Runtime Plugins in nix-openclaw

- Date: 2026-05-29
- Status: Draft
- Audience: OpenClaw and nix-openclaw maintainers

## Decision

Support OpenClaw runtime plugins by OpenClaw plugin id, not by install source.

Users write:

```nix
programs.openclaw.runtimePlugins = [
  "slack"
  "discord"
];
```

They do not write `npm:@openclaw/slack`, `clawhub:@openclaw/whatsapp`, or an
OpenClaw mutable install command in Nix config.

nix-openclaw reads the pinned OpenClaw source catalogs, decides which catalog
rows it can build reproducibly, generates checked-in locks for those rows, and
renders normal OpenClaw config:

```json
{
  "plugins": {
    "load": {
      "paths": [
        "/nix/store/...-openclaw-runtime-plugin-slack"
      ]
    },
    "entries": {
      "slack": { "enabled": true }
    }
  }
}
```

Runtime settings stay in upstream OpenClaw config:

```nix
programs.openclaw = {
  runtimePlugins = [ "slack" ];

  config.channels.slack = {
    enabled = true;
    appToken.source = "env";
    appToken.provider = "env";
    appToken.id = "SLACK_APP_TOKEN";
    botToken.source = "env";
    botToken.provider = "env";
    botToken.id = "SLACK_BOT_TOKEN";
  };
};
```

That is the whole user model:

- `runtimePlugins` selects supported OpenClaw runtime plugin ids.
- `programs.openclaw.config` configures OpenClaw runtime behavior.

Unsupported ids are rejected by Nix evaluation. The generated report is
maintainer machinery for deciding which builder gap to fix next.

## Why This Exists

OpenClaw moved integrations such as Slack out of the gateway core and into
runtime plugins. Mutable OpenClaw users can recover by running:

```bash
openclaw plugins install @openclaw/slack
```

That is not acceptable as the nix-openclaw source of truth.

In Nix mode:

- Home Manager activation must not resolve packages or mutate plugin install
  state;
- user builds must not follow `latest`, dist-tags, semver ranges, npm
  registry state, or ClawHub discovery state;
- rollback must not leave stale mutable install receipts claiming removed
  plugins are still installed;
- OpenClaw should load the same runtime plugin shape it normally loads, but
  from Nix-built roots selected declaratively.

The Slack bug is therefore a missing declarative catalog path, not a special
Slack fix.

## One Model

The only supported user selector is an OpenClaw plugin id:

```nix
programs.openclaw.runtimePlugins = [ "slack" ];
```

That id must come from the pinned OpenClaw catalogs and must have a generated
nix-openclaw lock. Source strings such as `npm:...`, `clawhub:...`, git paths,
local paths, archives, and marketplace references are not accepted here.

npm, ClawHub, tarballs, bundled dependencies, and dependency materialization are
not user-facing plugin types. They are only internal facts the lock generator
uses while trying to turn an OpenClaw catalog id into an immutable Nix store
plugin root:

```text
pinned OpenClaw catalog id
  -> selected artifact source from catalog metadata
  -> checked-in nix-openclaw lock, or explicit skip reason
  -> immutable /nix/store plugin root
  -> plugins.load.paths + plugins.entries.<id>.enabled
  -> upstream OpenClaw loader
```

A catalog id is supported when it has a generated lock and builds a valid
plugin root. Otherwise it is unsupported until nix-openclaw can build that same
catalog id immutably. The reason belongs in the generated maintainer report, not
in the user model.

Example: `whatsapp` is not a "ClawHub plugin" in nix-openclaw docs. It is the
OpenClaw catalog id `whatsapp`. When the generator can materialize the
catalog-selected ClawHub artifact, the user config is:

```nix
programs.openclaw.runtimePlugins = [ "whatsapp" ];
```

If a future catalog artifact cannot be materialized yet, the same rule applies:
maintainers fix the generated lock path or upstream package artifact, and users
do not switch to a source-specific Nix API.

## Admission Rule

nix-openclaw has one admission test for runtime plugin support:

- input: one row from the pinned OpenClaw catalogs;
- output: either one checked-in Nix lock plus package, or one explicit generated
  failure reason;
- invariant: user builds, evaluation, activation, and runtime never resolve
  packages, run npm/pnpm/yarn/corepack, call `openclaw plugins install`, or
  fetch the network.

This removes the old hand-maintained four-plugin list as the support authority.
The support authority becomes generated lock data plus
`nix/generated/openclaw-runtime-plugins/report.json`.

The lock generator may need source-specific code internally, but those code
paths are implementation detail behind the same admission test. Fixing one
generator limitation may make one catalog id or many catalog ids supported; it
must not create new user syntax or a parallel plugin model.

The report is the engineering queue, not a product model.

## Pinning Policy

The root of trust is:

```nix
nix/sources/openclaw-source.nix
```

For OpenClaw-owned catalog rows, nix-openclaw uses the pinned OpenClaw
`releaseVersion`. If OpenClaw is pinned to:

```nix
releaseVersion = "2026.5.27";
```

then `slack` resolves to `@openclaw/slack@2026.5.27`, not
`@openclaw/slack@latest`.

The lock updater may use the network because it is a maintainer command that
refreshes checked-in lock data. User evaluation, build, activation, and runtime
must consume checked-in locks and Nix store artifacts only.

Do not silently widen this rule. A catalog id is supported only when the lock
records exact artifact identity, integrity, dependency mode, runtime entry, and
OpenClaw compatibility evidence.

## What nix-openclaw Renders

For each Home Manager instance, nix-openclaw computes selected runtime plugin
ids. Instance-level `runtimePlugins` replaces the top-level list.

For each selected id, nix-openclaw:

- adds the Nix store plugin root to `plugins.load.paths`;
- sets `plugins.entries.<id>.enabled = true`;
- merges the id into `plugins.allow` only when the user already configured a
  restrictive allowlist.

It is a Nix evaluation error to:

- select an unsupported id;
- list the same id twice;
- select a runtime plugin id that collides with a nix-openclaw plugin id;
- select an id and also set `plugins.entries.<id>.enabled = false`;
- select an id and also list it in `plugins.deny`;
- mix `runtimePlugins` with raw user-authored `plugins.load.paths` in the same
  instance;
- write `plugins.installs` in rendered user config.

The raw `plugins.load.paths` restriction keeps the source of truth unambiguous:
selected ids come from generated Nix locks, not from arbitrary user-authored
runtime paths.

## Why Not Pretend Installation Happened?

Because OpenClaw install receipts are mutable state, not the declarative
runtime contract Nix should own.

| Option | Verdict |
| --- | --- |
| Build immutable plugin roots and render `plugins.load.paths` plus enabled entries. | Selected. It uses OpenClaw's real loader and keeps Nix as source of truth. |
| Run `openclaw plugins install` during Home Manager activation. | Reject. Activation would mutate state and depend on live network/package-manager behavior. |
| Write `$OPENCLAW_STATE_DIR/plugins/installs.json`. | Reject. Rollback would not roll back the mutable receipt. Stale records can claim removed plugins still exist. |
| Write `plugins.installs` into `openclaw.json`. | Reject. This is OpenClaw internal command-flow state, not public declarative API. |
| Ask users to choose `npm:` or `clawhub:` for OpenClaw catalog ids. | Reject. It leaks transport details and bypasses the pinned catalog policy. |

If OpenClaw later adds a first-class read-only provenance input for Nix-managed
plugins, use it for better diagnostics. It is not required for the core loading
model as long as load paths, enabled entries, registry isolation, and status
proof gates pass.

## Implementation Work

The implementation has four moving pieces:

1. Scan the pinned OpenClaw catalogs.
2. Generate lock files and one report covering every catalog id.
3. Expose package outputs from generated locks.
4. Render `runtimePlugins` as OpenClaw load paths and enabled entries.

The maintenance loop is also one path:

1. update the pinned OpenClaw source;
2. regenerate locks and the report;
3. build every supported id;
4. if an important id is skipped, fix the generator or builder until that same
   id has a lock.

Those fixes are maintainer work inside the single pipeline. The only acceptable
public result is that more OpenClaw catalog ids become valid in
`runtimePlugins`.

## Proof Gates

Before shipping the current RFC 1 slice:

1. Run the lock updater twice and prove the second run produces no diff.
2. Confirm the updater reads the pinned OpenClaw source catalogs.
3. Confirm every catalog row appears in the generated report with either a lock
   or one failure reason.
4. Confirm every supported row has exact version, root integrity, Nix hash,
   manifest id, runtime entry, host compatibility, and dependency-mode evidence.
5. Build every supported plugin root without package-manager execution or
   network access.
6. Confirm every unsupported row has one specific generated reason.
7. Evaluate Home Manager cases for load paths, enabled entries, allowlist merge,
   duplicate ids, unsupported ids, denied ids, disabled entries, raw load paths,
   and `plugins.installs`.
8. Validate OpenClaw in Nix mode with Slack configured, and verify `openclaw
   status` does not tell the user to run `openclaw plugins install` for Slack.
9. Start the gateway in Nix mode with a no-network runtime plugin and verify the
   gateway discovers the generated plugin root.
10. Verify stale mutable plugin registry records cannot shadow or alter selected
    Nix-managed runtime plugins.
11. Verify Darwin and Linux checks.
12. Update user docs with supported and rejected-input examples, and the rule
    that `runtimePlugins` uses plugin ids, not source strings.

The RFC is not falsified because some catalog rows remain skipped. It is
falsified if a row is silently ignored, dynamically resolved during user builds,
loaded through mutable install state, or documented as supported without a
checked-in lock and build proof.

## Falsifiers

This design needs to change if any of these are true:

- OpenClaw cannot load a valid `/nix/store` plugin root from
  `plugins.load.paths` in Nix mode.
- `plugins.entries.<id>.enabled = true` is insufficient for a config-origin
  plugin to enter the gateway startup plan.
- `openclaw status` still reports "plugin not installed" for a selected
  Nix-managed plugin after registry isolation, generated load paths, and enabled
  entries are present.
- OpenClaw requires mutable install receipts for validation rather than using
  the loaded plugin registry.
- A source cannot be pinned to exact artifact identity and integrity.
- Dependency materialization cannot be reproduced from checked-in lock data
  without package-manager resolution during user builds.

If a falsifier hits, do not paper over it with mutable state. Narrow the
supported report rows, fix generated config, or make the smallest upstream
OpenClaw change that preserves the declarative boundary.

## Out Of Scope

These are not RFC 1:

- user-supplied runtime plugin sources of any kind;
- Nix-only plugin runtime settings;
- plugin-to-agent assignment;
- mutable install/update/uninstall in Nix mode;
- activation-time dependency installation;
- fake install records.

Do not add placeholder sections for these. If nix-openclaw ever supports
user-supplied runtime plugin sources, that needs its own design because it
changes the public input model. It must not contaminate RFC 1.

## Evidence

OpenClaw source evidence:

- `docs/tools/plugin.md`: OpenClaw documents plugin install and official
  catalog resolution.
- `docs/cli/plugins.md`: OpenClaw supports `clawhub:`, `npm:`, `npm-pack:`,
  `git:`, local path, and marketplace installs, while Nix mode disables
  lifecycle mutators.
- `scripts/lib/official-external-channel-catalog.json`,
  `scripts/lib/official-external-plugin-catalog.json`, and
  `scripts/lib/official-external-provider-catalog.json`: pinned catalog rows
  and install metadata.
- `src/plugins/plugin-registry-snapshot.ts`: current registry isolation
  mechanism for Nix-managed gateways.

nix-openclaw source evidence:

- `nix/sources/openclaw-source.nix`: pinned OpenClaw source and release
  version.
- `nix/generated/openclaw-runtime-plugins/`: generated runtime plugin locks and
  support report.
- `nix/packages/default.nix`: exposes `pkgs.openclawRuntimePlugins`.
- `nix/modules/home-manager/openclaw/runtime-plugins.nix`: validates
  `runtimePlugins`, renders enabled entries, merges allowlists, and rejects
  contradictions.
- `nix/modules/home-manager/openclaw/config.nix`: merges generated runtime
  plugin load paths into rendered OpenClaw config and applies the current
  stale-registry isolation bridge.
