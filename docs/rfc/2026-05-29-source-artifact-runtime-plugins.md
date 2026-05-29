# RFC: Source Artifact Runtime Plugins

- Date: 2026-05-29
- Status: Draft
- Audience: OpenClaw and nix-openclaw maintainers

## Executive Model

Mutable OpenClaw can install runtime plugins from git repositories, local
directories, local archives, and npm-pack archives:

```bash
openclaw plugins install git:github.com/<owner>/<repo>@<ref>
openclaw plugins install ./my-plugin
openclaw plugins install --link ./my-plugin
openclaw plugins install ./my-plugin.tar.gz
openclaw plugins install npm-pack:./my-plugin.tgz
```

nix-openclaw should support the reproducible subset of those sources without
copying OpenClaw's mutable install lifecycle. The common Nix shape is:

1. the user pins a source artifact;
2. Nix fetches or imports that artifact;
3. nix-openclaw validates that it is an OpenClaw runtime plugin root;
4. nix-openclaw renders normal OpenClaw config with `plugins.load.paths` and
   `plugins.entries.<id>.enabled = true`.

No implementation in this source class should run `openclaw plugins install`,
write `plugins/installs.json`, generate npm dependencies at activation time, or
pretend that OpenClaw's mutable install command already ran.

## Decision

Extend the future attrset selector form of `programs.openclaw.runtimePlugins`
with source-artifact selectors:

```nix
programs.openclaw.runtimePlugins = [
  {
    id = "demo-git";
    source = {
      kind = "git";
      url = "https://github.com/acme/openclaw-demo.git";
      rev = "2f4a0d8b2e7c...";
      hash = "sha256-...";
    };
  }

  {
    id = "demo-path";
    source = {
      kind = "path";
      path = ./plugins/demo;
    };
  }

  {
    id = "demo-archive";
    source = {
      kind = "archive";
      url = "https://example.com/openclaw-demo-1.2.3.tar.gz";
      hash = "sha256-...";
    };
  }
];
```

The selected source must already be a runtime-complete OpenClaw plugin root
after fetch and unpack. It must contain `openclaw.plugin.json`, compiled runtime
entry files, and any runtime dependencies needed by Node module resolution.

If the source is an npm-pack archive and needs npm dependency semantics, it
belongs on the user-pinned npm path unless the archive is already
runtime-complete. `npm-pack:` is an OpenClaw install locator, not a Nix source
kind by itself.

## Why This Is Separate From npm And ClawHub

Source artifacts are selected by the user from source control or local files.
There is no OpenClaw-owned catalog row and no registry metadata resolution that
nix-openclaw can use as the root of trust.

That makes this class more like user-pinned npm than official coverage, but the
artifact shape is different:

- git sources pin a repository revision and NAR hash;
- path sources are imported into the Nix store from the user's checkout;
- archive sources pin a downloaded archive hash;
- npm-pack archives may require package-manager dependency semantics.

Collapsing these into arbitrary npm would hide important policy differences.
Collapsing them into raw `plugins.load.paths` would bypass the supported
`runtimePlugins` invariants: duplicate-id checks, explicit enabled entries,
restrictive allowlist merging, deny/disabled contradictions, nix-openclaw plugin
collisions, generated load-path ownership, and persisted-registry isolation.

## User API

The selector shape is data-only. Users choose source facts; nix-openclaw chooses
the builder.

Git:

```nix
programs.openclaw.runtimePlugins = [
  {
    id = "github-issue-agent";
    source = {
      kind = "git";
      url = "https://github.com/acme/github-issue-agent.git";
      rev = "7d4d42f8e8c2...";
      hash = "sha256-...";
    };
  }
];
```

Path:

```nix
programs.openclaw.runtimePlugins = [
  {
    id = "local-demo";
    source = {
      kind = "path";
      path = ./plugins/local-demo;
    };
  }
];
```

Archive:

```nix
programs.openclaw.runtimePlugins = [
  {
    id = "archive-demo";
    source = {
      kind = "archive";
      url = "https://example.com/archive-demo-1.2.3.zip";
      hash = "sha256-...";
      stripRoot = true;
    };
  }
];
```

Runtime config still uses upstream OpenClaw config:

```nix
programs.openclaw.config.plugins.entries.github-issue-agent.config = {
  owner = "acme";
  repo = "demo";
};
```

## Path Sources Are Store Imports, Not Live Links

OpenClaw's mutable `openclaw plugins install --link ./my-plugin` keeps the
source directory live and adds it to `plugins.load.paths`.

Nix path sources do not mean that. `path = ./plugins/local-demo` imports the
directory into the Nix store. That is the supported declarative behavior because
it is roll-backable and tied to the Home Manager generation.

Live development links are intentionally outside this RFC. They are useful, but
they are not declarative. A future dev-only escape hatch can document raw
`programs.openclaw.config.plugins.load.paths`, but it should not share the
supported `runtimePlugins` lane.

## Builder Contract

Each source kind feeds a single internal builder:

```nix
pkgs.openclawPackages.buildRuntimePluginFromSource {
  id = "demo";
  src = ...;
}
```

The builder must:

1. copy or unpack the source into a deterministic output;
2. reject missing `openclaw.plugin.json`;
3. reject a manifest id that does not match the selector id;
4. reject runtime entry files that do not exist;
5. reject symlinks escaping the output;
6. reject sources with unresolved runtime dependencies unless a supported
   dependency materialization policy is present;
7. expose the same `passthru.openclawRuntimePlugin` metadata as curated runtime
   plugins.

The module must not accept arbitrary derivations as source selectors. Otherwise
users can attach plausible metadata to a derivation built through an unknown
process, defeating the builder boundary.

## Dependency Policy

