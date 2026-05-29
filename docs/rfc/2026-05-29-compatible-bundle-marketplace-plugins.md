# RFC: Compatible Bundle And Marketplace Plugins

- Date: 2026-05-29
- Status: Draft
- Audience: OpenClaw and nix-openclaw maintainers

## Executive Model

OpenClaw's plugin install surface is broader than native OpenClaw runtime
plugins. It can also install marketplace entries and compatible bundle formats:

- Codex-compatible bundles with `.codex-plugin/plugin.json`;
- Claude-compatible bundles with `.claude-plugin/plugin.json` or the default
  Claude component layout;
- Cursor-compatible bundles with `.cursor-plugin/plugin.json`;
- marketplace entries selected by name from a local, GitHub, git, or path
  marketplace source.

Those are not automatically the same product as
`programs.openclaw.runtimePlugins`. A native OpenClaw runtime plugin contributes
runtime code loaded by the gateway. A compatible bundle may contribute skills,
command-skills, settings defaults, LSP defaults, hooks, or capabilities that
OpenClaw can inspect but does not yet execute.

nix-openclaw should not hide that difference by sending every marketplace or
compatible bundle through `runtimePlugins`.

## Decision

Do not add marketplace or compatible-bundle support to
`programs.openclaw.runtimePlugins` until the selected artifact resolves to a
native OpenClaw runtime plugin root.

For non-native compatible bundles, add a later, separate Nix-owned surface only
after the capability mapping is explicit:

```nix
programs.openclaw.compatiblePlugins = [
  {
    id = "claude-reviewer";
    source = {
      kind = "marketplace";
      marketplace = {
        kind = "git";
        url = "https://github.com/acme/claude-marketplace.git";
        rev = "9a1b...";
        hash = "sha256-...";
      };
      plugin = "reviewer";
    };
  }
];
```

That surface is intentionally not part of the first runtime-plugin
implementation. It needs its own capability contract because compatible bundles
can overlap with nix-openclaw plugins, raw skills, hooks, and local editor
settings.

## Why This Is Separate From Runtime Plugins

`runtimePlugins` means: "build or select an OpenClaw runtime plugin root, then
load it through OpenClaw's runtime plugin registry."

Compatible bundles mean: "translate another agent ecosystem's plugin bundle into
the subset of OpenClaw features that OpenClaw currently supports."

Those are different promises:

- runtime plugins need `openclaw.plugin.json` and compiled runtime entrypoints;
- compatible bundles may not have OpenClaw runtime entrypoints at all;
- bundle skills/settings/hooks may need materialization into OpenClaw skill,
  hook, or config paths rather than `plugins.load.paths`;
- some bundle capabilities are currently only shown in diagnostics/info and are
  not wired into runtime execution upstream.

If nix-openclaw pretends compatible bundles are runtime plugins, users will
expect gateway runtime behavior that upstream OpenClaw may not provide.

## Source Model

Marketplace sources are discovery manifests. They are not build inputs by
themselves until a specific marketplace version, entry, and entry source are
pinned.

The future Nix source model should resolve in two phases:

1. select a marketplace manifest artifact;
2. select one plugin entry inside that manifest.

Remote marketplace manifests must be pinned like any other source artifact:

```nix
source.marketplace = {
  kind = "git";
  url = "https://github.com/acme/marketplace.git";
  rev = "9a1b...";
  hash = "sha256-...";
};
source.plugin = "reviewer";
```

Known Claude marketplace names from `~/.claude/plugins/known_marketplaces.json`
are not a Nix input. They are local mutable discovery state and must not be used
by nix-openclaw as a supported selector.

For a remote marketplace, OpenClaw requires entries to stay inside the cloned
marketplace root. nix-openclaw should preserve that policy by resolving only
relative entry paths under the pinned marketplace artifact.

## Capability Contract

The first implementation should be report-only or fail-closed until it can
classify the bundle's capabilities.

A compatible bundle can be supported only when every selected capability has a
Nix-owned target:

| Bundle capability | nix-openclaw target |
| --- | --- |
| native OpenClaw runtime plugin root | `runtimePlugins` source-artifact path |
| skill files | `skills.load.extraDirs` or generated skill materialization |
| Claude command-skills | explicit OpenClaw skill/command mapping, not implicit |
| Claude settings defaults | explicit config mapping, not silent merge |
| LSP defaults | explicit runtime package/config mapping |
| compatible Codex hooks | explicit OpenClaw hook policy |
| unsupported detected capabilities | diagnostics, no runtime claim |

If any capability is unsupported, nix-openclaw should either reject the bundle or
render a report that says exactly what would be ignored. It should not silently
install a partial bundle and call it supported.

## User-Facing Model

Do not add README install instructions for compatible bundles until there is a
working capability contract.

When support exists, docs should say:

- `runtimePlugins` is for native OpenClaw runtime plugins;
- `compatiblePlugins` is for pinned compatible bundles and marketplace entries;
- known marketplace names from local Claude state are not supported in Nix;
- remote marketplace sources must be pinned by URL/rev/hash;
- only listed capabilities are wired into OpenClaw runtime behavior;
- ignored capabilities are unsupported, not best-effort support.

