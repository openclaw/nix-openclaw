# shellcheck shell=bash
# Sourced by the Nix-generated Bash gateway wrapper.
openclawExportEnv() {
  local key="$1" value="$2" cat_bin="$3"
  if [[ -f "$value" && "$key" != *_FILE ]]; then
    value=$("$cat_bin" -- "$value")
    value="${value#"$key="}"
  fi
  # Set the global binding even when a user variable matches a local name.
  declare -gx -- "$key=$value"
}
