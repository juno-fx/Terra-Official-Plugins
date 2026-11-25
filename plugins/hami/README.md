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

HAMi sits on top of the GPU operator for each vendor and replaces only its device plugin, adding
its own scheduler extender. The **NVIDIA GPU Operator** keeps providing drivers, the container
toolkit, the `nvidia` RuntimeClass, Node Feature Discovery and the DCGM exporter. With
`enable_amd`, the **AMD GPU Operator** keeps providing node labelling and the metrics exporter
while HAMi's AMD device plugin shares the GPUs as `amd.com/gpu`. Both vendors can run in one
cluster; a pod requests one vendor's resources.

The plugin installs two Argo CD Applications into `kube-system`, three with `enable_amd`:

| Application | Chart | Role |
|-------------|-------|------|
| `<release>-hami` | [`hami`](https://project-hami.github.io/HAMi/) | scheduler, webhook, device plugin |
| `<release>-hami-webui` | [`hami-webui`](https://github.com/Project-HAMi/HAMi-WebUI) 2.0.0 (from git) | GPU dashboard, embedded in Genesis |
| `<release>-hami-amd` | [`amd-gpu`](https://github.com/Project-HAMi/amd-device-plugin) (from git, `enable_amd` only) | AMD device plugin |

The dashboard is a Genesis **dashboard plugin**: it appears in the Genesis sidebar for admin
users and is served from the Genesis host under `/hami`, behind the Genesis authentication gate.

---

## How It Works

**Cluster Service** — installed once per cluster by an administrator.

- The HAMi device plugin runs on every node the NVIDIA GPU Operator labels
  `nvidia.com/gpu.deploy.device-plugin=true`. Nodes in VM pass-through mode are skipped. With
  `enable_amd`, HAMi's AMD device plugin runs on every node the AMD GPU Operator labels
  `feature.node.kubernetes.io/amd-gpu=true`. No manual node labelling is needed for either.
- Each device plugin advertises the vendor's GPU resource as before (`nvidia.com/gpu`,
  `amd.com/gpu`), multiplied by `device_split_count`, plus `<vendor>/gpumem` and
  `<vendor>/gpucores` so workloads can ask for a slice.
- A mutating webhook rewrites every pod that requests `nvidia.com/gpu` or `amd.com/gpu` to use
  the HAMi scheduler. Workload templates do not need `schedulerName` set.
- A pod that asks for `nvidia.com/gpu: 1` and nothing else gets an 8 GiB slice
  (`default_gpu_memory`). Workloads request `gpumem` and `gpucores` for a different size or a
  compute share. On AMD, a pod that sets only `gpumem` still books all of the compute, so set
  `gpucores` on every AMD pod that should share.

---

## Prerequisites

- **A GPU operator plugin installed and healthy**, one per vendor in the cluster:
  - **NVIDIA GPU Operator** for NVIDIA GPUs. HAMi needs the driver, the container toolkit and
    the `nvidia` RuntimeClass it provides.
  - **AMD GPU Operator** for AMD GPUs, used with `enable_amd`. HAMi needs the
    `feature.node.kubernetes.io/amd-gpu=true` label it sets; its metrics exporter keeps running
    and the HAMi AMD plugin reads the exporter's health socket. Nodes need `/dev/kfd` and
    `/dev/dri`. Nodes the operator targets with `vgpu_nodes` (label `amd-vgpu`) are not
    covered: HAMi's AMD plugin needs the physical device.
- **The operator's own device plugin must be off.** Two device plugins registering the same
  resource on one node fight over it. In the operator plugin set `device_plugin` to `false`
  (both are editable) and wait for its device-plugin DaemonSet to disappear before installing
  HAMi or turning `enable_amd` on. The NVIDIA operator's `slice_count` has no effect while its
  device plugin is off.
- **Prometheus with the Prometheus Operator CRDs** (the `kube-prometheus-stack` plugin) for the
  dashboard panels. The plugin creates its ServiceMonitors only when the CRDs exist, so HAMi
  installs without Prometheus; the dashboard then stays empty until Prometheus is added.
- **Genesis reachable over HTTPS** on `host`; the dashboard is embedded in Genesis as an iFrame.
- **A GPU node with a working `nvidia-smi`** (NVIDIA). GB10 unified-memory systems (NVIDIA DGX
  Spark and OEM equivalents) report `memory.total` as `N/A`; set `preconfigured_gpu_memory` for
  those (see Notes).

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
| `host` | **string** · Required<br>DNS name of the Genesis host; the dashboard Ingress and iFrame use it |
| `prefix` | **string** · Optional · Default: `/hami`<br>URL path of the GPU dashboard on the Genesis host. Change only if another plugin already uses that path |
| `scheduler_node_policy` | **select** · Optional · Default: `binpack`<br>Placement across nodes. `binpack` fills one node before using the next; `spread` distributes |
| `scheduler_gpu_policy` | **select** · Optional · Default: `spread`<br>Placement across the GPUs of one node. `spread` uses every GPU before doubling up; `binpack` fills one GPU first |
| `device_split_count` | **int** · Optional · Default: `10`<br>Maximum number of workloads sharing one physical GPU |
| `preconfigured_gpu_memory` | **int** · Optional · Default: `0`<br>GPU memory in MiB to register for a GPU whose memory the driver cannot report: GB10 unified-memory systems (DGX Spark and OEM equivalents such as ASUS Ascent GX10, Dell Pro Max GB10; 128 GB takes about `98304`). GPUs that report their memory ignore this, so it is safe in mixed clusters. `0` skips GPUs that cannot report it |
| `gpu_core_policy` | **select** · Optional · Default: `default`<br>When the `nvidia.com/gpucores` limit is enforced. `default`: only while another HAMi workload is active on the same GPU, so a lone workload runs at full speed. `force`: always. `disable`: never (gpucores only drives scheduling). Applies to workloads launched after a change. AMD compute slices are hardware masks and ignore this |
| `report_node_capacity` | **boolean** · Optional · Default: `false`<br>Both device plugins also publish each GPU node's total `gpumem` and `gpucores` (`nvidia.com/` and `amd.com/`) in node capacity and allocatable. Needed for Karpenter to scale GPU nodes from zero for sliced workloads and to consolidate them again (see Autoscaling) |
| `enable_amd` | **boolean** · Optional · Default: `false`<br>Also share AMD GPUs: installs HAMi's AMD device plugin on nodes labelled `feature.node.kubernetes.io/amd-gpu=true` and lets the scheduler handle `amd.com/gpu`, `amd.com/gpumem`, `amd.com/gpucores`. Needs the AMD GPU Operator with `device_plugin` off. Off leaves AMD pods to the operator, whole GPU each |

### Fixed Settings

Each of these has one right answer for this catalog, so they live in the plugin's `values.yaml`
and are not asked at install time. Change them in a fork if an environment needs a mirror or a
different pin.

- **`default_gpu_memory`** = `8192`. GPU memory in MiB for a workload that requests `nvidia.com/gpu` without `nvidia.com/gpumem`. Templates that set `gpumem` (`jupyter-notebook` via `HAMI_GPU_MEMORY`) override it per launch; every other GPU workload gets an 8 GiB slice instead of the whole card. Nonzero on purpose: on GB10 a request without an absolute size fails at Allocate (see Notes). `0` would hand over whole GPUs where the driver reports memory.
- **`device_memory_scaling`** = `1`. GPU memory overcommit. Above `1` advertises more memory than the card has and spills to host memory; not wanted on by default.
- **`device_core_scaling`** = `1`. Compute overcommit. Nothing in the catalog relies on it and the AMD plugin ignores it.
- **`device_list_strategy`** = `cdi-annotations`. The GPU Operator runs the nvidia runtime in CDI mode; `envvar` fails container start. The other CDI value, `cdi-cri`, gives nothing extra here.
- **`prometheus_url`** = in-cluster address of the catalog's Prometheus (`prometheus-kube-prometheus-prometheus.prometheus.svc.cluster.local:9090`). The `kube-prometheus-stack` plugin always installs release `prometheus` in namespace `prometheus`, so this is the only value that matches.
- **`prometheus_release_label`** = `prometheus`. Label the catalog's Prometheus requires on ServiceMonitors before it scrapes them.
- **`webui_git_repo`, `webui_git_revision`** = HAMi-WebUI repo, pinned commit. Source pin for the dashboard chart until upstream publishes 2.0.0 to its Helm repository. Bumped with the plugin version, not per install.
- **`amd_plugin_git_repo`, `amd_plugin_git_revision`** = HAMi AMD device plugin repo, `amd-gpu-helm-0.0.4`. Source pin for the AMD plugin chart. Chart and image must come from the same release, so it is bumped with the plugin version.

---

## Requesting a GPU

HAMi keeps the standard resource name, so existing workloads keep working. Slices are requested
with two extra resources per vendor:

| Resource | Meaning |
|----------|---------|
| `nvidia.com/gpu`, `amd.com/gpu` | Number of GPUs (or GPU slices) for the container |
| `nvidia.com/gpumem`, `amd.com/gpumem` | GPU memory for the container, in MiB |
| `nvidia.com/gpucores`, `amd.com/gpucores` | Share of the GPU's compute, 0–100 |

```yaml
# Plain request: an 8 GiB slice (default_gpu_memory), compute unthrottled
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

Workload templates in this catalog (for example `jupyter-notebook` with `gpu` set to `nvidia` or
`amd`) request one GPU. With HAMi installed that becomes an 8 GiB slice (`default_gpu_memory`)
on NVIDIA. `jupyter-notebook` sets memory and cores from env; other templates get the default
until they grow their own fields.

HAMi supports further pod-level settings this plugin does not expose, such as memory as a
percentage of the card or pinning a pod to a GPU model. To use them, fork this repository and
adjust the plugin. The upstream references for pod resources and annotations:

- [NVIDIA: device memory](https://project-hami.io/docs/userguide/NVIDIA-device/specify-device-memory-usage)
- [NVIDIA: device cores](https://project-hami.io/docs/userguide/NVIDIA-device/specify-device-core-usage)
- [AMD: GPU sharing](https://project-hami.io/docs/userguide/AMD-device/enable-amd-gpu-sharing)
- [AMD device plugin README](https://github.com/Project-HAMi/amd-device-plugin/blob/amd-gpu-helm-0.0.4/README.md)

---

## Dashboard

HAMi-WebUI is a read-only dashboard: cards per node and per GPU, allocation versus physical
capacity, running tasks and utilisation history. It never talks to HAMi directly; every panel is a
Prometheus query.

- Reached from the Genesis sidebar (admin users) or at `https://<host>/hami/`. The Ingress
  carries the Genesis `auth-url` gate; the dashboard has no login of its own.
- Served under `/hami` through the chart's `frontend.basePath`, with `frameAncestors` set to
  `'self'` so only the Genesis host may embed it. This is why the plugin needs chart 2.0.0: the
  1.x dashboard can only live at `/`.
- Two ServiceMonitors (HAMi device-plugin metrics in `kube-system`, and the dashboard's own
  exporter) carry `release: prometheus` so the catalog's Prometheus picks them up. They are
  rendered only while the Prometheus Operator CRDs exist; Argo CD adds them on the next refresh
  after the Prometheus plugin is installed. The chart's
  bundled Prometheus and DCGM exporter stay off because the cluster already has both.
- **Utilisation panels need DCGM metrics in Prometheus.** Allocation data comes from HAMi's own
  exporter and works out of the box. Per-GPU utilisation and memory-used graphs come from the GPU
  Operator's DCGM exporter. The `nvidia-gpu-operator` plugin creates its ServiceMonitor on its own
  wherever the Prometheus Operator CRDs exist, so with the Prometheus plugin installed the panels
  fill in; without Prometheus they stay empty.
- The chart is sourced from git because upstream has not published 2.0.0 to its Helm repository.
  Argo CD builds the chart's dependencies at sync time, so the repo-server needs outbound access to
  `prometheus-community.github.io` and `nvidia.github.io` as well as GitHub. The image is pulled by
  digest, pinned by the chart.

## Autoscaling with Karpenter

Karpenter launches nodes from the resources pending pods request. HAMi-sliced pods request
`nvidia.com/gpumem` and `nvidia.com/gpucores`, which Karpenter has never heard of, so two things
are needed. Both are only for scale-from-zero; nodes already running need neither.

**1. Turn on `report_node_capacity`** in this plugin. HAMi's device plugin then publishes each
node's total `gpumem` and `gpucores` in node capacity. Without it, Karpenter waits forever for
those resources to appear, never marks the node initialised and never consolidates it, so a node
launched for a sliced pod stays up until deleted by hand. Enable before the first launch.

**2. Add a Karpenter `NodeOverlay` per GPU model.** The overlay tells Karpenter how much `gpumem`
and `gpucores` an instance type will have once HAMi runs on it, so it can pick one. Needs
Karpenter 1.7+ with `settings.featureGates.nodeOverlay: true` (alpha).

```yaml
apiVersion: karpenter.sh/v1alpha1
kind: NodeOverlay
metadata:
  name: hami-a10g-1
spec:
  requirements:
    - key: karpenter.k8s.aws/instance-gpu-name   # GPU model: a10g (g5), l4 (g6), l40s (g6e), h100 (p5)
      operator: In
      values: ["a10g"]
    - key: karpenter.k8s.aws/instance-gpu-count  # GPUs per instance
      operator: In
      values: ["1"]
  capacity:
    # gpumem is the GPU's VRAM in MiB, as HAMi registers it, x GPU count.
    # Find it with: aws ec2 describe-instance-types --instance-types g5.xlarge \
    #   --query 'InstanceTypes[].GpuInfo.Gpus[].MemoryInfo.SizeInMiB'
    # or copy it from a node that has run that card (see below). Round down.
    nvidia.com/gpumem: 23028
    nvidia.com/gpucores: 100   # 100 x GPU count
```

NodeOverlay is cluster-scoped. Save it as `hami-a10g-1.yaml` and apply it with:

```bash
kubectl apply -f hami-a10g-1.yaml
kubectl get nodeoverlay          # READY True once Karpenter has parsed and matched it
```

How the pieces fit:

- An overlay covers every instance size with that GPU model and count: `a10g` x `1` is
  g5.xlarge through g5.16xlarge. Write one overlay per model and count your NodePool allows,
  not one per instance type. Restricting the NodePool to `instance-gpu-count In ["1"]` keeps it
  to one overlay per card.
- Karpenter picks the cheapest instance type whose declared capacity fits the pod. A 4 GiB slice
  lands on g5; a 40 GiB slice needs an overlay for a bigger card (`l40s`, `a100`, `h100`) and a
  NodePool that allows its family. With no overlay large enough the pod stays Pending with
  `no instance type satisfied resources`; nothing launches.
- `gpumem` is the card's VRAM. HAMi registers what the driver reports, which is a little less
  than the marketing figure, so copy it from a node that has run that card:
  `kubectl get node <node> -o jsonpath='{.status.allocatable.nvidia\.com/gpumem}'`.
  Without such a node, `aws ec2 describe-instance-types` gives the nominal size; round down.
  Too high launches nodes the pod cannot fit; too low only refuses launches.
- One pod slice is at most one GPU. `nvidia.com/gpu: 2` gives two slices, not one double-sized
  one.
- With `enable_amd`, the AMD device plugin publishes `amd.com/gpumem` and `amd.com/gpucores` the
  same way; its overlay uses those names and `instance-gpu-manufacturer: amd`.

Expected flow: sliced pod pending, NodeClaim within seconds, node Ready in about two minutes, HAMi
registers and reports capacity, `karpenter.sh/initialized=true`, pod runs. Delete the pod and the
node goes with `consolidateAfter`.

---

## Notes

- **Install order.** GPU operator first with its device plugin off, then HAMi (or `enable_amd`).
  Two device plugins registering the same resource on one node fight over it.
- **GB10 systems (DGX Spark and OEM equivalents).** `nvidia-smi` reports no memory total, so
  set `preconfigured_gpu_memory` (about `98304` for 128 GB) or HAMi skips the GPU. A plain
  `nvidia.com/gpu: 1` request also fails on GB10 without an absolute size, which is why
  `default_gpu_memory` is nonzero. Memory limits and `gpucores` both work on GB10.
- **Core policy.** `gpucores` is a throttle, not a hardware partition. `default` throttles a
  workload only while another HAMi workload is active on the same GPU; `force` throttles always,
  for the same throughput shared or not. Enforcement is a rate limiter, so load runs in bursts
  and only the average over tens of seconds matches the share. Set at admission: restart
  workloads after changing it.
- **CDI.** `device_list_strategy` stays `cdi-annotations`; `envvar` fails container start under
  the GPU Operator's CDI-mode runtime.
- **Scheduler image** tag is derived from the cluster's Kubernetes version; nothing to set.
- **Namespaces to leave alone.** Label a namespace `hami.io/webhook: ignore` to keep HAMi's
  webhook away from its pods.
- **AMD GPUs** share through HAMi's separate
  [AMD device plugin](https://github.com/Project-HAMi/amd-device-plugin) when `enable_amd` is
  on. A pod that sets only `gpumem` still books all of the compute, so set `gpucores` on every
  AMD pod that should share. The HAMi-WebUI dashboard has no AMD view yet. With `enable_amd` off
  the plugin blanks HAMi's AMD resource names so `amd.com/gpu` pods stay with the default
  scheduler and the AMD GPU Operator's device plugin instead of hanging on `node unregistered`.
- **AMD APUs (Ryzen AI, Strix Halo).** The plugin registers the driver's VRAM carve-out (512 MiB
  on a Radeon 8060S), not shared system memory. `gpumem` above that fails scheduling and
  omitting it books the whole 512 MiB, so one pod per GPU. Treat APU sharing as compute-only.
- **Uninstall** removes all Applications. Running workloads keep their slices until restart; new
  launches need a device plugin, so turn `device_plugin` back on in the GPU operator plugins.
