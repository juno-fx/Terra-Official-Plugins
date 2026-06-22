# OpenCode

![OpenCode](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/opencode/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `development` · `coding` · `workload`
**Compatibility:** `genesis-deployment>=3.0.0-beta.1` · `orion-deployment>=3.0.0-beta.1`

---

## Overview

OpenCode is an open-source AI-powered coding agent accessible directly from the browser. It provides an intelligent coding assistant experience — similar to terminal-based AI coding tools — delivered as a web-accessible workload within the Juno platform. Each OpenCode workload gets its own isolated environment with persistent storage for project files and configuration.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the OpenCode workload type in the workload creation UI. Individual OpenCode instances are launched by Kuiper when users create workloads.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 3.0.0-beta.1`, `orion-deployment >= 3.0.0-beta.1`
- A Kubernetes storage class available in the cluster
- API credentials for an LLM provider (configured within the OpenCode application after launch)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"OpenCode"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the OpenCode workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching an OpenCode workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `registry` | string | **Yes** | `docker.io` | Container registry for the nginx sidecar image |
| `repo` | string | **Yes** | `nginx` | nginx sidecar image repository |
| `tag` | string | **Yes** | `alpine` | nginx sidecar image tag |
| `timezone` | string | **Yes** | `America/New_York` | Timezone for the OpenCode instance |
| `storage_class` | k8sStorageClass | **Yes** | — | Storage class for the OpenCode data persistent volume |
| `storage_size` | string | **Yes** | `10Gi` | Size of the persistent volume for project and config data |

---

## Notes

- LLM provider API keys must be configured within the OpenCode application after launch — they are not set at workload creation time
- The nginx sidecar provides browser-accessible proxying for the OpenCode terminal interface
- Project files and OpenCode configuration are persisted to the storage volume across workload restarts
