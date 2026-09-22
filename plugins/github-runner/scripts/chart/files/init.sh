#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# nested-ci base environment initializer
#
# Prepares a pod so that container tooling (podman, buildah, kind, skaffold...)
# can be INSTALLED AND RUN later, by an arbitrary script, over an arbitrary
# base image. It installs NO tools itself.
#
# Everything here is something that either cannot be expressed in a pod spec,
# or must happen before the workload's first process runs. When done it
# exec()s "$@", so the payload inherits the prepared namespaces.
# ---------------------------------------------------------------------------
set -euo pipefail

BASE_DIR="${NESTED_CI_BASE_DIR:-/opt/nested-ci}"
GRAPHROOT="${NESTED_CI_GRAPHROOT:-/var/lib/containers}"

log()  { printf '\033[1;34m[nested-ci]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[nested-ci] FATAL\033[0m %s\n' "$*" >&2; exit 1; }

# --------------------------------------------------------------- 1. namespaces
# A privileged pod runs in the HOST cgroup namespace, so /sys/fs/cgroup is the
# NODE's cgroup root. Podman would then create /sys/fs/cgroup/libpod_parent at
# node level: nested containers escape this pod's cpu/memory limits, collide
# with other pods, and leak after the pod exits.
#
# Unsharing the cgroup namespace re-roots /sys/fs/cgroup at this container's own
# scope. This CANNOT be done from the pod spec -- Kubernetes has no cgroup
# namespace field, and `privileged: true` is what forces the host namespace in
# the first place. Hence this wrapper.
if [[ "${NESTED_CI_NS_READY:-0}" != "1" ]]; then
  if [[ "$(cat /proc/self/cgroup)" == "0::/" ]]; then
    log "already in a private cgroup namespace"
    export NESTED_CI_NS_READY=1 NESTED_CI_DID_UNSHARE=0
  else
    command -v unshare >/dev/null || die "unshare(1) not found -- base image needs util-linux"
    log "host cgroup namespace detected; re-execing in a private cgroup+mount namespace"
    export NESTED_CI_NS_READY=1 NESTED_CI_DID_UNSHARE=1
    exec unshare --cgroup --mount -- "$0" "$@"
  fi
fi

# NOTE: do NOT gate this on /proc/self/cgroup -- immediately after
# unshare --cgroup that already reads "0::/" (it is rendered relative to the
# new namespace) while /sys/fs/cgroup is still the OLD mount showing the node's
# hierarchy. Gating on the path silently skips the remount and then delegates
# controllers on the NODE's cgroup root. Use the explicit flag instead.
if [[ "${NESTED_CI_DID_UNSHARE:-0}" == "1" ]]; then
  mount --make-rslave / 2>/dev/null || true
  umount /sys/fs/cgroup 2>/dev/null || umount -l /sys/fs/cgroup 2>/dev/null || true
  mount -t cgroup2 none /sys/fs/cgroup || die "could not remount cgroup2 (is the pod privileged?)"
  log "cgroup2 remounted; root is now this pod's own cgroup"
fi

# Hard assertion: /sys/fs/cgroup must be OUR cgroup root, i.e. this process must
# appear in its cgroup.procs. If it is the node's root we are about to relocate
# the node's processes and pollute its hierarchy -- refuse instead.
grep -qx "$$" /sys/fs/cgroup/cgroup.procs \
  || die "/sys/fs/cgroup is not this pod's own cgroup root (pid $$ not in cgroup.procs) -- refusing to touch a hierarchy we do not own"

# ------------------------------------------------------- 2. cgroup delegation
# cgroup v2 "no internal processes" rule: controllers can only be delegated to
# children once this cgroup holds no processes of its own.
if [[ ! -w /sys/fs/cgroup ]]; then
  mount -o remount,rw /sys/fs/cgroup 2>/dev/null \
    || die "/sys/fs/cgroup is read-only and cannot be remounted -- pod needs privileged: true"
fi
mkdir -p /sys/fs/cgroup/init
xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || true
sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers \
  > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
DELEGATED="$(cat /sys/fs/cgroup/cgroup.subtree_control)"
for c in cpu memory pids cpuset; do
  grep -qw "$c" <<<"$DELEGATED" || die "cgroup controller '$c' unavailable (have: ${DELEGATED:-none}) -- pod needs privileged: true"
