# HAMi GPU Sharing

![HAMi](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/hami/assets/hami-graph-color.svg)

**Category:** Hardware
**Type:** Cluster Service
**Tags:** `gpu` · `hami` · `gpu-sharing`

---

## Overview

HAMi (Heterogeneous AI Computing Virtualization Middleware) slices physical GPUs into fractional vGPUs with hard memory and compute core isolation — multiple workloads can share a single GPU with deterministic guarantees, without modifying application code. It installs alongside the NVIDIA GPU Operator: GPU Operator manages drivers and the container runtime; HAMi manages GPU sharing and scheduling on top.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, GPU nodes are configured for fractional GPU allocation and any workload in the cluster can request shared GPU resources — no per-project setup needed.

---

## Prerequisites

- **GPU Operator installed** — HAMi replaces the GPU Operator's device plugin and scheduler; GPU Operator still manages drivers, nvidia-container-toolkit, NFD, and DCGM
- **GPU nodes labeled** — Nodes must have the label `nvidia.com/gpu.present: "true"` (automatically applied by GPU Operator's NFD component when a GPU is detected)
- Kubernetes 1.18+ (upstream HAMi requirement)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"HAMi GPU Sharing"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **select** · Required · Default: `v2.9.0`<br>Upstream HAMi release tag |
| `helm_repo` | **string** · Optional · Default: `https://project-hami.github.io/HAMi/`<br>Helm repository URL |
| `scheduler_node_policy` | **select** · Optional · Default: `binpack`<br>Node-level scheduling — binpack packs on fewer nodes; spread distributes across nodes |
| `scheduler_gpu_policy` | **select** · Optional · Default: `spread`<br>GPU-level scheduling — binpack packs on fewer GPUs; spread distributes |
| `device_split_count` | **int** · Optional · Default: `10`<br>Max concurrent workloads per physical GPU |
| `device_memory_scaling` | **string** · Optional · Default: `1`<br>GPU memory overcommit ratio. `1` = 1:1 no overcommit. `>1` allows virtual memory beyond physical capacity |
| `device_core_scaling` | **string** · Optional · Default: `1`<br>GPU compute core overcommit ratio. `1` = 1:1 no overcommit |
| `enable_monitoring` | **boolean** · Optional · Default: `false`<br>Enable Prometheus metrics endpoint (scheduler port 9393, device plugin port 9394) |

---

## Resource Naming

HAMi uses `hami.io/` resource names to avoid conflicts with GPU Operator's `nvidia.com/` resources. This gives you two independent GPU paths:

| Resource | Source | Meaning |
|----------|--------|---------|
| `nvidia.com/gpu` | GPU Operator | Whole GPU — standard allocation, no sharing |
| `hami.io/gpu` | HAMi | Fractional GPU — sliced with memory/core isolation |
| `hami.io/gpu-memory` | HAMi | Requested GPU memory (MiB) |
| `hami.io/gpu-cores` | HAMi | Requested GPU compute percentage (0–100) |
| `hami.io/gpu-memory-percentage` | HAMi | Request GPU memory as a % of total GPU memory |

### Workload Examples

```yaml
# Whole GPU via GPU Operator (no sharing)
apiVersion: v1
kind: Pod
metadata:
  name: full-gpu-pod
spec:
  containers:
    - name: app
      image: your-image
      resources:
        limits:
          nvidia.com/gpu: 1
```

```yaml
# Shared GPU via HAMi (fractional allocation)
apiVersion: v1
kind: Pod
metadata:
  name: shared-gpu-pod
spec:
  schedulerName: hami-scheduler  # required for HAMi scheduling
  containers:
    - name: app
      image: your-image
      resources:
        limits:
          hami.io/gpu: 1
          hami.io/gpu-memory: 3000          # 3 GB of GPU memory
          # hami.io/gpu-cores: 50            # 50% of GPU compute cores (optional)
          # hami.io/gpu-memory-percentage: 25  # or request by percentage
```

> **Note:** Workloads using `hami.io/` resources must set `schedulerName: hami-scheduler` in their pod spec. The GPU Operator path (`nvidia.com/gpu`) continues to work unchanged.

---

## Notes

- HAMi works alongside the GPU Operator — install GPU Operator first, then HAMi. GPU Operator handles drivers, the container runtime, NFD, and monitoring; HAMi provides GPU sharing and isolation
- The `hami.io/` prefix avoids resource name conflicts between the two device plugins
- `device_split_count` caps how many pods can share one GPU. Higher values = more sharing, but more fragmentation risk
- Memory or core overcommit (`>1`) allocates more virtual GPU capacity than physically available. Hard isolation is enforced at the device level; resource contention occurs only if all consumers request their full share simultaneously
- Prometheus metrics at ports 9393 (scheduler) and 9394 (device plugin) require a Prometheus scrape target to collect
- Additional GPU vendor support (Ascend, Cambricon, Hygon, Iluvatar, Moore Threads, MetaX, Enflame, Kunlunxin, AWS Neuron, Biren) is available but not exposed in the Terra UI. To enable, add vendor flags via Helm values override (e.g. `devices.ascend.enabled: true`). See the [HAMi upstream documentation](https://project-hami.io/docs) for per-vendor requirements
