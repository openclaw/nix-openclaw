# RFC: ClawHub Artifacts For Runtime Plugins

- Date: 2026-05-29
- Status: Draft
- Audience: OpenClaw and nix-openclaw maintainers

## Executive Model

The first runtime-plugin RFCs intentionally split plugin support into two jobs:

1. Nix prepares an immutable plugin root in `/nix/store`.
2. nix-openclaw renders normal OpenClaw config so the gateway loads that root.

ClawHub does not change that model. It changes where the source artifact comes
from.

Mutable OpenClaw treats ClawHub as a discovery, compatibility, artifact, and
update source. nix-openclaw should only consume the part that can be made
declarative: a resolved package version plus exact artifact identity. Search,
latest resolution, update fallback, and install records stay out of activation
and user builds.

## Decision

Add a generated runtime-plugin lock source class:

```nix
source.kind = "clawhub-artifact";
```

The class is for official OpenClaw runtime plugins whose pinned upstream install
metadata points at ClawHub and whose ClawHub artifact can be resolved to an exact
version, public download URL, and fixed hash before users build their systems.

The user-facing API does not change for supported ids:

```nix
programs.openclaw.runtimePlugins = [
  "matrix"
  "whatsapp"
];

programs.openclaw.config = {
  channels.matrix.enabled = true;
  channels.whatsapp.dmPolicy = "pairing";
};
```

Users should not write ClawHub locators in Nix config:

```nix
# Bad: this is a mutable OpenClaw install spec, not a nix-openclaw id.
programs.openclaw.runtimePlugins = [
  "clawhub:@openclaw/whatsapp"
];
```

`runtimePlugins` selects supported plugin ids. Runtime settings stay in upstream
OpenClaw config. The lock entry decides whether that id is built from npm,
materialized from shrinkwrap, or fetched from ClawHub.

## Why This Slice Exists

The current pinned OpenClaw source already includes official external install
metadata with ClawHub routes:

| id | ClawHub spec | npm fallback | upstream default |
| --- | --- | --- | --- |
| `matrix` | `clawhub:@openclaw/matrix` | `@openclaw/matrix` | ClawHub |
| `whatsapp` | `clawhub:@openclaw/whatsapp` | `@openclaw/whatsapp` | ClawHub |
| `diagnostics-otel` | `clawhub:@openclaw/diagnostics-otel` | `@openclaw/diagnostics-otel` | npm |
| `diagnostics-prometheus` | `clawhub:@openclaw/diagnostics-prometheus` | `@openclaw/diagnostics-prometheus` | npm |

The npm path can still be the fastest way to complete official coverage when an
exact OpenClaw-owned npm package exists and passes validation. This RFC is not a
rewrite of that path.

This RFC is needed because ClawHub is OpenClaw's primary public discovery and
distribution surface for plugins. Some official or future catalog entries may be
ClawHub-first or ClawHub-only. If nix-openclaw can only consume npm tarballs, it
will keep drifting away from upstream plugin distribution.

Evidence in the pinned OpenClaw source:

- `docs/cli/plugins.md` documents `openclaw plugins search` as ClawHub package
  search and says ClawHub is the primary distribution/discovery surface;
- `docs/channels/matrix.md` and `docs/channels/whatsapp.md` document ClawHub
  installs for those channels;
- `src/plugins/clawhub.ts` resolves exact ClawHub package artifacts and installs
  them through OpenClaw's archive path;
- `src/infra/clawhub.ts` defines the package detail, artifact, security, and
  download endpoints used below.

## Non-Goals

This slice does not support:

- arbitrary user-supplied ClawHub packages;
- private ClawHub packages or authenticated registries;
- ClawHub search during evaluation, build, activation, or gateway startup;
- floating `latest`, unversioned, or beta selectors in user config;
- `openclaw plugins install`, `update`, `enable`, or install-record mutation;
- npm fallback when a locked ClawHub artifact disappears;
- third-party/community package trust policy;
- arbitrary npm specs.

Those are separate RFCs. This slice is the official OpenClaw-owned ClawHub
artifact class.

## Candidate Selection

The generator only reads the pinned OpenClaw source catalogs:

- `scripts/lib/official-external-channel-catalog.json`;
- `scripts/lib/official-external-plugin-catalog.json`;
- `scripts/lib/official-external-provider-catalog.json`.

