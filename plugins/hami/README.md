# HAMi GPU Sharing

![HAMi](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/hami/assets/hami-graph-color.svg)

**Category:** Hardware
**Type:** Cluster Service
**Tags:** `gpu` · `hami` · `gpu-sharing` · `dashboard`
**Editable:** Yes

---

## Overview

HAMi (Heterogeneous AI Computing Virtualization Middleware) lets several workloads share one
physical GPU. Each workload gets a slice with a GPU memory limit and an optional compute quota,
enforced inside the container, with no changes to application code.

HAMi sits on top of the NVIDIA GPU Operator. The operator keeps providing drivers, the container
toolkit, the `nvidia` RuntimeClass, Node Feature Discovery and the DCGM exporter. HAMi replaces
only the device plugin and adds its own scheduler extender.

The plugin installs two Argo CD Applications into `kube-system`:

| Application | Chart | Role |
|-------------|-------|------|
| `<release>-hami` | [`hami`](https://project-hami.github.io/HAMi/) | scheduler, webhook, device plugin |
| `<release>-hami-webui` | [`hami-webui`](https://github.com/Project-HAMi/HAMi-WebUI) 2.0.0 (from git) | GPU dashboard, embedded in Genesis |

The dashboard is a Genesis **dashboard plugin**: it appears in the Genesis sidebar for admin
users and is served from the Genesis host under `prefix`, behind the Genesis authentication gate.

---

## How It Works

**Cluster Service** — installed once per cluster by an administrator.

- The HAMi device plugin runs on every node the GPU Operator labels
  `nvidia.com/gpu.deploy.device-plugin=true`. Nodes in VM pass-through mode are skipped. No
  manual node labelling is needed.
- The device plugin advertises `nvidia.com/gpu` as before, multiplied by `device_split_count`,
  plus `nvidia.com/gpumem` and `nvidia.com/gpucores` so workloads can ask for a slice.
- A mutating webhook rewrites every pod that requests `nvidia.com/gpu` to use the HAMi
  scheduler. Workload templates do not need `schedulerName` set.
- A pod that asks for `nvidia.com/gpu: 1` and nothing else still gets the whole GPU unless
  `default_gpu_memory` is set. Sharing starts when workloads request `nvidia.com/gpumem` or
  `nvidia.com/gpucores`, or when `default_gpu_memory` makes every plain request a slice.

---

## Prerequisites

- **NVIDIA GPU Operator plugin installed** and healthy. HAMi needs the driver, the container
  toolkit and the `nvidia` RuntimeClass it provides.
- **The GPU Operator's own device plugin must be off.** Two device plugins registering
  `nvidia.com/gpu` on the same node fight over the resource. In the `nvidia-gpu-operator`
  plugin set `device_plugin` to `false` (the plugin is editable) and wait for the operator's
  device-plugin DaemonSet to disappear before installing HAMi. Its `slice_count` has no effect
  while the device plugin is off.
- **Prometheus with the Prometheus Operator CRDs** (the `kube-prometheus-stack` plugin). The
  dashboard creates ServiceMonitors and reads every panel from Prometheus.
- **Genesis reachable over HTTPS** on `host`; the dashboard is embedded in Genesis as an iFrame.
- **A GPU node with a working `nvidia-smi`.** Unified-memory systems such as NVIDIA DGX Spark
  (GB10) report `memory.total` as `N/A`; set `preconfigured_gpu_memory` for those (see Notes).

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"HAMi GPU Sharing"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

The plugin is editable: fields can be changed after install and Argo CD rolls the change out.

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **select** · Required · Default: `2.11.0`<br>HAMi chart version |
| `helm_repo` | **string** · Required · Default: `https://project-hami.github.io/HAMi/`<br>Helm repository for the HAMi chart |
| `scheduler_node_policy` | **select** · Optional · Default: `binpack`<br>Placement across nodes. `binpack` fills one node before using the next; `spread` distributes |
| `scheduler_gpu_policy` | **select** · Optional · Default: `spread`<br>Placement across the GPUs of one node. `spread` uses every GPU before doubling up; `binpack` fills one GPU first |
| `device_split_count` | **int** · Optional · Default: `10`<br>Maximum number of workloads sharing one physical GPU |
| `device_memory_scaling` | **string** · Optional · Default: `1`<br>GPU memory overcommit ratio. `1` advertises the real memory; `2` lets workloads claim twice the physical memory in total |
| `device_core_scaling` | **string** · Optional · Default: `1`<br>GPU compute overcommit ratio. `1` advertises 100% of the cores per GPU |
| `device_list_strategy` | **select** · Optional · Default: `cdi-annotations`<br>How GPUs are handed to the container runtime: `cdi-annotations`, `cdi-cri` (both CDI, needed with the GPU Operator's CDI-mode runtime) or `envvar` (legacy) |
| `default_gpu_memory` | **int** · Optional · Default: `0`<br>GPU memory in MiB given to a workload that requests `nvidia.com/gpu` without `nvidia.com/gpumem`. `0` gives such workloads the whole GPU. Set to, for example, `8192` to make every plain GPU request a slice |
| `preconfigured_gpu_memory` | **int** · Optional · Default: `0`<br>Total GPU memory in MiB to assume per GPU when the driver cannot report it (DGX Spark / GB10). `0` uses the driver's value |
| `host` | **string** · Required<br>DNS name of the Genesis host; the dashboard Ingress and iFrame use it |
| `prefix` | **string** · Optional · Default: `/hami`<br>URL path the dashboard is served under on the Genesis host |
| `prometheus_url` | **string** · Optional · Default: `http://prometheus-kube-prometheus-prometheus.prometheus.svc.cluster.local:9090`<br>In-cluster Prometheus URL the dashboard reads from. The default matches the `kube-prometheus-stack` plugin |
| `prometheus_release_label` | **string** · Optional · Default: `prometheus`<br>Value of the `release` label Prometheus requires on ServiceMonitors. The default matches the `kube-prometheus-stack` plugin. Empty adds no label |
| `webui_git_repo` | **string** · Required · Default: `https://github.com/Project-HAMi/HAMi-WebUI.git`<br>Git repository holding the HAMi-WebUI chart at `charts/hami-webui` |
| `webui_git_revision` | **string** · Required · Default: pinned commit on `main`<br>Git revision of the HAMi-WebUI chart. Pinned until upstream publishes chart 2.0.0 to its Helm repository |

---

## Requesting a GPU

HAMi keeps the standard resource name, so existing workloads keep working. Slices are requested
with two extra resources:

| Resource | Meaning |
|----------|---------|
| `nvidia.com/gpu` | Number of GPUs (or GPU slices) for the container |
| `nvidia.com/gpumem` | GPU memory for the container, in MiB |
| `nvidia.com/gpumem-percentage` | GPU memory as a percentage of the card, instead of `gpumem` |
| `nvidia.com/gpucores` | Share of the GPU's compute, 0–100 |

```yaml
# Whole GPU — unchanged from the GPU Operator (unless default_gpu_memory is set)
resources:
  limits:
    nvidia.com/gpu: 1
```

```yaml
# One slice: 4 GiB of GPU memory and up to 30% of compute
resources:
  limits:
    nvidia.com/gpu: 1
    nvidia.com/gpumem: 4096
    nvidia.com/gpucores: 30
```

Workload templates in this catalog (for example `jupyter-notebook` with `gpu` on and
`gpu_vendor: nvidia`) request `nvidia.com/gpu: "1"`. With HAMi installed that is a whole GPU
until either `default_gpu_memory` is set or the template grows memory and core fields.

---

## Dashboard

HAMi-WebUI is a read-only dashboard: cards per node and per GPU, allocation versus physical
capacity, running tasks and utilisation history. It never talks to HAMi directly; every panel is a
Prometheus query.

- Reached from the Genesis sidebar (admin users) or at `https://<host><prefix>/`. The Ingress
  carries the Genesis `auth-url` gate; the dashboard has no login of its own.
- Served under `prefix` through the chart's `frontend.basePath`, with `frameAncestors` set to
  `'self'` so only the Genesis host may embed it. This is why the plugin needs chart 2.0.0: the
  1.x dashboard can only live at `/`.
- Two ServiceMonitors (HAMi device-plugin metrics in `kube-system`, and the dashboard's own
  exporter) carry `release: <prometheus_release_label>` so Prometheus picks them up. The chart's
  bundled Prometheus and DCGM exporter stay off because the cluster already has both.
- **Utilisation panels need DCGM metrics in Prometheus.** Allocation data comes from HAMi's own
  exporter and works out of the box. Per-GPU utilisation and memory-used graphs come from the GPU
  Operator's DCGM exporter; turn on `dcgm_servicemonitor` in the `nvidia-gpu-operator` plugin
  (same `prometheus_release_label`). Without it those panels stay empty.
- The chart is sourced from git because upstream has not published 2.0.0 to its Helm repository.
  Argo CD builds the chart's dependencies at sync time, so the repo-server needs outbound access to
  `prometheus-community.github.io` and `nvidia.github.io` as well as GitHub. The image is pulled by
  digest, pinned by the chart.

---

## Notes

- **Install order matters.** GPU Operator first, with its device plugin disabled; then HAMi.
  Installing HAMi while the operator's device plugin still runs leaves two plugins registering
  `nvidia.com/gpu` on each node.
- **Overcommit** (`device_memory_scaling` or `device_core_scaling` above `1`) advertises more
  capacity than the hardware has. Memory limits are still enforced per container; contention
  happens only when every consumer uses its full share at once.
- **DGX Spark / GB10** share system memory with the GPU and `nvidia-smi` reports no total.
  Without `preconfigured_gpu_memory` HAMi registers the node with zero GPU memory and no slice
  can be placed there. A 128 GB Spark takes about `98304`. On top of that, HAMi 2.11.0 validates
  percentage-sized allocations against the NVML memory value, which is 0 on GB10, so a plain
  `nvidia.com/gpu: 1` request fails at Allocate with "allocated N MB … but requests 0 MB". Set
  `default_gpu_memory` (or have workloads request `nvidia.com/gpumem`) so the request carries an
  absolute size. Compute quotas (`gpucores`) on this platform are not yet confirmed to throttle;
  memory limits work.
- **CDI.** Leave `device_list_strategy` on a CDI value with the GPU Operator plugin. With `envvar`
  the nvidia runtime in CDI mode fails container start with
  `unresolvable CDI devices management.nvidia.com/gpu=GPU-…`.
- **Scheduler image.** The chart derives the kube-scheduler image tag from the cluster's
  Kubernetes version; nothing to set.
- **Namespaces to leave alone.** Label a namespace `hami.io/webhook: ignore` to keep HAMi's
  webhook away from its pods.
- **AMD GPUs** are not handled by this plugin yet. HAMi's AMD device plugin is a separate,
  git-only chart; wiring it in is planned as a follow-up once the NVIDIA path is proven.
- **Uninstall** removes both Applications. Running GPU workloads keep their slices until they
  restart; new launches fall back to whatever device plugin is registered, so re-enable the GPU
  Operator's device plugin after removing HAMi.
