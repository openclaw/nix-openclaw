---
written_by: ai
---

# Performance Audit

Append-only measurement ledger for default stable `openclaw` /
`openclaw-gateway` packaging. Runtime plugin shrinkwrap is recorded here only
when it changes default package metrics; broad plugin support is tracked in the
plugin PR.

## Rules

- Add a new run when packaging, CI shape, or release-update behavior changes.
- Do not overwrite old run rows. If a value was wrong, add a correction row with
  the correcting commit.
- Tie every run to a commit SHA. Use the commit whose package/check graph was
  measured, not a later prose-only commit.
- Keep metric rows concrete: baseline provenance, measured provenance, command,
  value, and change.
- Keep each run small: purpose, commit/store provenance, metrics, proof.

## Build Analysis Toolbox

Checked on 2026-06-06 with Determinate Nix `3.21.0` / Nix `2.34.6` and pinned
nixpkgs `16c7794d0a28b5a37904d55bcca36003b9109aaa`.

- Default CI meter:
  - keep timestamped raw Nix stderr plus `NIX_SHOW_STATS=1`;
  - this preserves exact copy-source lines, build lines, warning text, phase
    hints, and evaluator counters in a commit-tied summary.
- Structured drill-down:
  - use `nix build --log-format internal-json` with the same timestamp sidecar
    when text scraping is ambiguous;
  - `json-log-path` records the same event stream but does not include
    timestamps, so it is not enough by itself for phase-duration attribution;
  - `nix-output-monitor` / `nom` is the best local human display for this
    stream, but CI should keep machine-readable summaries and raw logs.
- Active-build drill-down:
  - on Determinate Nix `3.14.0+`, `nix ps --json` exposes in-flight build
    derivations and child process trees:
    https://determinate.systems/blog/changelog-determinate-nix-3140/;
  - use it as an optional sampler for long local/macOS builds, not as a required
    CI metric while Linux CI still uses upstream Nix through
    `cachix/install-nix-action`.
- Cache/eval probes:
  - use `nix-eval-jobs --check-cache-status` for explicit local/cached/not-built
    attribution across many attrs;
  - use `scripts/summarize-nix-eval-jobs.mjs` to turn that JSONL into a
    commit-tied cache-status summary when doing manual or periodic cache
    audits;
  - use `nix-fast-build` for separate cache-presence experiments, not the
    default proof path, because skip-cached modes can stop proving the cold
    install/apply closure copy behavior users hit.
- Closure and dependency drill-down:
  - the CI wrapper captures Nix build-result JSON and uses the `drvPath` to
    summarize realized build-closure hotspots with
    `nix-store -qR --include-outputs` plus
    `nix path-info --json --json-format 2 --size --closure-size`;
  - this attributes the runner's copied/built closure to concrete store paths
    without changing the proof target;
  - use `nix path-info --json --recursive --size --closure-size` for closure
    top offenders;
  - use `nix derivation show` for input-derivation fan-out, but parse both the
    older `inputDrvs`/`inputSrcs` shape and the Determinate Nix `3.21.0`
    `derivations.<drv>.inputs.{drvs,srcs}` shape;
  - use `nix why-depends`, `nix-diff`, `nix-tree`, `nix-du`, and `nvd` when a
    path appears unexpectedly or a closure/derivation changes.
- Deep evaluator profiling:
  - `NIX_SHOW_STATS=1` belongs in CI summaries;
  - use Nix `2.34+` eval profiles for local flamegraph drill-down:
    `--option eval-profiler flamegraph --option eval-profile-file <path>`;
    https://nix.dev/manual/nix/2.34/advanced-topics/eval-profiler.html
  - verified locally on `.checks.aarch64-darwin.ci`: the profile is useful for
    hot evaluation paths, but too large/noisy for every PR CI run;
  - keep `trace-function-calls` as a fallback only. It is noisier than the eval
    profiler and not appropriate for default PR proof.
- Low-value for this repo:
  - `nix build --dry-run --json` only emits result metadata (`drvPath` and
    `outputs`); fetch/build plans still arrive on stderr, so it does not replace
    the timestamped stderr meter;
  - newer closure explorers such as `nix-deps` are useful orientation tools, but
    remain interactive/cache.nixos.org-oriented and lack the stable JSON output
    needed for this PR's provenance ledger:
    https://github.com/manelinux/nix-deps

## Run Index

| Run | Base | Measured | Purpose | Result |
| --- | --- | --- | --- | --- |
| `pr100-npm-default-2026-06-05` | `561aa2809a9c` | `aaadab2da7c2d` | switch default gateway from source/pnpm to npm shrinkwrap | major closure/output/file reduction |
| `pr100-on99-acpx-convergence-2026-06-05` | `8c2595e682d1` | `f785b9d3b6fa` | stack on PR #99 and reuse generated ACPX lock | fewer knobs/files, faster pin apply, slightly smaller closure |
| `pr100-on99-ci-apply-split-2026-06-05` | `ba3b6e65b07d` | `e93b21ed88e0` | split default CI/apply proof from exhaustive plugin catalog packaging | default CI schedules far less work while retaining explicit catalog proof |
| `pr100-remote-ci-cache-2026-06-06` | `51aff7a59ba20` | `9d0ae60e8cbc` | measure real GitHub Actions/Garnix behavior and stop duplicate PR branch CI | one PR-branch workflow per SHA, cache behavior characterized |
| `pr100-macos-hm-cache-split-2026-06-06` | `9d0ae60e8cbc` | `d7b1bca93146` | move macOS HM activation package into the cacheable flake check graph | fewer remote built derivations while retaining launchd/apply proof |
| `pr100-ci-meter-2026-06-06` | `3b70138463a9` | `5733ebdf9ed4` | add Nix build metering to opaque CI aggregate steps | no graph change; remaining cost is substitution volume plus 29 Linux proof drvs |
| `pr100-gha-cache-rejected-2026-06-06` | `886ad5710ac1` | `a05e9981c943` | test Magic Nix Cache as a GitHub Actions Nix cache layer | rejected: Linux slower, macOS cache startup blocked proof |
| `pr100-nix-eval-telemetry-2026-06-06` | `a05e9981c943` | `4d4ec0996548` | replace rejected cache action with Nix eval and phase telemetry | no graph change; eval cost is now visible in CI summaries |
| `pr100-on99-latest-restack-2026-06-06` | `c31825060717` | `6e87b41a28df` | restack PR #100 on latest PR #99 runtime-plugin source-lock head | package metrics stable; first remote run slower from cache miss/builds |
| `pr100-macos-max-jobs-2-2026-06-06` | `6e87b41a28df` | `debf0c1ce94c` | test hosted macOS Nix concurrency after npm shrinkwrap removes source gateway build | accepted; warm run fast, but speedup is cache-influenced |
| `pr100-contextful-config-json-2026-06-06` | `6197f2f2f543` | `6ce39fb68fca` | track store references in generated OpenClaw config JSON | OpenClaw config improper-context warnings removed; package metrics unchanged |
| `pr100-qmd-instance-split-2026-06-06` | `e9bf98d4c457` | `ff85f6bb3ad2` | split QMD module proof out of default instance CI | Linux aggregate 23.3% faster; QMD output copy/build removed from default CI |
| `pr100-qmd-lazy-input-2026-06-06` | `3842f6732f0d` | `063d825de228` | stop forcing QMD while constructing default package/check attrs | QMD input fetch removed from default CI; no wall-time win on sampled runner |
| `pr100-build-closure-meter-2026-06-06` | `7555c3bdb2cc` | `7ff4d4ddff82` | add CI build-closure hotspot attribution | no graph change; Linux/macOS CI now reports top closure paths |
| `pr100-build-analysis-tooling-2026-06-06` | `76c45773853d` | `c99051b5dae3` | add optional `nix-eval-jobs` cache-status summarizer after current tooling survey | no graph change; attr-level cache probes available without default CI overhead |
| `pr100-structured-nix-log-meter-2026-06-06` | `c99051b5dae3` | `4998f2759d99` | parse optional Nix internal-json build activity events | no graph change; opt-in runs can report structured activity spans |
| `pr100-hm-manuals-off-2026-06-06` | `4cb703b54f44` | `2896ac3847e0` | disable Home Manager manual outputs in activation proof fixtures | fewer doc/options paths; `options.json` warning removed; apply proof retained |

## Runs

### `pr100-npm-default-2026-06-05`

- PR: `#100`
- Measured commit: `aaadab2da7c2dbfeebe08d287999c87ae969747a`
- Base commit: `561aa2809a9cbfc9ba7b86c02b5796cd71937ecc`
- Package outputs:
  - baseline gateway: `/nix/store/a0ky4lhljzsjcbip97ykpjnj29lcf5q9-openclaw-gateway-unstable-2e08f0f4`
  - baseline `openclaw`: `/nix/store/3i3xlpx2pysv076gz3f9yjsx5rv9czwd-openclaw-2026.6.1`
  - measured gateway: `/nix/store/kh5j0cgbihmz4cl67w6fy0j4kimqcj70-openclaw-gateway-2026.6.1`
  - measured `openclaw`: `/nix/store/sflqabvcsphsqn6s11nw82la3gafzp0a-openclaw-2026.6.1`
- Notes:
  - Size baselines compare the old source-build gateway output to the npm
    gateway output.
  - Workflow/check baselines compare earlier draft PR state before the
    simplification pass.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Gateway closure | source gateway store path above | 2,273,877,888 B | `aaadab2da` gateway store path above | 915,457,000 B | 59.7% smaller | `nix path-info -S "$gateway"` |
| `openclaw` closure | source `openclaw` store path above | 3,215,431,032 B | `aaadab2da` `openclaw` store path above | 1,857,010,136 B | 42.2% smaller | `nix path-info -S "$openclaw"` |
| Gateway output | source gateway store path above | 2.1G | `aaadab2da` gateway store path above | 727M | 66.2% smaller | `du -sh "$gateway"` |
| Package manifests | source gateway store path above | 1,452 | `aaadab2da` gateway store path above | 584 | 59.8% fewer | `find "$gateway/lib/openclaw" -name package.json \| wc -l` |
| Files under `lib/openclaw` | source gateway store path above | 97,909 | `aaadab2da` gateway store path above | 34,053 | 65.2% fewer | `find "$gateway/lib/openclaw" -type f \| wc -l` |
| Garnix targets | draft PR wildcard state `b434edea34cbdae652c5fabfddf68c5f6a6532d3` implied expansion | 83 | `aaadab2da` `garnix.yaml` include list | 5 | 94.0% fewer | `ruby -e 'require "yaml"; puts YAML.load_file("garnix.yaml")["builds"]["include"].length'` |
| Darwin check attrs | draft PR before source-check removal | 13 | `aaadab2da` flake checks | 11 | 15.4% fewer | `nix eval .#checks.aarch64-darwin --apply 'attrs: builtins.length (builtins.attrNames attrs)'` |
| Linux check attrs | draft PR before source-check removal | 14 | `aaadab2da` flake checks | 12 | 14.3% fewer | `nix eval .#checks.x86_64-linux --apply 'attrs: builtins.length (builtins.attrNames attrs)'` |
| Workflow hardcoded npm wrapper paths | draft PR workflow `b434edea` | 20 | `aaadab2da` workflow | 0 | removed | `rg -o 'nix/npm/openclaw\|nix/npm/openclaw-runtime-plugins/acpx' .github/workflows/pin-stable-openclaw-version.yml \| wc -l` |
| Top-level ACPX package outputs | draft PR `nix/packages/default.nix` exported `openclaw-bundled-acpx` | 1 | `aaadab2da` package attr set | 0 | removed | `nix eval .#packages.aarch64-darwin --apply 'attrs: builtins.filter (name: builtins.match ".*acpx.*" name != null) (builtins.attrNames attrs)'` |
| PR diff shape | `origin/main` at `561aa2809a9cbfc9ba7b86c02b5796cd71937ecc` | 0 | `aaadab2da` vs `origin/main` | 29 files, +5217/-639 | recorded | `git diff --shortstat origin/main` |
| Non-lock PR diff | `origin/main` at `561aa2809a9cbfc9ba7b86c02b5796cd71937ecc` | 0 | `aaadab2da` excluding npm lockfiles | 27 files, +662/-639 | recorded | `git diff --numstat origin/main -- ':!nix/npm/openclaw/package-lock.json' ':!nix/npm/openclaw-runtime-plugins/acpx/package-lock.json'` |
| Build/workflow/doc diff | `origin/main` at `561aa2809a9cbfc9ba7b86c02b5796cd71937ecc` | 0 | `aaadab2da` selected files | 16 files, +422/-372 | recorded | `git diff --numstat origin/main -- README.md 'maintainers/*.md' 'nix/**/*.nix' flake.nix 'scripts/*.sh' '.github/workflows/*.yml' garnix.yaml ':!nix/npm/**'` |

