#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: maintainers/scripts/ci-nix-build.sh <label> <nix-build-args...>" >&2
  exit 1
fi

label="$1"
shift

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
log_dir="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/nix-openclaw-ci-meter"
safe_label=$(printf '%s' "$label" | tr -c 'A-Za-z0-9_.-' '-')
log_path="$log_dir/${safe_label}.nix.log"
outputs_path="$log_dir/${safe_label}.outputs"

mkdir -p "$log_dir"
: > "$log_path"
: > "$outputs_path"

build_args=("$@")
if [[ "${NIX_METER_CAPTURE_OUTPUTS:-${NIX_METER_PRINT_OUT_PATHS:-1}}" != "0" ]]; then
  has_print_out_paths=0
  has_json_output=0
  for arg in "${build_args[@]}"; do
    [[ "$arg" == "--print-out-paths" ]] && has_print_out_paths=1
    [[ "$arg" == "--json" ]] && has_json_output=1
  done
  if [[ "$has_print_out_paths" -eq 0 && "$has_json_output" -eq 0 ]]; then
    build_args+=("--json")
  fi
fi

start_epoch=$(date +%s)
echo "nix-meter: start label=$label log=$log_path"

set +e
env NIX_SHOW_STATS="${NIX_SHOW_STATS:-0}" nix build --print-build-logs "${build_args[@]}" > >(tee "$outputs_path") 2> >(
  perl -MPOSIX=strftime -e '
    my $log_path = shift @ARGV;
    open my $log, ">>", $log_path or die "open $log_path: $!";
    while (my $line = <STDIN>) {
      chomp $line;
      print {$log} strftime("%Y-%m-%dT%H:%M:%SZ", gmtime), " ", $line, "\n";
      print STDERR $line, "\n";
      select($log); $| = 1;
      select(STDERR); $| = 1;
    }
  ' "$log_path"
)
status=$?
set -e

end_epoch=$(date +%s)
elapsed=$((end_epoch - start_epoch))
echo "nix-meter: end label=$label status=$status seconds=$elapsed"

"$repo_root/maintainers/scripts/summarize-nix-build-log.mjs" \
  --label "$label" \
  --seconds "$elapsed" \
  "$log_path" || true

if [[ "$status" -eq 0 && "${NIX_METER_BUILD_CLOSURE:-0}" != "0" ]]; then
  "$repo_root/maintainers/scripts/summarize-nix-build-closure.mjs" \
    --label "$label" \
    "$outputs_path" || true
fi

exit "$status"
