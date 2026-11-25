# AMD GPU Operator

![AMD GPU Operator](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/amd-gpu-operator/assets/logo.png)

**Category:** Hardware
**Type:** Cluster Service
**Tags:** `gpu` · `amd` · `operator`
**Editable:** Yes

---

## Overview

The AMD GPU Operator automates the management of AMD Instinct and Radeon GPUs in a Kubernetes cluster. It finds the nodes that carry an AMD GPU, runs the device plugin that makes those GPUs schedulable as `amd.com/gpu`, labels nodes with their GPU properties, and exports GPU metrics.

This plugin installs the upstream [ROCm/gpu-operator](https://github.com/ROCm/gpu-operator) Helm chart into the `kube-amd-gpu` namespace.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, AMD GPU nodes are detected and configured automatically and `amd.com/gpu` becomes a schedulable resource for any workload in the cluster — no per-workspace setup needed.

---

## Prerequisites

- At least one cluster node with an AMD GPU
- Kubernetes 1.29 or newer
- GPU nodes must already have a working `amdgpu` kernel driver — this plugin does not install one
- If the NVIDIA GPU Operator plugin (or anything else) already installs Node Feature Discovery (NFD), set `install_nfd` to `false`; the cluster should have one NFD install
- **NFD is owned by whichever plugin installs it.** Turning that plugin's `install_nfd` off later, or uninstalling the plugin, removes NFD, its CRDs and the GPU node labels, which breaks every other operator that relies on them (NVIDIA GPU Operator, HAMi). Decide which plugin owns NFD before installing, leave its `install_nfd` alone afterwards, and uninstall it last

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"AMD GPU Operator"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **string** · Required · Default: `v1.5.1`<br>AMD GPU Operator chart version to install. Built and tested with `v1.5.1`. Older versions lack settings the plugin relies on (`kmm.watch`, `devicePlugin.enableDevicePlugin`) and will not install; newer versions may carry breaking changes, so check the release notes first |
| `helm_repo` | **string** · Required · Default: `https://rocm.github.io/gpu-operator`<br>Helm repository URL for the AMD GPU Operator chart |
| `install_nfd` | **boolean** · Optional · Default: `true`<br>Install Node Feature Discovery (NFD), which labels the GPU nodes for the operator. Only one NFD install per cluster: if the NVIDIA GPU Operator plugin (or anything else) already installs NFD, turn this off, or the two collide over the shared NFD CRDs. |
| `detect_all_gpus` | **boolean** · Optional · Default: `true`<br>Which nodes count as AMD GPU nodes. `true` labels any node with an AMD GPU, integrated GPUs and unlisted cards included (e.g. Ryzen AI / Strix Halo). `false` labels only AMD's supported list (Instinct, Radeon Pro, selected Radeon RX). Labelling alone does not make GPUs schedulable. |
| `vgpu_nodes` | **boolean** · Optional · Default: `false`<br>Target nodes labelled `amd-vgpu` instead of `amd-gpu`. Use when the nodes are virtual machines that see an AMD GPU virtual function. |
| `device_plugin` | **boolean** · Optional · Default: `true`<br>Make the GPUs on labelled nodes schedulable as `amd.com/gpu`. Turn off to hand that job to a third-party installed GPU scheduler like HAMi, which brings its own device plugin. Node labelling and the metrics exporter keep running. |

---

## Requesting a GPU

Workloads request a whole GPU with `resources.limits["amd.com/gpu"]`. One workload holds the GPU for as long as it runs; the operator has no sharing or time-slicing setting. For sharing, see [Install with HAMi](#install-with-hami).

```yaml
resources:
  limits:
    amd.com/gpu: "1"
```

In the catalog, the **Jupyter Notebook** workload template renders this limit when its `gpu` field is set to `amd`.

---

## Install with HAMi

The HAMi GPU Sharing plugin runs on top of this plugin when its `enable_amd` field is on. The AMD GPU Operator keeps providing node labels and GPU metrics. HAMi replaces only the device plugin, so it can hand out slices of a GPU with a memory and compute limit (`amd.com/gpumem`, `amd.com/gpucores`) instead of whole GPUs.

### Field values

| Field | Value | Why |
|-------|-------|-----|
| `device_plugin` | `false` | HAMi brings its own AMD device plugin. Two on one node fight over `amd.com/gpu`. |
| `detect_all_gpus` | `true` | HAMi installs its device plugin on nodes carrying the operator's `amd-gpu` label; this labels every AMD GPU node, APUs included. |
| `install_nfd` | as installed | Unchanged by HAMi. Keep whichever plugin already provides NFD. |

Leave the other fields at their defaults.

### Steps

1. Install the **NVIDIA GPU Operator** and **HAMi** plugins first if the cluster also has NVIDIA GPUs; HAMi's NVIDIA side is its base install
2. Install this plugin with the values above. On an existing install, edit it and set `device_plugin` to `false`
3. Wait until the operator's device-plugin DaemonSet pods are gone from `kube-amd-gpu`
4. In the **HAMi** plugin, set `enable_amd` to `true`

To go back, set `enable_amd` to `false` in HAMi first, then set `device_plugin` to `true` here.

---

## Notes

- This plugin is **editable** — you can change the version and node targeting after install via Terra
- Workload templates whose `gpu` field is a plain toggle request `nvidia.com/gpu` and do not attach an AMD GPU; only templates whose `gpu` field offers an `amd` option (Jupyter Notebook) render `amd.com/gpu`
- GPU nodes are labelled `feature.node.kubernetes.io/amd-gpu: "true"` (or `amd-vgpu` with `vgpu_nodes` on) automatically. With `detect_all_gpus: true` that covers any AMD GPU; with `false` only the GPUs on AMD's supported list are labelled, and other nodes need `kubectl label node <node> feature.node.kubernetes.io/amd-gpu=true`
- GPUs outside AMD's supported list are detected and scheduled on a best-effort basis — the device plugin works with any GPU driven by `amdgpu`, but the metrics exporter is built for Instinct and may not report on them
- If operator pods on a GPU node stay in `Init:0/1`, the node has no `amdgpu` driver loaded — install one on the node
- **NVIDIA GPU Operator:** both plugins can install NFD, and a cluster should have only one. Keep `install_nfd` on in one plugin and off in the other. The plugin that installs NFD must be uninstalled last; removing it takes the NFD CRDs and node labels with it. If you add the NVIDIA GPU Operator later, keep `install_nfd` on here and turn its `install_nfd` off. With `install_nfd` off here, the plugin adds its AMD detection rule to the existing NFD as a `NodeFeatureRule`
- The operator's `default` DeviceConfig is owned by this plugin. Manual edits to it are reverted on the next sync — change the fields above instead
- **Prometheus:** when the `kube-prometheus-stack` plugin is installed, a ServiceMonitor for the device metrics exporter is created automatically, so GPU metrics land in Prometheus. The exporter serves `/metrics` on port `5000` either way
- **HAMi:** see [Install with HAMi](#install-with-hami)
- **Karpenter with HAMi:** Karpenter does not know HAMi's slice resources (`amd.com/gpumem`, `amd.com/gpucores`), so a sliced workload cannot scale a GPU node pool from zero. Keep one GPU node warm, or declare the resources with a NodeOverlay
- Auto node remediation is disabled: it installs an Argo Workflows controller and CRDs that conflict with an existing Argo Workflows install
- The device plugin, node labeller and metrics exporter images use the upstream chart's `latest` tags