A ClawHub candidate must satisfy all of these before resolution:

- catalog entry `source = "official"`;
- `openclaw.install.clawhubSpec` exists and parses as `clawhub:<package>`;
- the package name is in the `@openclaw/*` namespace;
- the runtime plugin id comes from upstream `openclaw.plugin.id` or
  `openclaw.channel.id`, as in the npm-source RFCs;
- the entry is `defaultChoice = "clawhub"` or has no `npmSpec`.

Rows with `defaultChoice = "npm"` should continue using npm when npm is already
the upstream default, even when the npm builder does not support the package
yet. They can appear in the ClawHub resolver report as available but not
selected. The generator must not make source selection depend on today's
nix-openclaw implementation coverage.

## Version Resolution

Resolution happens only in the maintainer lock update flow.

For official OpenClaw-owned packages, the generator should prefer the pinned
OpenClaw release version. If nix-openclaw pins OpenClaw `2026.5.26`, then
`clawhub:@openclaw/whatsapp` resolves as `@openclaw/whatsapp@2026.5.26` only if
ClawHub exposes that exact version and an installable artifact.

If the upstream catalog contains an explicit ClawHub version that is not the
pinned OpenClaw release version, skip it for this official source class and
write a report entry. Exact third-party or non-release selectors need the later
catalog-pinned/community RFC.

Do not fall back to ClawHub `latest`, beta, npm, or mutable OpenClaw update
semantics inside the generated support set.

The lock entry is the support promise, not the catalog string.

## Resolver Contract

The lock update flow uses ClawHub APIs only during maintainer generation, never
during user evaluation, build, activation, or gateway startup.

For package `@openclaw/whatsapp` at version `2026.5.26`, the resolver calls:

```text
GET https://clawhub.ai/api/v1/packages/%40openclaw%2Fwhatsapp
GET https://clawhub.ai/api/v1/packages/%40openclaw%2Fwhatsapp/versions/2026.5.26
GET https://clawhub.ai/api/v1/packages/%40openclaw%2Fwhatsapp/versions/2026.5.26/artifact
GET https://clawhub.ai/api/v1/packages/%40openclaw%2Fwhatsapp/versions/2026.5.26/security
HEAD https://clawhub.ai/api/v1/packages/%40openclaw%2Fwhatsapp/versions/2026.5.26/artifact/download
```

The package detail response must prove:

- `package.name` equals the catalog ClawHub package;
- `package.family` is `code-plugin` or `bundle-plugin`;
- `package.channel = "official"`;
- `package.isOfficial = true`;
- `package.verification.tier = "source-linked"`;
- `package.verification.sourceRepo = "openclaw/openclaw"`.

The version response must prove:

- `version.version` equals the pinned OpenClaw release version;
- `version.verification.tier = "source-linked"`;
- `version.verification.sourceRepo = "openclaw/openclaw"`;
- when present, `version.verification.sourceTag` and `sourceCommit` are
  recorded as exact-version provenance and drift-checked.

If ClawHub also returns `sourceCommit` or `sourceTag` as package-level latest
metadata, record it only as diagnostic provenance. It must not override the
exact-version verification response.

The artifact response must prove:

- resolved `package.name`, `package.family`, and version match the package
  detail and pinned release version;
- `artifact.kind` is `npm-pack` or `legacy-zip`;
- `artifact.sha256` exists;
- for `npm-pack`, `artifact.npmIntegrity` exists;
- `artifact.downloadUrl` or the canonical `/artifact/download` endpoint is
  anonymously fetchable.

The security response must prove that ClawHub is not blocking the release:

- scan state is clean or approved under the current response schema;
- moderation is not quarantined, rejected, or revoked;
- download is not blocked;
- verdict is not pending or stale.

The generator stores the raw normalized facts it used. If ClawHub changes a
field name, the generator should fail with an unsupported-schema report entry
instead of guessing.

## Lock Shape

A generated ClawHub lock entry should include enough source facts to make drift
obvious in review. The original ClawHub spec can be recorded for provenance,
but the build input is the resolved exact artifact:

