# GPU Resource Claim

![GPU Resource Claim](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/gpu-resource-claim/assets/logo.png)

**Category:** Hardware
**Type:** Workspace Resource
**Tags:** `gpu` · `dra` · `amd` · `nvidia`
**Editable:** No

---

## Overview

Creates a Kubernetes `ResourceClaim` for a GPU in the workspace namespace, using Dynamic Resource Allocation (DRA). A claim is a named handle on a GPU: every workload in the workspace that references the claim is scheduled onto the same GPU. This is how one GPU is shared between several workloads on a DRA-based GPU operator, which has no time-slicing setting.

The install name becomes the claim name. Install the plugin several times for several claims — each install is independent.

---

## How It Works

**Workspace Resource** — When added to a workspace, Terra creates a `ResourceClaim` named after the install in the workspace namespace. The first pod that references the claim makes the scheduler pick a concrete GPU matching the claim's device class and selectors; the claim stays bound to that GPU and every further pod referencing it lands there too. Pods that reference different claims get different GPUs (or wait until one is free).

A workload references the claim by name:

```yaml
spec:
  resourceClaims:
    - name: gpu
      resourceClaimName: <install-name>
  containers:
    - name: app
      resources:
        claims:
          - name: gpu
```

Workload templates that support DRA expose this as a field that takes the install name.

---

## Prerequisites

- Kubernetes 1.34 or newer (`resource.k8s.io/v1`)
- A GPU operator running its DRA driver for the chosen vendor:
  - AMD: the **AMD GPU Operator** plugin with `use_dra` enabled
  - NVIDIA: the NVIDIA DRA driver (`gpu.nvidia.com` device class)
- At least one GPU published as a `ResourceSlice` — check with `kubectl get resourceslices`

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"GPU Resource Claim"**
3. Click **Install**
4. Pick an install name — this becomes the claim name workloads reference
5. Fill in the configuration fields below
6. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `vendor` | **select** · Required · Default: `amd`<br>GPU vendor; selects the DRA device class (`gpu.amd.com` or `gpu.nvidia.com`). The matching operator must run its DRA driver. |
| `gpu_count` | **int** · Required · Default: `1`<br>Number of GPUs allocated to the claim. Pods referencing it see all of them. |
| `min_memory` | **string** · Optional<br>Only allocate GPUs with at least this much memory, e.g. `8Gi`. Skips integrated GPUs on nodes that also carry a discrete card. |
| `cel_selector` | **string** · Optional<br>Extra CEL expression evaluated per device, e.g. `device.attributes["gpu.amd.com"].deviceID == "0x747e"`. ANDed with `min_memory`. Attribute names come from `kubectl get resourceslices -o yaml`. |

---

## Notes

- Sharing a claim gives every referencing pod the whole GPU at once. There is no memory or compute isolation between them — one pod can exhaust GPU memory for the others
- A claim is bound to a GPU while at least one pod references it and released when the last one goes away; the next pod may land on a different GPU
- Kubernetes allows at most 256 pods on one claim
- The claim spec cannot be changed after creation, so this plugin is not editable. To change vendor, count or selectors, uninstall and install again under the same name
- Uninstalling while pods still reference the claim leaves it `Terminating` until those pods are gone
- With `min_memory` the capacity key is `device.capacity["<device class>"].memory`; both the AMD and NVIDIA DRA drivers publish GPU memory under that name