Build-time rows:

| Metric | Provenance | Value | Command |
| --- | --- | ---: | --- |
| New default gateway forced rebuild | earlier PR proof, same npm output path retained through `aaadab2da` | 51.03s | `nix build --accept-flake-config --rebuild --no-link --print-out-paths .#openclaw-gateway` |
| Old source forced rebuild | source-builder baseline derivation | 399.37s then determinism failure | `nix build --rebuild --no-link --print-out-paths '/nix/store/w7z8m445bb9ykm4fzxvdmjvv8cnyjnq0-openclaw-gateway-unstable-2e08f0f4.drv^*'` |
| Same-version stable pin apply | `aaadab2da` update path | 80.28s | `GITHUB_ACTIONS=true /usr/bin/time -p scripts/update-pins.sh apply v2026.6.1 2e08f0f4221f522b60423ed6ffd83427942b28de v2026.6.1 https://github.com/openclaw/openclaw/releases/download/v2026.6.1/OpenClaw-2026.6.1.zip` |
| Cached Darwin CI aggregate | after removing dogfood/source from default aggregate | 42.56s | `nix build --accept-flake-config --no-link --print-out-paths .#checks.aarch64-darwin.ci` |
| Cached Linux CI aggregate | after removing dogfood/source from default aggregate | 43.58s | `nix build --accept-flake-config --no-link --print-out-paths .#checks.x86_64-linux.ci` |
| Darwin CI aggregate with local auto-GC | same command, GC-contaminated | 111.16s | same as above |
| Linux CI aggregate with local auto-GC | same command, GC-contaminated | 216.83s | same as above |

Remote proof for measured commit:

- GitHub Actions Linux: pass.
- GitHub Actions macOS: pass.
- Garnix: pass on 5 targets: Darwin CI, stable `openclaw` and
  `openclaw-gateway` packages on Darwin and Linux.

### `pr100-on99-acpx-convergence-2026-06-05`

- PR: `#100`, stacked locally on PR `#99`
  (`ca3cdce4c08b164c9474b86066fc595f3701630e`).
- Measured commit: `f785b9d3b6fad7fd4f8b556e943ecd9001ac7d15`
- Base commit: `8c2595e682d1e6aef68cf11eedb7d8904ba5b6d6`
- Purpose:
  - delete the private ACPX npm wrapper and `acpxNpmDepsHash` pin;
  - embed ACPX through PR #99's generated runtime-plugin lock in no-peer-link
    mode;
  - prune extraneous shrinkwrap package roots so the generated path does not
    carry unused shrinkwrap entries.
- Package outputs:
  - baseline gateway: `/nix/store/kh5j0cgbihmz4cl67w6fy0j4kimqcj70-openclaw-gateway-2026.6.1`
  - baseline `openclaw`: `/nix/store/sflqabvcsphsqn6s11nw82la3gafzp0a-openclaw-2026.6.1`
  - measured gateway: `/nix/store/mlyfrm6ypp1s9bzsx4fdv6qnyprb9r69-openclaw-gateway-2026.6.1`
  - measured `openclaw`: `/nix/store/jbjym54w7jj6mqd46slf590q74piqby7-openclaw-2026.6.1`
- Rejected candidate:
  - Generated ACPX without pruning built
    `/nix/store/hslnswgsi1inxmb02mb740m3hx6qmd80-openclaw-gateway-2026.6.1`.
    It was cleaner than the wrapper but worse on size: gateway closure
    `923,022,856` bytes and embedded ACPX `438M`, `149` package manifests,
    `5,901` files. The committed prune path keeps the generated lock source of
    truth without that size regression.
- Automation boundary:
  - Full runtime plugin lock update/check cost was measured at `114.86s` with
    `/usr/bin/time -p nix/scripts/update-openclaw-runtime-plugin-locks.mjs --check`.
    This run does not add that full catalog refresh to stable pin apply.
- Rebase correction:
  - After rebasing onto PR #99 head
    `a528abcacd3903ac6898db02a757f9f7331122cf`, the equivalent package graph
    commit is `557df7b4b41c820e09917d6d74862ebd3af528c5`, with audit follow-up
    `ba3b6e65b07d6ff50119247db6588416e68bd6b5`.
  - The remeasured package outputs are
    `/nix/store/v3algdl8d8vh7nynmwa2j0xxzxs7wqbl-openclaw-gateway-2026.6.1`
    and `/nix/store/z6945hw6msi58cyfh78pybinfzpn5i2m-openclaw-2026.6.1`.
    Gateway closure remained `904,983,184` B and `openclaw` closure remained
    `1,846,536,320` B.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Gateway closure | `8c2595e6` gateway store path above | 915,457,000 B | `f785b9d3` gateway store path above | 904,983,184 B | 1.1% smaller | `nix path-info -S "$gateway"` |
| `openclaw` closure | `8c2595e6` `openclaw` store path above | 1,857,010,136 B | `f785b9d3` `openclaw` store path above | 1,846,536,320 B | 0.6% smaller | `nix path-info -S "$openclaw"` |
| Gateway output | `8c2595e6` gateway store path above | 727M | `f785b9d3` gateway store path above | 727M | unchanged | `du -sh "$gateway"` |
| Package manifests | `8c2595e6` gateway store path above | 584 | `f785b9d3` gateway store path above | 584 | unchanged | `find "$gateway/lib/openclaw" -name package.json \| wc -l` |
| Files under `lib/openclaw` | `8c2595e6` gateway store path above | 34,053 | `f785b9d3` gateway store path above | 34,054 | +1 file | `find "$gateway/lib/openclaw" -type f \| wc -l` |
| Private ACPX wrapper files | `8c2595e6` tracked wrapper package plus install script | 3 | `f785b9d3` tracked tree | 0 | removed | `git ls-tree -r --name-only <commit> -- nix/npm/openclaw-runtime-plugins/acpx nix/scripts/openclaw-bundled-acpx-install.sh \| wc -l` |
| Stable source npm hash knobs | `8c2595e6` `nix/sources/openclaw-source.nix` | 2 | `f785b9d3` source pin | 1 | 50.0% fewer | `rg -n 'NpmDepsHash' nix/sources/openclaw-source.nix \| wc -l` |
| Release pin files | `8c2595e6` `scripts/update-pins.sh files` | 7 | `f785b9d3` `scripts/update-pins.sh files` | 5 | 28.6% fewer | `GITHUB_ACTIONS=true scripts/update-pins.sh files \| wc -l` |
| Same-version stable pin apply | `8c2595e6` update path | 80.28s | `f785b9d3` update path | 55.66s | 30.7% faster | `GITHUB_ACTIONS=true /usr/bin/time -p scripts/update-pins.sh apply v2026.6.1 2e08f0f4221f522b60423ed6ffd83427942b28de v2026.6.1 https://github.com/openclaw/openclaw/releases/download/v2026.6.1/OpenClaw-2026.6.1.zip` |

Targeted runtime plugin sizes at measured commit:

| Plugin | Closure | Output | Package manifests | Files |
| --- | ---: | ---: | ---: | ---: |
| `acpx` | 1,332,793,752 B | 411M | 43 | 1,210 |
| `codex` | 1,115,280,248 B | 206M | 15 | 2,162 |
| `copilot` | 1,377,159,120 B | 433M | 29 | 1,161 |
| `matrix` | 939,052,272 B | 43M | 62 | 4,614 |
| `memory-lancedb` | 1,037,644,056 B | 142M | 139 | 5,787 |
| `tlon` | 986,309,872 B | 86M | 64 | 3,884 |
| `whatsapp` | 956,039,968 B | 56M | 78 | 3,221 |

Proof for measured commit:

- `bash -n scripts/update-pins.sh nix/scripts/check-package-contents.sh nix/scripts/openclaw-gateway-npm-install.sh`
- `node --check nix/scripts/openclaw-runtime-plugin-install.mjs`
- `node --check nix/scripts/update-openclaw-runtime-plugin-locks.mjs`
- `node --check nix/scripts/patch-openclaw-npm-dist.mjs`
- `nix build --accept-flake-config --no-link --print-out-paths .#openclaw-gateway`
- `nix build --accept-flake-config --no-link --print-out-paths .#packages.aarch64-darwin.openclaw-runtime-plugin-acpx .#checks.aarch64-darwin.package-contents .#checks.aarch64-darwin.runtime-plugin-locks`
- `nix build --accept-flake-config --no-link --print-out-paths .#packages.aarch64-darwin.openclaw-runtime-plugin-acpx .#packages.aarch64-darwin.openclaw-runtime-plugin-codex .#packages.aarch64-darwin.openclaw-runtime-plugin-copilot .#packages.aarch64-darwin.openclaw-runtime-plugin-matrix .#packages.aarch64-darwin.openclaw-runtime-plugin-memory-lancedb .#packages.aarch64-darwin.openclaw-runtime-plugin-tlon .#packages.aarch64-darwin.openclaw-runtime-plugin-whatsapp`
- `GITHUB_ACTIONS=true /usr/bin/time -p scripts/update-pins.sh apply v2026.6.1 2e08f0f4221f522b60423ed6ffd83427942b28de v2026.6.1 https://github.com/openclaw/openclaw/releases/download/v2026.6.1/OpenClaw-2026.6.1.zip`
- `nix build --accept-flake-config --no-link --print-out-paths .#checks.aarch64-darwin.ci` (`192.23s`)
- `nix build --accept-flake-config --no-link --print-out-paths .#checks.x86_64-linux.ci` (`413.95s`)

### `pr100-on99-ci-apply-split-2026-06-05`

- PR: `#100`, stacked locally on PR `#99`
  (`a528abcacd3903ac6898db02a757f9f7331122cf`).
- Measured code commit: `e93b21ed88e0a1e6f58e6c9487a141e540f9a66c`
- Base commit: `ba3b6e65b07d6ff50119247db6588416e68bd6b5`
- Purpose:
  - keep the default `ci` aggregate focused on the default package/config/apply
    contract;
  - move exhaustive runtime plugin catalog packaging into an explicit
    `runtime-plugin-packages` check;
  - remove duplicate macOS workflow builds of `.#openclaw-gateway`, since
    `stableChecks.gateway` is already a direct `ci` input.
- External rationale:
  - Nix `flake check` builds derivations under the `checks` output:
    https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-flake-check
  - Garnix selects named flake outputs through `garnix.yaml` include/exclude
    matchers and builds each selected drv path:
    https://garnix.io/docs/yaml_config/ and https://garnix.io/docs/steps/
  - NixOS VM tests are the right expensive proof for apply confidence, because
    they build and run a machine test in an isolated VM:
    https://nixos.org/manual/nixos/stable/#sec-nixos-tests
- Discrawl signals:
  - `golden-path-deployments`, 2026-05-26, reported the old pnpm dependency
    fetch path producing nondeterministic hashes, cross-platform optional
    dependency fetches, and Garnix cache misses.
  - `golden-path-deployments`, 2026-05-28, reported Garnix cache continuity as
    a project risk, so CI should avoid unnecessary cache targets while keeping
    the default install/apply contract explicit.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Darwin `ci` direct derivation inputs | `ba3b6e65` `ci` drv | 47 | `e93b21ed` `ci` drv | 13 | 72.3% fewer | `nix derivation show "$(nix eval --raw <ref>#checks.aarch64-darwin.ci.drvPath)" \| jq '.derivations[] \| .inputs.drvs \| keys \| length'` |
