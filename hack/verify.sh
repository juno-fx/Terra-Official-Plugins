#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
plugins_dir="$repo_root/plugins"
change_mode=false

if [[ "${1:-}" == "change" ]]; then
  change_mode=true
fi

declare -a mismatches=()

for plugin_path in "$plugins_dir"/*; do
  plugin=$(basename "$plugin_path")
  scripts_dir="$plugin_path/scripts"
  if [[ ! -d "$scripts_dir" ]]; then
    echo "Skipping plugin $plugin: no scripts directory."
    continue
  fi

  # Generate base64 of tarball (gzip + tar)
  base64_tar=$(tar -czf - -C "$plugin_path" scripts | base64 -w 0)

  for cm_file in "$plugin_path"/templates/packaged-scripts.yaml "$plugin_path"/templates/packaged-scripts-cleanup.yaml; do
    if [[ ! -f "$cm_file" ]]; then
      echo "Warning: ConfigMap file not found: $cm_file"
      continue
    fi

    if ! grep -Fq "$base64_tar" "$cm_file"; then
      echo "❗ MISMATCH detected in $cm_file"
      echo "---- Contents of $cm_file ----"
      cat "$cm_file"
      echo "---- End of $cm_file ----"
      mismatches+=("$plugin")
    fi
  done

  # If change mode and mismatch for this plugin, fix it
  if $change_mode && [[ " ${mismatches[*]} " == *" $plugin "* ]]; then
    echo "🔧 Running 'make package $plugin' to fix plugin $plugin"
    make package ARGS="$plugin"
    # Re-generate base64_tar after fixing
    base64_tar=$(tar -czf - -C "$plugin_path" scripts | base64 -w 0)
    # Re-check files
    for cm_file in "$plugin_path"/templates/packaged-scripts.yaml "$plugin_path"/templates/packaged-scripts-cleanup.yaml; do
      if [[ ! -f "$cm_file" ]]; then
        echo "Warning: ConfigMap file not found after fix: $cm_file"
        continue
      fi
      if ! grep -Fq "$base64_tar" "$cm_file"; then
        echo "❌ STILL MISMATCH after fix in $cm_file"
      else
        echo "✅ Fixed $cm_file"
        # Remove from mismatches since fixed
        mismatches=("${mismatches[@]/$plugin}")
      fi
    done
  fi
done

if [[ ${#mismatches[@]} -gt 0 ]]; then
  echo "❌ Plugins out of sync: ${mismatches[*]}"
  exit 1
else
  echo "✅ All plugins verified successfully."
  exit 0
fi
