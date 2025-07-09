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

  # Generate base64 of tarball (gzip + tar), and remove newlines to ensure consistent comparison
  base64_tar=$(tar -czf - -C "$plugin_path" scripts | base64 -w 0 | tr -d '\n')

  for cm_file in "$plugin_path"/templates/packaged-scripts.yaml "$plugin_path"/templates/packaged-scripts-cleanup.yaml; do
    if [[ ! -f "$cm_file" ]]; then
      echo "Warning: ConfigMap file not found: $cm_file"
      continue
    fi

    if ! grep -Fq "$base64_tar" "$cm_file"; then
      echo "❗ MISMATCH detected in $cm_file"
      mismatched_plugins["$plugin"]=1
    fi
  done
done

if [[ ${#mismatched_plugins[@]} -gt 0 ]]; then
  echo
  echo "❌ Plugins out of sync. You can fix them by running:"
  echo
  for plugin in "${!mismatched_plugins[@]}"; do
    echo "make package $plugin \\"
  done | sed '$ s/ \\\\$//'  # Remove the trailing backslash
  echo
  exit 1
else
  echo "✅ All plugins verified successfully."
  exit 0
fi