Bad:

```nix
# Ambiguous: depends on mutable local Claude marketplace state.
programs.openclaw.runtimePlugins = [
  "reviewer@some-claude-marketplace"
];
```

Better:

```nix
programs.openclaw.compatiblePlugins = [
  {
    id = "reviewer";
    source = {
      kind = "marketplace";
      marketplace = {
        kind = "git";
        url = "https://github.com/acme/marketplace.git";
        rev = "9a1b...";
        hash = "sha256-...";
      };
      plugin = "reviewer";
    };
  }
];
```

## Runtime Contract

Compatible bundles must not write OpenClaw install records:

- no `plugins.installs`;
- no `$OPENCLAW_STATE_DIR/plugins/installs.json`;
- no managed npm roots;
- no local Claude marketplace cache reads;
- no `openclaw plugins install` or `plugins marketplace list` during activation
  or gateway startup.

If a marketplace entry resolves to a native OpenClaw plugin root, the final
runtime config should look exactly like other runtime plugin sources:

```nix
programs.openclaw.config.plugins.load.paths = [
  "/nix/store/...-openclaw-runtime-plugin-reviewer"
];

programs.openclaw.config.plugins.entries.reviewer.enabled = true;
```

If it resolves to skills/settings/hooks, those must be rendered through their
own Nix-owned targets, not hidden behind `plugins.load.paths`.

## Proof Gates

Evaluation tests:

- known marketplace names fail because they depend on local mutable state;
- marketplace selectors require a pinned source artifact;
- remote marketplace entry paths cannot escape the marketplace root;
- unsupported bundle capabilities fail or produce an explicit unsupported
  report;
- native OpenClaw plugin entries can hand off to the source-artifact
  runtime-plugin builder;
- generated config writes no `plugins.installs`;
- compatible bundle selectors do not collide with nix-openclaw plugin ids or
  skill ids.

Builder/tests:

- Codex bundle fixture is classified without runtime overclaiming;
- Claude bundle fixture with skills is classified;
- Cursor bundle fixture is classified;
- native OpenClaw plugin inside a marketplace builds through the runtime-plugin
  source builder;
- marketplace entry with absolute path or remote nested source fails;
- marketplace source pinned by git rev/hash is reproducible;
- bundle with unsupported capability fails closed or reports unsupported.

Runtime tests:

- supported skill capabilities appear in `skills.load.extraDirs`;
- native runtime plugin marketplace entry appears in `plugins list`;
- unsupported capabilities do not appear as silently active runtime behavior.

## Implementation Order

1. Add a report-only classifier for compatible bundle sources.
2. Add fixtures for Codex, Claude, Cursor, and native OpenClaw marketplace
   entries.
3. Prove native OpenClaw marketplace entries can reuse the source-artifact
   runtime-plugin builder.
4. Design explicit targets for each compatible bundle capability before exposing
   user docs.
5. Add README docs only after at least one non-native compatible bundle has a
   complete capability mapping.

## Rejected Designs

### Put Marketplace Strings In `runtimePlugins`

Rejected. A marketplace string is a mutable discovery locator, not a pinned Nix
source.

### Read Claude Known Marketplaces At Evaluation

Rejected. `~/.claude/plugins/known_marketplaces.json` is local mutable state.
Using it would make evaluation depend on a user cache outside the flake.

### Treat Compatible Bundles As Native Runtime Plugins

Rejected. Compatible bundles can lack OpenClaw runtime entrypoints and can
contain skills/settings/hooks instead. The user-visible promise is different.

### Silently Ignore Unsupported Bundle Capabilities

Rejected. That produces false support. If a bundle is only partially supported,
the missing capabilities must be explicit.

## Open Questions

- Should compatible bundle support live under `programs.openclaw.compatiblePlugins`
  or a more specific name once the first capability mapping is chosen?
- Should marketplace source locks be generated by a maintainer command or
  handwritten by advanced users?
- Should native OpenClaw plugin entries from marketplaces be allowed in
  `runtimePlugins` once their pinned marketplace source is explicit?
- Should compatible bundles be allowed to contribute nix-openclaw skills, or
  should they always materialize as upstream OpenClaw skills only?

## Evidence

- OpenClaw `docs/cli/plugins.md`: plugin install supports marketplace shorthand,
  explicit marketplace sources, local marketplace roots, GitHub sources, and git
  URLs.
- OpenClaw `docs/cli/plugins.md`: remote marketplace entries must stay inside
  the cloned marketplace repo and may only use relative plugin paths.
- OpenClaw `docs/cli/plugins.md`: local paths and archives auto-detect native
  OpenClaw plugins, Codex-compatible bundles, Claude-compatible bundles, and
  Cursor-compatible bundles.
- OpenClaw `docs/cli/plugins.md`: compatible bundles install into the normal
  plugin root, but some detected capabilities are currently diagnostics-only.
- OpenClaw `src/plugins/marketplace.ts`: marketplace resolution normalizes
  remote sources and rejects entries that escape the marketplace root.
