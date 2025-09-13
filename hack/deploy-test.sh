#!/bin/bash
set -euo pipefail

# Require at least one argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <plugin-name>"
    exit 1
fi

PLUGIN_NAME=$1

# Clean hostname (strip off -N suffix, e.g. fred-0 -> fred)
CLEAN_HOSTNAME=$(echo "$HOSTNAME" | cut -d'-' -f1)

# Current git branch
CURRENT_GIT_REF=$(git rev-parse --abbrev-ref HEAD)

# Build URL
if [ -z "${JUNO_PROJECT:-}" ]; then
  echo "Error: JUNO_PROJECT environment variable not set" >&2
  exit 1
fi

URL="git://${CLEAN_HOSTNAME}.${JUNO_PROJECT}.svc.cluster.local:9418/Terra-Official-Plugins"

echo "Plugin: $PLUGIN_NAME"
echo "TDK Name: $CLEAN_HOSTNAME"
echo "Git Branch: $CURRENT_GIT_REF"
echo "URL: $URL"

# Define cleanup function
cleanup() {
  echo
  echo ">>> Caught termination signal. Cleaning up..."
  echo ">>> Uninstalling Helm release: $CLEAN_HOSTNAME"
  helm uninstall "$CLEAN_HOSTNAME" || true
  killall git-daemon
  echo ">>> Cleanup complete."
}

# Trap Ctrl+C (SIGINT), SIGTERM, and EXIT
trap cleanup INT TERM EXIT

helm upgrade -i "$CLEAN_HOSTNAME" ./tests/Application/ \
  --set branch="$CURRENT_GIT_REF" \
  --set remote="$URL" \
  --set plugin="$PLUGIN_NAME"

# start the local git server
cd ../
git daemon --verbose --export-all --base-path=. --reuseaddr --informative-errors &
cd -

sleep 2

echo
echo
echo " >> Starting Development Shell << "
echo " >> Press CTRL+D to exit << "

PLUGIN_NAME=$PLUGIN_NAME /bin/bash
