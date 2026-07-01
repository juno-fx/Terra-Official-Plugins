# Karpenter NodePool

![Karpenter NodePool](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/karpenter-nodepool/assets/logo.png?raw=true)

**Category:** Compute
**Type:** Cluster Service
**Tags:** `karpenter` · `autoscaling` · `ec2` · `nodepool` · `aws` · `cluster-level`

---

## Overview

The Karpenter NodePool plugin configures a single Karpenter NodePool — the scaling policy that controls which EC2 instance types Karpenter provisions, under what constraints, and for which workloads. Each installation creates one NodePool. Install multiple times to create multiple pools (service, workstation, GPU, etc.), each independently configured and named by its install name.

Requires `karpenter-nodeclass` (or an equivalent EC2NodeClass) to already be installed in the cluster.

---

## How It Works

**Cluster Service** — Each install creates one `NodePool` resource in the cluster. The install name becomes the NodePool resource name. The `pool_type` field controls which node label and CPU architecture are applied to provisioned nodes — this is how workloads target the correct pool.

| Pool Type | Node Label | Architecture |
|---|---|---|
| `service` | `juno-innovations.com/service=true` | amd64 |
| `workstation-cpu` | `juno-innovations.com/workstation=true` | amd64 |
| `workstation-arm64` | `juno-innovations.com/workstation=true` | arm64 |
| `workstation-gpu` | `juno-innovations.com/workstation=true` | amd64 |

---

## Prerequisites

- EKS cluster with Karpenter installed
- `karpenter-nodeclass` plugin installed (or an EC2NodeClass already present in the cluster)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Karpenter NodePool"**
3. Click **Install**
4. Choose an install name — this becomes the NodePool resource name (e.g. `service`, `arm64-workstations`, `gpu`)
5. Fill in the configuration fields below
6. Click **Confirm** to deploy

Repeat for each additional NodePool your cluster needs.

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `nodeclass_ref` | **string** · Required<br>Name of the EC2NodeClass to use. Must match the install name of your `karpenter-nodeclass` plugin install. |
| `pool_type` | **select** · Required<br>Type of NodePool. Controls the node label and CPU architecture. Options: `service`, `workstation-cpu`, `workstation-arm64`, `workstation-gpu`. |
| `availability_zone` | **string** · Required<br>Availability zone for provisioned nodes (e.g. `us-east-1a`). |
| `capacity_type` | **select** · Required · Default: `spot`<br>EC2 capacity type. `spot` for cost savings, `on-demand` for guaranteed availability. GPU pools typically use `on-demand`. |
| `instance_categories` | **string** · Required · Default: `c,t,r`<br>Comma-separated Karpenter instance category letters. `c`=compute, `m`=general, `r`=memory, `t`=burstable, `g`=GPU, `p`=GPU-optimized. |
| `instance_types` | **string** · Required · Default: `c5.xlarge,c5a.xlarge,c5ad.xlarge,c6a.xlarge,c7i-flex.xlarge`<br>Comma-separated EC2 instance types Karpenter may provision. Use ARM64 instance types (e.g. `c6g.xlarge`) for `workstation-arm64` pools. |
| `cpu_limit` | **string** · Required · Default: `16`<br>Maximum total CPU cores this pool may provision across all nodes. |
| `memory_limit` | **string** · Required · Default: `32Gi`<br>Maximum total memory this pool may provision across all nodes. |
| `weight` | **int** · Optional<br>NodePool scheduling weight (1–100). Higher weight = higher priority when Karpenter selects between pools. Leave empty for Karpenter default (0). |
| `min_cpu` | **string** · Optional<br>Minimum vCPUs for candidate instance types. Leave empty to allow any size. |

---

## Notes

- Install once per logical pool — most clusters need at minimum a `service` pool (for ingress-nginx) and one or more workstation pools
- Use `weight` to express pool preference: e.g. set GPU pool weight lower than CPU pools so Karpenter exhausts cheaper options first
- `instance_categories` and `instance_types` work together — Karpenter must satisfy both constraints when selecting an instance
- For ARM64 pools, ensure `instance_types` contains only ARM64 instance families (e.g. `c6g`, `c7g`, `m6g`, `r6g`)
- For GPU pools, on-demand capacity is recommended — spot GPU interruptions can disrupt long-running training jobs
