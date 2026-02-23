#!/bin/bash
set -euo pipefail

# Import shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Check that we are running inside Kubernetes
if ! in_cluster; then
  echo "Error: This script can only be run inside a Kubernetes cluster."
  echo "Reason: The script depends on cluster-specific DNS and services that are not available locally."
  exit 1
fi

# Clean hostname (strip off -N suffix, e.g. fred-0 -> fred)
CLEAN_HOSTNAME=$(echo "$HOSTNAME" | cut -d'-' -f1)

# Current git branch
CURRENT_GIT_REF=$(git rev-parse --abbrev-ref HEAD)

# Build in-cluster URL
URL="git://${CLEAN_HOSTNAME}.${JUNO_ENVIRONMENT}.svc.cluster.local:9418/Terra-Official-Plugins"

echo "TDK Name: $CLEAN_HOSTNAME"
echo "Git Branch: $CURRENT_GIT_REF"
echo "URL: $URL"

# Define cleanup function
cleanup() {
  echo
  echo ">>> Caught termination signal. Cleaning up..."
  echo ">>> Uninstalling Source: $CLEAN_HOSTNAME"
  curl -sS -X DELETE "http://terra:8000/terra/sources/$CLEAN_HOSTNAME" || true
  killall git-daemon || true
  echo ">>> Cleanup complete."
}

# Trap Ctrl+C (SIGINT), SIGTERM, and EXIT
trap cleanup INT TERM EXIT

# Always start the local git server
start_git_daemon

# Let it start up
sleep 1

# Build JSON payload safely with jq
DATA=$(jq -n \
  --arg name "$CLEAN_HOSTNAME" \
  --arg ref "$CURRENT_GIT_REF" \
  --arg url "$URL" \
  '{name: $name, ref: $ref, url: $url}')

echo " >> Terra Payload << "
echo "$DATA"
echo

# Send POST request
curl -sS -X POST http://terra:8000/terra/sources \
     -H "Content-Type: application/json" \
     -d "$DATA"

echo
echo
echo " >> Starting Development Shell << "
echo " >> Press CTRL+D to exit << "

PLUGIN_CATALOG="true" PLUGIN_NAME="$CLEAN_HOSTNAME" /bin/bash
