---
written_by: ai
---

# RFC 2: Runtime Plugin Artifact Materialization

- Date: 2026-06-05
- Status: Draft
- Audience: OpenClaw and nix-openclaw maintainers

## Decision

Extend the existing OpenClaw catalog runtime plugin pipeline so one immutable
Nix builder can materialize every packageable runtime plugin artifact shape:

1. plugin roots with no runtime dependencies;
2. plugin roots with bundled `node_modules`;
3. plugin roots with runtime dependencies locked by a materializer-valid
   `npm-shrinkwrap.json`.

For OpenClaw catalog plugins, the user-facing API remains:

```nix
programs.openclaw.runtimePlugins = [
  "slack"
  "memory-lancedb"
];
```

`runtimePlugins` selects OpenClaw plugin ids. It does not expose npm, ClawHub,
archive, or dependency-mode choices. Source-specific resolution is maintainer
machinery behind generated locks.

For a later arbitrary-source API, require locked source definitions rather than
mutable install specs. A source spec such as `npm:@scope/plugin@1.2.3` or
`clawhub:@openclaw/whatsapp@2026.6.1` must be resolved by a maintainer/user
lock generation step into real artifact URL, hash, package identity, and
dependency materialization evidence before Nix can build it. Nix evaluation,
Home Manager activation, and runtime never resolve latest versions or call
package registries.

## Why This Exists

RFC 1 established the user model: select supported OpenClaw runtime plugin ids
and let nix-openclaw render immutable plugin roots into `plugins.load.paths`.

The first implementation supports catalog rows whose npm package tarballs are
already complete:

- dependency-free package roots;
- packages that publish bundled `node_modules`.

That leaves important upstream plugin installs absent from the generated lock
even when upstream appears to have enough package data to make the install
deterministic:

- npm packages such as `memory-lancedb`, `codex`, and `acpx` publish
  `npm-shrinkwrap.json` but intentionally do not bundle every runtime
  dependency.
- ClawHub packages such as WhatsApp and Matrix resolve to npm-pack `.tgz`
  artifacts with SHA-256, npm integrity, and shrinkwrap, but each artifact
  still has to pass the same offline materialization proof before nix-openclaw
  can support it.

The gap is not a new user-facing plugin type. It is a missing artifact
materialization path for package roots that can be installed from shrinkwrap
instead of being pre-bundled.

This RFC is about external catalog/package artifacts. Bundled OpenClaw runtime
plugins that already ship inside the packaged gateway, including bundled Codex
or ACPX entries when present in the pinned OpenClaw release, remain a separate
upstream runtime source. In OpenClaw 2026.6.1 the external Codex and ACPX npm
package roots are also Nix-packaged through the shrinkwrap materializer. If a
future external package row is skipped, that does not imply that a separately
bundled gateway entry disappeared.

## Upstream Contract

OpenClaw keeps dependency work at install/update time. Gateway startup and
runtime plugin loading do not run package managers, repair dependencies, or
mutate the OpenClaw package directory.

Publishable npm plugin packages should ship `npm-shrinkwrap.json` when they
expect npm to install runtime dependencies. Upstream uses that shrinkwrap as
the publishable dependency graph for users. Native-heavy OpenClaw packages can
opt out of bundled runtime dependencies with
`openclaw.release.bundleRuntimeDependencies = false`; those packages still ship
shrinkwrap and let npm resolve dependencies at install time.

ClawHub is a resolver and distribution surface, not a separate dependency
graph. Modern ClawHub plugin artifacts are npm-pack `.tgz` files. Once a
ClawHub spec resolves to an npm-pack artifact, nix-openclaw can treat the
downloaded payload like any other OpenClaw plugin package tarball.

## Packageability Rule

A runtime plugin artifact is packageable by nix-openclaw when all of these are
true:

1. The source resolver produced exact artifact identity:
   - package name;
   - package version;
   - artifact URL or local source path;
   - artifact hash;
   - npm integrity or equivalent when available.
2. The artifact expands to one OpenClaw runtime plugin root with
   `openclaw.plugin.json`.
3. Manifest id, package name, version, runtime entries, setup entry, peer
   `openclaw` range, and OpenClaw compatibility match the generated lock.
4. Runtime dependencies are one of:
   - absent;
   - already bundled in `node_modules` and matching the lock's expected package
     roots;
   - declared in `package.json` and locked by a complete `npm-shrinkwrap.json`
     that the selected Nix materializer can install offline.
5. The built output contains no invalid symlinks and links any
   `node_modules/openclaw` peer to the packaged OpenClaw host.

