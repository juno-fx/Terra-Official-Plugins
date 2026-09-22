# GitHub Runner

![GitHub Runner](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/github-runner/scripts/assets/logo.png)

**Category:** CI/CD
**Type:** Workload Template
**Tags:** `workload` · `cluster-level` · `cicd` · `github` · `runner`

---

## Overview

Self-hosted GitHub Actions runner as a workload. Each runner pod is a clean, install-capable
environment (privileged, cgroup- and mount-namespaced, **KinD-capable**) running the runner agent —
**no toolchain is pre-installed**. Workflow jobs install the tools they need (podman, kind, skaffold,
kubectl, devbox, gh, …) at job time, typically via the team's existing tooling action — so an image
built in this plugin is a runner that can build images with podman and deploy them to a real (nested)
KinD cluster, without a Docker socket, host mounts, or a Dockerfile to maintain.

---

## How It Works

**Workload Template** — Installs the GitHub Runner workload schema into Genesis. Once installed,
launch a runner from the Workloads page like any other workload.

The runner pod is a privileged pod whose first process (`init.sh`) fixes the one thing Kubernetes
cannot express: a privileged pod runs in the **host cgroup namespace**, so `init.sh` re-execs into
a private cgroup + mount namespace, remounts cgroup2 to the pod's own scope, delegates the cgroup
controllers, and stages `/etc/containers` config plus a non-overlayfs graphroot. It then `exec`s
the payload script, which bootstraps a minimal apt base and downloads, registers and starts the
GitHub Actions runner agent. The agent is the pod's command chain — `kubectl exec` cannot enter the
unshared namespaces, so the agent must run this way.

Workflow jobs run inside the pod on a clean base. The first job on a pod installs the toolchain
into the pod's rootfs (via the team's tooling action); later jobs on the same pod reuse it. The pod
exposes `KIND_EXPERIMENTAL_PROVIDER=podman` and `DOCKER_HOST=unix:///run/podman/podman.sock` so
tooling that shells out to `docker` or boots a KinD cluster finds the right socket once podman is
installed.

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

- **Scheduling** — the pod schedules on any (untainted) node by default. Use the `pool` field to
  target a labeled pool. The pod tolerates no node taints, so tainted nodes — including dedicated
  workstation nodes — reject it.
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
| `architecture` | **select** · Required · Default: `x64`<br>Runner binary architecture: `x64` or `arm64` |
| `baseImage` | **string** · Default: `ubuntu:26.04`<br>Base image for the pod. Keep it stock — the toolchain is installed at job time by the tooling action. Change only if you need a pinned/mirrored image in an air-gapped cluster |
| `tuneInotify` | **boolean** · Required · Default: `true`<br>Raise `fs.inotify.max_user_instances` / `max_user_watches` from inside the pod. This is required for the nested KinD node's systemd to boot (at the default 128, systemd dies with "Failed to create control group inotify object" and kind only reports an opaque "could not find a log line that matches Multi-User System"). The limits are per-UID and *not* namespaced, so raising them changes the setting node-wide for every workload on that node (runtime only, not persisted). Disable if the cluster pre-tunes nodes via DaemonSet/machine config |
| `pool` | **string** · Optional<br>Node pool label to schedule onto (adds a `pool=<value>` nodeSelector entry) |
| `cpu` | **string** · Default: `2`<br>CPU cores requested |
| `memory` | **string** · Default: `4Gi`<br>Memory requested |
| `runnerStorageClass` | **string** · Optional<br>Storage class for the runner config PVC. Omit to use the default StorageClass |
| `runnerStorageSize` | **string** · Default: `1Gi`<br>PVC size for the runner agent + registration config (~200 MB); jobs' build workspace stays on ephemeral storage |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time (the `env`
field, auto-injected into every schema). These are suggested for this workload:

| Variable | Description |
|----------|-------------|
| `RUNNER_TOKEN` | Runner registration token (org/repo **Settings → Actions → Runners → New self-hosted runner**) or a PAT with `admin:org` / `repo` scope. Only needed for the first registration — a live config on the PVC survives restarts without it (see Notes). Registration tokens expire after ~1 hour. **Plain text (no `sensitive` masking) and stored in the workload metadata ConfigMap — treat as a short-lived credential.** |

---

## Example workflow

The pod ships no toolchain — each job installs what it needs, usually via the team's tooling action
(the first job on a pod installs; later jobs are skipped by the action's `tooling_needed` check):

```yaml
name: build
on: push
jobs:
  build:
    runs-on: [self-hosted, juno]
    steps:
      - uses: actions/checkout@v4
      # installs podman, devbox, kind, skaffold, gh, node, ... into the pod's rootfs
      - uses: <ci-repo>/actions/runners/tooling@main   # path to your tooling action
      - name: Build with podman
        run: |
          podman build -t my-app:latest .
```

The pod pre-sets `KIND_EXPERIMENTAL_PROVIDER=podman` and `DOCKER_HOST=unix:///run/podman/podman.sock`,
so once the tooling action has installed podman, jobs can boot a nested KinD cluster (the pod is
more than capable of one per job):

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

- **Cold start** — the pod installs only a minimal apt base; the toolchain install happens at job
  time into the pod's rootfs (the first job on a pod pays it), and each job that boots KinD pulls
  the kind node image (~900 MB into the emptyDir at `/var/lib/containers`). The emptyDir counts
  toward the ephemeral-storage request/limit (6 Gi / 12 Gi); rootfs writes are not.
- **`/var/lib/containers`** is an `emptyDir` — podman's graphroot must not sit on the container's
  overlayfs, which the pod satisfies without any PVC or host mount.
- **systemd gap** — the tooling action's `systemctl enable --now podman.socket` step assumes
  systemd as PID 1 (live VM runners). Pods have no systemd, so under GitHub's default `bash -e`
  that step fails. Use a pod-compatible variant: create the socket with
  `podman system service --time=0 unix:///run/podman/podman.sock &`, or `systemctl enable` without
  `--now`. This is action-side — the pod only guarantees a clean, install-capable, non-systemd
  environment.
- **`/var/lib/containers`** is an `emptyDir` — podman's graphroot must not sit on the container's
  overlayfs, which the pod satisfies without any PVC or host mount.
- **Registration survives restarts** — the runner agent + registration config live on a PVC
  mounted at `/runner`. After the first successful registration, pod restarts skip registration
  entirely, so the ~1-hour registration-token expiry is only a first-launch concern. Jobs'
  working directory (`_work`) stays on the ephemeral `/work` emptyDir, so build artifacts never
  grow the PVC. If the PVC is lost (or the workload is deleted and recreated), the next launch
  re-registers from scratch — re-add the `RUNNER_TOKEN` env var with a fresh value at launch.
- **PVC caveats** — if the cluster has no default StorageClass, set `runnerStorageClass` or the
  PVC stays Pending. A ReadWriteOnce PVC binds to the first node the pod lands on; if the pod is
  rescheduled, the PVC keeps it pinned to that node (`safe-to-evict: false` limits eviction
  churn).
- **No ingress, no service** — the runner only makes outbound connections; nothing listens.