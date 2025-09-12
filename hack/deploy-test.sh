#!/bin/bash
set -euo pipefail

# Clean hostname (strip off -N suffix, e.g. fred-0 -> fred)
CLEAN_HOSTNAME=$(echo "$HOSTNAME" | cut -d'-' -f1)

# Current git branch
CURRENT_GIT_REF=$(git rev-parse --abbrev-ref HEAD)

# Build URL
if [ -z "${JUNO_PROJECT:-}" ]; then
  echo "Error: JUNO_PROJECT environment variable not set" >&2
  exit 1
fi

URL="http://${CLEAN_HOSTNAME}.${JUNO_PROJECT}.svc.cluster.local:9418/"

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