| Linux `ci` direct derivation inputs | `ba3b6e65` `ci` drv | 48 | `e93b21ed` `ci` drv | 14 | 70.8% fewer | same command for `checks.x86_64-linux.ci` |
| Direct runtime plugin package inputs in Darwin `ci` | `ba3b6e65` `ci` drv | 34 | `e93b21ed` `ci` drv | 0 | removed from default gate | `nix derivation show "$drv" \| jq -r '.derivations[] \| .inputs.drvs \| keys[]' \| rg -P 'openclaw-runtime-plugin-(?!locks)[a-z0-9-]+-[0-9].*\\.drv' \| wc -l` |
| Direct runtime plugin package inputs in Linux `ci` | `ba3b6e65` `ci` drv | 34 | `e93b21ed` `ci` drv | 0 | removed from default gate | same command for `checks.x86_64-linux.ci` |
| Runtime plugin lock check in `ci` | `ba3b6e65` `ci` drv | 1 | `e93b21ed` `ci` drv | 1 | retained | `nix derivation show "$drv" \| jq -r '.derivations[] \| .inputs.drvs \| keys[]' \| rg -c 'openclaw-runtime-plugin-locks'` |
| Explicit exhaustive runtime plugin package check | `ba3b6e65` flake checks | 0 | `e93b21ed` flake checks | 1 | added | `nix eval .#checks.aarch64-darwin --apply 'attrs: builtins.attrNames attrs'` |
| Hardcoded macOS gateway build command mentions | `ba3b6e65` workflows | 3 | `e93b21ed` workflows | 0 | removed | `rg -o 'nix build --accept-flake-config .#openclaw-gateway' .github/workflows \| wc -l` |
| Linux default CI aggregate | `557df7b4` equivalent aggregate before split | 413.95s | `862a887c`/`e93b21ed` equivalent graph after split | 268.33s uncached local run; 1.96s exact-ref cached rerun | 35.2% faster on uncached local run | `/usr/bin/time -p nix build --accept-flake-config --no-link --print-out-paths .#checks.x86_64-linux.ci` |
| Darwin exhaustive catalog proof | `e93b21ed` split checks, same local cache state | n/a | `ci` plus `runtime-plugin-packages` | 252.17s | recorded | `/usr/bin/time -p nix build --accept-flake-config --no-link --print-out-paths .#checks.aarch64-darwin.ci .#checks.aarch64-darwin.runtime-plugin-packages` |
| Darwin default CI aggregate warm rerun | `e93b21ed` after exhaustive proof | n/a | `ci` only | 0.87s dirty-tree, 36.94s contended clean rerun | recorded, cache-biased | `/usr/bin/time -p nix build --accept-flake-config --no-link --print-out-paths .#checks.aarch64-darwin.ci` |

Apply-confidence retained in `ci`:

- `packageSetStable.openclaw`
- `stableChecks.gateway` (`openclaw-gateway`)
- `bin-surface`
- `package-contents`
- `default-instance`
- `runtime-plugin-locks`
- `workspace-materializer`
- `config-validity`
- `gateway-smoke`
- `qmd-runtime` when available
- Linux `hm-activation`; macOS workflows still run
  `scripts/hm-activation-macos.sh`

Proof for measured commit:

- `git diff --check`
- `ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }; puts "yaml ok"' .github/workflows/ci.yml .github/workflows/pin-stable-openclaw-version.yml garnix.yaml`
- `nix eval --accept-flake-config --json .#checks.aarch64-darwin --apply 'attrs: builtins.attrNames attrs'`
- `nix eval --accept-flake-config --json .#checks.x86_64-linux --apply 'attrs: builtins.attrNames attrs'`
- `nix build --accept-flake-config --no-link --print-out-paths .#checks.aarch64-darwin.runtime-plugin-packages` (`2.18s` warm rerun after the exhaustive proof)
- `nix build --accept-flake-config --no-link --print-out-paths .#checks.aarch64-darwin.ci`
- `nix build --accept-flake-config --no-link --print-out-paths .#checks.x86_64-linux.ci`
- Exact rebased-code ref reruns:
  - `nix build --accept-flake-config --no-link --print-out-paths "git+file://$PWD?rev=e93b21ed88e0a1e6f58e6c9487a141e540f9a66c#checks.aarch64-darwin.ci"` (`1.80s` cached)
  - `nix build --accept-flake-config --no-link --print-out-paths "git+file://$PWD?rev=e93b21ed88e0a1e6f58e6c9487a141e540f9a66c#checks.x86_64-linux.ci"` (`1.96s` cached)
  - `nix build --accept-flake-config --no-link --print-out-paths "git+file://$PWD?rev=e93b21ed88e0a1e6f58e6c9487a141e540f9a66c#checks.aarch64-darwin.runtime-plugin-packages"` (`1.50s` cached)

### `pr100-remote-ci-cache-2026-06-06`

- PR: `#100`, stacked on PR `#99`
  (`a528abcacd3903ac6898db02a757f9f7331122cf`).
- Measured code commit: `9d0ae60e8cbc077d1969b0a4ca48863ec46a05b4`
- Base commit: `51aff7a59ba205bccdd77fd4f9e80fdbe3680d79`
- Purpose:
  - measure real remote CI/cache behavior for PR #100 instead of relying on
    local timings;
  - remove duplicate `push` plus `pull_request` GitHub Actions runs for PR
    branch pushes;
  - identify which work remains uncached by Garnix.
- Rejected interpretation:
  - The workflow change does not prove an individual derivation got faster. It
    removes duplicated remote workload for PR branches. Per-job speedups below
    are also affected by Garnix/cache warmth and must not be counted as pure
    code-speed gains.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| GitHub Actions CI events per PR branch SHA | run list for `51aff7a59`: `27045221578` push plus `27045223506` pull request | 2 | run list for `9d0ae60e`: `27045444112` pull request only | 1 | 50.0% fewer | `gh run list --repo openclaw/nix-openclaw --branch codex/npm-shrinkwrap-default --workflow CI --limit 8 --json databaseId,event,headSha,status,conclusion,createdAt,updatedAt,url` |
| GitHub Actions jobs per PR branch SHA | same two baseline runs | 4 | measured run `27045444112` | 2 | 50.0% fewer | `gh run view <run> --json jobs` |
| Observed Actions job-seconds per PR branch update | baseline push plus PR job durations: `167+232+166+231` | 796s | measured PR-only job durations: `132+193` | 325s | 59.2% fewer | `gh run view <run> --json jobs --jq '.jobs[] | {name,startedAt,completedAt}'` |
| Remote CI wall time to completed PR run | PR run `27045223506` | 234s | PR run `27045444112` | 197s | 15.8% faster, cache-influenced | `gh run view <run> --json createdAt,updatedAt` |
| Linux GitHub job duration | PR run `27045223506` | 166s | PR run `27045444112` | 132s | 20.5% faster, cache-influenced | `gh run view <run> --json jobs` |
| macOS GitHub job duration | PR run `27045223506` | 231s | PR run `27045444112` | 193s | 16.5% faster, cache-influenced | `gh run view <run> --json jobs` |
| Built derivation log lines in PR run | parsed log for `27045223506` | 131 | parsed log for `27045444112` | 91 | 30.5% fewer | `gh run view <run> --log | rg '^building ' | wc -l` |
| Unique built derivations in PR run | parsed log for `27045223506` | 76 | parsed log for `27045444112` | 58 | 23.7% fewer | `gh run view <run> --log | rg '^building ' | sort -u | wc -l` |
| macOS Darwin aggregate built derivation lines | `27045223506` step log | 37 | `27045444112` step log | 0 | fully substituted in measured run | parsed from `gh run view <run> --log` by step |
| macOS HM activation built derivation lines | `27045223506` step log | 59 | `27045444112` step log | 59 | unchanged | parsed from `gh run view <run> --log` by step |
| Garnix selected PR checks | PR #100 checks at `9d0ae60e` | n/a | Garnix status rows | 6 targets, all pass in 4s-14s plus overall 26s | recorded | `gh pr checks 100 --repo openclaw/nix-openclaw --watch=false` |

Remote cache analysis:

- `27045444112` copied `1,162` unique store paths: `60` from
  `cache.garnix.io`, `1,031` from `cache.nixos.org`, and `71` from
  `install.determinate.systems`.
- The Darwin `ci` aggregate was substituted completely in the measured run.
- Linux still built `openclaw-runtime-plugin-locks`,
  `openclaw-package-contents`, selected package/check derivations, and the
  Linux Home Manager/VM activation proof.
- macOS `scripts/hm-activation-macos.sh` remains outside the flake check graph,
  so Garnix cannot prebuild the activation package or its local activation
  derivations as currently wired.

Proof for measured commit:

- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "yaml ok"'`
- `gh run list --repo openclaw/nix-openclaw --branch codex/npm-shrinkwrap-default --workflow CI --limit 8 --json databaseId,event,headSha,status,conclusion,createdAt,updatedAt,url`
- `gh pr checks 100 --repo openclaw/nix-openclaw --watch=false`
- `gh pr view 100 --repo openclaw/nix-openclaw --json headRefName,headRefOid,baseRefName,baseRefOid,mergeStateStatus,isDraft,url`
- Latest measured PR-only run: `27045444112`, success,
  `2026-06-05T23:28:03Z` to `2026-06-05T23:31:20Z`.
- PR status at measured commit: `CLEAN`; all GitHub Actions, Garnix, Socket,
  and flake-evaluation checks passed.

### `pr100-macos-hm-cache-split-2026-06-06`

- PR: `#100`, stacked on PR `#99`
  (`a528abcacd3903ac6898db02a757f9f7331122cf`).
- Measured code commit: `d7b1bca93146f96f6194ab4b23e9e7b3f7bc2a4d`
- Base commit: `9d0ae60e8cbc077d1969b0a4ca48863ec46a05b4`
- Purpose:
  - expose the macOS Home Manager activation package as
    `checks.aarch64-darwin.hm-activation-macos-package`;
  - include it in Darwin `ci` so Garnix can prebuild/cache it;
  - keep `scripts/hm-activation-macos.sh` responsible for the impure runtime
    activation, launchd assertion, and gateway health assertion.
- Anti-regression review:
  - This does not remove macOS apply confidence. The script still runs
    `activate`, checks generated files/symlinks, checks launchd, and checks
    gateway health.
  - The main flake check and the nested consumer test flake resolved to the
    same activation-package drv locally:
    `/nix/store/s9axxmgixj273ai4z3idg21p6vfj14rf-home-manager-generation.drv`.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Remote CI wall time to completed PR run | `27045444112` at `9d0ae60e` | 197s | `27045908804` at `d7b1bca` | 156s | 20.8% faster | `gh run view <run> --json createdAt,updatedAt` |
| Linux GitHub job duration | `27045444112` | 132s | `27045908804` | 149s | 12.9% slower | `gh run view <run> --json jobs` |
| macOS GitHub job duration | `27045444112` | 193s | `27045908804` | 153s | 20.7% faster | same |
| macOS Darwin aggregate step | `27045444112` | 103s | `27045908804` | 86s | 16.5% faster, cache-influenced | same |
| macOS HM activation step | `27045444112` | 44s | `27045908804` | 22s | 50.0% faster | same |
| Built derivation log lines in PR run | parsed log for `27045444112` | 91 | parsed log for `27045908804` | 33 | 63.7% fewer | `gh run view <run> --log \| rg "building '/nix/store" \| wc -l` |
| Unique built derivations in PR run | parsed log for `27045444112` | 58 | parsed log for `27045908804` | 33 | 43.1% fewer | `gh run view <run> --log \| rg "building '/nix/store" \| sort -u \| wc -l` |
| macOS HM activation built derivation lines | `27045444112` step log | 59 | `27045908804` step log | 1 | 98.3% fewer | parsed from `gh run view <run> --log` by step |
| macOS Darwin aggregate built derivation lines | `27045444112` step log | 0 | `27045908804` step log | 0 | unchanged | same |
| Remote copy lines | parsed log for `27045444112` | 1,165 | parsed log for `27045908804` | 1,168 | +3 | same |
| Garnix selected PR checks | PR #100 checks at `9d0ae60e` | 6 targets, overall 26s, Darwin `ci` 10s | PR #100 checks at `d7b1bca` | 6 targets, overall 1m25s, Darwin `ci` 56s | slower first-run Garnix for larger Darwin `ci` | `gh pr checks 100 --repo openclaw/nix-openclaw --watch=false` |

