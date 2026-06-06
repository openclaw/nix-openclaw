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

Local proof for measured commit:

- `node --check scripts/summarize-nix-build-log.mjs`
- `bash -n scripts/ci-nix-build.sh`
- `ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }; puts "yaml ok"' .github/workflows/ci.yml .github/workflows/pin-stable-openclaw-version.yml garnix.yaml`
- `scripts/summarize-nix-build-log.mjs --github-log /tmp/nix-openclaw-ci-logs/run-27047041028.log`
- `RUNNER_TEMP=/tmp scripts/ci-nix-build.sh local-darwin-ci --accept-flake-config --no-link .#checks.aarch64-darwin.ci`
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
