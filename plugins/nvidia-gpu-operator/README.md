# NVIDIA GPU Operator

![NVIDIA GPU Operator](https://www.nvidia.com/content/nvidiaGDC/us/en_US/about-nvidia/legal-info/logo-brand-usage/_jcr_content/root/responsivegrid/nv_container_392921705/nv_container/nv_image.coreimg.100.410.png/1703060329053/nvidia-logo-vert.png)

**Category:** Hardware
**Type:** Cluster-Level Plugin
**Tags:** `gpu` · `nvidia` · `time-slicing` · `vm-passthrough` · `operator`
**Editable:** Yes

---

## Overview

The NVIDIA GPU Operator automates the management of NVIDIA GPU resources in a Kubernetes cluster. It installs and configures all necessary software components — GPU drivers, container runtime (nvidia-container-toolkit), device plugin, and monitoring exporters — so that GPU-accelerated workloads can be scheduled on GPU nodes without manual configuration. It also configures time-slicing, which allows multiple containers to share a single GPU.

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. The GPU Operator manages GPU hardware across all cluster nodes via DaemonSets and cluster-scoped CRDs.

---

## Prerequisites

- At least one cluster node with an NVIDIA GPU (Pascal architecture or newer recommended)
- Nodes must be running a supported Linux kernel
- For k3s clusters: the plugin must be configured with `k3s: true` (see configuration below)
- For open kernel modules: the `open_kernel_modules` flag should match your driver installation type

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

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | select | **Yes** | — | GPU Operator version to install (`v25.10.1` or `v25.3.4`) |
| `install_crds` | boolean | No | `false` | Install the GPU Operator CRDs. Set to `true` on first install; `false` for subsequent installs to avoid CRD conflicts. |
| `open_kernel_modules` | boolean | No | `false` | Use open kernel modules for the NVIDIA driver (required for open-source kernel module installations) |
| `k3s` | boolean | No | `true` | Configure for k3s clusters (sets containerd socket path to `/run/k3s/containerd/containerd.sock`) |
| `slice_count` | int | **Yes** | `4` | Number of time-slices per GPU. Each GPU is divided into this many virtual GPU slices. |
| `helm_repo` | string | **Yes** | `https://helm.ngc.nvidia.com/nvidia` | Helm repository URL for the GPU Operator chart |

---

## Notes

- This plugin is **editable** — you can update slice count, version, and flags after install via Terra
- `install_crds` should be `true` on the **first installation only**. If you are reinstalling or running multiple GPU Operator instances, set it to `false` to avoid CRD conflicts
- `slice_count` controls GPU time-slicing — a value of `4` means each physical GPU appears as 4 schedulable GPU resources. Higher values allow more concurrent workloads per GPU at the cost of per-workload performance
- After installation, GPU nodes will be labelled `nvidia.com/gpu.present: "true"` and workloads can request GPUs with `resources.limits["nvidia.com/gpu"]`
