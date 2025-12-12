#!/bin/bash
set -euo pipefail

# Import shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

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

# If JUNO_ENVIRONMENT is not set, ask the user to choose a namespace
if [ -z "${JUNO_ENVIRONMENT:-}" ]; then
  echo ">>> JUNO_ENVIRONMENT environment variable not set."
  echo ">>> Fetching available namespaces from Kubernetes..."
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl not found in PATH. Please install it or set JUNO_ENVIRONMENT manually." >&2
    exit 1
  fi

  NAMESPACES=$(kubectl get ns --no-headers -o custom-columns=":metadata.name")
  if [ -z "$NAMESPACES" ]; then
    echo "Error: No namespaces found in the cluster." >&2
    exit 1
  fi

  echo "Available namespaces:"
  echo "$NAMESPACES" | nl -w2 -s'. '

  echo
  read -rp "Enter the target namespace: " USER_NAMESPACE

  if ! echo "$NAMESPACES" | grep -qw "$USER_NAMESPACE"; then
    echo "Error: '$USER_NAMESPACE' is not a valid namespace." >&2
    exit 1
  fi

  export JUNO_ENVIRONMENT="$USER_NAMESPACE"
  echo ">>> JUNO_ENVIRONMENT set to '$JUNO_ENVIRONMENT'"
fi

# Build URL depending on environment
if in_cluster; then
  URL="git://${CLEAN_HOSTNAME}.${JUNO_ENVIRONMENT}.svc.cluster.local:9418/Terra-Official-Plugins"
else
  LOCAL_IP=$(get_local_ip)
  URL="git://${LOCAL_IP}:9418/Terra-Official-Plugins"
fi

echo "Plugin: $PLUGIN_NAME"
echo "TDK Name: $CLEAN_HOSTNAME"
echo "Git Branch: $CURRENT_GIT_REF"
echo "Namespace (JUNO_ENVIRONMENT): $JUNO_ENVIRONMENT"
echo "URL: $URL"

# Define cleanup function
cleanup() {
  echo
  echo ">>> Caught termination signal. Cleaning up..."
  echo ">>> Uninstalling Helm release: $CLEAN_HOSTNAME"
  helm uninstall "$CLEAN_HOSTNAME" --namespace "$JUNO_ENVIRONMENT" || true
  killall git-daemon || true
  echo ">>> Cleanup complete."
}

# Trap Ctrl+C (SIGINT), SIGTERM, and EXIT
trap cleanup INT TERM EXIT

# Always start the local git server
start_git_daemon

sleep 1

helm upgrade -i "$CLEAN_HOSTNAME" ./tests/Application/ \
  --set branch="$CURRENT_GIT_REF" \
  --set remote="$URL" \
  --set plugin="$PLUGIN_NAME" \
  --set name="$PLUGIN_NAME-$CLEAN_HOSTNAME-dev" \
  --set project="$JUNO_ENVIRONMENT"

echo
echo
echo " >> Starting Development Shell << "
echo " >> Press CTRL+D to exit << "

PLUGIN_NAME=$PLUGIN_NAME /bin/bash
