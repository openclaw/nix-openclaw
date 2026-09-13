#!/bin/sh

log_step() (
  step_name="$1"
  shift
  if [ "${OPENCLAW_NIX_TIMINGS:-1}" != "1" ]; then
    "$@"
    exit $?
  fi

  start=$(date +%s)
  printf '>> [timing] %s...\n' "$step_name" >&2
  "$@"
  exit_code=$?
  end=$(date +%s)
  printf '>> [timing] %s: %ss\n' "$step_name" "$((end - start))" >&2
  exit "$exit_code"
)