Local proof for measured commit:

- `nix eval --accept-flake-config --raw .#checks.aarch64-darwin.hm-activation-macos-package.drvPath`
- `nix eval --accept-flake-config --raw --impure --override-input nix-openclaw "path:$PWD" ./nix/tests/hm-activation-macos#homeConfigurations.hm-test.activationPackage.drvPath`
- `nix build --accept-flake-config --no-link --print-out-paths .#checks.aarch64-darwin.hm-activation-macos-package` (`8.70s`, 10 local derivations built)
- `nix build --accept-flake-config --no-link --print-out-paths .#checks.aarch64-darwin.ci` (`37.53s` local rerun after activation-package build)
- `scripts/hm-activation-macos.sh` (`27.25s` first local run, `23.85s` warm rerun)
- `nix eval --accept-flake-config --json .#checks.x86_64-linux --apply 'attrs: builtins.attrNames attrs'`
- `ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }; puts "yaml ok"' .github/workflows/ci.yml .github/workflows/pin-stable-openclaw-version.yml garnix.yaml`
- `git diff --check`

Remote proof for measured commit:

- `27045908804`, success, `pull_request` only,
  `2026-06-05T23:42:21Z` to `2026-06-05T23:44:57Z`.
- PR status at measured commit: `CLEAN`; all GitHub Actions, Garnix, Socket,
  and flake-evaluation checks passed.

### `pr100-ci-meter-2026-06-06`

- PR: `#100`
- Measured commit: `5733ebdf9ed4597b8713d775fe6f0eefdbdc5a6a`
- Base commit: `3b70138463a962ae82fa9116f7f929c43440c7a9`
- Purpose:
  - wrap the Linux and Darwin aggregate `nix build` steps with a log tee and
    compact summary;
  - expose planned fetches, copied paths, built derivations, input fetches,
    warnings, and elapsed time in the GitHub step summary;
  - keep the check graph and build arguments unchanged.
- Tooling decision:
  - `nix-output-monitor` is useful locally, especially with Nix JSON logs, but
    the CI path avoids a new runtime dependency and keeps raw Nix logs intact.
  - `nix-fast-build --skip-cached` is relevant for future cache-presence probes,
    but it can skip downloading cached outputs. That is not the default
    install/apply proof contract in this PR.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Remote CI wall time to completed PR run | `27046069426` at `3b701384` | 163s | `27046898805` at `5733ebdf` | 146s | 10.4% faster, variance only | `gh run view <run> --json createdAt,updatedAt` |
| Linux GitHub job duration | `27046069426` | 140s | `27046898805` | 133s | 5.0% faster, variance only | `gh run view <run> --json jobs` |
| macOS GitHub job duration | `27046069426` | 160s | `27046898805` | 144s | 10.0% faster, variance only | same |
| Linux CI aggregate step | `27046069426` | 129s | `27046898805` | 126s | 2.3% faster, variance only | same |
| macOS Darwin aggregate step | `27046069426` | 93s | `27046898805` | 81s | 12.9% faster, variance only | same |
| macOS HM activation step | `27046069426` | 24s | `27046898805` | 20s | 16.7% faster, variance only | same |
| Total built derivation log lines | parsed log for `27046069426` | 33 | parsed log for `27046898805` | 33 | unchanged | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Total copied path log lines | parsed log for `27046069426` | 1,168 | parsed log for `27046898805` | 1,168 | unchanged | same |
| Linux aggregate fetch plan | parsed log for `27046069426` | 932 paths, 1.2 GiB download, 5.2 GiB unpacked | parsed log for `27046898805` | 932 paths, 1.2 GiB download, 5.2 GiB unpacked | unchanged | same |
| Darwin aggregate fetch plan | parsed log for `27046069426` | 227 paths, 286 MiB download, 1.8 GiB unpacked | parsed log for `27046898805` | 227 paths, 286 MiB download, 1.8 GiB unpacked | unchanged | same |
| Metered aggregate workflow calls | `3b701384` workflows | 0 | `5733ebdf` workflows | 4 | added | `rg -o 'scripts/ci-nix-build\\.sh .*checks\\.(x86_64-linux\|aarch64-darwin)\\.ci' .github/workflows/*.yml \| wc -l` |
| Direct unmetered aggregate `nix build` run calls | `3b701384` workflows | 4 | `5733ebdf` workflows | 0 | removed | `rg -o 'run: (timeout --foreground 50m )?nix build .*checks\\.(x86_64-linux\|aarch64-darwin)\\.ci' .github/workflows/*.yml \| wc -l` |

Metered remote profile at `5733ebdf`:

| Step | Seconds | Fetch plan | Planned builds | Copied paths | Built drvs | Copy sources |
| --- | ---: | --- | ---: | ---: | ---: | --- |
| Linux aggregate | 126 | 932 paths, 1.2 GiB download, 5.2 GiB unpacked | 29 | 937 | 29 | cache.nixos.org 887, cache.garnix.io 50 |
| Darwin aggregate | 81 | 227 paths, 286 MiB download, 1.8 GiB unpacked | 0 | 231 | 0 | cache.nixos.org 138, install.determinate.systems 59, cache.garnix.io 34 |
| macOS HM activation | 20 | none | 0 | 0 | 1 | none |

Interpretation:

- This change adds observability, not a claimed performance improvement.
- The unchanged built/copy profile shows the wrapper did not alter the package
  graph.
- The remaining CI hot spot is cold-runner substitution volume: Linux copies
  5.2 GiB unpacked before building the 29 Linux proof derivations; Darwin
  copies 1.8 GiB unpacked and builds no aggregate derivations.
- Next improvement candidates should target cache topology and Linux proof
  derivations, not more macOS aggregate splitting.

Local proof for measured commit:

- `node --check scripts/summarize-nix-build-log.mjs`
- `bash -n scripts/ci-nix-build.sh`
- `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-27046069426.log`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci --accept-flake-config --no-link .#checks.aarch64-darwin.ci`
- `ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }; puts "yaml ok"' .github/workflows/ci.yml .github/workflows/pin-stable-openclaw-version.yml garnix.yaml`
- `git diff --check`

Remote proof for measured commit:

- `27046898805`, success, `pull_request`,
  `2026-06-06T00:15:29Z` to `2026-06-06T00:17:55Z`.
- PR checks at measured commit: GitHub Actions Linux/macOS pass; Garnix
  flake evaluation, Darwin `ci`, and selected package targets pass.

### `pr100-gha-cache-rejected-2026-06-06`

- PR: `#100`
- Baseline commit: `886ad5710ac1cb94bcf1f4e493db3858d9855560`
- Candidate commits:
  - `0802eb1d0a00da4779b3a795ff19f082cd87080d`: Magic Nix Cache on
    Linux and macOS.
  - `a05e9981c943140b65771bb67c17d3eb3aa2884e`: Magic Nix Cache on
    Linux only.
- Purpose:
  - test whether GitHub Actions cache can replace some cold-runner
    substitution cost now that Garnix is going away;
  - keep upstream substituter proof intact and disable FlakeHub/diagnostics
    in the action.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Remote PR run wall time | `27047041028` at `886ad571` | 144s | `27047323809` at `a05e998` | 166s | 15.3% slower | `gh run view <run> --json createdAt,updatedAt` |
| Linux GitHub job duration | `27047041028` | 139s | `27047323809` | 155s | 11.5% slower | `gh run view <run> --json jobs` |
| Linux aggregate step | `27047041028` | 128s | `27047323809` | 136s | 6.3% slower | same |
| Linux cache setup step | `27047041028` | 0s | `27047323809` | 10s | added overhead | same |
| Linux post-cache step | `27047041028` | 0s | `27047323809` | 1s | added overhead | same |
| Linux copied path log lines | parsed log for `27047041028` | 937 | parsed log for `27047323809` | 1292 | 37.9% more lines | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Linux copied unique paths | parsed log for `27047041028` | 937 | parsed log for `27047323809` | 937 | unchanged | same |
| Linux Garnix copy lines | parsed log for `27047041028` | 50 | parsed log for `27047323809` | 50 | unchanged | same |
| Linux local cache proxy copy lines | parsed log for `27047041028` | 0 | parsed log for `27047323809` | 887 | added indirection | same |
| macOS all-platform cache setup | no cache step in `27047041028` | 0s | `27047224090` at `0802eb1` | 183s then cancelled | blocked proof | `gh run view 27047224090 --json jobs` |
| Magic cache workflow markers | `a05e998` workflows | 10 | `4d4ec099` workflows | 0 | removed | `git grep -n 'magic-nix-cache-action\|Cache Nix store' <rev> -- .github/workflows \| wc -l` |

Interpretation:

- Reject this cache action for PR `#100`.
- It did not reduce unique substitution work, did not reduce Garnix reliance,
  inflated Linux copy logs, added Linux setup overhead, and made the first
  macOS candidate fail to reach the Darwin proof.
- The next CI speed work should target closure volume, eval cost, public cache
  topology, or runner shape rather than GitHub Actions store-cache wrapping.

### `pr100-nix-eval-telemetry-2026-06-06`

- PR: `#100`
- Measured commit: `4d4ec0996548984a1f2e2a07e240b88b7e57d3e8`
- Base commit: `a05e9981c943140b65771bb67c17d3eb3aa2884e`
- Purpose:
  - remove the rejected Magic Nix Cache workflow steps;
  - timestamp the CI meter's raw Nix stderr sidecar without changing console
    output;
  - set `NIX_SHOW_STATS=1` for metered aggregate `nix build` calls and render
    eval counters plus phase hints in the summary.
- Tooling decision:
  - `nix-output-monitor` remains a good local/human display, but the PR needs
    parseable audit metrics more than a new CI display dependency.
  - `json-log-path`, `--log-format internal-json`, `nix-eval-jobs`,
    `nix-fast-build`, `nix path-info`, `nix derivation show`, `nix why-depends`,
    and `nix-tree` are the drill-down toolbox for follow-up hotspot work.
  - Do not use `nix-fast-build --skip-cached` as the default proof path because
    skipping cached outputs would no longer prove the install/apply closure copy
    behavior that users actually hit.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Magic cache workflow markers | `a05e998` workflows | 10 | `4d4ec099` workflows | 0 | removed | `git grep -n 'magic-nix-cache-action\|Cache Nix store' <rev> -- .github/workflows \| wc -l` |
| Metered aggregate workflow calls | `886ad571` workflows | 4 | `4d4ec099` workflows | 4 | unchanged | `git grep -n 'scripts/ci-nix-build.sh .*checks\\.' <rev> -- .github/workflows \| wc -l` |
| Cached local Darwin aggregate wall time | old meter had no eval stats | n/a | `4d4ec099` dirty worktree local run | 8s | recorded | `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci --accept-flake-config --no-link .#checks.aarch64-darwin.ci` |
| Cached local Darwin eval CPU | old meter had no eval stats | n/a | same local run | 6.62s | added | same |
| Cached local Darwin eval thunks | old meter had no eval stats | n/a | same local run | 14,467,912 | added | same |
| Cached local Darwin eval values | old meter had no eval stats | n/a | same local run | 29,254,120 | added | same |
| Cached local Darwin eval function calls | old meter had no eval stats | n/a | same local run | 7,542,030 | added | same |
| Historical Linux phase hints | `27047041028` parsed before telemetry | n/a | parser at `4d4ec099` over same log | input fetch +9.83s, plan +42s, copy +0.95s..+69s, build +56s..+123s | added | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-27047041028.log` |
| Remote PR run wall time | `27047323809` cache candidate | 166s | `27047822497` at `2b9ec611` | 156s | 6.0% faster than rejected cache | `gh run view <run> --json createdAt,updatedAt` |
| Remote Linux job duration | `27047323809` cache candidate | 155s | `27047822497` | 125s | 19.4% faster than rejected cache | `gh run view <run> --json jobs` |
| Remote Linux aggregate step | `27047323809` cache candidate | 136s | `27047822497` | 115s | 15.4% faster than rejected cache | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-27047822497.log` |
| Remote Darwin aggregate step | `27047041028` pre-cache baseline | 79s | `27047822497` | 85s | 7.6% slower, variance plus stats output | same |
| Remote Linux aggregate eval CPU | telemetry not present before `4d4ec099` | n/a | `27047822497` | 15s | added | same |
| Remote Darwin aggregate eval CPU | telemetry not present before `4d4ec099` | n/a | `27047822497` | 14s | added | same |
| Remote Linux copied unique paths | `27047041028` pre-cache baseline | 937 | `27047822497` | 937 | unchanged | same |
| Remote Linux copied path log lines | `27047323809` cache candidate | 1292 | `27047822497` | 937 | 27.5% fewer than rejected cache | same |

