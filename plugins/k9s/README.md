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

**Workload Template** — Adds the k9s terminal dashboard type to Genesis. Once installed, users can launch a browser-accessible k9s session directly from the Genesis workload screen.

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

Once installed, the k9s workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a k9s workload in **Genesis**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry for the nginx sidecar image |
| `repo` | **string** · Required · Default: `nginx`<br>nginx sidecar image repository |
| `tag` | **string** · Required · Default: `alpine`<br>nginx sidecar image tag |
| `timezone` | **string** · Required · Default: `America/New_York`<br>Timezone for the k9s instance |
| `cluster_access` | **select** · Required · Default: `readonly-ns`<br>Kubernetes RBAC access level (`readonly-ns` or `admin-ns`) |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the k9s data disk |
| `storage_size` | **string** · Required · Default: `10Gi`<br>Size of the persistent volume for k9s data |

---

## Notes

- `readonly-ns` grants read-only access to the project's resources; `admin-ns` grants full admin access — choose carefully based on your security requirements
- k9s is a powerful tool with direct cluster access; restrict who can launch k9s workloads using Genesis project permissions
- The nginx sidecar provides the browser-accessible web proxy for the k9s terminal interface
