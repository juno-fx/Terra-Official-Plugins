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

# If JUNO_PROJECT is not set, ask the user to choose a namespace
if [ -z "${JUNO_PROJECT:-}" ]; then
  echo ">>> JUNO_PROJECT environment variable not set."
  echo ">>> Fetching available namespaces from Kubernetes..."
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl not found in PATH. Please install it or set JUNO_PROJECT manually." >&2
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

  export JUNO_PROJECT="$USER_NAMESPACE"
  echo ">>> JUNO_PROJECT set to '$JUNO_PROJECT'"
fi

# Build URL depending on environment
if in_cluster; then
  URL="git://${CLEAN_HOSTNAME}.${JUNO_PROJECT}.svc.cluster.local:9418/Terra-Official-Plugins"
else
  LOCAL_IP=$(get_local_ip)
  URL="git://${LOCAL_IP}:9418/Terra-Official-Plugins"
fi

echo "Plugin: $PLUGIN_NAME"
echo "TDK Name: $CLEAN_HOSTNAME"
echo "Git Branch: $CURRENT_GIT_REF"
echo "Namespace (JUNO_PROJECT): $JUNO_PROJECT"
echo "URL: $URL"

# Define cleanup function
cleanup() {
  echo
  echo ">>> Caught termination signal. Cleaning up..."
  echo ">>> Uninstalling Helm release: $CLEAN_HOSTNAME"
  helm uninstall "$CLEAN_HOSTNAME" --namespace "$JUNO_PROJECT" || true
  killall git-daemon || true
  echo ">>> Cleanup complete."
}

# Trap Ctrl+C (SIGINT), SIGTERM, and EXIT
trap cleanup INT TERM EXIT

# Always start the local git server
start_git_daemon

sleep 1

helm upgrade -i "$CLEAN_HOSTNAME" ./tests/Application/ \
  --namespace "$JUNO_PROJECT" \
  --set branch="$CURRENT_GIT_REF" \
  --set project="$JUNO_PROJECT" \
  --set remote="$URL" \
  --set plugin="$PLUGIN_NAME" \
  --set name="$PLUGIN_NAME-$CLEAN_HOSTNAME-dev"
echo
echo
echo " >> WARNING <<"
echo " >> Depending on your cluster environment, storage bind could take a while to be ready."
echo
echo " >> Starting Development Shell << "
echo " >> Press CTRL+D to exit << "
echo
PLUGIN_NAME=$PLUGIN_NAME /bin/bash
