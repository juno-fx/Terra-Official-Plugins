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

**Cluster Service** — Installed once per cluster by an administrator. Once active, AMD GPU nodes are detected and configured automatically and `amd.com/gpu` becomes a schedulable resource for any workload in the cluster — no per-project setup needed.

---

## Prerequisites

- At least one cluster node with an AMD GPU
- Kubernetes 1.29 or newer
- GPU nodes must already have a working `amdgpu` kernel driver — this plugin does not install one

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
| `version` | **select** · Required · Default: `v1.5.1`<br>AMD GPU Operator version to install (`v1.5.1`, `v1.5.0` or `v1.4.1`) |
| `helm_repo` | **string** · Required · Default: `https://rocm.github.io/gpu-operator`<br>Helm repository URL for the AMD GPU Operator chart |
| `install_nfd` | **boolean** · Optional · Default: `true`<br>Install Node Feature Discovery with the operator. Set to `false` when NFD already runs in the cluster, e.g. alongside the NVIDIA GPU Operator. |
| `detect_all_gpus` | **boolean** · Optional · Default: `true`<br>Label every node that has an AMD GPU, including integrated GPUs and cards outside AMD's supported list (e.g. Ryzen AI / Strix Halo). Set to `false` to label only supported GPUs (Instinct, Radeon Pro, selected Radeon RX). |
| `vgpu_nodes` | **boolean** · Optional · Default: `false`<br>Target nodes labelled `amd-vgpu` instead of `amd-gpu`. Use when the nodes are virtual machines that see an AMD GPU virtual function. |
| `use_dra` | **boolean** · Optional · Default: `false`<br>Expose GPUs through the DRA driver instead of the device plugin, so several workloads can share one GPU. Requires operator `v1.5.0`+, Kubernetes 1.32+ and containerd 2.0+. |

---

## Sharing a GPU Between Workloads

The AMD operator has no time-slicing setting. To let several workloads use the same GPU, enable `use_dra`. The operator then runs the DRA driver instead of the device plugin: `amd.com/gpu` is no longer advertised and workloads request GPUs with a `ResourceClaim` of device class `gpu.amd.com`.

Every pod that references the same `ResourceClaim` gets the same GPU. There is no memory or compute isolation between them.

```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaim
metadata:
  name: shared-gpu
spec:
  devices:
    requests:
      - name: gpu
        exactly:
          deviceClassName: gpu.amd.com
          allocationMode: ExactCount
          count: 1
---
apiVersion: v1
kind: Pod
metadata:
  name: gpu-workload-1
spec:
  containers:
    - name: app
      image: docker.io/rocm/pytorch:latest
      command: ["sleep", "infinity"]
      resources:
        claims:
          - name: gpu
  resourceClaims:
    - name: gpu
      resourceClaimName: shared-gpu
```

Further pods share the GPU by using the same `resourceClaimName`. The claim and the pods must be in the same namespace. Check what the driver found with `kubectl get resourceslices`.

---

## Notes

- This plugin is **editable** — you can change the version and node targeting after install via Terra
- By default workloads request an AMD GPU with `resources.limits["amd.com/gpu"]`, one workload per GPU. The `gpu` toggle on the catalog's workload templates requests `nvidia.com/gpu` and does not attach an AMD GPU
- GPU nodes are labelled `feature.node.kubernetes.io/amd-gpu: "true"` (or `amd-vgpu` for virtual functions) automatically. With `detect_all_gpus: true` that covers any AMD GPU; with `false` only the GPUs on AMD's supported list are labelled, and other nodes need `kubectl label node <node> feature.node.kubernetes.io/amd-gpu=true`
- GPUs outside AMD's supported list are detected and scheduled on a best-effort basis — the device plugin works with any GPU driven by `amdgpu`, but the metrics exporter is built for Instinct and may not report on them
- If operator pods on a GPU node stay in `Init:0/1`, the node has no `amdgpu` driver loaded — install one on the node
- With `install_nfd: false` an NFD install must already exist in the cluster; the operator still adds its own rule for detecting AMD GPUs. With `install_nfd: true` next to another NFD install, both manage the same NFD CRDs, and uninstalling this plugin removes them
- The operator's `default` DeviceConfig is owned by this plugin. Manual edits to it are reverted on the next sync — change the fields above instead
- GPU metrics are exported in-cluster on port `5000` by the device metrics exporter
- Auto node remediation is disabled: it installs an Argo Workflows controller and CRDs that conflict with an existing Argo Workflows install
- The device plugin, node labeller and metrics exporter images use the upstream chart's `latest` tags