Local proof for measured commit:

- `node --check scripts/summarize-nix-build-log.mjs`
- `bash -n scripts/ci-nix-build.sh`
- `ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }; puts "yaml ok"' .github/workflows/ci.yml .github/workflows/pin-stable-openclaw-version.yml garnix.yaml`
- `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-27047041028.log`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci --accept-flake-config --no-link .#checks.aarch64-darwin.ci`
- `git diff --check`

Remote proof:

- `27047822497`, success, `pull_request`,
  `2026-06-06T00:50:53Z` to `2026-06-06T00:53:29Z`.
- PR checks at `2b9ec6114f3728306ac512984c1ac9661484274f`: GitHub
  Actions Linux/macOS pass; Garnix flake evaluation, Darwin `ci`, and selected
  package targets pass; Socket checks pass.
- Parsed summary:
  - Linux aggregate: 115s, 932 paths fetched, 1.2 GiB download, 5.2 GiB
    unpacked, 937 unique copied paths, 29 built derivations, eval CPU 15s.
  - Darwin aggregate: 85s, 227 paths fetched, 286 MiB download, 1.8 GiB
    unpacked, 231 unique copied paths, 0 built derivations, eval CPU 14s.

### `pr100-on99-latest-restack-2026-06-06`

- PR: `#100`
- Measured commit: `6e87b41a28dfc40658bc59293201963a2792c5cd`
- Previous PR #100 head: `c318250607171c4bc460c0b98c2dc10d9e32f1dd`
- Latest PR #99 head used as stack base:
  `b0c24bdb778eab0a18d9ac5e95cbd76b052a1e77`
- Purpose:
  - rebase PR #100 onto latest PR #99;
  - keep PR #99's locked runtime plugin source/spec interface;
  - keep PR #100's generated ACPX reuse, optional OpenClaw peer linking, and
    shrinkwrap package pruning.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Gateway closure | prior optimized graph `557df7b4`/`f785b9d3` equivalent | 904,983,184 B | `6e87b41a` gateway path `/nix/store/6q5fc2xg5ialr6a6ax1b3vf6162k4qv9-openclaw-gateway-2026.6.1` | 904,983,184 B | unchanged | `nix path-info -S "$gateway"` |
| `openclaw` closure | prior optimized graph `557df7b4`/`f785b9d3` equivalent | 1,846,536,320 B | `6e87b41a` path `/nix/store/ndybc97fhchy2mxw1mplgk8brqmfcc2v-openclaw-2026.6.1` | 1,846,536,320 B | unchanged | `nix path-info -S "$openclaw"` |
| ACPX runtime plugin closure | prior optimized graph `f785b9d3` | 1,332,793,752 B | `6e87b41a` path `/nix/store/lc3mqmq4kj2vclkc20c0c7v13xzw7da5-openclaw-runtime-plugin-acpx-2026.6.1` | 1,332,793,752 B | unchanged | `nix path-info -S "$acpx"` |
| Package manifests | prior optimized graph `f785b9d3` | 584 | `6e87b41a` gateway path | 584 | unchanged | `find "$gateway/lib/openclaw" -name package.json \| wc -l` |
| Files under `lib/openclaw` | prior optimized graph `f785b9d3` | 34,054 | `6e87b41a` gateway path | 34,054 | unchanged | `find "$gateway/lib/openclaw" -type f \| wc -l` |
| Darwin `ci` direct derivation inputs | `e93b21ed` split gate before latest PR #99 source-lock checks | 13 | `6e87b41a` `ci` drv | 14 | +1 source-lock/apply input | `nix derivation show "$(nix eval --raw .#checks.aarch64-darwin.ci.drvPath)" \| jq '.derivations[] \| .inputs.drvs \| keys \| length'` |
| Linux `ci` direct derivation inputs | `e93b21ed` split gate | 14 | `6e87b41a` `ci` drv | 14 | unchanged | same for `checks.x86_64-linux.ci` |
| Direct runtime plugin package inputs in `ci` | `e93b21ed` split gate | 0 | `6e87b41a` Darwin/Linux `ci` drvs | 0 | unchanged | `nix derivation show "$drv" \| jq -r '.derivations[] \| .inputs.drvs \| keys[]' \| rg 'openclaw-runtime-plugin-' \| rg -v 'openclaw-runtime-plugin-locks' \| wc -l` |
| Runtime plugin lock check in `ci` | `e93b21ed` split gate | 1 | `6e87b41a` Darwin/Linux `ci` drvs | 1 | retained | same |
| Local Darwin aggregate | rebased store paths cold locally | n/a | `6e87b41a` | 121s, 24 planned builds, 22 unique built drvs, eval CPU 8.52s | recorded | `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci --accept-flake-config --no-link .#checks.aarch64-darwin.ci` |
| Local Linux aggregate via remote builder | rebased store paths cold locally | n/a | `6e87b41a` | 208s, 31 planned builds, 31 unique built drvs, eval CPU 8.26s | recorded | `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-ci --accept-flake-config --no-link .#checks.x86_64-linux.ci` |
| Explicit Darwin runtime plugin catalog proof | latest PR #99 stack plus PR #100 packager resolution | n/a | `6e87b41a` | 165.76s, 32 planned plugin derivations | recorded | `nix build --accept-flake-config --no-link .#checks.aarch64-darwin.runtime-plugin-packages` |
| Remote PR run wall time | `27047925150` at `c318250` | 194s | `27048540708` at `6e87b41a` | 292s | 50.5% slower, cache miss | `gh run view <run> --json createdAt,updatedAt` |
| Remote Linux job duration | `27047925150` | 118s | `27048540708` | 166s | 40.7% slower, cache miss | `gh run view <run> --json jobs` |
| Remote macOS job duration | `27047925150` | 192s | `27048540708` | 288s | 50.0% slower, cache miss | same |
| Remote Linux aggregate | `27047925150` | 108s, 932 fetched paths, 1.2 GiB download, 29 built drvs | `27048540708` | 157s, 941 fetched paths, 2.1 GiB download, 32 built drvs | slower first-run graph/cache | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Remote Darwin aggregate | `27047925150` | 111s, 227 fetched paths, 286 MiB download, 0 built drvs | `27048540708` | 211s, 275 fetched paths, 1.4 GiB download, 24 built drvs | slower first-run graph/cache | same |

Interpretation:

- The rebase preserved the optimized package graph: gateway, `openclaw`, ACPX,
  manifest count, and file count are unchanged from the prior optimized graph.
- The first remote run on the new stack was slower because the new PR #99 base
  changed store paths and GitHub built proof derivations before the external
  cache had caught up. This is not a permanent graph regression by itself.
- The default `ci` gate still avoids exhaustive runtime plugin package fan-out.
  Runtime plugin catalog packaging remains explicit and was locally proven.

Local proof for measured commit:

- `node --check nix/scripts/openclaw-runtime-plugin-install.mjs`
- `node --check nix/scripts/update-openclaw-runtime-plugin-locks.mjs`
- `node --check scripts/summarize-nix-build-log.mjs`
- `bash -n scripts/ci-nix-build.sh scripts/hm-activation-macos.sh scripts/update-pins.sh nix/scripts/check-package-contents.sh nix/scripts/openclaw-gateway-npm-install.sh`
- `ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }' .github/workflows/ci.yml .github/workflows/pin-stable-openclaw-version.yml garnix.yaml`
- `nix eval --accept-flake-config --json .#checks.aarch64-darwin --apply 'attrs: builtins.attrNames attrs'`
- `nix eval --accept-flake-config --json .#checks.x86_64-linux --apply 'attrs: builtins.attrNames attrs'`
- `nix build --accept-flake-config --no-link .#packages.aarch64-darwin.openclaw-runtime-plugin-acpx`
- `nix build --accept-flake-config --no-link .#openclaw-gateway`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci --accept-flake-config --no-link .#checks.aarch64-darwin.ci`
- `nix build --accept-flake-config --no-link .#checks.aarch64-darwin.runtime-plugin-locks`
- `nix build --accept-flake-config --no-link .#checks.aarch64-darwin.runtime-plugin-packages`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-ci --accept-flake-config --no-link .#checks.x86_64-linux.ci`
- `git diff --check`

Remote proof:

- `27048540708`, success, `pull_request`,
  `2026-06-06T01:18:53Z` to `2026-06-06T01:23:45Z`.
- PR checks at `6e87b41a28dfc40658bc59293201963a2792c5cd`: GitHub
  Actions Linux/macOS pass; Garnix flake evaluation, Darwin `ci`, and selected
  package targets pass; Socket checks pass.

### `pr100-macos-max-jobs-2-2026-06-06`

- PR: `#100`
- Measured commit: `debf0c1ce94c06585c059e5a0cf5af38127ec6d3`
- Base commit: `6e87b41a28dfc40658bc59293201963a2792c5cd`
- Purpose:
  - raise hosted macOS Nix build concurrency from `max-jobs 1` to `max-jobs 2`;
  - keep the same Darwin `ci` aggregate and Home Manager activation proof;
  - apply the same setting to stable-pin macOS validation.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| macOS workflow `max-jobs` | `6e87b41a` workflows | 1 | `debf0c1c` workflows | 2 | raised | `rg 'max-jobs' .github/workflows/*.yml` |
| Remote PR run wall time | `27048540708` at `6e87b41a` | 292s | `27048722860` at `debf0c1c` | 184s | 37.0% faster, cache-influenced | `gh run view <run> --json createdAt,updatedAt` |
| Remote macOS job duration | `27048540708` | 288s | `27048722860` | 180s | 37.5% faster, cache-influenced | `gh run view <run> --json jobs` |
| Remote macOS Darwin aggregate | `27048540708` | 211s, 275 fetched paths, 1.4 GiB download, 24 built drvs | `27048722860` | 111s, 227 fetched paths, 286 MiB download, 0 built drvs | 47.4% faster, cache-influenced | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Warm-run Darwin aggregate comparison | `27047925150` at `c318250`, `max-jobs 1` | 111s, 0 built drvs | `27048722860`, `max-jobs 2` | 111s, 0 built drvs | no isolated warm-cache speedup | same |
| Remote Linux job duration | `27048540708` | 166s | `27048722860` | 133s | 19.9% faster, cache-influenced control | `gh run view <run> --json jobs` |
| Remote Linux aggregate | `27048540708` | 157s, 941 fetched paths, 2.1 GiB download, 32 built drvs | `27048722860` | 125s, 932 fetched paths, 1.2 GiB download, 29 built drvs | 20.4% faster, cache-influenced control | parser command above |
| Local cached Darwin aggregate with `max-jobs 2` | after local proof warmed paths | n/a | `debf0c1c` dirty worktree | 10s, 0 built drvs, eval CPU 7.78s | recorded | `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci-max-jobs-2 --accept-flake-config --option max-jobs 2 --no-link .#checks.aarch64-darwin.ci` |

Interpretation:

- Keep `max-jobs 2`: hosted macOS accepted it and the proof contract is
  unchanged.
- Do not claim the full remote speedup as an isolated concurrency win. The
  measured run was cache-warm and built zero Darwin derivations; it mainly
  proves that the less-serialized setting no longer trips the hosted runner.