If an artifact declares runtime dependencies without bundled dependency roots,
without shrinkwrap, or with shrinkwrap that cannot be replayed offline by the
selected Nix materializer, it is left out of the generated lock. That is a
packageability failure, not a user-interface variant.

## Shrinkwrap Materialization

For shrinkwrapped artifacts, the builder should:

1. fetch or receive the plugin package artifact as a fixed-output input;
2. extract the package root;
3. validate `package.json`, `openclaw.plugin.json`, runtime entries, setup
   entry, compatibility, and peer `openclaw` before dependency work;
4. normalize package metadata before dependency work:
   - remove dev-only package metadata, including workspace dev dependencies,
     from the build copy;
   - when `npm-shrinkwrap.json` already selects an exact package version,
     normalize dependency specs inside lock package entries to that selected
     version so npm does not ask the registry to solve a range during offline
     replay;
   - preserve runtime dependencies, optional dependencies, peer declarations,
     OpenClaw metadata, and published runtime files;
5. validate `npm-shrinkwrap.json`:
   - supported lockfile version;
   - root package name/version matches the package;
   - no dev packages in the runtime lock;
   - every non-root dependency has enough resolved/integrity data for offline
     materialization;
   - no unsupported `file:`, `workspace:`, git, or non-registry dependency
     source unless a later lock schema explicitly supports it;
6. materialize `node_modules` using nixpkgs `fetchNpmDeps` and a generated
   `npmDepsHash`;
7. run npm offline with script-free install semantics:
   `npm ci --omit=dev --omit=peer --legacy-peer-deps --ignore-scripts`;
8. keep rebuild script execution disabled;
9. link the `openclaw` peer to the packaged gateway root;
10. run the existing output validation.

`fetchNpmDeps` is the selected materializer for RFC 2. It works directly from
the package root's `npm-shrinkwrap.json`, produces the normal Nix
`npmDepsHash`, and avoids checking full shrinkwrap JSON files into generated
Nix data. `importNpmLock` is rejected for this slice because it wants the lock
JSON at Nix evaluation time; using it would require generated lockfile files or
inline lock contents before it has shown enough benefit over `fetchNpmDeps`.

The dependency-spec normalization is intentionally narrow. It does not resolve
latest versions, choose alternate packages, or trust registry metadata outside
the shrinkwrap. It only makes npm follow the package graph that the shrinkwrap
already selected. If the lock lacks the selected package entry or lacks enough
resolved/integrity data to prefetch it, the artifact still fails closed.

The generator should compute `npmDepsHash` from the extracted artifact during
lock updates. User builds consume that checked-in hash. They must fail closed
when npm tries to read an uncached registry package during materialization.

## ClawHub Resolution

For OpenClaw catalog rows whose selected source is ClawHub, the lock generator
should resolve the ClawHub spec at maintainer update time:

```text
catalog id
  -> clawhub:<package>@<exact version>
  -> ClawHub artifact metadata
  -> npm-pack tarball URL + hash + npm integrity
  -> normal runtime plugin artifact builder
```

Generated locks must record enough ClawHub metadata for drift detection and
debugging, but Home Manager config must not render ClawHub install records or
call ClawHub at activation/runtime. ClawHub npm-pack artifacts are supported
when the normal runtime plugin artifact builder can materialize them offline.
For OpenClaw 2026.6.1 that includes WhatsApp and Matrix.

Legacy ClawHub zip artifacts are only packageable when the extracted plugin root
is dependency-free or already self-contained. A legacy zip with unmaterialized
runtime dependencies remains unsupported until it has a shrinkwrap-capable
package root or a separate deterministic lock format.

## User-Supplied Sources

Arbitrary user-supplied sources are still not RFC 2 implementation scope. This
RFC only defines the packageability rule and the generated-lock shape needed to
make a future source API sane.

When that API exists, it should look like a Nix package definition, not a
mutable install command. The user or maintainer supplies a locked source record,
or runs a lock updater that writes one. Illustrative shape only:

```nix
programs.openclaw.runtimePluginSources = [
  {
    spec = "npm:@scope/plugin@1.2.3";
    hash = "sha256-...";
    # Present only if the selected dependency materializer needs it.
    npmDepsHash = "sha256-...";
  }
];
```

This is a future surface. The first shipping path should keep
`runtimePlugins = [ "id" ]` for pinned OpenClaw catalog ids and make more ids
supported.

## Validation Gates

Before shipping RFC 2:

1. The lock generator supports at least one shrinkwrapped npm artifact from the
   pinned OpenClaw catalog.
