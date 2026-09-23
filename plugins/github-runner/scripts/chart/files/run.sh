#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# github-runner payload
#
# Runs inside the nested-ci base pod: init.sh has already prepared the
# environment (private cgroup/mount namespaces, inotify limits,
# non-overlayfs graphroot). This script bootstraps a minimal
# apt base and execs the GitHub Actions runner agent.
#
# The rest of the toolchain (devbox, kind, skaffold, gh, node, ...) is NOT
# installed here: workflow jobs install it per-job via the team's tooling
# action (actions/runners/tooling). It writes into the pod's rootfs, so the
# first job on a pod pays the install and later jobs on the same pod skip it
# (tooling_needed check).
#
# podman IS installed here (plus netavark for bridge networking) and its
# Docker-compatible API socket is started at boot (stage 5). Starting it pod-side
# -- rather than in the tooling action -- keeps it alive for the pod's lifetime:
# the runner kills the process tree of every job when it ends, so any socket
# started from inside a job dies with that job.
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
# jobs' working directory lives on the runner-config PVC (subPath "work"),
# alongside the graphroot (subPath "containers") and logs (subPath "varlog")
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
apt-get install -y -qq ca-certificates curl sudo jq lsb-release podman netavark >/dev/null
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

stage "3. runner .NET runtime dependencies (libicu, lttng)"
# The agent is .NET-based; stock ubuntu images ship no libicu, so config.sh
# dies with "Libicu's dependencies is missing for Dotnet Core 6.0". The agent
# ships bin/installdependencies.sh with a distro-robust fallback chain
# (libicu80..libicu52 + liblttng-ust). Idempotent -- agent + config persist on
# the PVC, so this runs every boot and no-ops once installed.
"$RUNNER_DIR/bin/installdependencies.sh" \
  || fail "installdependencies.sh failed -- .NET runtime missing"
ok "runner runtime dependencies installed"

stage "4. register runner (only on first launch)"
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

stage "5. podman docker shim + Docker-compatible API socket"
# podman is installed at boot (not by the tooling action), so the socket is
# owned by the pod: it starts before any job and is never a child of a job,
# so the runner's job-end process-tree cleanup can't kill it. skopeo's
# `docker-daemon:` transport talks to /var/run/docker.sock -> this socket.
mkdir -p /run/podman
ln -sf /usr/bin/podman /usr/bin/docker
setsid nohup podman system service --time=0 unix:///run/podman/podman.sock \
  >/var/log/podman-system-service.log 2>&1 &
ln -sf /run/podman/podman.sock /var/run/docker.sock
# socket binds async; wait up to 30s (non-fatal) before handing over to the agent
for _ in $(seq 1 30); do
  if curl -fsS --unix-socket /run/podman/podman.sock http://d/_ping >/dev/null 2>&1; then
    ok "podman API socket live at /run/podman/podman.sock"
    break
  fi
  sleep 1
done

stage "6. starting runner agent (exec)"
cd "$RUNNER_DIR"
exec ./run.sh
