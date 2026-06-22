# Wetty

![Wetty](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/wetty/scripts/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `development` · `workload`
**Compatibility:** `genesis-deployment>=1.5.0` · `orion-deployment>=1.5.0`

---

## Overview

Wetty (Web + tty) provides a terminal emulator accessible directly from the browser over HTTP/HTTPS. It gives users a full interactive shell in their project environment without requiring SSH access or a desktop environment. The Wetty workload template lets users launch browser-based terminal sessions directly from Genesis, with support for custom packages, Terra RBAC roles, and optional public access modes.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the Wetty workload type in the workload creation UI. Individual terminal sessions are launched by Kuiper when users create workloads.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 1.5.0`, `orion-deployment >= 1.5.0`
- No additional prerequisites

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"wetty"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Wetty workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a Wetty workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `registry` | string | **Yes** | `wettyoss` | Container registry for the Wetty image |
| `repo` | string | **Yes** | `wetty` | Wetty image repository |
| `tag` | string | **Yes** | `2.5` | Wetty image tag |
| `packages` | string | No | `vim` | Space-separated list of additional packages to install at startup |
| `terra_role` | k8sServiceAccount | No | — | A Terra plugin-level service account role to assign to the terminal (grants Kubernetes RBAC permissions within the project) |
| `nginx_registry` | string | **Yes** | `docker.io` | Container registry for the nginx proxy image |
| `nginx_repo` | string | **Yes** | `nginx` | nginx proxy image repository |
| `nginx_tag` | string | **Yes** | `1.29.3` | nginx proxy image tag |
| `publicAccess` | boolean | **Yes** | `false` | Disable authentication and allow unauthenticated browser access to the terminal |

---

## Notes

- Setting `publicAccess` to `true` removes all authentication from the terminal — use only in isolated or trusted network environments
- The `terra_role` field assigns a Kubernetes ServiceAccount to the terminal pod, allowing CLI tools in the terminal to interact with Kubernetes resources at the specified permission level
- The `packages` field installs system packages via `apt-get` at workload startup; include any CLI tools your terminal users need
- Wetty is ideal for quick administrative shell access, running scripts, and interacting with cluster resources via `kubectl` or `helm`
