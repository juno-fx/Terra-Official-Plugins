# Longhorn Storage

![Longhorn](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/longhorn/assets/logo.png)

**Category:** Storage
**Type:** Cluster Service
**Tags:** `storage` · `longhorn` · `dashboard`

---

## Overview

Longhorn is a cloud-native distributed block storage system for Kubernetes that provides highly available persistent volumes for your cluster workloads. It offers automatic replication across nodes, scheduled snapshots, backup and restore to S3-compatible storage, and a built-in web dashboard for storage management. Longhorn is designed to be simple to operate and is a popular choice for on-premise and bare-metal Kubernetes clusters that need reliable, replicated storage without a cloud provider.

> **Version Note:** Versions above `v1.10.x` are not supported due to an upstream [CNI compatibility issue with k3s](https://github.com/longhorn/longhorn/issues/12642).

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, Longhorn provides replicated block storage to the whole cluster. Projects can use Longhorn-backed volumes without any per-project setup.

---

## Prerequisites

- All cluster nodes must have `open-iscsi` installed and the `iscsid` service running (required by Longhorn for volume attachment)
- Sufficient disk capacity on cluster nodes at the configured `storage_path`
- A DNS record pointing to your cluster's ingress for the Longhorn dashboard host
- An nginx ingress controller in the cluster

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Longhorn Storage"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `storage_path` | **string** · Required · Default: `/var/lib/longhorn`<br>Path on host nodes where Longhorn stores volume data |
| `default_replica_count` | **int** · Required · Default: `3`<br>Number of replicas for each volume. Higher = more redundancy but more storage used. |
| `fs` | **string** · Required · Default: `ext4`<br>Default filesystem type for new volumes (`ext4`, `xfs`, or `btrfs`) |
| `release` | **select** · Required · Default: `v1.10.x`<br>Longhorn version to install |
| `host` | **string** · Required<br>Hostname for the Longhorn management dashboard |
| `prefix` | **string** · Optional · Default: `/longhorn`<br>URL sub-path for the Longhorn dashboard |

---

## Notes

- The `storage_path` must exist on **all** nodes that will store Longhorn volumes — Longhorn will create volume subdirectories within this path
- A `default_replica_count` of `3` requires at least 3 nodes; reduce this for single-node or two-node clusters
- Longhorn creates a `longhorn` StorageClass that can be used when creating persistent volumes for workloads
- The Longhorn dashboard provides volume management, snapshot scheduling, and backup configuration
