# Web IDE

![Web IDE](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/web-ide/scripts/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `ide` · `vscode` · `workload`

---

## Overview

Web IDE is a browser-based VS Code environment powered by [code-server](https://github.com/coder/code-server). It delivers a full VS Code editing experience — extensions, integrated terminal, Git, IntelliSense — accessible from any browser without installing VS Code or a desktop environment. Each Web IDE workload is an isolated development environment with its own persistent storage and system packages.

---

## How It Works

**Workload Template** — Installs the Web IDE workload schema into Genesis. Once installed, the Web IDE type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own browser-based VS Code environment on demand within a project through **Hubble**.

---

## Prerequisites

- No additional prerequisites beyond a running Juno platform

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"web-ide"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Web IDE schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision Web IDE instances on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a Web IDE instance through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `lscr.io`<br>Container registry for the code-server image |
| `repo` | **string** · Required · Default: `linuxserver/code-server`<br>code-server image repository |
| `tag` | **string** · Required · Default: `latest`<br>code-server image tag |
| `packages` | **string** · Optional · Default: `python3 python3-venv`<br>Space-separated list of additional system packages to install at startup |
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Container registry for the nginx proxy image |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>nginx proxy image repository |
| `nginx_tag` | **string** · Required · Default: `latest`<br>nginx proxy image tag |

---

## Notes

- The `packages` field accepts space-separated package names installed via `apt-get` at workload startup — useful for adding language runtimes, build tools, or CLI utilities
- VS Code extensions are managed per-user within the code-server UI and persist to the workload's storage volume
- The nginx sidecar handles web proxying to integrate the Web IDE into the Juno platform's ingress and authentication
- For a native VS Code desktop experience within a full desktop environment, consider using the **Visual Studio Code** installer plugin with a **Helios** or **LSIO Webtop** workstation instead
