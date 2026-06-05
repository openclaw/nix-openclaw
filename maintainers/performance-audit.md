---
written_by: ai
---

# Performance Audit

Scope: default stable `openclaw` / `openclaw-gateway` packaging. Runtime plugin
shrinkwrap is tracked separately in the plugin PR.

## Current Measurements

Measured on 2026-06-05. Size baselines use local source-build store paths;
workflow/check baselines use the earlier draft PR shape before this
simplification pass.

- Baseline source gateway: `/nix/store/a0ky4lhljzsjcbip97ykpjnj29lcf5q9-openclaw-gateway-unstable-2e08f0f4`
- Baseline source `openclaw`: `/nix/store/3i3xlpx2pysv076gz3f9yjsx5rv9czwd-openclaw-2026.6.1`
- Current npm gateway: `/nix/store/kh5j0cgbihmz4cl67w6fy0j4kimqcj70-openclaw-gateway-2026.6.1`
- Current npm `openclaw`: `/nix/store/sflqabvcsphsqn6s11nw82la3gafzp0a-openclaw-2026.6.1`

| Metric | Baseline | Current | Change | Command |
| --- | ---: | ---: | ---: | --- |
| Gateway closure | 2,273,877,888 B | 915,457,000 B | 59.7% smaller | `nix path-info -S "$gateway"` |
| `openclaw` closure | 3,215,431,032 B | 1,857,010,136 B | 42.2% smaller | `nix path-info -S "$openclaw"` |
| Gateway output | 2.1G | 727M | 66.2% smaller | `du -sh "$gateway"` |
| Package manifests | 1,452 | 584 | 59.8% fewer | `find "$gateway/lib/openclaw" -name package.json \| wc -l` |
| Files under `lib/openclaw` | 97,909 | 34,053 | 65.2% fewer | `find "$gateway/lib/openclaw" -type f \| wc -l` |
| Garnix targets | 83 | 5 | 94.0% fewer | `ruby -e 'require "yaml"; puts YAML.load_file("garnix.yaml")["builds"]["include"].length'` |
| Darwin check attrs | 13 | 11 | 15.4% fewer | `nix eval .#checks.aarch64-darwin --apply 'attrs: builtins.length (builtins.attrNames attrs)'` |
| Linux check attrs | 14 | 12 | 14.3% fewer | `nix eval .#checks.x86_64-linux --apply 'attrs: builtins.length (builtins.attrNames attrs)'` |
| Workflow hardcoded npm wrapper paths | 20 | 0 | removed | `rg -o 'nix/npm/openclaw\|nix/npm/openclaw-runtime-plugins/acpx' .github/workflows/pin-stable-openclaw-version.yml \| wc -l` |
| Top-level ACPX package outputs | 1 | 0 | removed | `nix eval .#packages.aarch64-darwin --apply 'attrs: builtins.filter (name: builtins.match ".*acpx.*" name != null) (builtins.attrNames attrs)'` |

## Build-Time Notes

- Same-version stable pin apply: `80.28s` with `GITHUB_ACTIONS=true /usr/bin/time -p scripts/update-pins.sh apply v2026.6.1 ...`.
- Previous forced source path: `399.37s`, then hit a Nix determinism failure.
- Cached CI aggregate after removing dogfood/source from the default aggregate:
  `42.56s` on Darwin and `43.58s` on Linux. Later reruns took `111.16s`
  on Darwin and `216.83s` on Linux because Nix auto-GC ran first; keep GC
  time separate.
- Current PR diff shape versus `origin/main`: total `25 files,
  5204 insertions, 632 deletions`; excluding npm lockfiles `23 files,
  649 insertions, 632 deletions`; build/workflow/doc logic `12 files,
  409 insertions, 365 deletions`.

## Update Rules

When changing packaging, update this file with:

1. Fresh store paths from `nix build --no-link --print-out-paths .#openclaw-gateway .#openclaw`.
2. The table values above.
3. Pin apply time and CI aggregate times, noting cache and GC state.
4. Any metric that regresses, with the reason it is acceptable.
