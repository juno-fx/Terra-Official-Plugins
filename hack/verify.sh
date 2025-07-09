#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"
CHANGE_MODE="${1:-}"

mismatches=()
plugins_checked=()

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

  echo "🔍 Checking plugin: $plugin"
  plugins_checked+=("$plugin")

  actual_b64=$(tar -czf - -C "$plugin_path" scripts | base64 -w 0)

  for cm_name in "packaged-scripts.yaml" "packaged-scripts-cleanup.yaml"; do
    local cm_path="${templates_dir}/${cm_name}"
    echo "   📄 ConfigMap path: $cm_path"

    if [[ ! -f "$cm_path" ]]; then
      echo "   ❗ Missing file: $cm_path"
      mismatches+=("$plugin (missing ${cm_name})")
      continue
    fi

    # Extract base64 value using improved awk logic that trims quotes properly
    expected_b64=$(awk -F': ' '
      $1 ~ /^\s*packaged_scripts\.base64/ {
        val = $2
        gsub(/^ +/, "", val)     # strip leading spaces
        gsub(/^"/, "", val)      # remove starting quote
        gsub(/"$/, "", val)      # remove trailing quote
        print val
      }
    ' "$cm_path")

    if [[ -z "$expected_b64" ]]; then
      echo "   ❗ Missing 'packaged_scripts.base64' key in $cm_path"
      mismatches+=("$plugin (missing key in ${cm_name})")
      continue
    fi

    if [[ "$actual_b64" != "$expected_b64" ]]; then
      echo "   ❌ MISMATCH detected in $cm_path"
      echo "     🔄 actual   : ${actual_b64:0:100}..."
      echo "     ✅ expected : ${expected_b64:0:100}..."
      mismatches+=("$plugin (mismatch in ${cm_name})")
    else
      echo "   ✅ Match"
    fi
  done
}

# Run verification pass
for plugin_path in "$PLUGINS_DIR"/*/; do
  plugin="$(basename "$plugin_path")"
  verify_plugin "$plugin"
done

# Change mode: fix and reverify
if [[ "$CHANGE_MODE" == "change" && "${#mismatches[@]}" -gt 0 ]]; then
  echo
  echo "🔧 Fixing out-of-sync plugins using 'make package <plugin>'..."

  to_fix=()
  for entry in "${mismatches[@]}"; do
    plugin="${entry%% *}"
    echo "⚙️  Re-packaging plugin: $plugin"
    make -C "$REPO_ROOT" package ARGS="$plugin"
    to_fix+=("$plugin")
  done

  # Clear mismatch list and re-verify those plugins
  mismatches=()
  echo
  echo "🔁 Re-verifying fixed plugins..."
  for plugin in "${to_fix[@]}"; do
    verify_plugin "$plugin"
  done
fi

echo

if [[ "${#mismatches[@]}" -gt 0 ]]; then
  echo "❌ The following plugins are out of sync:"
  for m in "${mismatches[@]}"; do
    echo "   - $m"
  done
  echo
  if [[ "$CHANGE_MODE" == "change" ]]; then
    echo "⚠️  Auto-fix attempted, but some plugins are still out of sync."
  else
    echo "👉 Run 'make package <plugin>' or 'hack/verify.sh change' to fix."
  fi
  exit 1
else
  echo "✅ All plugins are up to date."
  exit 0
fi
