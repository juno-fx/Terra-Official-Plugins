# Gitea

![Gitea](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/gitea/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `git` · `source-control` · `development`

---

## Overview

Gitea is a lightweight, self-hosted Git service written in Go. It provides a full-featured Git server with a web interface for managing repositories, reviewing code, tracking issues, and managing pull requests — all running entirely within your Juno cluster. The Gitea workload template lets users launch private Git server instances directly from the Genesis workload UI, with persistent storage for repositories and an nginx proxy for web access.

---

## How It Works

**Workload Template** — Adds a Gitea Git server workload type to Genesis. Once installed, users can launch their own private Gitea instance directly from the Genesis workload screen. Each instance gets its own persistent storage and is independent from other users' instances.

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

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry to pull the Gitea image from |
| `repo` | **string** · Required · Default: `gitea/gitea`<br>Gitea image repository |
| `tag` | **string** · Required · Default: `1.23`<br>Gitea image tag (version) |
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Registry for the nginx sidecar image |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>nginx sidecar image repository |
| `nginx_tag` | **string** · Required · Default: `1.29.3`<br>nginx sidecar image tag |
| `storage_class` | **k8sStorageClass** · Required<br>Kubernetes storage class for Gitea repository data |
| `storage_size` | **string** · Required · Default: `5Gi`<br>Size of the persistent volume for repository storage |

---

## Notes

- Each launched Gitea workload gets its own isolated Git server and persistent storage volume
- The nginx sidecar handles web traffic proxying and is required for the Gitea web UI to function within the Juno ingress setup
- Gitea is free and open-source software (MIT license) — no license key is needed
- Repository data persists across workload restarts as long as the persistent volume is retained