2. Running the generator twice is stable.
3. Generated locks record artifact hash, package identity, manifest id,
   compatibility, runtime entries, dependency mode, and `npmDepsHash` when
   dependency materialization is required.
4. User builds do not use the network except through fixed-output fetches.
5. Home Manager activation and OpenClaw runtime do not run npm, call ClawHub,
   write install records, or call `openclaw plugins install`.
6. ClawHub-selected rows resolve through the ClawHub artifact endpoint at lock
   update time and are either promoted through the shared builder or skipped
   with a precise offline-materialization diagnostic.
7. At least one shrinkwrapped npm-only catalog id, such as `memory-lancedb`, is
   supported if its dependencies build on the target platforms.
8. Unsupported rows remain explicit in the generated maintainer report.
9. Existing no-dep and bundled-dependency plugin roots still build and load.
10. Nix mode `plugins list` or gateway smoke proof shows generated store roots
    load through upstream OpenClaw's normal plugin loader.

## Rejected Alternatives

| Option | Verdict |
| --- | --- |
| Add `runtimePluginsNpm`, `runtimePluginsClawHub`, or similar user-facing source buckets. | Reject. It leaks resolver details and recreates the taxonomy RFC 1 removed. |
| Accept mutable source strings without hashes. | Reject. That is upstream install UX, not Nix packaging. |
| Run `npm install` during Home Manager activation. | Reject. Activation becomes a mutable package-manager install. |
| Write OpenClaw install records for Nix-managed plugins. | Reject. The declarative contract is immutable load paths plus enabled entries. |
| Support unshrinkwrapped dependency packages by letting npm solve during build. | Reject. The output would depend on registry state outside checked-in lock data. |
| Resolve inconsistent shrinkwrap ranges from the registry. | Reject. RFC 2 may normalize lock edges to the exact versions already selected by shrinkwrap, but it must not solve ranges, choose different versions, or depend on registry state outside fixed-output fetches. |
| Keep separate builders for npm, ClawHub npm-pack, and npm-pack archives after resolution. | Reject unless required by evidence. They all produce package roots and should share the same materialization boundary. |

## Evidence

OpenClaw source evidence:

- `docs/plugins/dependency-resolution.md`: dependency work belongs to
  install/update, runtime loading never installs dependencies, publishable npm
  plugin packages can ship package-local shrinkwrap, and native-heavy packages
  may opt out of bundled runtime dependencies.
- `docs/gateway/security/shrinkwrap.md`: shrinkwrap is the published npm
  package dependency graph for users.
- `docs/cli/plugins.md`: ClawHub installs can resolve to npm-pack artifacts and
  record artifact digest, npm integrity, shasum, and tarball metadata.
- `src/plugins/clawhub.ts`: ClawHub package install downloads npm-pack
  artifacts and verifies SHA-256 and npm integrity before using the normal
  archive install path.
- Local RFC 2 implementation: OpenClaw 2026.6.1 generated 34 supported catalog
  rows. Seven are shrinkwrapped roots: `acpx`, `codex`, `copilot`, `matrix`,
  `memory-lancedb`, `tlon`, and `whatsapp`.
- Local RFC 2 implementation: ClawHub WhatsApp and Matrix resolve to npm-pack
  artifacts with tarball URL, SHA-256, npm integrity, shrinkwrap, and generated
  `npmDepsHash`; both are emitted as supported runtime plugin locks.
- Local RFC 2 implementation: the current skipped diagnostics are
  unshrinkwrapped runtime dependencies in Weixin, Yuanbao, and WeCom, plus a
  duplicate PixVerse catalog row.
- Local artifact check: the Weixin, Yuanbao, and WeCom npm tarballs declare
  runtime dependencies but contain no `npm-shrinkwrap.json`, package lock, or
  bundled `node_modules`. Supporting them under this RFC requires upstream to
  publish a shrinkwrap or bundled runtime dependencies.

nix-openclaw source evidence:

- `nix/generated/openclaw-runtime-plugins/`: generated locks already support
  no-dep and bundled-node_modules package roots.
- `nix/scripts/update-openclaw-runtime-plugin-locks.mjs`: generator owns
  source resolution, fixed artifact validation, dependency-mode classification,
  and skipped-row diagnostics.
- `nix/lib/openclaw-runtime-plugin.nix`: runtime plugin builder currently
  fetches one package tarball and validates already-present dependency roots.
- `nix/scripts/openclaw-runtime-plugin-install.mjs`: output validator already
  checks manifest, runtime entries, bundled package roots, and the `openclaw`
  peer link.
