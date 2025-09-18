#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"

mismatches=()
unique_plugins=()

verify_plugin() {
  local plugin="$1"
  local plugin_path="$PLUGINS_DIR/$plugin"
  local scripts_dir="${plugin_path}/scripts"
  local templates_dir="${plugin_path}/templates"

  if [[ ! -d "$scripts_dir" ]]; then
    echo "⚠️  Plugin '$plugin' has no scripts/ directory, skipping."
    return
  fi

  if [[ ! -d "$templates_dir" ]]; then
    echo "⚠️  Plugin '$plugin' has no templates/ directory, skipping."
    return
  fi

  actual_b64=$(tar --owner=0 --group=0 --mtime='1970-01-01' --sort=name -czf - -C "$plugin_path" scripts | base64 -w 0)

  for cm_name in "packaged-scripts.yaml" "packaged-scripts-cleanup.yaml"; do
    local cm_path="${templates_dir}/${cm_name}"

    if [[ ! -f "$cm_path" ]]; then
      echo "⚠️  Missing file: $cm_path"
      mismatches+=("$plugin (missing ${cm_name})")
      unique_plugins+=("$plugin")
      continue
    fi

    expected_b64=$(awk -F': ' '
      $1 ~ /^\s*packaged_scripts\.base64/ {
        val = $2
        gsub(/^ +/, "", val)
        gsub(/^"/, "", val)
        gsub(/"$/, "", val)
        print val
      }
    ' "$cm_path")

    if [[ -z "$expected_b64" ]]; then
      echo "⚠️  Missing 'packaged_scripts.base64' key in $cm_path"
      mismatches+=("$plugin (missing key in ${cm_name})")
      unique_plugins+=("$plugin")
      continue
    fi

    if [[ "$actual_b64" != "$expected_b64" ]]; then
      echo "❌ MISMATCH in $cm_path for plugin '$plugin'"
      mismatches+=("$plugin (mismatch in ${cm_name})")
      unique_plugins+=("$plugin")
    fi
  done
}

for plugin_path in "$PLUGINS_DIR"/*/; do
  plugin="$(basename "$plugin_path")"
  verify_plugin "$plugin"
done

# Deduplicate plugin list
unique_plugins=($(printf "%s\n" "${unique_plugins[@]}" | sort -u))

echo
if [[ "${#mismatches[@]}" -gt 0 ]]; then
  echo "❌ Plugins out of sync:"
  for m in "${mismatches[@]}"; do
    echo "   - $m"
  done

  echo
  echo "👉 To fix, run the following:"
  for plugin in "${unique_plugins[@]}"; do
    echo "make package $plugin"
  done
  exit 1
else
  echo "✅ All plugins are up to date."
  exit 0
fi