- If future package-affecting runs build locally on macOS, this setting should
  reduce cold-build wall time relative to `max-jobs 1`, but that remains a
  hypothesis until a comparable cold remote run builds the same derivations.

Local proof for measured commit:

- Workflow YAML parse for CI, stable-pin, and Garnix config.
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci-max-jobs-2 --accept-flake-config --option max-jobs 2 --no-link .#checks.aarch64-darwin.ci`
- `git diff --check`

Remote proof:

- `27048722860`, success, `pull_request`,
  `2026-06-06T01:26:37Z` to `2026-06-06T01:29:41Z`.
- PR checks at `debf0c1ce94c06585c059e5a0cf5af38127ec6d3`: GitHub
  Actions Linux/macOS pass; Garnix flake evaluation, Darwin `ci`, and selected
  package targets pass; Socket checks pass.

### `pr100-contextful-config-json-2026-06-06`

- PR: `#100`
- Base commit: `6197f2f2f543952d0c11f8266490f8c2fa6697e1`
- Measured code commit: `6ce39fb68fca65f092d13ecf9d1b7a267fe1bbd0`
- Purpose:
  - preserve Nix string context when rendering generated OpenClaw JSON config;
  - keep Home Manager activation source-backed while preserving eval-time config
    text for checks;
  - normalize plugin-provided skill directories as explicit Nix store paths.
- Package outputs:
  - measured gateway:
    `/nix/store/6q5fc2xg5ialr6a6ax1b3vf6162k4qv9-openclaw-gateway-2026.6.1`
  - measured `openclaw`:
    `/nix/store/ndybc97fhchy2mxw1mplgk8brqmfcc2v-openclaw-2026.6.1`

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Darwin improper-context warnings | `6197f2f2` eval stderr | 4 | `6ce39fb6` eval stderr | 1 | 75.0% fewer | `nix eval --accept-flake-config --option eval-cache false --raw .#checks.aarch64-darwin.ci.drvPath` |
| Linux improper-context warnings | `6197f2f2` eval stderr | 6 | `6ce39fb6` eval stderr | 1 | 83.3% fewer | same for `.#checks.x86_64-linux.ci.drvPath` |
| Generated OpenClaw config improper-context warnings, Darwin | `6197f2f2` eval stderr | 3 | `6ce39fb6` eval stderr | 0 | removed | same |
| Generated OpenClaw config improper-context warnings, Linux | `6197f2f2` eval stderr | 5 | `6ce39fb6` eval stderr | 0 | removed | same |
| Darwin aggregate direct input derivations | `6197f2f2` `ci.drvPath` | 14 | `6ce39fb6` `ci.drvPath` | 14 | unchanged | `nix derivation show "$drv" \| jq '.derivations[] \| .inputs.drvs \| length'` |
| Linux aggregate direct input derivations | `6197f2f2` `ci.drvPath` | 14 | `6ce39fb6` `ci.drvPath` | 14 | unchanged | same |
| Gateway closure | prior optimized graph `6e87b41a`/`6197f2f2` equivalent | 904,983,184 B | `6ce39fb6` gateway path above | 904,983,184 B | unchanged | `nix path-info -S "$gateway"` |
| `openclaw` closure | prior optimized graph `6e87b41a`/`6197f2f2` equivalent | 1,846,536,320 B | `6ce39fb6` `openclaw` path above | 1,846,536,320 B | unchanged | `nix path-info -S "$openclaw"` |
| Gateway package manifests | prior optimized graph | 584 | `6ce39fb6` gateway path above | 584 | unchanged | `find "$gateway/lib/openclaw" -name package.json \| wc -l` |
| Files under `lib/openclaw` | prior optimized graph | 34,054 | `6ce39fb6` gateway path above | 34,054 | unchanged | `find "$gateway/lib/openclaw" -type f \| wc -l` |
| Remote GitHub workflow wall time | `27048974295` at `6197f2f2` | 166s | `27049891158` at docs commit `72936ff2`, graph commit `6ce39fb6` | 160s | 3.6% faster, cache-influenced | `gh run view <run> --json createdAt,updatedAt` |
| Remote Linux job duration | `27048974295` | 141s | `27049891158` | 146s | 3.5% slower | `gh run view <run> --json jobs` |
| Remote Linux aggregate | `27048974295` | 130s, 932 fetched paths, 1.2 GiB download, 29 built drvs | `27049891158` | 136s, 929 fetched paths, 1.2 GiB download, 31 built drvs | 4.6% slower; two tiny generated config drvs are now tracked | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Remote macOS job duration | `27048974295` | 163s | `27049891158` | 155s | 4.9% faster | `gh run view <run> --json jobs` |
| Remote Darwin aggregate | `27048974295` | 93s, 227 fetched paths, 286 MiB download, 0 built drvs, 5 warnings | `27049891158` | 88s, 226 fetched paths, 286 MiB download, 0 built drvs, 2 warnings | 5.4% faster, 60.0% fewer warnings | parser command above |
| Remote macOS HM activation | `27048974295` | 20s, 3 warnings | `27049891158` | 17s, 1 warning | 15.0% faster, 66.7% fewer warnings | parser command above |
| Remote macOS warning lines, aggregate plus HM activation | `27048974295` | 8 | `27049891158` | 3 | 62.5% fewer | parser command above |

Rejected simplification:

- Replacing generated config derivations with `builtins.toFile` would have
  removed tiny JSON derivations, but Nix rejected config files that reference
  derivation outputs such as runtime-plugin packages. Keep `pkgs.writeText`.

Local proof for measured code commit:

- `nix eval --accept-flake-config --json .#checks.aarch64-darwin --apply 'attrs: builtins.attrNames attrs'`
- `nix eval --accept-flake-config --json .#checks.x86_64-linux --apply 'attrs: builtins.attrNames attrs'`
- `nix build --accept-flake-config --no-link .#checks.aarch64-darwin.config-validity`
- `nix build --accept-flake-config --no-link .#checks.aarch64-darwin.default-instance`
- `nix build --accept-flake-config --no-link .#checks.x86_64-linux.default-instance`
- `nix build --accept-flake-config --no-link .#checks.aarch64-darwin.hm-activation-macos-package`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci --accept-flake-config --no-link .#checks.aarch64-darwin.ci`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-ci --accept-flake-config --no-link .#checks.x86_64-linux.ci`
- `git diff --check`
- `bash -n scripts/ci-nix-build.sh scripts/hm-activation-macos.sh scripts/update-pins.sh nix/scripts/check-package-contents.sh nix/scripts/openclaw-gateway-npm-install.sh`
- `node --check scripts/summarize-nix-build-log.mjs`

Remote proof:

- Garnix on PR head `06ebf991d41a81297c03b4152fd477b8a299c279`,
  success, `2026-06-06T02:24:22Z` to `2026-06-06T02:25:09Z`:
  flake evaluation `14s`, Darwin `ci` `33s`, selected package targets `5s`
  to `14s`.
- GitHub Actions did not create a `pull_request` run after pushing
  `72936ff2383d31c0d0ef029acb36e2a44d6b6358`; manually dispatched
  `27049891158` on `codex/npm-shrinkwrap-default`, success,
  `2026-06-06T02:19:29Z` to `2026-06-06T02:22:09Z`.
- GitHub Actions jobs for `27049891158`: Linux `2m26s`, macOS `2m35s`.
  Because `72936ff2383d31c0d0ef029acb36e2a44d6b6358` is this audit-only
  documentation commit, the measured package/check graph is the
  `6ce39fb68fca65f092d13ecf9d1b7a267fe1bbd0` graph.
- PR `#100` base was retargeted to PR `#99`
  (`codex/runtime-plugin-shrinkwrap-materialization`) after the proof run so
  the review base matches the commit stack. GitHub then reported
  `mergeStateStatus=CLEAN` at `06ebf991d41a81297c03b4152fd477b8a299c279`.

### `pr100-qmd-instance-split-2026-06-06`

- PR: `#100`
- Measured commit: `ff85f6bb3ad264a75c0eafb7a9dac0e22871288c`
- Base commit: `e9bf98d4c4571bf07c47723bf3bde2cf139bc0a6`
- Purpose:
  - keep default CI focused on default package/config/apply proof;
  - preserve explicit QMD proof through `qmd-instance` and `qmd-runtime`;
  - remove the QMD package output copy/build from the default aggregate.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Linux `default-instance` direct QMD inputs | `e9bf98d4` cache-status JSONL | 1 | `ff85f6bb` cache-status JSONL | 0 | removed | `nix-eval-jobs --flake .#checks.x86_64-linux --workers 1 --check-cache-status --show-input-drvs` |
| Darwin `default-instance` direct QMD inputs | `e9bf98d4` cache-status JSONL | 1 | `ff85f6bb` cache-status JSONL | 0 | removed | same for `.#checks.aarch64-darwin` |
| Explicit QMD check attrs, Linux | `e9bf98d4` check attr names | 1 | `ff85f6bb` check attr names | 2 | `qmd-instance` added | `nix eval --accept-flake-config --json .#checks.x86_64-linux --apply 'attrs: builtins.attrNames attrs'` |
| Explicit QMD check attrs, Darwin | `e9bf98d4` check attr names | 1 | `ff85f6bb` check attr names | 2 | `qmd-instance` added | same for `.#checks.aarch64-darwin` |
| Linux QMD output copy/build log lines | `27050280272` at `e9bf98d4` | 4 | `27050639529` at `ff85f6bb` | 0 | removed | `rg -n 'openclaw-qmd\|qmd-[0-9].*\|copying path .*qmd' /tmp/nix-openclaw-ci-logs/run-<run>.log \| rg -v 'github:tobi/qmd'` |
| Linux aggregate planned builds | `27050280272` | 30 | `27050639529` | 29 | 3.3% fewer | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Linux aggregate copied paths | `27050280272` | 934 | `27050639529` | 931 | 0.3% fewer | same |
| Linux aggregate fetch plan, download | `27050280272` | 1.2 GiB | `27050639529` | 936 MiB | about 22% smaller | same |
| Linux aggregate fetch plan, unpacked | `27050280272` | 5.2 GiB | `27050639529` | 4.2 GiB | about 19% smaller | same |
| Linux aggregate step | `27050280272` | 129s | `27050639529` | 99s | 23.3% faster | same |
| Linux job duration | `27050280272` | 140s | `27050639529` | 107s | 23.6% faster | `gh run view <run> --json jobs` |
| macOS aggregate step | `27050280272` | 85s | `27050639529` | 106s | 24.7% slower, runner variance | parser command above |
| macOS job duration | `27050280272` | 151s | `27050639529` | 173s | 14.6% slower, runner variance | `gh run view <run> --json jobs` |
| Garnix all checks | `e9bf98d4` PR status | 58s | `ff85f6bb` PR status | 48s | 17.2% faster, cache-influenced | `gh pr view 100 --json statusCheckRollup` |

Local proof for measured commit:

- `nix eval --accept-flake-config --json .#checks.x86_64-linux --apply 'attrs: builtins.attrNames attrs'`
- `nix eval --accept-flake-config --json .#checks.aarch64-darwin --apply 'attrs: builtins.attrNames attrs'`
- `nix run --accept-flake-config nixpkgs#nix-eval-jobs -- --flake .#checks.x86_64-linux --workers 1 --check-cache-status --show-input-drvs`
- `nix run --accept-flake-config nixpkgs#nix-eval-jobs -- --flake .#checks.aarch64-darwin --workers 1 --check-cache-status --show-input-drvs`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci-qmd-split --accept-flake-config --no-link .#checks.aarch64-darwin.ci .#checks.aarch64-darwin.qmd-instance .#checks.aarch64-darwin.qmd-runtime`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-ci-qmd-split --accept-flake-config --no-link .#checks.x86_64-linux.ci .#checks.x86_64-linux.qmd-instance .#checks.x86_64-linux.qmd-runtime`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci-qmd-split-ci-only --accept-flake-config --no-link .#checks.aarch64-darwin.ci`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-ci-qmd-split-ci-only --accept-flake-config --no-link .#checks.x86_64-linux.ci`
- `git diff --check`

