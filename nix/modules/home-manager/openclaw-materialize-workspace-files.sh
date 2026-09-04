#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
  echo "usage: openclaw-materialize-workspace-files <state-manifest> <source-target-manifest> <workspace-roots>" >&2
  exit 1
fi

manifest="$1"
source_manifest="$2"
workspace_roots="$3"

manifest_dir="$(dirname "$manifest")"
mkdir -p "$manifest_dir"
desired_manifest="$(mktemp)"
new_manifest="$(mktemp)"
trap 'rm -f "$desired_manifest" "$new_manifest"' EXIT

valid_absolute_path() {
  case "$1" in
    /*) ;;
    *) return 1 ;;
  esac
  case "$1/" in
    *//*|*/./*|*/../*) return 1 ;;
  esac
}

within_workspace() (
  target="$(printf '%s\n' "$1" | tr -s /)"
  valid_absolute_path "$target" || return 1

  # A stale managed file may still occupy a parent that cleanup will remove.
  # Resolve the nearest directory, never the final symlink being removed.
  parent="$(dirname "$target")"
  while [ ! -d "$parent" ] && [ ! -L "$parent" ]; do
    parent="$(dirname "$parent")"
  done
  physical_parent="$(cd -P "$parent" 2>/dev/null && pwd -P)" || return 1
  physical_directory=""
  if [ ! -L "$target" ] && [ -d "$target" ]; then
    physical_directory="$(cd -P "$target" 2>/dev/null && pwd -P)" || return 1
  fi

  allowed=false
  while IFS= read -r root; do
    root="$(printf '%s\n' "$root" | tr -s /)"
    while [ "${root%/}" != "$root" ]; do root="${root%/}"; done
    valid_absolute_path "$root" || continue
    case "$root" in
      "$target"|"$target"/*) return 1 ;;
    esac
    physical_root="$(cd -P "$root" 2>/dev/null && pwd -P)" || continue
    [ "$physical_root" != / ] || continue
    if [ -n "$physical_directory" ]; then
      case "$physical_root" in
        "$physical_directory"|"$physical_directory"/*) return 1 ;;
      esac
    fi
    case "$target" in
      "$root"/*) ;;
      *) continue ;;
    esac
    case "$physical_parent" in
      "$physical_root"|"$physical_root"/*) allowed=true ;;
    esac
  done < "$workspace_roots"
  [ "$allowed" = true ]
)

remove_path() {
  # Unlink final symlinks without chmod following their targets. Only directory
  # permissions are needed for recursive removal; leave hardlinked files alone.
  if [ ! -L "$1" ] && [ -d "$1" ]; then
    find "$1" -type d -exec chmod u+w {} + 2>/dev/null || true
  fi
  rm -rf -- "$1"
}

copy_path() {
  source="$1"
  target="$2"

  if [ -e "$target" ] || [ -L "$target" ]; then
    remove_path "$target"
  fi
  mkdir -p "$(dirname "$target")"

  if [ -d "$source" ]; then
    cp -RL "$source" "$target"
  else
    cp -L "$source" "$target"
  fi

  printf '%s\n' "$target" >> "$new_manifest"
}

while IFS="$(printf '\t')" read -r source target; do
  if [ -n "$source" ] && [ -n "$target" ]; then
    if ! within_workspace "$target"; then
      echo "Refusing to materialize path outside configured workspaces: $target" >&2
      exit 1
    fi
    printf '%s\n' "$target" >> "$desired_manifest"
  fi
done < "$source_manifest"

sort -u "$desired_manifest" -o "$desired_manifest"

if [ -f "$manifest" ]; then
  while IFS= read -r old_target; do
    if [ -n "$old_target" ] && ! grep -Fxq "$old_target" "$desired_manifest"; then
      if ! within_workspace "$old_target"; then
        echo "Preserving stale path outside configured workspaces: $old_target" >&2
        printf '%s\n' "$old_target" >> "$new_manifest"
        continue
      fi
      if [ -e "$old_target" ] || [ -L "$old_target" ]; then
        remove_path "$old_target"
      fi
    fi
  done < "$manifest"
fi

while IFS="$(printf '\t')" read -r source target; do
  if [ -n "$source" ] && [ -n "$target" ]; then
    copy_path "$source" "$target"
  fi
done < "$source_manifest"

sort -u "$new_manifest" > "$manifest"
