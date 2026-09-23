# GitHub Runner

![GitHub Runner](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/github-runner/scripts/assets/logo.png)

**Category:** CI/CD
**Type:** Workload Template
**Tags:** `workload` · `cluster-level` · `cicd` · `github` · `runner`

---

## Overview

Self-hosted GitHub Actions runner as a workload. Each runner pod is a clean, install-capable
environment (privileged, cgroup- and mount-namespaced, **KinD-capable**) running the runner agent —
**no toolchain is pre-installed except podman**. Podman (with its recommended networking
packages: netavark, nftables, aardvark-dns — plain apt install, no `--no-install-recommends`) is
installed at pod boot along with its Docker-compatible API socket, so image builds work out of the
box; the rest of the toolchain (kind, skaffold, kubectl, devbox, gh, …) is installed by workflow
jobs at job time, typically via the team's existing tooling action — so an image built in this
plugin is a runner that can build images with podman and deploy them to a real (nested)
KinD cluster, without a Docker socket, host mounts, or a Dockerfile to maintain.

---

## How It Works

**Workload Template** — Installs the GitHub Runner workload schema into Genesis. Once installed,
launch a runner from the Workloads page like any other workload.

The runner pod is a privileged pod whose first process (`init.sh`) fixes the one thing Kubernetes
cannot express: a privileged pod runs in the **host cgroup namespace**, so `init.sh` re-execs into
a private cgroup + mount namespace, remounts cgroup2 to the pod's own scope, delegates the cgroup
controllers, and verifies the podman graphroot sits on non-overlayfs storage. It then `exec`s
the payload script, which bootstraps a minimal apt base and downloads, registers and starts the
GitHub Actions runner agent. The agent is the pod's command chain — `kubectl exec` cannot enter the
unshared namespaces, so the agent must run this way.

Podman is installed and its Docker-compatible API socket started at pod boot (stage 5 of the
payload script) — the socket lives for the pod's lifetime, started by the pod's own init chain
rather than by any job, so the runner's job-end process cleanup can't kill it. The rest of the
toolchain is installed at job time: the first job on a pod installs it (via the team's tooling
action) into the pod's rootfs; later jobs on the same pod reuse it. The pod
exposes `KIND_EXPERIMENTAL_PROVIDER=podman` and `DOCKER_HOST=unix:///run/podman/podman.sock` so
tooling that shells out to `docker` or boots a KinD cluster finds the right socket on day one.

---

## Prerequisites

- **Privileged Pod Security Admission on the workload's namespace.** The runner pod sets
  `securityContext.privileged: true` (not reducible to capabilities — the nested kubelet needs a
  read-write `/sys`, which only `privileged` provides). Label the namespace where the workload will
  launch:

  ```bash
  kubectl label ns <namespace> pod-security.kubernetes.io/enforce=privileged --overwrite
  kubectl label ns <namespace> pod-security.kubernetes.io/warn=privileged --overwrite
  ```