Remote proof:

- GitHub Actions `27050639529`, `pull_request`, success on
  `ff85f6bb3ad264a75c0eafb7a9dac0e22871288c`.
- GitHub Actions jobs: Linux `1m47s`, macOS `2m53s`.
- Parser summary: Linux aggregate `99s`, 926 fetched paths, 936 MiB download,
  4.2 GiB unpacked, 29 planned/built derivations; macOS aggregate `106s`, 226
  fetched paths, 286 MiB download, 1.8 GiB unpacked.
- `rg` over the GitHub log shows only the QMD flake input unpack remains; QMD
  package output copy and `openclaw-qmd.drv` build lines are gone from default
  CI.
- Garnix on PR head `ff85f6bb3ad264a75c0eafb7a9dac0e22871288c`, success,
  `2026-06-06T02:55:19Z` to `2026-06-06T02:56:07Z`.
- GitHub reported `mergeStateStatus=CLEAN` at
  `ff85f6bb3ad264a75c0eafb7a9dac0e22871288c`.

### `pr100-qmd-lazy-input-2026-06-06`

- PR: `#100`
- Measured commit: `063d825de22814eb30a22e45978a43815d493ed1`
- Base commit: `3842f6732f0d3570d9acb0564ed5526688d018c6`
- Purpose:
  - keep the QMD package/check outputs available;
  - avoid forcing `qmdPackage != null` while constructing default package and
    check attrsets;
  - remove the remaining `github:tobi/qmd` input unpack from default CI eval.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Clean-cache Linux `ci.drvPath` QMD input unpack | `3842f673` remote log `27050743619` | 1 | `063d825` clean local eval and remote log `27050932456` | 0 | removed | `XDG_CACHE_HOME=$(mktemp -d) nix eval --accept-flake-config --option eval-cache false --raw .#checks.x86_64-linux.ci.drvPath` |
| Linux CI QMD log lines | `27050743619` | 1 | `27050932456` | 0 | removed | `rg -n 'qmd\|openclaw-qmd\|github:tobi/qmd' /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Linux aggregate input fetches | `27050743619` | 2 | `27050932456` | 1 | 50.0% fewer | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Linux aggregate copied paths | `27050743619` | 931 | `27050932456` | 930 | 0.1% fewer | same |
| Linux aggregate Garnix copies | `27050743619` | 46 | `27050932456` | 45 | 2.2% fewer | same |
| Linux eval thunks | `27050743619` | 14,488,466 | `27050932456` | 14,304,918 | 1.3% fewer | same |
| Linux eval values | `27050743619` | 28,507,042 | `27050932456` | 27,971,449 | 1.9% fewer | same |
| Linux eval function calls | `27050743619` | 10,651,729 | `27050932456` | 10,510,394 | 1.3% fewer | same |
| Linux aggregate step | `27050743619` | 119s | `27050932456` | 124s | 4.2% slower, runner variance | same |
| Linux job duration | `27050743619` | 127s | `27050932456` | 131s | 3.1% slower, runner variance | `gh run view <run> --json jobs` |
| macOS aggregate step | `27050743619` | 85s | `27050932456` | 88s | 3.5% slower, runner variance | parser command above |
| Package `qmd` outputs | `3842f673` package attrs | present on Linux and Darwin | `063d825` package attrs | present on Linux and Darwin | preserved | `nix eval --accept-flake-config --json .#packages.<system>.qmd.name` |
| Explicit QMD checks | `3842f673` check attrs | `qmd-instance`, `qmd-runtime` | `063d825` check attrs | unchanged | preserved | `nix eval --accept-flake-config --json .#checks.<system> --apply 'attrs: builtins.attrNames attrs'` |

Local proof for measured commit:

- `XDG_CACHE_HOME=$(mktemp -d) nix eval --accept-flake-config --option eval-cache false --raw .#checks.x86_64-linux.ci.drvPath`
- `nix eval --accept-flake-config --json .#checks.x86_64-linux --apply 'attrs: builtins.attrNames attrs'`
- `nix eval --accept-flake-config --json .#checks.aarch64-darwin --apply 'attrs: builtins.attrNames attrs'`
- `nix eval --accept-flake-config --json .#packages.x86_64-linux.qmd.name`
- `nix eval --accept-flake-config --json .#packages.aarch64-darwin.qmd.name`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-ci-qmd-lazy-ci-only --accept-flake-config --no-link .#checks.x86_64-linux.ci`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci-qmd-lazy-ci-only --accept-flake-config --no-link .#checks.aarch64-darwin.ci`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-qmd-explicit-after-lazy --accept-flake-config --no-link .#checks.x86_64-linux.qmd-instance .#checks.x86_64-linux.qmd-runtime .#checks.aarch64-darwin.qmd-instance .#checks.aarch64-darwin.qmd-runtime`
- `nix run --accept-flake-config nixpkgs#nix-eval-jobs -- --flake .#checks.x86_64-linux --workers 1 --check-cache-status --show-input-drvs`
- `git diff --check`

Remote proof:

- GitHub Actions `27050932456`, `pull_request`, success on
  `063d825de22814eb30a22e45978a43815d493ed1`.
- GitHub Actions jobs: Linux `2m11s`, macOS `2m39s`.
- Parser summary: Linux aggregate `124s`, 926 fetched paths, 936 MiB download,
  4.2 GiB unpacked, 29 planned/built derivations; macOS aggregate `88s`, 226
  fetched paths, 286 MiB download, 1.8 GiB unpacked.
- `rg` over the GitHub log found no QMD lines. This removes the last default
  CI QMD fetch that remained after `ff85f6bb`.
- Garnix on PR head `063d825de22814eb30a22e45978a43815d493ed1`, success,
  `2026-06-06T03:09:22Z` to `2026-06-06T03:10:01Z`.
  Garnix time was slower than the previous sampled docs-only head, so this is
  not counted as a Garnix wall-time win.
- GitHub reported `mergeStateStatus=CLEAN` at
  `063d825de22814eb30a22e45978a43815d493ed1`.

### `pr100-build-closure-meter-2026-06-06`

- PR: `#100`
- Base commit: `7555c3bdb2cc6a94174eb71fbd1074dc19da80a3`
- Measured code commit: `7ff4d4ddff82db650123ec7a73a3bfaf685e081a`
- Purpose:
  - keep the existing aggregate CI proof unchanged;
  - capture Nix build-result JSON from the metered `nix build`;
  - use the captured `drvPath` to summarize concrete realized build-closure
    hotspots in GitHub step summaries.
- Rejected/fixed candidate:
  - `2645b1149048600ca1b5e4a4b53dcf857d98b72e` recovered derivers from output
    paths. Linux worked, but hosted macOS substituted the `ci` output without
    deriver metadata and reported an empty closure. The measured commit fixes
    this by using Nix build-result JSON.
- Anti-regression review:
  - The wrapper still runs the same installable and treats the real `nix build`
    status as authoritative.
  - The closure summary runs only after a successful build and is best-effort.
  - The summary does not use `nix-fast-build --skip-cached`, does not skip
    substitutions, and does not remove apply proof.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Metered aggregate build-result capture | `7555c3bd` wrapper | output path text only | `7ff4d4dd` wrapper | Nix build-result JSON with `drvPath` | added | `scripts/ci-nix-build.sh` |
| Linux aggregate step | `27051028322` at `7555c3bd` | 122s | `27051461275` at `7ff4d4dd` | 118s | 3.3% faster, runner variance | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-<run>.log` |
| Linux job duration | `27051028322` | 132s | `27051461275` | 125s | 5.3% faster, runner variance | `gh run view <run> --json jobs` |
| Linux fetch/copy/build graph | `27051028322` | 926 fetched, 930 copied, 29 built | `27051461275` | 926 fetched, 930 copied, 29 built | unchanged | parser command above |
| Linux build-closure summary | no closure summary in baseline | n/a | `27051461275` | 1,547 paths, 4.2 GiB summed NAR | added | closure section in GitHub log |
| Linux top NAR paths | no closure summary in baseline | n/a | `27051461275` | gateway 959 MiB; `summarize` 430 MiB; QEMU VM test 390 MiB; GCC 264 MiB; Linux modules 126 MiB | added | same |
| Linux top closure paths | no closure summary in baseline | n/a | `27051461275` | NixOS HM activation VM proof at 3.7 GiB closure | added | same |
| macOS aggregate step | `27051028322` | 84s | `27051461275` | 115s | 36.9% slower, runner variance plus meter overhead | parser command above |
| macOS job duration | `27051028322` | 147s | `27051461275` | 215s | 46.3% slower, runner variance plus meter overhead | `gh run view <run> --json jobs` |
| macOS fetch/copy/build graph | `27051028322` | 226 fetched, 230 copied, 0 built | `27051461275` | 226 fetched, 230 copied, 0 built | unchanged | parser command above |
| macOS build-closure summary | `2645b114` candidate | 0 paths due missing output deriver | `27051461275` at `7ff4d4dd` | 648 paths, 1.8 GiB summed NAR | fixed | closure section in GitHub log |
| macOS top NAR paths | no valid closure summary in baseline | n/a | `27051461275` | gateway 670 MiB; app 212 MiB; `summarize` 156 MiB; Python 110 MiB; Node 24 81 MiB | added | same |
| Garnix all checks | `7555c3bd` PR status | 25s | `7ff4d4dd` PR status | 42s | slower, cache/runner variance | `gh pr view 100 --json statusCheckRollup` |

Interpretation:

- This is an observability improvement, not a build-speed improvement.
- The check graph did not change: fetched paths, copied paths, and built
  derivations are stable against the prior green head.
- The closure meter gives concrete next targets:
  - Linux CI time is dominated by the default install/apply proof closure:
    `openclaw-gateway`, `summarize`, QEMU VM-test runtime, GCC, Linux modules,
    Python, and Node.
  - The largest Linux closure umbrella is the NixOS Home Manager activation VM
    proof at `3.7 GiB`; optimizing it would require a careful proof-design
    decision, not simply deleting the check.
  - macOS aggregate copy cost is dominated by the gateway/app payload and
    supporting runtime tools.

Local proof for measured commit:

- `node --check scripts/summarize-nix-build-closure.mjs && bash -n scripts/ci-nix-build.sh && git diff --check`
- `tmp=$(mktemp /tmp/nix-openclaw-json-output.XXXXXX); nix build --accept-flake-config --json --no-link .#checks.aarch64-darwin.ci > "$tmp"; scripts/summarize-nix-build-closure.mjs --label json-darwin-ci --limit 5 "$tmp"`
- `RUNNER_TEMP=/tmp NIX_METER_BUILD_CLOSURE=1 scripts/ci-nix-build.sh local-darwin-ci-json-closure-probe --accept-flake-config --no-link .#checks.aarch64-darwin.ci`
- `RUNNER_TEMP=/tmp NIX_METER_BUILD_CLOSURE=1 scripts/ci-nix-build.sh local-linux-ci-json-closure-probe --accept-flake-config --no-link .#checks.x86_64-linux.ci`

Remote proof:

- GitHub Actions `27051332716`, `pull_request`, success on
  `2645b1149048600ca1b5e4a4b53dcf857d98b72e`, proved Linux closure attribution
  but exposed the hosted macOS deriver gap.
- GitHub Actions `27051461275`, `pull_request`, success on
  `7ff4d4ddff82db650123ec7a73a3bfaf685e081a`.
- GitHub Actions jobs for `27051461275`: Linux `2m05s`, macOS `3m35s`.
- Parser summary for `27051461275`: Linux aggregate `118s`, 926 fetched paths,
  936 MiB download, 4.2 GiB unpacked, 29 planned/built derivations; macOS
  aggregate `115s`, 226 fetched paths, 286 MiB download, 1.8 GiB unpacked,
  0 built derivations.
- Garnix on PR head `7ff4d4ddff82db650123ec7a73a3bfaf685e081a`, success,
  `2026-06-06T03:34:18Z` to `2026-06-06T03:35:00Z`.
- GitHub reported `mergeStateStatus=CLEAN` at
  `7ff4d4ddff82db650123ec7a73a3bfaf685e081a`.

