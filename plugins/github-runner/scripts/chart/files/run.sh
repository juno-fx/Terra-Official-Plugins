#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# github-runner payload
#
# Runs inside the nested-ci base pod: init.sh has already prepared the
# environment (private cgroup/mount namespaces, /etc/containers config,
# inotify limits, non-overlayfs graphroot). This script bootstraps a minimal
# apt base and execs the GitHub Actions runner agent.
#
# The toolchain (podman, devbox, kind, skaffold, gh, node, ...) is NOT
# installed here: workflow jobs install it per-job via the team's tooling
# action (actions/runners/tooling). It writes into the pod's rootfs, so the
# first job on a pod pays the install and later jobs on the same pod skip it
# (tooling_needed check).
#
# The agent MUST be exec'd from this pod command chain: kubectl exec cannot
# enter the unshared cgroup/mount namespaces, so a runner started from an
# exec'd shell would escape the pod's limits.
# ---------------------------------------------------------------------------
set -euo pipefail

WORK="${WORK_DIR:-/work}"
# agent + registration config live on the runner-config PVC: survives restarts
# and the ~1h registration-token expiry (".runner" present => skip config.sh)
RUNNER_DIR="${RUNNER_DIR:-/runner}"
# jobs' working directory stays on the ephemeral /work emptyDir, so build
# artifacts never grow the PVC
RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-/work/runner-work}"

stage() { printf '\n\033[1;36m=== [%s] %s\033[0m\n' "$(date -u +%H:%M:%S)" "$*"; }
ok()    { printf '\033[1;32m  PASS\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31m  FAIL\033[0m %s\n' "$*"; exit 1; }

export DEBIAN_FRONTEND=noninteractive
# the runner agent refuses to run as root without this; the pod runs as root
export RUNNER_ALLOW_RUNASROOT=1

[[ -n "${RUNNER_URL:-}" ]]   || fail "RUNNER_URL is not set"
[[ -n "${RUNNER_TOKEN:-}" ]] || fail "RUNNER_TOKEN is not set"
[[ -n "${RUNNER_NAME:-}" ]]  || fail "RUNNER_NAME is not set"

stage "1. apt prerequisites"
# curl + ca-certificates: agent download; sudo + jq: tooling action steps;
# lsb-release: tooling action runs `lsb_release -is`. The action installs the
# rest of its own dependencies (git, make, wget, gh, ...) when needed.
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
  ca-certificates curl sudo jq lsb-release >/dev/null
mkdir -p "$WORK"
ok "apt packages installed"

stage "2. GitHub Actions runner agent"
case "${RUNNER_ARCH:-x64}" in
  x64)   BIN_ARCH=x64 ;;
  arm64) BIN_ARCH=arm64 ;;
  *)     fail "unsupported RUNNER_ARCH: ${RUNNER_ARCH}" ;;
esac
if [[ "${RUNNER_VERSION:-latest}" == "latest" ]]; then
  RUNNER_VERSION="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest \
    | jq -r .tag_name | sed 's/^v//')"
fi
RUNNER_ARCHIVE="actions-runner-linux-${BIN_ARCH}-${RUNNER_VERSION}.tar.gz"
mkdir -p "$RUNNER_DIR"
if [[ ! -d "$RUNNER_DIR/bin" ]]; then
  curl -fsSL -o "$WORK/$RUNNER_ARCHIVE" \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_ARCHIVE}" \
    || fail "failed to download runner v${RUNNER_VERSION}"
  tar xzf "$WORK/$RUNNER_ARCHIVE" -C "$RUNNER_DIR"
  rm -f "$WORK/$RUNNER_ARCHIVE"
  ok "runner agent v${RUNNER_VERSION} (${BIN_ARCH}) downloaded and extracted"
else
  ok "runner agent already present"
fi

stage "3. register runner (only on first launch)"
mkdir -p "$RUNNER_WORK_DIR"
if [[ ! -f "$RUNNER_DIR/.runner" ]]; then
  ( cd "$RUNNER_DIR" && ./config.sh \
      --url "$RUNNER_URL" \
      --token "$RUNNER_TOKEN" \
      --name "$RUNNER_NAME" \
      --labels "${RUNNER_LABELS:-juno}" \
      --work "$RUNNER_WORK_DIR" \
      --unattended --replace )
  ok "runner registered with $RUNNER_URL"
else
  ok "runner already registered ($RUNNER_NAME); skipping config.sh (token not needed)"
fi

stage "4. starting runner agent (exec)"
cd "$RUNNER_DIR"
exec ./run.sh
