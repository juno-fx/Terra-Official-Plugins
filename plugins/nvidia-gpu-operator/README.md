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
- Open kernel modules are picked automatically where the GPU needs them; `open_kernel_modules` only forces them
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
| `slice_count` | **int** · Required · Default: `4`<br>Number of time-slices per GPU; each GPU appears as this many `nvidia.com/gpu` resources. `1` turns time-slicing off. Ignored while `device_plugin` is off, so the HAMi handover needs no change here |
| `install_driver` | **boolean** · Optional · Default: `true`<br>Run the operator's driver DaemonSet. Turn off when the node image ships the driver (EKS/Bottlerocket NVIDIA AMIs, distro-installed drivers); the operator then validates the host driver instead. |
| `open_kernel_modules` | **boolean** · Optional · Default: `false`<br>Force NVIDIA's open-source kernel modules (`driver.kernelModuleType: open`). Off leaves the choice to the operator (`auto`), which already picks the open modules where they are required (Blackwell and newer: DGX Spark GB10, B200). Only applies while `install_driver` is on |
| `install_toolkit` | **boolean** · Optional · Default: `true`<br>Run the operator's container-toolkit DaemonSet. Turn off when the node image ships nvidia-container-toolkit (EKS NVIDIA AMIs). The plugin then creates the `nvidia` RuntimeClass itself. Off also disables the `k3s` socket override. |
| `k3s` | **boolean** · Optional · Default: `true`<br>Configure for k3s clusters (sets containerd socket path to `/run/k3s/containerd/containerd.sock`). Only applies while `install_toolkit` is on; set `false` on EKS. |
| `install_crds` | **boolean** · Optional · Default: `false`<br>Manage the driver through an `NVIDIADriver` custom resource instead of the ClusterPolicy, and add the operator's CRD upgrade and cleanup jobs. Does not install CRDs: both always ship with the chart. Turning it on restarts the driver pods. The driver part is skipped while `install_driver` is off |
| `install_nfd` | **boolean** · Optional · Default: `true`<br>Install Node Feature Discovery (NFD), which labels the GPU nodes for the operator. Only one NFD install per cluster: turn off if the AMD GPU Operator plugin (or anything else) already installs it. |
| `device_plugin` | **boolean** · Optional · Default: `true`<br>Run the operator's own device plugin. Turn off before installing the HAMi GPU Sharing plugin, which brings its own. Drivers, container toolkit, NFD and DCGM keep running. |

---

## Install with HAMI

The HAMi GPU Sharing plugin runs on top of this plugin. The GPU Operator keeps providing the driver, the container toolkit, the `nvidia` RuntimeClass, node labels and GPU metrics. HAMi replaces only the device plugin, so it can hand out slices of a GPU with a memory limit instead of whole GPUs.

### Field values

| Field | Value | Why |
|-------|-------|-----|
| `device_plugin` | `false` | HAMi brings its own device plugin. Two on one node fight over `nvidia.com/gpu`. |
| `version` | `v25.10.1` | The version HAMi is tested with. |
| `install_driver` | `true` | HAMi needs a working driver. `false` only when the node image ships it (EKS NVIDIA AMIs). |
| `install_toolkit` | `true` | HAMi needs the `nvidia` runtime. `false` only when the node image ships it (EKS NVIDIA AMIs). |
| `k3s` | `true` on k3s, `false` elsewhere | Same as a normal install. |
| `slice_count` | any | Ignored while `device_plugin` is off. HAMi does the slicing. |

Leave the other fields at their defaults.

### Steps

1. Install the **Prometheus** plugin (`kube-prometheus-stack`) if you want the HAMi dashboard's GPU panels
2. Install this plugin with the values above. On an existing install, edit it and set `device_plugin` to `false`
3. Wait until the `nvidia-device-plugin-daemonset` pods are gone from the operator's namespace
4. Install the **HAMi** plugin

To go back, uninstall HAMi first, then set `device_plugin` to `true`.

---

## Notes

- This plugin is **editable** — you can update slice count, version, and flags after install via Terra
- After installation, GPU nodes are labelled `nvidia.com/gpu.present: "true"` and workloads request GPUs with `resources.limits["nvidia.com/gpu"]`
- `slice_count` of `4` means each physical GPU appears as 4 schedulable GPUs. Higher values allow more workloads per GPU at the cost of per-workload performance
- **EKS:** the AL2023 and Bottlerocket NVIDIA AMIs already ship the driver and container toolkit. Set `install_driver`, `install_toolkit` and `k3s` to `false`; the plugin then creates the `nvidia` RuntimeClass itself
- **HAMi:** see [Install with HAMI](#install-with-hami)
- **Karpenter with HAMi:** Karpenter does not know HAMi's slice resources (`nvidia.com/gpumem`, `nvidia.com/gpucores`), so a sliced workload cannot scale a GPU node pool from zero. Keep one GPU node warm, or declare the resources with a NodeOverlay
- **Prometheus:** when the `kube-prometheus-stack` plugin is installed, a ServiceMonitor for the DCGM exporter is created automatically, so GPU metrics land in Prometheus
- **AMD GPU Operator:** both plugins can install NFD, and a cluster should have only one. Keep `install_nfd` on in one plugin and off in the other. The plugin that installs NFD must be uninstalled last; removing it takes the NFD CRDs and node labels with it
- **NFD naming:** NFD resources are named `<release>-nfd-*`. Installs from before this change rename them on the next sync (brief NFD restart, GPU workloads unaffected)
