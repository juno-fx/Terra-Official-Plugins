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

## How It Works

**Workload Template** — Installs the Wetty workload schema into Genesis. Once installed, the Wetty type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision browser-accessible shell sessions on demand within a project through **Hubble**.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 1.5.0`, `orion-deployment >= 1.5.0`

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"wetty"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Wetty schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision terminal sessions on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a terminal session through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `wettyoss`<br>Container registry for the Wetty image |
| `repo` | **string** · Required · Default: `wetty`<br>Wetty image repository |
| `tag` | **string** · Required · Default: `2.5`<br>Wetty image tag |
| `packages` | **string** · Optional · Default: `vim`<br>Space-separated list of additional packages to install at startup |
| `terra_role` | **k8sServiceAccount** · Optional<br>A Terra plugin-level service account role to assign to the terminal (grants Kubernetes RBAC permissions within the project) |
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Container registry for the nginx proxy image |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>nginx proxy image repository |
| `nginx_tag` | **string** · Required · Default: `1.29.3`<br>nginx proxy image tag |
| `publicAccess` | **boolean** · Required · Default: `false`<br>Disable authentication and allow unauthenticated browser access to the terminal |

---

## Notes

- Setting `publicAccess` to `true` removes all authentication from the terminal — use only in isolated or trusted network environments
- The `terra_role` field assigns a Kubernetes ServiceAccount to the terminal pod, allowing CLI tools in the terminal to interact with Kubernetes resources at the specified permission level
- The `packages` field installs system packages via `apt-get` at workload startup; include any CLI tools your terminal users need
- Wetty is ideal for quick administrative shell access, running scripts, and interacting with cluster resources via `kubectl` or `helm`