The first implementation should support only runtime-complete source artifacts.

If a source artifact has `package.json` runtime dependencies but no bundled
`node_modules`, it fails with a direct dependency-lock error. Later support can
reuse the dependency materialization RFC once there is a checked lock format for
user-owned source artifacts.

Do not run npm, pnpm, yarn, corepack, or OpenClaw install/update commands during
evaluation, build, activation, or gateway startup.

## Runtime Contract

Generated OpenClaw config stays the same as curated runtime plugins:

```nix
programs.openclaw.config.plugins.load.paths = [
  "/nix/store/...-openclaw-runtime-plugin-demo"
];

programs.openclaw.config.plugins.entries.demo.enabled = true;
```

When any `runtimePlugins` selector renders a Nix-owned load path,
nix-openclaw must keep persisted mutable registry state out of the managed
gateway process until OpenClaw has a first-class Nix/declarative registry policy.

The source selector must not write:

- `plugins.installs`;
- `$OPENCLAW_STATE_DIR/plugins/installs.json`;
- managed npm roots under OpenClaw state;
- mutable marketplace or update records.

## User-Facing Documentation

The README should keep one OpenClaw runtime plugin install section.

After this RFC is implemented, add a short "Advanced: pinned source runtime
plugins" subsection:

```nix
programs.openclaw.runtimePlugins = [
  {
    id = "demo";
    source = {
      kind = "git";
      url = "https://github.com/acme/openclaw-demo.git";
      rev = "7d4d42f8e8c2...";
      hash = "sha256-...";
    };
  }
];
```

The docs must say:

- `path` sources are copied/imported into the Nix store, not live linked;
- live `--link` development is outside the supported Nix lane;
- sources must already be runtime-complete unless a later dependency-lock
  format is supplied;
- runtime config still lives in upstream OpenClaw config;
- `openclaw plugins install`, `plugins update`, and mutable install records are
  not part of the Nix workflow.

## Proof Gates

Evaluation tests:

- git, path, and archive selectors render load paths and enabled entries;
- missing required source fields fail;
- selector strings with Nix string context fail when used where a data-only
  source is required;
- unknown selector fields fail;
- duplicate ids across curated, npm, git, path, and archive selectors fail;
- source ids that collide with nix-openclaw plugins fail;
- raw `plugins.load.paths` mixed with `runtimePlugins` still fails;
- generated config contains no `plugins.installs`;
- managed launchd/systemd gateway env keeps persisted registry reads disabled
  when source selectors render load paths.

Builder tests:

- valid native OpenClaw plugin fixture builds from git-like source;
- valid path fixture builds;
- valid `.zip` and `.tar.gz` fixtures build;
- manifest id mismatch fails;
- missing runtime entry fails;
- dependency-bearing package without supported lock fails;
- escaping symlink fails;
- archive traversal fails;
- archive with no plugin root fails.

Runtime tests:

- `openclaw plugins list --json --verbose` discovers the source-built plugin
  from config;
- plugin origin is config/Nix load path, not mutable install record;
- runtime inspection can import the plugin when dependencies are complete;
- stale persisted install records do not shadow the Nix-selected source plugin.

## Implementation Order

1. Add selector parsing for `source.kind = "git" | "path" | "archive"`.
2. Add the source builder using the same validation path as curated runtime
   plugins.
3. Add fixtures for path and archive plugin roots.
4. Keep dependency-bearing source artifacts rejected.
5. Add README advanced source examples only after runtime proof passes.
6. Add `npm-pack` only if it can be expressed without package-manager mutation
   or after the user-owned dependency-lock format exists.

## Rejected Designs

### Raw `plugins.load.paths` As The Supported API

Rejected. It is upstream-compatible, but it bypasses the `runtimePlugins`
invariants and gives users no single supported Nix lane.

### Live Local Links In `runtimePlugins`

Rejected for the supported declarative path. Live links are useful for local
development, but they are mutable host state. Nix path sources should import the
source into the store.

### Arbitrary Derivation Selectors

Rejected for the same reason as arbitrary npm derivation selectors. A derivation
can do anything and then attach plausible metadata. The selector must be data;
the builder must be owned by nix-openclaw.

### Running OpenClaw Install In Activation

Rejected. It writes mutable install records and makes rollback/state ownership
ambiguous.

### Treating `npm-pack:` As Plain Archive

Rejected as the default. OpenClaw's `npm-pack:` path means npm package install
semantics, including package metadata and dependency handling. A runtime-complete
tarball can use `source.kind = "archive"`; dependency-bearing npm packs need the
dependency-lock path.

## Open Questions

- Should the first path-source implementation support only repo-relative Nix
  paths, or also absolute paths through an explicit impure/dev-only option?
- Should source selectors require `version` for user-facing status output, or
  derive it from package/manifest metadata when present?
- Should archive selectors support `stripRoot`, `root`, or both?
- Should source-built plugins be included in exported package attrs, or only in
  Home Manager module outputs?

## Evidence

- OpenClaw `docs/cli/plugins.md`: mutable OpenClaw supports `git:`, local paths,
  `npm-pack:`, archives, and marketplace install sources.
- OpenClaw `docs/cli/plugins.md`: git installs clone and record the resolved
  commit for later update; `--pin` is npm-only.
- OpenClaw `docs/cli/plugins.md`: local `--link` adds a source directory to
  `plugins.load.paths` instead of copying it.
- OpenClaw `docs/cli/plugins.md`: local paths and archives are auto-detected as
  native OpenClaw plugins or compatible bundles.
- nix-openclaw `docs/rfc/2026-05-28-openclaw-runtime-plugins.md`: supported
  runtime plugins are immutable roots loaded through generated
  `plugins.load.paths` and explicit entries.
