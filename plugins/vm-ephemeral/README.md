# Generic Ephemeral VM

<img src="https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/vm-ephemeral/scripts/assets/logo.png" alt="Generic Ephemeral VM" width="80" />

**Category:** Virtual Machine
**Type:** Workload Template
**Tags:** `virtualization` · `virtual-machine` · `kubevirt`
**Bundle:** KubeVirt Bundle

> **Alpha:** This plugin is currently in Alpha. Use at your own risk.

---

## Overview

The Generic Ephemeral VM workload template provides a flexible, temporary Virtual Machine environment powered by KubeVirt. Designed for short-term use cases where persistent storage is not required, ephemeral VMs are ideal for testing, development, software evaluation, or any workload where data does not need to survive between sessions. VMs are configurable with hardware options including GPU passthrough, Secure Boot, EFI, TPM, and port exposure, and are provisioned on demand through Hubble.

---

## How It Works

**Workload Template** — Installs the Generic Ephemeral VM workload schema into Genesis. Once installed, the VM type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision virtual machines on demand within a project through **Hubble**. VMs are ephemeral — discarded when stopped unless external storage is attached.

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

Once installed, the Generic Ephemeral VM schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision VMs on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a VM through **Hubble**:

| Field | Details |
|-------|---------|
| `gpu` | **boolean** · Required · Default: `false`<br>Enable GPU passthrough to the VM |
| `gpu_device_name` | **string** · Optional<br>Specific GPU device name for passthrough (when multiple GPU types are available) |
| `secure_boot` | **boolean** · Required · Default: `false`<br>Enable Secure Boot for the VM |
| `efi` | **boolean** · Required · Default: `false`<br>Enable EFI firmware (required for Secure Boot) |
| `tpm` | **boolean** · Required · Default: `false`<br>Enable TPM 2.0 (required for Windows 11) |
| `virtio_drivers` | **boolean** · Optional · Default: `false`<br>Mount VirtIO drivers ISO to the VM (useful for Windows guest driver installation) |
| `prefered_disk_bus` | **select** · Required · Default: `virtio`<br>Preferred disk bus type (`virtio`) |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the VM's boot disk |
| `ports` | **list** · Optional<br>Ports to expose from the VM (name, type: `ClusterIP` or `NodePort`) |

---

## Notes

- This plugin is included in the **KubeVirt Bundle** — you can install KubeVirt and the Generic Ephemeral VM workload template together in one step from Terra
- VMs are **ephemeral** — data written inside the VM does not persist after the workload is stopped unless you attach external storage
- Windows 11 requires `tpm: true` and `efi: true` (and `secure_boot: true` is recommended)
- GPU passthrough gives the VM exclusive access to the GPU while it's running — other workloads will not be able to use that GPU simultaneously
- This plugin is in **Alpha** — behaviour may change and stability is not guaranteed in production environments
