# Generic Ephemeral VM

![Generic Ephemeral VM](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/vm-ephemeral/scripts/assets/logo.png)

**Category:** Virtual Machine
**Type:** Workload Template
**Tags:** `virtualization` · `virtual-machine` · `kubevirt`

> **Alpha:** This plugin is currently in Alpha. Use at your own risk.

---

## Overview

The Generic Ephemeral VM workload template provides a flexible, temporary Virtual Machine environment powered by KubeVirt. Designed for short-term use cases where persistent storage is not required, ephemeral VMs are ideal for testing, development, software evaluation, or any workload where data does not need to survive between sessions. Users can launch VMs directly from the Genesis workload UI with configurable hardware options including GPU passthrough, Secure Boot, EFI, TPM, and port exposure.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the Generic Ephemeral VM workload type in the workload creation UI. Individual VM instances are launched by Kuiper when users create workloads.

---

## Prerequisites

- **KubeVirt** plugin installed and configured in the cluster
- At least one cluster node with kernel-level virtualization support (`/dev/kvm` accessible)
- For GPU passthrough: compatible NVIDIA GPU and the **NVIDIA GPU Operator** plugin
- For Windows 11: TPM 2.0 and Secure Boot must both be enabled in the workload configuration
- A Kubernetes storage class available for VM disk storage

---

## Installation

1. Install the **KubeVirt** plugin first
2. Open **Terra** and navigate to the **Plugin Marketplace**
3. Search for **"Generic Ephemeral VM"**
4. Click **Install**
5. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Generic Ephemeral VM workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a VM workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `gpu` | boolean | **Yes** | `false` | Enable GPU passthrough to the VM |
| `gpu_device_name` | string | No | — | Specific GPU device name for passthrough (when multiple GPU types are available) |
| `secure_boot` | boolean | **Yes** | `false` | Enable Secure Boot for the VM |
| `efi` | boolean | **Yes** | `false` | Enable EFI firmware (required for Secure Boot) |
| `tpm` | boolean | **Yes** | `false` | Enable TPM 2.0 (required for Windows 11) |
| `virtio_drivers` | boolean | No | `false` | Mount VirtIO drivers ISO to the VM (useful for Windows guest driver installation) |
| `prefered_disk_bus` | select | **Yes** | `virtio` | Preferred disk bus type (`virtio`) |
| `storage_class` | k8sStorageClass | **Yes** | — | Storage class for the VM's boot disk |
| `ports` | list | No | — | Ports to expose from the VM (name, type: `ClusterIP` or `NodePort`) |

---

## Notes

- VMs are **ephemeral** — data written inside the VM does not persist after the workload is stopped unless you attach external storage
- Windows 11 requires `tpm: true` and `efi: true` (and `secure_boot: true` is recommended)
- GPU passthrough gives the VM exclusive access to the GPU while it's running — other workloads will not be able to use that GPU simultaneously
- This plugin is in **Alpha** — behaviour may change and stability is not guaranteed in production environments
