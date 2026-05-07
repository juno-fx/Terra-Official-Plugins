#!/bin/bash
# hack/watch.sh — watch a plugin's scripts/ directory and auto-repackage on changes.
# Usage: ./hack/watch.sh <plugin-name>
# Called via: make watch <plugin-name>
#
# Requires inotifywait (inotify-tools). Available in the devbox shell.

set -e

PLUGIN="${1}"

if [ -z "${PLUGIN}" ]; then
  echo "Usage: make watch <plugin-name>"
  exit 1
fi

PLUGIN_DIR="./plugins/${PLUGIN}"
SCRIPTS_DIR="${PLUGIN_DIR}/scripts"

if [ ! -d "${PLUGIN_DIR}" ]; then
  echo "Error: plugins/${PLUGIN} does not exist."
  exit 1
fi

if [ ! -d "${SCRIPTS_DIR}" ]; then
  echo "Error: plugins/${PLUGIN}/scripts/ does not exist — nothing to watch."
  exit 1
fi

if ! command -v inotifywait &>/dev/null; then
  echo "Error: inotifywait not found."
  echo "Install inotify-tools or run 'devbox shell' to get it."
  exit 1
fi

echo "Watching plugins/${PLUGIN}/scripts/ for changes..."
echo "Press Ctrl+C to stop."
echo ""

# Initial package to ensure we start from a clean state
make --no-print-directory package "${PLUGIN}"

while true; do
  inotifywait -r -e modify,create,delete,move --quiet "${SCRIPTS_DIR}" 2>/dev/null
  echo ""
  echo "[watch] Change detected — repackaging ${PLUGIN}..."
  make --no-print-directory package "${PLUGIN}"
  echo "[watch] Done. Watching for more changes..."
done
