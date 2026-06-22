# Gitea

![Gitea](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/gitea/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `git` · `source-control` · `development`

---

## Overview

Gitea is a lightweight, self-hosted Git service written in Go. It provides a full-featured Git server with a web interface for managing repositories, reviewing code, tracking issues, and managing pull requests — all running entirely within your Juno cluster. The Gitea workload template lets users launch private Git server instances directly from the Genesis workload UI, with persistent storage for repositories and an nginx proxy for web access.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the Gitea workload type in the workload creation UI. The actual Gitea server is launched when a user creates a workload — not at plugin install time.

---

## Prerequisites

- A Kubernetes storage class available in the cluster (for Gitea repository data)
- The workload will be accessible through the Juno platform's ingress after launch

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Gitea"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Gitea workload type will appear in **Genesis** when creating new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a Gitea workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `registry` | string | **Yes** | `docker.io` | Container registry to pull the Gitea image from |
| `repo` | string | **Yes** | `gitea/gitea` | Gitea image repository |
| `tag` | string | **Yes** | `1.23` | Gitea image tag (version) |
| `nginx_registry` | string | **Yes** | `docker.io` | Registry for the nginx sidecar image |
| `nginx_repo` | string | **Yes** | `nginx` | nginx sidecar image repository |
| `nginx_tag` | string | **Yes** | `1.29.3` | nginx sidecar image tag |
| `storage_class` | k8sStorageClass | **Yes** | — | Kubernetes storage class for Gitea repository data |
| `storage_size` | string | **Yes** | `5Gi` | Size of the persistent volume for repository storage |

---

## Notes

- Each launched Gitea workload gets its own isolated Git server and persistent storage volume
- The nginx sidecar handles web traffic proxying and is required for the Gitea web UI to function within the Juno ingress setup
- Gitea is free and open-source software (MIT license) — no license key is needed
- Repository data persists across workload restarts as long as the persistent volume is retained
