# Storage NFS

<img src="https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/storage-nfs/scripts/assets/logo.png" alt="Storage NFS" width="80" />

**Category:** Storage
**Type:** Cluster Service
**Tags:** `storage` · `nfs` · `persistent-volume`

---

## Overview

The Storage NFS plugin mounts an NFS (Network File System) share and exposes it as a Kubernetes Persistent Volume. NFS is the most common shared storage solution for on-premise Kubernetes clusters — it allows multiple Pods across different nodes to mount the same volume simultaneously, enabling shared workspaces for collaborative workstations and shared asset libraries.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Creates a shared storage volume backed by an NFS share, mountable by multiple workstations across all projects simultaneously.

---

## Prerequisites

- An NFS server with a configured export accessible from all cluster nodes
- Cluster nodes must have the NFS client utilities installed (`nfs-common` on Debian/Ubuntu, `nfs-utils` on RHEL/CentOS)
- Network connectivity from all cluster nodes to the NFS server

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Storage NFS"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `server` | **string** · Required<br>IP address or hostname of the NFS server (e.g. `192.168.1.50` or `nas.example.com`) |
| `path` | **string** · Required<br>Exported path on the NFS server (e.g. `/exports/shared`) |
| `size` | **string** · Required<br>Advertised size of the Persistent Volume (e.g. `500Gi`). For scheduling purposes — actual capacity depends on the NFS export. |

---

## Notes

- NFS volumes support `ReadWriteMany` access mode — multiple workstations can mount and use the volume simultaneously, making it ideal for shared project storage
- The NFS export on the server must be configured with appropriate permissions for the UIDs/GIDs used by Juno workstation containers
- For high-throughput workloads (e.g. large file rendering), ensure the NFS server and network can handle the required bandwidth
- Multiple Storage NFS plugin instances can be installed in the same cluster to expose different NFS shares as separate Persistent Volumes