```nix
{
  id = "whatsapp";
  packageName = "@openclaw/whatsapp";
  version = "2026.5.26";
  source = {
    kind = "clawhub-artifact";
    clawhubUrl = "https://clawhub.ai";
    clawhubPackage = "@openclaw/whatsapp";
    clawhubFamily = "code-plugin";
    clawhubChannel = "official";
    spec = "clawhub:@openclaw/whatsapp";
    resolvedSpec = "clawhub:@openclaw/whatsapp@2026.5.26";
    artifactKind = "npm-pack";
    artifactFormat = "tgz";
    artifactUrl = "https://clawhub.ai/api/v1/packages/%40openclaw%2Fwhatsapp/versions/2026.5.26/artifact/download";
    artifactSha256 = "f33f82ee...";
    nixSha256 = "sha256-...";
    npmIntegrity = "sha512-...";
    npmShasum = "...";
    npmTarballName = "whatsapp-2026.5.26.tgz";
    clawpackSha256 = "...";
    clawpackManifestSha256 = "...";
    verification = {
      tier = "source-linked";
      sourceRepo = "openclaw/openclaw";
      sourceCommit = "10ad3aa...";
      sourceTag = "refs/heads/release/2026.5.26";
      scanStatus = "clean";
    };
    security = {
      scanState = "clean";
      blockedFromDownload = false;
      pending = false;
      stale = false;
    };
  };
}
```

Not every artifact exposes every ClawPack npm field. The generator must record
the fields ClawHub returns and fail closed when it cannot prove a stable artifact
hash. If ClawHub only exposes file-list verification for a legacy archive, the
maintainer lock update flow must still download the archive once, compute the
archive hash, and write that hash into the lock. User builds must have a fixed
output hash before they fetch.

## Drift Contract

Lock regeneration must fail in check mode when an already-locked id/version
returns different source facts:

- artifact URL;
- artifact SHA-256;
- npm integrity, shasum, or tarball name;
- ClawPack SHA-256, manifest SHA-256, spec version, or size;
- legacy zip file-list proof;
- package family, channel, official flag, verification tier, source repo, or
  version-scoped source commit/tag when present;
- security verdict fields used by the lock.

The report should put these rows in `driftFailed` with the old value and new
value. A maintainer can intentionally accept the new artifact by reviewing the
generated diff and committing the lock change. User builds never decide this.

## Builder Contract

The builder consumes the generated lock. It does not call ClawHub APIs.

For `artifactKind = "npm-pack"`:

1. fetch the exact artifact URL as a fixed-output derivation;
2. validate the Nix hash against `nixSha256`, derived from `artifactSha256`;
3. validate npm integrity and npm shasum when present;
4. unpack with the same tar safety rules as npm-sourced runtime plugins;
5. validate package name, version, plugin manifest id, runtime entries, and
   compatibility metadata;
6. send the package root through the existing complete-tarball or
   shrinkwrap-materialization path based on its extracted contents.

For `artifactKind = "legacy-zip"`:

1. fetch the exact artifact URL as a fixed-output derivation;
2. validate the Nix hash against `nixSha256`, derived from `artifactSha256`;
3. unpack with zip traversal, symlink, size, and entry-count guards;
4. validate ClawHub file-list proof when present;
5. normalize to a single plugin root;
6. validate the same OpenClaw plugin contract before exposing it as a runtime
   plugin.

No generic builder runs package lifecycle scripts. If a plugin needs native
build steps, it needs a package-specific derivation and proof gate, not this
generic ClawHub artifact class.

## OpenClaw Runtime Contract

nix-openclaw still renders the same runtime config:

```json
{
  "plugins": {
    "load": {
      "paths": ["/nix/store/...-openclaw-runtime-plugin-whatsapp"]
    },
    "entries": {
      "whatsapp": { "enabled": true }
    }
  }
}
```

Do not forge `$OPENCLAW_STATE_DIR/plugins/installs.json`.

Installed-plugin records are OpenClaw's mutable receipt for update, uninstall,
and drift prompts. They are not required for runtime discovery when a prepared
plugin root is already listed in `plugins.load.paths`. Writing fake records would
make rollback and drift behavior less declarative, not more.

## User-Facing Documentation

The README should keep one install section for OpenClaw runtime plugins. Users
should not need to care whether an id is sourced from npm or ClawHub.

Good after `matrix` or `whatsapp` appears in the generated supported lock set:

```nix
programs.openclaw.runtimePlugins = [
  "whatsapp"
];

programs.openclaw.config.channels.whatsapp = {
  enabled = true;
  dmPolicy = "pairing";
};
```

Bad:

```bash
openclaw plugins install clawhub:@openclaw/whatsapp
```

