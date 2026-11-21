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
users and is served from the Genesis host under `/hami`, behind the Genesis authentication gate.

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
- A pod that asks for `nvidia.com/gpu: 1` and nothing else gets an 8 GiB slice
  (`default_gpu_memory`). Workloads request `nvidia.com/gpumem` and `nvidia.com/gpucores` for a
  different size or a compute share.

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
- **For AMD GPUs (`enable_amd`):** the **AMD GPU Operator** plugin installed with
  `device_plugin` set to `false` (its labeller and metrics exporter keep running; the HAMi AMD
  plugin even reads the exporter's health socket). Wait for the operator's device-plugin
  DaemonSet to disappear before turning `enable_amd` on. Nodes need `/dev/kfd`, `/dev/dri`
  and the operator's `feature.node.kubernetes.io/amd-gpu=true` label.

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
| `preconfigured_gpu_memory` | **int** · Optional · Default: `0`<br>Total GPU memory in MiB to assume per GPU when the driver cannot report it (DGX Spark / GB10). `0` uses the driver's value |
| `gpu_core_policy` | **select** · Optional · Default: `default`<br>When the `nvidia.com/gpucores` limit is enforced. `default`: only while another HAMi workload is active on the same GPU, so a lone workload runs at full speed. `force`: always. `disable`: never (gpucores only drives scheduling). Applies to workloads launched after a change. AMD compute slices are hardware masks and ignore this |
| `report_node_capacity` | **boolean** · Optional · Default: `false`<br>HAMi's device plugin also publishes each GPU node's total `nvidia.com/gpumem` and `nvidia.com/gpucores` in node capacity and allocatable. Needed for Karpenter to scale GPU nodes from zero for sliced workloads and to consolidate them again (see Autoscaling) |
| `host` | **string** · Required<br>DNS name of the Genesis host; the dashboard Ingress and iFrame use it |
| `enable_amd` | **boolean** · Optional · Default: `false`<br>Also share AMD GPUs: installs HAMi's AMD device plugin on nodes labelled `feature.node.kubernetes.io/amd-gpu=true` and lets the scheduler handle `amd.com/gpu`, `amd.com/gpumem`, `amd.com/gpucores`. Needs the AMD GPU Operator with `device_plugin` off. Off leaves AMD pods to the operator, whole GPU each |

### Fixed Settings

These used to be form fields. Each has one right answer for this catalog, so they now live in the
plugin's `values.yaml` and are not asked at install time. Change them in a fork if an environment
needs a mirror or a different pin.

| Setting | Value | Why fixed |
|---------|-------|-----------|
| `default_gpu_memory` | `8192` | GPU memory in MiB given to a workload that requests `nvidia.com/gpu` without `nvidia.com/gpumem`. Templates that set `gpumem` (`jupyter-notebook` via `HAMI_GPU_MEMORY`) override it per launch; every other GPU workload gets an 8 GiB slice instead of the whole card. Nonzero on purpose: on DGX Spark / GB10 a request without an absolute size fails at Allocate (see Notes). `0` would hand over whole GPUs where the driver reports memory |
| `device_memory_scaling` | `1` | GPU memory overcommit. Above `1` advertises more memory than the card has and spills to host memory; not something this catalog wants on by default |
| `device_core_scaling` | `1` | Compute overcommit. Nothing in the catalog relies on it and the AMD plugin ignores it |
| `device_list_strategy` | `cdi-annotations` | The GPU Operator runs the nvidia runtime in CDI mode; `envvar` fails container start. The other CDI value, `cdi-cri`, gives nothing extra here |
| `prefix` | `/hami` | Dashboard URL path on the Genesis host. Only a path collision would change it |
| `prometheus_url` | `http://prometheus-kube-prometheus-prometheus.prometheus.svc.cluster.local:9090` | In-cluster address of the Prometheus the dashboard reads from. The `kube-prometheus-stack` plugin always installs release `prometheus` in namespace `prometheus`, so this is the only value that matches the catalog |
| `prometheus_release_label` | `prometheus` | Label the catalog's Prometheus requires on ServiceMonitors before it scrapes them. Fixed for the same reason |
| `webui_git_repo`, `webui_git_revision` | HAMi-WebUI repo, pinned commit | Source pin for the dashboard chart until upstream publishes 2.0.0 to its Helm repository. Bumped with the plugin version, not per install |
| `amd_plugin_git_repo`, `amd_plugin_git_revision` | HAMi AMD device plugin repo, `amd-gpu-helm-0.0.4` | Source pin for the AMD plugin chart. Chart and image must come from the same release, so it is bumped with the plugin version |

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

Workload templates in this catalog (for example `jupyter-notebook` with `gpu` on and
`gpu_vendor: nvidia`) request `nvidia.com/gpu: "1"`. With HAMi installed that becomes an 8 GiB
slice (`default_gpu_memory`). `jupyter-notebook` sets memory and cores from env; other templates
get the default until they grow their own fields.

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
  exporter) carry `release: prometheus` so the catalog's Prometheus picks them up. The chart's
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

