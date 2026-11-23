# NVIDIA GPU Operator

![NVIDIA GPU Operator](https://www.nvidia.com/content/nvidiaGDC/us/en_US/about-nvidia/legal-info/logo-brand-usage/_jcr_content/root/responsivegrid/nv_container_392921705/nv_container/nv_image.coreimg.100.410.png/1703060329053/nvidia-logo-vert.png)

**Category:** Hardware
**Type:** Cluster Service
**Tags:** `gpu` · `nvidia` · `time-slicing` · `vm-passthrough` · `operator`
**Editable:** Yes

---

## Overview

The NVIDIA GPU Operator automates the management of NVIDIA GPU resources in a Kubernetes cluster. It installs and configures all necessary software components — GPU drivers, container runtime (nvidia-container-toolkit), device plugin, and monitoring exporters — so that GPU-accelerated workloads can be scheduled on GPU nodes without manual configuration. It also configures time-slicing, which allows multiple containers to share a single GPU.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, GPU nodes are automatically configured and GPU resources become schedulable for any workload in the cluster — no per-workspace setup needed.

---

## Prerequisites

- At least one cluster node with an NVIDIA GPU (Pascal architecture or newer recommended)
- Nodes must be running a supported Linux kernel
- For k3s clusters: the plugin must be configured with `k3s: true` (see configuration below)
- For open kernel modules: the `open_kernel_modules` flag should match your driver installation type
- For node images that already ship the NVIDIA driver and container toolkit (EKS AL2023 / Bottlerocket NVIDIA AMIs, Karpenter `al2023@latest` on GPU instance types): set `install_driver` and `install_toolkit` to `false`, and `k3s` to `false`

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"NVIDIA GPU Operator"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **select** · Required · Default: `v25.10.1`<br>GPU Operator version to install (`v25.10.1` or `v25.3.4`) |
| `helm_repo` | **string** · Required · Default: `https://helm.ngc.nvidia.com/nvidia`<br>Helm repository URL for the GPU Operator chart |
| `install_driver` | **boolean** · Optional · Default: `true`<br>Run the operator's driver DaemonSet. Turn off when the node image ships the driver (EKS/Bottlerocket NVIDIA AMIs, distro-installed drivers); the operator then validates the host driver instead. |
| `open_kernel_modules` | **boolean** · Optional · Default: `false`<br>Install NVIDIA's open-source kernel modules instead of the proprietary ones. Required on Blackwell and newer (DGX Spark GB10, B200), supported on Turing and newer data-centre GPUs. Only applies while `install_driver` is on |
| `install_toolkit` | **boolean** · Optional · Default: `true`<br>Run the operator's container-toolkit DaemonSet. Turn off when the node image ships nvidia-container-toolkit (EKS NVIDIA AMIs). The plugin then creates the `nvidia` RuntimeClass itself. Off also disables the `k3s` socket override. |
| `k3s` | **boolean** · Optional · Default: `true`<br>Configure for k3s clusters (sets containerd socket path to `/run/k3s/containerd/containerd.sock`). Only applies while `install_toolkit` is on; set `false` on EKS. |
| `install_crds` | **boolean** · Optional · Default: `false`<br>Let the operator manage its optional CRDs (NVIDIADriver CRD, CRD upgrade and cleanup). The ClusterPolicy CRD always ships with the chart. Leave off when another GPU Operator release already owns these CRDs |
| `slice_count` | **int** · Required · Default: `4`<br>Number of time-slices per GPU; each GPU appears as this many `nvidia.com/gpu` resources. `1` turns time-slicing off. Ignored while `device_plugin` is off, so the HAMi handover needs no change here |
| `device_plugin` | **boolean** · Optional · Default: `true`<br>Run the operator's own device plugin. Turn off before installing the HAMi GPU Sharing plugin, which brings its own. Drivers, container toolkit, NFD and DCGM keep running. |

---

## Notes

- NFD resources are named `<release>-nfd-*` (`fullnameOverride`). The default naming overflowed Kubernetes' 63-character label limit on the NFD post-delete prune Job, which left uninstalls stuck in Argo CD with `DeletionError`. Existing installs from before this change rename their NFD Deployments/DaemonSet on the next sync (brief NFD restart, no GPU workload impact)
- This plugin is **editable** — you can update slice count, version, and flags after install via Terra
- **Pre-installed driver/toolkit (EKS):** the EKS AL2023 and Bottlerocket NVIDIA AMIs already carry the driver and `nvidia-container-toolkit`, with containerd's `nvidia` runtime registered. Running the operator's own driver or toolkit DaemonSets on those nodes fails or rewrites the containerd config, so set `install_driver` and `install_toolkit` to `false`. With the toolkit off the operator no longer creates the `nvidia` RuntimeClass, so this plugin creates it (handler `nvidia`); HAMi's device plugin and the workload templates rely on it
- **Karpenter:** Karpenter only provisions nodes for extended resources it knows (`nvidia.com/gpu`, `amd.com/gpu`, Neuron, EFA). HAMi slice resources (`nvidia.com/gpumem`, `nvidia.com/gpucores`) are unknown to it, so a sliced workload cannot scale a GPU node pool from zero; it schedules only onto a GPU node that already exists. Keep one GPU node warm (a placeholder pod with a `nodeSelector` on the pool's GPU label and no GPU request) or use Karpenter's NodeOverlay (alpha, v1.13+) to declare the slice resources on the instance types
- `install_crds` should be `true` on the **first installation only**. If you are reinstalling or running multiple GPU Operator instances, set it to `false` to avoid CRD conflicts
- `slice_count` controls GPU time-slicing — a value of `4` means each physical GPU appears as 4 schedulable GPU resources. Higher values allow more concurrent workloads per GPU at the cost of per-workload performance
- After installation, GPU nodes will be labelled `nvidia.com/gpu.present: "true"` and workloads can request GPUs with `resources.limits["nvidia.com/gpu"]`
- **With the HAMi GPU Sharing plugin:** set `device_plugin` to `false` first, then install HAMi. HAMi registers `nvidia.com/gpu` itself and handles slicing; two device plugins on one node fight over the resource. `slice_count` is ignored while the device plugin is off, so it can stay as is; GPU Feature Discovery then labels nodes as unsliced and HAMi does the slicing. Turn `device_plugin` back on after removing HAMi
- When the cluster has the Prometheus Operator CRDs (the `kube-prometheus-stack` plugin), the plugin creates a ServiceMonitor for the DCGM exporter automatically, labelled `release: prometheus`, so GPU utilisation and memory metrics land in Prometheus. HAMi-WebUI's utilisation and memory-used panels read these. No CRDs, no ServiceMonitor; install Prometheus later and Argo CD picks it up on its next refresh