Bad:

```nix
programs.openclaw.runtimePlugins = [
  "clawhub:@openclaw/whatsapp"
];
```

Docs should say: if an id is listed as supported, nix-openclaw has already
locked and packaged the artifact. If it is not listed as supported, mutable
OpenClaw install commands may work outside Nix mode, but they are not supported
by nix-openclaw.

## Proof Gates

Generator checks:

- official catalog entries with `clawhubSpec` resolve against the pinned
  OpenClaw release version or are skipped with a reason;
- generated locks include exact version, artifact URL, artifact hash, channel,
  family, and artifact kind;
- unversioned/floating ClawHub specs never appear as build inputs;
- ClawHub entries with missing artifact hash fail closed;
- ClawHub entries whose package detail is not official/source-linked
  OpenClaw-owned content fail closed;
- ClawHub entries whose security verdict is blocked, pending, stale,
  quarantined, rejected, revoked, suspicious, or malicious fail closed;
- ClawHub entries with package family `skill` are rejected from runtime plugin
  support.

Report shape:

```json
{
  "releaseVersion": "2026.5.26",
  "openclawRev": "...",
  "supported": [{ "id": "whatsapp", "source": "clawhub-artifact" }],
  "availableButNotSelected": [{ "id": "diagnostics-prometheus", "reason": "npm-source-selected" }],
  "skipped": [{ "id": "matrix", "reason": "security-suspicious" }],
  "driftFailed": [
    { "id": "whatsapp", "field": "artifactSha256", "old": "...", "new": "..." }
  ]
}
```

The generator needs `--check` mode that proves generated locks, report output,
and README supported-id docs are in sync.

Builder checks:

- tar and zip traversal attacks fail;
- wrong package name/version fails;
- wrong `openclaw.plugin.json.id` fails;
- missing runtime entries fail;
- lifecycle-script packages are skipped unless they have a package-specific
  derivation;
- ClawPack npm integrity drift fails;
- legacy zip file-list drift fails.

Home Manager checks:

- `runtimePlugins = [ "whatsapp" ]` renders load path plus enabled entry when
  `whatsapp` is in the generated lock set;
- `runtimePlugins = [ "clawhub:@openclaw/whatsapp" ]` fails with a direct
  unsupported-id error;
- duplicate, denied, disabled, collision, and raw-load-path checks behave the
  same as npm-sourced runtime plugins;
- per-instance override semantics stay unchanged.

Runtime smoke:

- `openclaw plugins list --json` sees the selected plugin id from the Nix store
  load path;
- `openclaw status` does not report "plugin not installed" for selected ids;
- a minimal configured channel plugin logs its startup path on Darwin and Linux.

## Rollout

1. Extend the lock generator with a report-only ClawHub resolver.
2. Generate candidate rows for the pinned official catalog entries that already
   have `clawhubSpec`.
3. Implement the generic `npm-pack` ClawHub artifact path first.
4. Prove one ClawHub-default official channel, preferably `whatsapp` or
   `matrix`, on Darwin and Linux.
5. Add legacy zip support only when a current official/catalog-pinned package
   requires it.
6. Add README examples only for ids that pass all proof gates.

## Rejected Designs

### Run `openclaw plugins install clawhub:...`

Rejected. It resolves network state, mutates OpenClaw-owned plugin state, writes
install records, and changes update behavior outside the Nix store.

### Let Users Put ClawHub Specs In `runtimePlugins`

Rejected for this slice. A ClawHub spec is a mutable install locator. A
nix-openclaw runtime-plugin id is a supported, locked artifact. Mixing the two
would make unsupported community packages look declarative before the trust and
locking model exists.

### Fall Back To npm Automatically

Rejected. OpenClaw's mutable updater can use fallback to keep interactive users
moving. Nix support should fail closed when the locked source artifact is
missing or changed. If npm is the intended source for an id, the generated lock
should say npm.

### Store Fake Install Records

Rejected. OpenClaw already loads prepared plugin roots through config. Fake
install records would only make mutable update/uninstall state disagree with the
Nix source of truth.

## Follow-Up RFCs

This RFC deliberately leaves three source classes for later:

- catalog-pinned third-party/community plugins with explicit trust policy;
- arbitrary user-supplied npm specs with lock-file ownership and update flow;
- git/path/archive plugin sources, including local development workflows.
