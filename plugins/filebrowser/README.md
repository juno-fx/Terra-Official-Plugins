# File Browser

![File Browser](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/filebrowser/assets/logo.png)

**Category:** Workstations
**Type:** Workload Template
**Tags:** `file-management` · `storage` · `web-interface`
**Compatibility:** `genesis-deployment>=3.0.2` · `orion-deployment>=3.1.0`

---

## Overview

File Browser is a lightweight, web-based file manager that runs entirely in a browser — no desktop environment required. It provides a clean interface for drag-and-drop upload, directory browsing, file editing, and file download. The File Browser workload can optionally mount project storage volumes.

---

## How It Works

**Workload Template** — Installs the File Browser workload schema into Genesis. Once installed, the File Browser type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own file manager on demand within a project through **Hubble**.

**Access and authentication** — Each instance runs with an nginx sidecar in the same pod. The ingress routes `/<namespace>/filebrowser/<workload-name>/` to the sidecar, which checks the user's Hubble login before forwarding the request to File Browser. Because authentication happens inside the pod rather than through ingress-controller annotations, it works the same with any ingress controller (ingress-nginx, Traefik, etc.).

---

## Prerequisites

- An ingress controller in the cluster (ingress-nginx, Traefik, etc.)

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
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry to pull the File Browser image from |
| `repo` | **string** · Required · Default: `filebrowser/filebrowser`<br>File Browser image repository |
| `tag` | **string** · Required · Default: `latest`<br>File Browser image tag |
| `cpu` | **string** · Required · Default: `512m`<br>CPU request for the File Browser container |
| `memory` | **string** · Required · Default: `256Mi`<br>Memory request for the File Browser container |
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Registry to pull the nginx sidecar image from |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>Repository to pull the nginx sidecar image from |
| `nginx_tag` | **string** · Required · Default: `alpine`<br>Tag to pull the nginx sidecar image from |
| `root` | **string** · Optional · Default: `/`<br>Root filesystem path visible in File Browser. Leave as `/` to browse the entire container filesystem, or set it to a mount path to restrict the view to that volume. |

---

## Notes

- File Browser is free and open-source software (Apache 2.0 license) — no license key is needed
- Authentication is handled by the nginx sidecar, which checks the user's Hubble login — no separate login is required within the application
- The File Browser container runs as a non-root user with all Linux capabilities dropped
- The `root` field controls the scope of the filesystem visible in File Browser — set it to a mount path for a scoped view, or leave it as `/` for full container filesystem access
- File Browser has no storage of its own: its database lives in `/tmp` and is lost on pod restart, and anything uploaded outside a mounted volume is lost too
- Project storage mounts are available at workload launch time through the standard Genesis volume mounting interface — they appear at their mount paths, and are visible in File Browser when they sit under `root`
- The workload's network policy only accepts inbound traffic on the nginx sidecar port (8080); File Browser's own port is not reachable from elsewhere in the cluster. It sets no egress rules, so outbound access is controlled entirely by your namespace/cluster
- The ingress uses the `nginx` IngressClass by default; Kuiper 4.8.0 and later replaces it with the launching namespace's IngressClass
