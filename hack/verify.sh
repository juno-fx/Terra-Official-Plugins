#!/usr/bin/env bash
set -euo pipefail

repo_root="$(pwd)"
plugins_dir="$repo_root/plugins"

declare -A mismatched_plugins=()

for plugin_path in "$plugins_dir"/*; do
  plugin=$(basename "$plugin_path")
  scripts_dir="$plugin_path/scripts"
  if [[ ! -d "$scripts_dir" ]]; then
    echo "Skipping plugin $plugin: no scripts directory."
    continue
  fi

  # Create temporary tarball and compute checksum
  tmp_tar=$(mktemp)
  tar -czf "$tmp_tar" -C "$plugin_path" scripts
  actual_checksum=$(sha256sum "$tmp_tar" | awk '{print $1}')
  rm -f "$tmp_tar"

  for cm_file in "$plugin_path"/templates/packaged-scripts.yaml "$plugin_path"/templates/packaged-scripts-cleanup.yaml; do
    if [[ ! -f "$cm_file" ]]; then
      echo "Warning: ConfigMap file not found: $cm_file"
      continue
    fi

    # Extract checksum using sed and strip whitespace/newlines
    expected_checksum=$(sed -nE 's/.*packaged_scripts\.checksum: *"([^"]+)".*/\1/p' "$cm_file" | tr -d '\r\n' || true)

    if [[ -z "$expected_checksum" ]]; then
      echo "❗ Missing checksum in $cm_file"
      mismatched_plugins["$plugin"]=1
      continue
    fi

    echo "Plugin: $plugin"
    echo "  Checking file: $cm_file"
    echo "  Expected checksum: $expected_checksum"
    echo "  Actual checksum:   $actual_checksum"

    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
      echo "❗ Checksum mismatch in $cm_file"
      mismatched_plugins["$plugin"]=1
    fi
  done
done

if [[ ${#mismatched_plugins[@]} -gt 0 ]]; then
  echo
  echo "❌ Plugins out of sync. You can fix them by running:"
  echo
  for plugin in "${!mismatched_plugins[@]}"; do
    echo "make package $plugin"
  done | sed '$ s/ \\\\$//'
  echo
  exit 1
else
  echo "✅ All plugins verified successfully."
  exit 0
fi
