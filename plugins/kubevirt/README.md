# KubeVirt

![KubeVirt](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/kubevirt/scripts/assets/logo.png)

**Category:** Virtualization
**Type:** Cluster Service
**Tags:** `kubevirt` · `kubernetes` · `virtualization` · `vm` · `virtual-machine`
**Editable:** Yes
**Bundle:** KubeVirt Bundle

> **Alpha:** KubeVirt support is currently in Alpha. Use at your own risk.

---

## Overview

KubeVirt extends Kubernetes to support running virtual machines (VMs) alongside containerized workloads. It addresses the needs of teams that have adopted Kubernetes but still have VM-based workloads that cannot be easily containerized. With KubeVirt, VMs and containers share the same scheduling, networking, and storage infrastructure — managed through the same Kubernetes APIs. The **Generic Ephemeral VM** and **Crossplane EC2** workload templates depend on KubeVirt being installed.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, the cluster gains the ability to run virtual machines alongside containers. Workload templates like **Generic Ephemeral VM** depend on KubeVirt being installed first.

---

## Prerequisites

- Kernel-level virtualization support on cluster nodes (`/dev/kvm` must be accessible on nodes that will run VMs)
- For nested virtualization (e.g. running VMs inside cloud VMs), the host hypervisor must support it
- Sufficient node resources — VMs typically require dedicated CPU and memory allocations

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"KubeVirt"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **select** · Required · Default: `v1.7.0`<br>KubeVirt version to install |
| `nested_virtualization` | **boolean** · Required · Default: `false`<br>Enable nested virtualization support (required when running VMs inside cloud VMs or hypervisors that support it) |

---

## Notes

- This plugin is included in the **KubeVirt Bundle** — you can install KubeVirt and the Generic Ephemeral VM workload template together in one step from Terra
- KubeVirt is **Alpha** in this plugin — production deployments should validate behaviour in a staging environment first
- This plugin is **editable** — you can update the version and nested virtualization setting after install via Terra
- Nested virtualization must be supported and enabled at the host hypervisor level; enabling this flag without host support will cause VMs to fail to start
- After installing KubeVirt, install the **Generic Ephemeral VM** workload template to begin launching VMs from Genesis
