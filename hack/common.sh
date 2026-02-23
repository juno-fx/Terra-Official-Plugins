#!/bin/bash
set -euo pipefail

# Detect local IP in a cross-platform way
get_local_ip() {
  # Linux: hostname -I (take first IP)
  if command -v hostname >/dev/null 2>&1; then
    if hostname -I >/dev/null 2>&1; then
      hostname -I | awk '{print $1}'
      return 0
    fi
  fi

  # macOS / BSD: ipconfig
  if command -v ipconfig >/dev/null 2>&1; then
    if ipconfig getifaddr en0 >/dev/null 2>&1; then
      ipconfig getifaddr en0
      return 0
    fi
  fi

  # Linux modern distros: ip route
  if command -v ip >/dev/null 2>&1; then
    ip route get 1 | awk '{print $7; exit}'
    return 0
  fi

  echo "Error: Unable to determine local IP address on this system." >&2
  exit 1
}

# Detect if running inside Kubernetes
in_cluster() {
  if [ -d "/var/run/secrets/kubernetes.io/serviceaccount" ] || [ -n "${KUBERNETES_SERVICE_HOST:-}" ]; then
    return 0
  else
    return 1
  fi
}

# Start a git daemon in the project root
start_git_daemon() {
  cd ../
  git daemon --verbose --export-all --base-path=. --reuseaddr --informative-errors &
  cd -
}
