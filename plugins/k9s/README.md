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

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the k9s workload type in the workload creation UI. k9s instances are launched by Kuiper when users create workloads.

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

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `registry` | string | **Yes** | `docker.io` | Container registry for the nginx sidecar image |
| `repo` | string | **Yes** | `nginx` | nginx sidecar image repository |
| `tag` | string | **Yes** | `alpine` | nginx sidecar image tag |
| `timezone` | string | **Yes** | `America/New_York` | Timezone for the k9s instance |
| `cluster_access` | select | **Yes** | `readonly-ns` | Kubernetes RBAC access level (`readonly-ns` or `admin-ns`) |
| `storage_class` | k8sStorageClass | **Yes** | — | Storage class for the k9s data disk |
| `storage_size` | string | **Yes** | `10Gi` | Size of the persistent volume for k9s data |

---

## Notes

- `readonly-ns` grants read-only access scoped to the project namespace; `admin-ns` grants full admin access to the namespace — choose carefully based on your security requirements
- k9s is a powerful tool with direct cluster access; restrict who can launch k9s workloads using Genesis project permissions
- The nginx sidecar provides the browser-accessible web proxy for the k9s terminal interface