### `pr100-build-analysis-tooling-2026-06-06`

- PR: `#100`
- Base commit: `76c45773853dc7f49befd1bfc27f55408f8d145c`
- Measured code commit: `c99051b5dae377748ffa4b12705881bca696be07`
- Purpose:
  - check current Nix build-analysis tooling before adding more CI machinery;
  - keep the default CI proof path unchanged;
  - add a small parser for optional `nix-eval-jobs --check-cache-status`
    probes, so cache-status audits can be recorded without forcing that tool
    into every PR build.
- Tooling survey:
  - `nix-eval-jobs --check-cache-status` is the most direct answer to
    attr-level `local` / `cached` / `notBuilt` questions.
  - `nix-fast-build --skip-cached` is useful for cache-presence experiments,
    but not for this PR's default proof path because it can optimize away the
    install/apply copy behavior the user will hit on a clean machine.
  - `nix-output-monitor` / `nom` remains a strong local UI for active builds,
    but it does not replace the machine-readable CI summaries.
  - `nix-diff`, `nix why-depends`, `nix-tree`, `nix-du`, and `nvd` remain
    targeted drill-down tools after a hotspot or derivation delta is known.
  - Determinate Nix `nix ps --json` is useful for in-flight local/macOS build
    sampling, but Linux CI still uses upstream Nix through
    `cachix/install-nix-action`, and no active local builds were running during
    this probe.
- Rejected candidate:
  - Disabling NixOS test documentation in
    `nix/checks/openclaw-hm-activation.nix` rebuilt 17 VM-related derivations
    locally and still produced the same `options.json` eval warning. The local
    closure summary remained at 1,647 build-closure paths and 6.7 GiB summed
    NAR, with the same top hotspots. Rejected as churn without improvement.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Default CI installable | `76c45773` workflow | `.ci` aggregate | `c99051b5dae3` workflow | unchanged | no graph change | `git diff -- .github/workflows flake.nix` |
| New cache-status parser | `76c45773` scripts | absent | `c99051b5dae3` scripts | present | added optional audit tool | `scripts/summarize-nix-eval-jobs.mjs --label <label> <jsonl>` |
| Local Linux cache probe wall time | `76c45773` clean worktree | n/a | local probe on `76c45773` plus parser commit | 23s | measured overhead, not added to default CI | `nix run --accept-flake-config nixpkgs#nix-eval-jobs -- --flake .#checks.x86_64-linux --workers 1 --check-cache-status --show-input-drvs` |
| Local Linux check attrs | same probe | n/a | warmed local store | 13 local, 1 notBuilt | `runtime-plugin-packages` only non-local attr | `scripts/summarize-nix-eval-jobs.mjs --label local-linux-cache-probe <jsonl>` |
| Local Darwin cache probe wall time | `76c45773` clean worktree | n/a | local probe on `76c45773` plus parser commit | 24s | measured overhead, not added to default CI | `nix run --accept-flake-config nixpkgs#nix-eval-jobs -- --flake .#checks.aarch64-darwin --workers 1 --check-cache-status --show-input-drvs` |
| Local Darwin check attrs | same probe | n/a | warmed local store | 14 local, 0 notBuilt | all attrs already local | `scripts/summarize-nix-eval-jobs.mjs --label local-darwin-cache-probe <jsonl>` |
| Active-build sampler | local Determinate Nix `3.21.0` | n/a | no active local build | 0 active builds | command supported, no data in idle run | `nix ps --json \| jq '. \| length'` |

Local proof for measured commit:

- `node --check scripts/summarize-nix-eval-jobs.mjs`
- `scripts/summarize-nix-eval-jobs.mjs --label local-linux-cache-probe --limit 6 /tmp/nix-openclaw-eval-jobs-linux.e3WWib.jsonl`
- `scripts/summarize-nix-eval-jobs.mjs --label local-darwin-cache-probe --limit 6 /tmp/nix-openclaw-eval-jobs-darwin.Z0KqsY.jsonl`
- `git diff --check`

### `pr100-structured-nix-log-meter-2026-06-06`

- PR: `#100`
- Base commit: `c99051b5dae377748ffa4b12705881bca696be07`
- Measured code commit: `4998f2759d993d1e1402d3cf088df4899b79e7f3`
- Purpose:
  - improve the optional build-time attribution path from text phase hints to
    structured Nix activity events;
  - keep default CI behavior unchanged until a remote run proves the log-noise
    tradeoff is worth it;
  - preserve existing human-log summaries.
- Tooling sources checked:
  - Nix internal-json logging and build-result JSON expose structured event and
    top-level timing data:
    https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-log and
    https://nix.dev/manual/nix/2.34/protocols/json/build-result.html
  - `json-log-path` can capture internal-json sidecars, but lacks timestamps on
    its own:
    https://manpages.debian.org/unstable/nix-bin/nix.conf.5.en.html
  - `nix-output-monitor` recommends internal-json input for better Nix output:
    https://github.com/maralorn/nix-output-monitor
  - newer package closure explorers (`nix-deps`, `nixard`) are useful for
    user/profile closure impact, but are not CI build-time ledgers for this PR:
    https://github.com/manelinux/nix-deps and
    https://github.com/manelinux/nixard
  - `nix-log-check` is useful for binary-cache failure prediction, but not for
    timing attribution:
    https://github.com/dramforever/nix-log-check

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Default CI installable | `c99051b5` workflow | `.ci` aggregate | `4998f275` workflow | unchanged | no graph change | `git diff c99051b5..4998f275 -- .github/workflows flake.nix` |
| Internal-json event summary | `c99051b5` log summarizer | absent | `4998f275` log summarizer | present | added opt-in structured activity meter | `scripts/summarize-nix-build-log.mjs --label local-internal-json-config-validity /tmp/nix-openclaw-ci-meter/local-internal-json-config-validity.nix.log` |
| Timestamped internal-json probe | no structured parser | n/a | `4998f275` dirty worktree probe | 9s, 140 events, 15 starts, 15 stops, 109 results | recorded | `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-internal-json-config-validity --accept-flake-config --log-format internal-json --rebuild --no-link .#checks.aarch64-darwin.config-validity` |
| Top structured spans in probe | no structured parser | n/a | same probe | `Builds`/`CopyPaths`/`Realise` umbrella 8s; config-validity `Build` 7s, last phase `fixupPhase` | recorded | parser command above |
| Existing remote log parser regression | latest remote log `27051998719` | 4 metered steps | `4998f275` parser replay | 4 metered steps, same fetch/build/copy counts | unchanged | `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-27051998719.log` |

Interpretation:

- This is an analysis improvement, not a build-speed improvement.
- The useful SOTA path for this repo is native Nix internal-json events plus the
  existing timestamp sidecar, because it can attribute Nix activity spans without
  depending only on English stderr text.
- Do not flip CI to internal-json by default until a remote aggregate run proves
  the summary improves attribution enough to justify noisier raw logs.

Local proof for measured commit:

- `node --check scripts/summarize-nix-build-log.mjs`
- `scripts/summarize-nix-build-log.mjs --label local-internal-json-config-validity /tmp/nix-openclaw-ci-meter/local-internal-json-config-validity.nix.log`
- `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-27051998719.log`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-internal-json-config-validity --accept-flake-config --log-format internal-json --rebuild --no-link .#checks.aarch64-darwin.config-validity`

### `pr100-hm-manuals-off-2026-06-06`

- PR: `#100`
- Base commit: `4cb703b54f44b9f1e17f5155117e8fcc2f579355`
- Measured code commit: `2896ac3847e046f151bec65b85e0dfa39b0bd42f`
- Purpose:
  - stop generating Home Manager manual outputs inside CI activation fixtures;
  - remove Home Manager `options.json` eval warnings from the activation proof
    path;
  - keep user-facing Home Manager defaults unchanged and keep the OpenClaw
    config/apply/service/gateway assertions intact.
- Anti-regression review:
  - The change is scoped to `nix/checks/openclaw-hm-activation.nix` and
    `nix/tests/hm-activation-macos/home.nix`.
  - It does not remove `programs.openclaw` assertions, workspace file checks,
    runtime profile checks, launchd/systemd service checks, or gateway health
    checks.
  - It removes only Home Manager documentation/manual artifacts that the tests
    never asserted on.

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
| Linux HM derivation eval warning | `4cb703b` eval of `.hm-activation.drvPath` | `options.json` context warning present | `2896ac38` dirty eval | warning absent | removed | `nix eval --accept-flake-config --json .#checks.x86_64-linux.hm-activation.drvPath` |
| Darwin HM derivation eval warning | `4cb703b` eval of `.hm-activation-macos-package.drvPath` | `options.json` context warning present | `2896ac38` dirty eval | warning absent | removed | `nix eval --accept-flake-config --json .#checks.aarch64-darwin.hm-activation-macos-package.drvPath` |
| Linux HM derivation closure paths | old drv `/nix/store/wc6iczyzmbjmbxnxhgb9j6pjfdzmd3mf-vm-test-run-openclaw-hm-activation.drv` | 5,364 paths | new drv `/nix/store/dbjanaa7fw928rr1r7gljnxk0f9zppr9-vm-test-run-openclaw-hm-activation.drv` | 5,350 paths | 14 fewer | `nix-store -qR --include-outputs "$drv" \| wc -l` |
| Darwin HM derivation closure paths | old drv `/nix/store/wc3sxqs6bifx9wf0lkiz8ajxbgx0y9mm-home-manager-generation.drv` | 2,676 paths | new drv `/nix/store/9wpjdg4c4a7mcrz86ky1p25j0jmnkkf3-home-manager-generation.drv` | 2,658 paths | 18 fewer | `nix-store -qR --include-outputs "$drv" \| wc -l` |
| Removed HM doc paths | old/new closure name diff | `home-configuration-reference-manpage`, `home-manager.1`, `options.json`, `nixos-render-docs` present | new closure name diff | absent | removed from activation fixtures | `comm -23 /tmp/hm-old.names /tmp/hm-new.names` |
| Local Darwin HM package rebuild | prior fixture with manuals enabled | n/a | `2896ac38` dirty local run | 6s, 7 planned/built derivations | recorded | `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-hm-manuals-off --accept-flake-config --no-link .#checks.aarch64-darwin.hm-activation-macos-package` |
| Local Linux HM VM proof | prior fixture with manuals enabled | n/a | `2896ac38` dirty local run | 69s, 15 planned derivations, VM proof passed | recorded | `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-hm-manuals-off --accept-flake-config --no-link .#checks.x86_64-linux.hm-activation` |

Interpretation:

- This is a small real simplification of the activation proof closure. It does
  not move the main Linux bottleneck: QEMU/NixOS VM proof, OpenClaw gateway,
  default tools, and Node still dominate.
- The expected remote CI effect is fewer generated Home Manager doc paths and
  fewer warnings, not a large wall-time improvement.
- Remote GitHub Actions proof is still required after pushing this commit.

Local proof for measured commit:

- `nix eval --accept-flake-config --json .#checks.aarch64-darwin.hm-activation-macos-package.drvPath`
- `nix eval --accept-flake-config --json .#checks.x86_64-linux.hm-activation.drvPath`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-hm-manuals-off --accept-flake-config --no-link .#checks.aarch64-darwin.hm-activation-macos-package`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-hm-manuals-off --accept-flake-config --no-link .#checks.x86_64-linux.hm-activation`
- `scripts/hm-activation-macos.sh`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci-hm-manuals-off --accept-flake-config --option max-jobs 2 --no-link .#checks.aarch64-darwin.ci`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-linux-ci-hm-manuals-off --accept-flake-config --no-link .#checks.x86_64-linux.ci`
- `git diff --check`

## Add A Run

Use this shape and append below the previous run:

```text
### `<run-id>`

- PR:
- Measured commit:
- Base commit:
- Package outputs:
  - baseline gateway:
  - baseline `openclaw`:
  - measured gateway:
  - measured `openclaw`:

| Metric | Baseline provenance | Baseline | Measured provenance | Measured | Change | Command |
| --- | --- | ---: | --- | ---: | ---: | --- |
```
