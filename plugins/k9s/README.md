# k9s — Kubernetes TUI

![k9s](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/k9s/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `development` · `kubernetes`
**Compatibility:** `genesis-deployment>=3.0.0-beta.1` · `orion-deployment>=3.0.0-beta.1`

---

## Overview

k9s is a terminal-based Kubernetes management UI that provides a fast, keyboard-driven interface for interacting with cluster resources. The k9s workload template delivers k9s accessible directly from the browser, allowing developers and operators to inspect pods, view logs, exec into containers, and manage cluster resources without installing any local tooling. Each workload instance runs in its own container with configurable Kubernetes RBAC access and persistent storage.

---

## How It Works

**Workload Template** — Installs the k9s workload schema into Genesis. Once installed, the k9s type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision a browser-accessible k9s session on demand within a project through **Hubble**.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 3.0.0-beta.1`, `orion-deployment >= 3.0.0-beta.1`
- A Kubernetes storage class available in the cluster
- RBAC permissions appropriate for the level of cluster access you want to grant

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"k9s"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the k9s schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision k9s sessions on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a k9s session through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry for the nginx sidecar image |
| `repo` | **string** · Required · Default: `nginx`<br>nginx sidecar image repository |
| `tag` | **string** · Required · Default: `alpine`<br>nginx sidecar image tag |
| `timezone` | **string** · Required · Default: `America/New_York`<br>Timezone for the k9s instance |
| `cluster_access` | **select** · Required · Default: `readonly-ns`<br>Kubernetes RBAC access level (`readonly-ns` or `admin-ns`) |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the k9s data disk |
| `storage_size` | **string** · Required · Default: `10Gi`<br>Size of the persistent volume for k9s data |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for a k9s/kubectl terminal session:

| Variable | Description |
|----------|--------------|
| `EDITOR` | Text editor invoked by k9s's `e` (edit resource) command. |

---

## Notes

- `readonly-ns` grants read-only access to the project's resources; `admin-ns` grants full admin access — choose carefully based on your security requirements
- k9s is a powerful tool with direct cluster access; restrict who can launch k9s workloads using Genesis project permissions
- The nginx sidecar provides the browser-accessible web proxy for the k9s terminal interface
