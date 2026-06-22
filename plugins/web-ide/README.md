# Web IDE

![Web IDE](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/web-ide/scripts/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `ide` · `vscode` · `workload`

---

## Overview

Web IDE is a browser-based VS Code environment powered by [code-server](https://github.com/coder/code-server). It delivers a full VS Code editing experience — extensions, integrated terminal, Git, IntelliSense — accessible from any browser without installing VS Code or a desktop environment. Each Web IDE workload is an isolated development environment with its own persistent storage and system packages.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the Web IDE workload type in the workload creation UI. Individual Web IDE instances are launched by Kuiper when users create workloads.

---

## Prerequisites

- No additional prerequisites beyond a running Juno platform

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"web-ide"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Web IDE workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a Web IDE workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `registry` | string | **Yes** | `lscr.io` | Container registry for the code-server image |
| `repo` | string | **Yes** | `linuxserver/code-server` | code-server image repository |
| `tag` | string | **Yes** | `latest` | code-server image tag |
| `packages` | string | No | `python3 python3-venv` | Space-separated list of additional system packages to install at startup |
| `nginx_registry` | string | **Yes** | `docker.io` | Container registry for the nginx proxy image |
| `nginx_repo` | string | **Yes** | `nginx` | nginx proxy image repository |
| `nginx_tag` | string | **Yes** | `latest` | nginx proxy image tag |

---

## Notes

- The `packages` field accepts space-separated package names installed via `apt-get` at workload startup — useful for adding language runtimes, build tools, or CLI utilities
- VS Code extensions are managed per-user within the code-server UI and persist to the workload's storage volume
- The nginx sidecar handles web proxying to integrate the Web IDE into the Juno platform's ingress and authentication
- For a native VS Code desktop experience within a full desktop environment, consider using the **Visual Studio Code** installer plugin with a **Helios** or **LSIO Webtop** workstation instead
