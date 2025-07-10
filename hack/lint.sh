#!/bin/bash

# Set root directory to 'plugins'
ROOT_DIR="plugins"

# Collect all chart directories (where Chart.yaml exists)
chart_paths=()

while IFS= read -r chart_file; do
  chart_dir=$(dirname "$chart_file")
  chart_paths+=("$chart_dir")
done < <(find "$ROOT_DIR" -type f -name "Chart.yaml")

# If no charts found, exit early
if [ ${#chart_paths[@]} -eq 0 ]; then
  echo "No charts found in $ROOT_DIR"
  exit 0
fi

# Run helm lint on all chart paths at once
echo "Linting ${#chart_paths[@]} charts..."
helm lint --strict "${chart_paths[@]}"
exit_code=$?

# Exit with helm lint's exit code
if [ $exit_code -ne 0 ]; then
  echo "❌ Linting failed"
else
  echo "✅ All charts passed linting"
fi

exit $exit_code
