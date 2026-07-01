# File Browser

![File Browser](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/filebrowser/scripts/assets/icon.png)

**Category:** Workstations
**Type:** Workload Template
**Tags:** `file-management` · `storage` · `web-interface`
**Compatibility:** `genesis-deployment>=3.0.2` · `orion-deployment>=3.1.0`

---

## Overview

File Browser is a lightweight, web-based file manager that runs entirely in a browser — no desktop environment required. It provides a clean interface for drag-and-drop upload, directory browsing, file editing, and file download. The File Browser workload can optionally mount project storage volumes and persist uploaded data across restarts.

---

## How It Works

**Workload Template** — Installs the File Browser workload schema into Genesis. Once installed, the File Browser type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own file manager on demand within a project through **Hubble**.

---

## Prerequisites

- A Kubernetes storage class available in the cluster (required when persistent storage is enabled)
- An nginx ingress controller in the cluster

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"File Browser"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the File Browser schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision file browser instances on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a File Browser instance through **Hubble**:

| Field | Details |
|-------|---------|
| `workspace` | **string** · Optional<br>Optional target workspace name. If set, the URL becomes `/filebrowser/<workspace>` instead of the workload name. |
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry to pull the File Browser image from |
| `repo` | **string** · Required · Default: `filebrowser/filebrowser`<br>File Browser image repository |
| `tag` | **string** · Required · Default: `latest`<br>File Browser image tag |
| `ingressNamespace` | **string** · Optional · Default: `ingress-nginx`<br>Ingress controller namespace (used for the network policy) |
| `cpu` | **string** · Required · Default: `512m`<br>CPU request for the File Browser container |
| `memory` | **string** · Required · Default: `256Mi`<br>Memory request for the File Browser container |
| `dataPersistent` | **boolean** · Optional · Default: `false`<br>Enable persistent storage for uploaded files and database. When enabled, creates a PVC. When disabled, data is ephemeral (emptyDir). |
| `storageClass` | **string** · Optional<br>Storage class for the data PVC. Leave empty for cluster default. |
| `storageSize` | **string** · Optional · Default: `10Gi`<br>Persistent volume size when `dataPersistent` is enabled |
| `root` | **string** · Optional · Default: `/data`<br>Root filesystem path visible in File Browser. Set to `/` to browse the entire container filesystem, or `/data` to restrict to the data volume only. |

---

## Notes

- File Browser is free and open-source software (Apache 2.0 license) — no license key is needed
- Authentication is handled by the Juno platform's Hubble ingress — no separate login is required within the application
- The container runs as a non-root user with a read-only root filesystem for security
- The `root` field controls the scope of the filesystem visible in File Browser — restrict to `/data` for a scoped view, or set to `/` for full container filesystem access
- Uploaded files and the File Browser database are ephemeral unless `dataPersistent` is enabled
- Project storage mounts are available at workload launch time through the standard Genesis volume mounting interface — they will appear under `/data` or the path specified by `root`
- The File Browser database (`filebrowser.db`) stores user settings and is lost on restart when ephemeral storage is used
