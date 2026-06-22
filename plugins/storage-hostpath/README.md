# Storage HostPath

![Storage HostPath](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/storage-hostpath/scripts/assets/logo.png)

**Category:** Storage
**Type:** Cluster-Level Plugin
**Tags:** `storage` · `hostpath` · `persistent-volume`

---

## Overview

The Storage HostPath plugin mounts an existing directory from a cluster node's filesystem as a Kubernetes Persistent Volume. This enables workloads to access directories that already exist on the host node — useful for integrating legacy tools managed by Ansible, exposing pre-existing datasets, or reusing directories that are already populated via NFS mounts or local disk on the node.

> **Security Warning:** HostPath volumes give Pods direct access to the host node's filesystem. This can pose security risks if Pods are permitted to write to sensitive directories. Restrict access appropriately and ensure only trusted workloads can request HostPath-backed volumes.

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. This plugin creates a cluster-scoped Persistent Volume that can be claimed by workloads in any project namespace.

---

## Prerequisites

- The specified host path must exist on **all** nodes that may schedule the workload using this volume (HostPath volumes are node-local and not replicated)
- Appropriate file permissions on the host path for the user(s) running the workloads

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Storage HostPath"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `path` | string | **Yes** | — | Absolute path on the host node to expose as a Persistent Volume (e.g. `/data/shared`) |
| `size` | string | **Yes** | `10Gi` | Advertised size of the Persistent Volume. This is for scheduling purposes only and does not limit actual disk usage. |

---

## Notes

- HostPath volumes are **node-local** — if a workload is rescheduled to a different node, it will not have access to the same data unless the path exists and is populated on that node as well
- The `size` field is for Kubernetes scheduling metadata only; the actual available space depends on the host node's disk capacity
- For production multi-node environments, consider using **Storage NFS** or **Storage iSCSI** instead, which provide storage accessible from any node
