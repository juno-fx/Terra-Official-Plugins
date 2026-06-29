# Storage iSCSI

![Storage iSCSI](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/storage-iscsi/scripts/assets/logo.png)

**Category:** Storage
**Type:** Cluster Service
**Tags:** `storage` · `iscsi` · `persistent-volume`

---

## Overview

The Storage iSCSI plugin connects an iSCSI target (from a SAN, NAS, or software iSCSI server) and exposes it as a Kubernetes Persistent Volume in your cluster. This enables workloads to mount high-performance block storage from existing enterprise storage infrastructure directly into Kubernetes Pods — without additional storage drivers or provisioners.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Creates a shared storage volume backed by an iSCSI target, available to workloads across all projects.

---

## Prerequisites

- An accessible iSCSI target with a known IQN (iSCSI Qualified Name) and portal address
- Cluster nodes must have the `open-iscsi` package installed and `iscsid` service running for iSCSI connectivity
- Network connectivity from cluster nodes to the iSCSI portal address

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Storage iSCSI"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `iqn` | **string** · Required<br>iSCSI Qualified Name of the target (e.g. `iqn.2023-01.com.example:storage`) |
| `lun` | **int** · Required · Default: `0`<br>Logical Unit Number (LUN) of the iSCSI target |
| `portal` | **string** · Required<br>IP address or hostname of the iSCSI target portal (e.g. `192.168.1.100`) |
| `size` | **string** · Required<br>Advertised size of the Persistent Volume (e.g. `100Gi`). Must match the actual LUN size for accurate scheduling. |

---

## Notes

- iSCSI volumes are block-level storage; the volume must be formatted with a filesystem before a workload can write to it (Kubernetes will do this automatically on first mount if `fsType` is configured)
- Only one Pod can mount an iSCSI volume in ReadWriteOnce mode at a time; multiple Pods cannot share an iSCSI LUN simultaneously
- The `portal` field should be the iSCSI target's IP address, not a hostname, for reliable connectivity in environments without stable DNS for storage networks
- For multi-path iSCSI configurations, additional cluster-level setup is required beyond what this plugin provides
