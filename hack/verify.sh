#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"

mismatches=()
plugins_checked=()

verify_plugin() {
  local plugin="$1"
  local plugin_path="$PLUGINS_DIR/$plugin"
  local scripts_dir="${plugin_path}/scripts"
  local templates_dir="${plugin_path}/templates"

  [[ ! -d "$scripts_dir" ]] && return
  [[ ! -d "$templates_dir" ]] && return

  plugins_checked+=("$plugin")

  actual_b64=$(tar --owner=0 --group=0 -czf - -C "$plugin_path" scripts | base64 -w 0)

  for cm_name in "packaged-scripts.yaml" "packaged-scripts-cleanup.yaml"; do
    local cm_path="${templates_dir}/${cm_name}"

    if [[ ! -f "$cm_path" ]]; then
      mismatches+=("$plugin (missing file: ${cm_name})")
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
      mismatches+=("$plugin (missing packaged_scripts.base64 key in ${cm_name})")
      continue
    fi

    if [[ "$actual_b64" != "$expected_b64" ]]; then
      mismatches+=("$plugin (mismatch in ${cm_name})")
    fi
  done
}

for plugin_path in "$PLUGINS_DIR"/*/; do
  plugin="$(basename "$plugin_path")"
  verify_plugin "$plugin"
done

if [[ "${#mismatches[@]}" -gt 0 ]]; then
  echo "❌ Plugins out of sync:"
  for m in "${mismatches[@]}"; do
    echo "  - $m"
  done
  echo "👉 Run 'make package <plugin>' to fix."
  exit 1
else
  echo "✅ All plugins are up to date. Checked: ${#plugins_checked[@]}"
  exit 0
fi
