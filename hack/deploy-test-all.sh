#!/bin/bash
set -euo pipefail

# Clean hostname (strip off -N suffix, e.g. fred-0 -> fred)
CLEAN_HOSTNAME=$(echo "$HOSTNAME" | cut -d'-' -f1)

# Current git branch
CURRENT_GIT_REF=$(git rev-parse --abbrev-ref HEAD)

URL="git://${CLEAN_HOSTNAME}.${JUNO_PROJECT}.svc.cluster.local:9418/Terra-Official-Plugins"

echo "TDK Name: $CLEAN_HOSTNAME"
echo "Git Branch: $CURRENT_GIT_REF"
echo "URL: $URL"

# Define cleanup function
cleanup() {
  echo
  echo ">>> Caught termination signal. Cleaning up..."
  echo ">>> Uninstalling Source: $CLEAN_HOSTNAME"
  curl -sS -X DELETE "http://terra:8000/terra/sources/$CLEAN_HOSTNAME" || true
  killall git-daemon
  echo ">>> Cleanup complete."
}

# Trap Ctrl+C (SIGINT), SIGTERM, and EXIT
trap cleanup INT TERM EXIT

# start the local git server
cd ../
git daemon --verbose --export-all --base-path=. --reuseaddr --informative-errors &

# let it start up
sleep 1

# Build JSON payload safely with jq
DATA=$(jq -n \
  --arg name "$CLEAN_HOSTNAME" \
  --arg ref "$CURRENT_GIT_REF" \
  --arg url "$URL" \
  '{name: $name, ref: $ref, url: $url}')

echo " >> Terra Payload << "
echo $DATA
echo

# Send POST request
curl -sS -X POST http://terra:8000/terra/sources \
     -H "Content-Type: application/json" \
     -d "$DATA"

sleep infinity