Karpenter decides what to launch from the resources pending pods request, and HAMi-sliced pods
request `nvidia.com/gpumem` and `nvidia.com/gpucores`. Two things stop that from working out of
the box, and the plugin plus one Karpenter object fix both:

1. **Karpenter does not know those resources exist on any instance type**, so no node is launched
   for a sliced pod ("no instance type satisfied resources"). A Karpenter `NodeOverlay` adds them
   to the scheduling simulation. Needs Karpenter 1.7 or newer with the `NodeOverlay` feature gate
   (`settings.featureGates.nodeOverlay: true`; alpha). One overlay per GPU model and GPU count, with
   the memory NVML reports per GPU (what HAMi registers), not the marketing figure:

   ```yaml
   apiVersion: karpenter.sh/v1alpha1
   kind: NodeOverlay
   metadata:
     name: hami-a10g-1
   spec:
     requirements:
       - key: karpenter.k8s.aws/instance-gpu-name
         operator: In
         values: ["a10g"]
       - key: karpenter.k8s.aws/instance-gpu-count
         operator: In
         values: ["1"]
     capacity:
       nvidia.com/gpumem: 23028   # MiB per GPU x GPU count
       nvidia.com/gpucores: 100   # 100 x GPU count
   ```

2. **A launched node would never be initialised.** Karpenter waits until every resource the pods
   asked for appears in the node's allocatable before it marks the NodeClaim initialised, with no
   timeout, and never consolidates an uninitialised node. By default HAMi registers only
   `nvidia.com/gpu`. Turn on `report_node_capacity` (HAMi's `devicePlugin.reportNodeCapacity`):
   the device plugin then sums the healthy GPUs' memory and cores it registered and patches the
   totals into the node's capacity and allocatable as `nvidia.com/gpumem` and `nvidia.com/gpucores`
   on every registration cycle. Karpenter then initialises the node, counts free slice capacity on
   existing GPU nodes before launching another, and consolidates empty ones.

Expected flow: sliced pod pending, NodeClaim within seconds, node Ready in about two minutes, HAMi
device plugin registers and reports capacity, `karpenter.sh/initialized=true`, pod runs. Delete the
pod and the node goes with `consolidateAfter`. Without it a node launched for a sliced pod
stays up until someone deletes the NodeClaim by hand, so enable the field before the first launch.

`report_node_capacity` is harmless on clusters without an autoscaler: the extra capacity
entries make kube-scheduler and kubelet check slice totals per node, which HAMi already enforces
per GPU. AMD nodes are not covered yet.

---

## Notes

- **Install order matters.** GPU Operator first, with its device plugin disabled; then HAMi.
  Installing HAMi while the operator's device plugin still runs leaves two plugins registering
  `nvidia.com/gpu` on each node.
- **DGX Spark / GB10** share system memory with the GPU and `nvidia-smi` reports no total.
  Without `preconfigured_gpu_memory` HAMi registers the node with zero GPU memory and no slice
  can be placed there. A 128 GB Spark takes about `98304`. On top of that, HAMi 2.11.0 validates
  percentage-sized allocations against the NVML memory value, which is 0 on GB10, so a plain
  `nvidia.com/gpu: 1` request fails at Allocate with "allocated N MB … but requests 0 MB". The
  plugin's `default_gpu_memory` of 8192 gives every such request an absolute size, so plain GPU
  workloads run; templates that set `nvidia.com/gpumem` (`jupyter-notebook` via `HAMI_GPU_MEMORY`)
  choose their own. Memory limits and compute quotas (`gpucores`) both work on GB10.
- **Core policy.** `gpucores` is a throttle in HAMi-core, not a hardware partition. With
  `gpu_core_policy: default` a workload alone on a GPU is never throttled; when a second HAMi
  workload becomes active on the same GPU, HAMi's monitor switches enforcement on within about
  10 s, each workload stalls for a few seconds while the token bucket refills, then settles at
  its share. When the other workload stops, the survivor climbs back to full speed. `force`
  pins every workload to its share from the first kernel, which is the setting to use when
  tenants should see the same throughput whether or not the GPU is shared. Enforcement is a
  token-bucket rate limiter, so a steady load runs as bursts with pauses in between (on GB10
  roughly 8 s near full speed, then 10 s blocked) and only the average over tens of seconds
  matches the share; measured 23% for a 25% limit. The policy is injected at admission
  (`GPU_CORE_UTILIZATION_POLICY`), so after changing it restart the workloads that should
  pick it up.
- **CDI.** `device_list_strategy` is fixed at `cdi-annotations` for the GPU Operator's CDI-mode runtime. With `envvar`
  the nvidia runtime in CDI mode fails container start with
  `unresolvable CDI devices management.nvidia.com/gpu=GPU-…`.
- **Scheduler image.** The chart derives the kube-scheduler image tag from the cluster's
  Kubernetes version; nothing to set.
- **Namespaces to leave alone.** Label a namespace `hami.io/webhook: ignore` to keep HAMi's
  webhook away from its pods.
- **AMD GPUs** share through HAMi's separate [AMD device plugin](https://github.com/Project-HAMi/amd-device-plugin)
  when `enable_amd` is on (a third Application, `<release>-hami-amd`, git-sourced at the tagged
  chart). Pods request `amd.com/gpu` plus `amd.com/gpumem` (MiB) and `amd.com/gpucores` (%).
  Differences from NVIDIA: a pod that sets only `gpumem` still books 100% of the compute units,
  so set `gpucores` on every pod that should share; compute slices are whole WGPs (CU pairs) on
  RDNA; the memory cap is an `LD_AUDIT` hook (glibc 2.34+) plus a kernel dmem cgroup cap where
  the kernel has that controller. There is no AMD view in the HAMi-WebUI dashboard yet.
  With `enable_amd` off the plugin blanks HAMi's AMD resource names so the webhook leaves
  `amd.com/gpu` pods to the default scheduler and the AMD GPU Operator's own device plugin;
  without that, HAMi 2.11 claims every such pod and leaves it pending with `node unregistered`.
- **AMD APUs (Ryzen AI, Strix Halo).** The plugin registers the VRAM carve-out reported by the
  driver (512 MiB on a Radeon 8060S), not the shared system memory ROCm actually allocates
  from. `amd.com/gpumem` above that fails scheduling, and omitting it books the whole 512 MiB,
  so one pod per GPU. Compute slicing (`gpucores`) is unaffected. Treat APU sharing as
  compute-only until the plugin reads GTT for APUs.
- **Uninstall** removes both Applications. Running GPU workloads keep their slices until they
  restart; new launches fall back to whatever device plugin is registered, so re-enable the GPU
  Operator's device plugin after removing HAMi.