- **Scheduling** — the `architecture` field always adds a `kubernetes.io/arch` nodeSelector
  (x64 → amd64, arm64 → arm64), so a runner lands on matching-architecture nodes; an arm64 runner
  with no free arm node stays Pending (visible) instead of crashlooping on an amd64 node ("Exec
  format error"). Use the `pool` field to target a labeled pool; `selector` entries add more rows
  (a `kubernetes.io/arch` entry overrides the auto row). Soft pod anti-affinity (preference, not a
  requirement) spreads runners across nodes — every new runner prefers a host with no other runner,
  matched cluster-wide across namespaces; it still lands on a shared node when no free one fits, and
  only new placements are affected. (Cluster-wide matching is unavailable only if the cluster
  enables the CrossNamespaceAffinity quota scope as a limited resource — not default.) The pod
  tolerates no node taints, so tainted nodes — including dedicated workstation nodes — reject it.
- **Outbound access** to `github.com` (runner agent registration + job API) and everything the
  tooling action needs at job time (`get.jetify.com`, `cache.nixos.org`, `docker.io`, the GitHub
  release CDN, the container registries your jobs pull from).
- **`fs.inotify` limits** — raised in-pod by default (`tuneInotify`). See Configuration below.

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"GitHub Runner"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the GitHub Runner schema is available in **Genesis**. From the Workloads page,
author the template — users can then launch runner instances on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time
a runner is provisioned through **Hubble**:

| Field | Details |
|-------|---------|
| `url` | **string** · Required<br>GitHub repository or organization URL the runner registers to |
| `labels` | **string** · Default: `juno`<br>Comma-separated labels the runner advertises; workflows match them via `runs-on` |
| `version` | **string** · Default: `latest`<br>GitHub runner version to install, or `latest` to resolve the newest release at launch |
| `architecture` | **select** · Required · Default: `x64`<br>Runner binary architecture: `x64` or `arm64`. Also adds a `kubernetes.io/arch` nodeSelector (x64 → amd64, arm64 → arm64) pinning the pod to matching nodes |
| `baseImage` | **string** · Default: `ubuntu:26.04`<br>Base image for the pod. Keep it stock — the boot script installs podman with its recommended networking packages (netavark, nftables, aardvark-dns), and the rest of the toolchain is installed at job time by the tooling action. Change only if you need a pinned/mirrored image in an air-gapped cluster |
| `tuneInotify` | **boolean** · Required · Default: `true`<br>Raise `fs.inotify.max_user_instances` / `max_user_watches` from inside the pod. This is required for the nested KinD node's systemd to boot (at the default 128, systemd dies with "Failed to create control group inotify object" and kind only reports an opaque "could not find a log line that matches Multi-User System"). The limits are per-UID and *not* namespaced, so raising them changes the setting node-wide for every workload on that node (runtime only, not persisted). Disable if the cluster pre-tunes nodes via DaemonSet/machine config |
| `pool` | **string** · Optional<br>Node pool label to schedule onto (adds a `pool=<value>` nodeSelector entry) |
| `cpu` | **string** · Default: `2`<br>CPU cores requested |
| `memory` | **string** · Default: `4Gi`<br>Memory requested |
| `runnerStorageClass` | **string** · Optional<br>Storage class for the runner config PVC. Omit to use the default StorageClass |
| `runnerStorageSize` | **string** · Default: `50Gi`<br>PVC size for the runner agent, container storage, job workspace, and logs — everything writable lives on this one PVC (see Notes) |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time (the `env`
field, auto-injected into every schema). These are suggested for this workload:

| Variable | Description |
|----------|-------------|
| `RUNNER_TOKEN` | Runner registration token (org/repo **Settings → Actions → Runners → New self-hosted runner**) or a PAT with `admin:org` / `repo` scope. Only needed for the first registration — a live config on the PVC survives restarts without it (see Notes). Registration tokens expire after ~1 hour. **Plain text (no `sensitive` masking) and stored in the workload metadata ConfigMap — treat as a short-lived credential.** |

---

## Example workflow

The pod ships no toolchain except podman (installed at boot with its API socket live). Each job
installs what else it needs, usually via the team's tooling action (the first job on a pod
installs; later jobs are skipped by the action's `tooling_needed` check):

```yaml
name: build
on: push
jobs:
  build:
    runs-on: [self-hosted, juno]
    steps:
      - uses: actions/checkout@v4
      # podman is already installed at pod boot; this installs devbox, kind,
      # skaffold, gh, node, ... into the pod's rootfs
      - uses: <ci-repo>/actions/runners/tooling@main   # path to your tooling action
      - name: Build with podman
        run: |
          podman build -t my-app:latest .
```

The pod pre-sets `KIND_EXPERIMENTAL_PROVIDER=podman` and `DOCKER_HOST=unix:///run/podman/podman.sock`,
and the socket is live from boot — no tooling action needed first — so jobs can boot a nested KinD
cluster (the pod is more than capable of one per job):

```yaml
      - name: Bootstrap KinD and deploy
        run: |
          kind create cluster
          kubectl cluster-info
          skaffold run --kube-context kind-kind
          kind delete cluster
```

---

## Notes

- **Cold start** — the pod installs podman (with recommended: netavark, nftables, aardvark-dns)
  at boot (its Docker-compatible API socket
  starts there too); the rest of the toolchain installs at job time into the pod's rootfs (the
  first job on a pod pays it), and each job that boots KinD pulls
  the kind node image (~900 MB into the PVC-backed graphroot at `/var/lib/containers`).
- **`/var/lib/containers`** is a `subPath` on the runner-config PVC — podman's graphroot must not
  sit on the container's own overlayfs, which the PVC satisfies. `/etc/containers` configs
  (policy.json, registries.conf, storage.conf) are **not** pre-staged by the pod — Ubuntu's
  `containers-common` package installs them (stock registries.conf already lists `docker.io`).
  (Pre-staging them collided with the package's conffiles and broke `apt install podman` with an
  EOF conffile prompt.)
- **Podman socket ownership** — podman and its Docker-compatible API socket (`/run/podman/podman.sock`,
  symlinked at `/var/run/docker.sock`) are started by the pod's own init chain at boot (stage 5 of
  the payload script), **not** by any workflow job. This matters: the GitHub runner kills the whole
  process tree of a job when it ends, so a socket started from inside a job (the old tooling-action
  approach) died with each job. A socket started by the pod before the agent exists is never a job's
  child, so it survives job boundaries and lives for the pod's lifetime. Log: `/var/log/podman-system-service.log`.
  `/run` is tmpfs, so pod restarts clear stale sockets; `--time=0` prevents idle eviction.
- **Registration survives restarts** — the runner agent + registration config live on a PVC
  mounted at `/runner`. After the first successful registration, pod restarts skip registration
  entirely, so the ~1-hour registration-token expiry is only a first-launch concern. Jobs'
  working directory (`_work`) lives under the PVC (subPath `work`), so build artifacts grow the
  PVC — size it (`runnerStorageSize`) for what your jobs produce. If the PVC is lost (or the
  workload is deleted and recreated), the next launch re-registers from scratch — re-add the
  `RUNNER_TOKEN` env var with a fresh value at launch.
- **PVC caveats** — if the cluster has no default StorageClass, set `runnerStorageClass` or the
  PVC stays Pending. A ReadWriteOnce PVC binds to the first node the pod lands on; if the pod is
  rescheduled, the PVC keeps it pinned to that node (`safe-to-evict: false` limits eviction
  churn).
- **No ingress, no service** — the runner only makes outbound connections; nothing listens.