done
log "cgroup v2 controllers delegated: $DELEGATED"

# --------------------------------------------------------------- 3. inotify
# Every nested systemd/kubelet consumes inotify instances. The common default
# (128) is exhausted quickly by kind-in-a-pod, and systemd in the kind node then
# dies at boot with:
#     Failed to create control group inotify object: Too many open files
#     Failed to allocate manager object. Exiting PID 1...
# which surfaces from kind only as the opaque
#     could not find a log line that matches "Reached target .*Multi-User System.*"
#
# These limits are per-UID and NOT namespaced away from a privileged pod (which
# shares the host user namespace), so raising them here changes the NODE's
# runtime setting for every workload on it. It is not persisted across reboot.
# Set NESTED_CI_TUNE_INOTIFY=0 to require the node to be pre-tuned instead.
if [[ "${NESTED_CI_TUNE_INOTIFY:-1}" == "1" ]]; then
  want_inst="${NESTED_CI_MIN_INOTIFY_INSTANCES:-1024}"
  want_watch="${NESTED_CI_MIN_INOTIFY_WATCHES:-524288}"
  for pair in "max_user_instances:$want_inst" "max_user_watches:$want_watch"; do
    knob="${pair%%:*}"; want="${pair##*:}"
    have="$(cat "/proc/sys/fs/inotify/$knob" 2>/dev/null || echo 0)"
    if (( have < want )); then
      if echo "$want" > "/proc/sys/fs/inotify/$knob" 2>/dev/null; then
        log "raised NODE-WIDE fs.inotify.$knob $have -> $want"
      else
        log "WARNING: fs.inotify.$knob is $have (< $want) and could not be raised; nested systemd may fail to boot"
      fi
    fi
  done
else
  have="$(cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null || echo 0)"
  (( have < 512 )) && log "WARNING: fs.inotify.max_user_instances=$have and tuning is disabled"
fi

# --------------------------------------------------- 3. containers/ system config
# nixpkgs' (and several distros') podman ship no /etc/containers. Without
# policy.json every image pull fails with "no policy.json file found".
# Copied rather than mounted so a payload can still edit them.
if [[ -d "$BASE_DIR/containers" ]]; then
  mkdir -p /etc/containers
  for f in "$BASE_DIR"/containers/*; do
    [[ -e "/etc/containers/$(basename "$f")" ]] || cp "$f" /etc/containers/
  done
  log "containers config in place: $(ls /etc/containers | tr '\n' ' ')"
fi

# ------------------------------------------------------------ 4. docker shim
if [[ -f "$BASE_DIR/bin/docker" && ! -e /usr/local/bin/docker ]]; then
  install -m 0755 "$BASE_DIR/bin/docker" /usr/local/bin/docker
  log "installed docker->podman shim at /usr/local/bin/docker"
fi

# ------------------------------------------------------------- 5. preflight
# Fail loudly and name the missing POD SETTING, so a misconfigured chart is
# obvious immediately instead of failing deep inside a build 90 seconds later.
SYS_OPTS="$(awk '$5 == "/sys" {print $6; exit}' /proc/self/mountinfo)"
[[ "$SYS_OPTS" == rw* ]] \
  || die "/sys is mounted $SYS_OPTS -- pod needs privileged: true (capabilities alone are NOT enough)"

mkdir -p "$GRAPHROOT"
BACKING="$(stat -fc %T "$GRAPHROOT")"
[[ "$BACKING" == "overlayfs" ]] \
  && die "$GRAPHROOT is on overlayfs -- mount an emptyDir/PVC there or podman's overlay driver will fail"
log "container storage $GRAPHROOT on $BACKING"

[[ -d /lib/modules ]] \
  || die "/lib/modules missing -- kind bind-mounts it into node containers; mount an emptyDir there"

[[ -e /dev/fuse ]] || log "WARNING: /dev/fuse absent; fuse-overlayfs fallback unavailable"

log "environment ready; tools are NOT installed -- handing off to: ${*:-<nothing>}"

# --------------------------------------------------------------- 6. handoff
if [[ $# -eq 0 ]]; then
  log "no payload given; sleeping so a script can be exec'd in later"
  exec sleep infinity
fi
exec "$@"
