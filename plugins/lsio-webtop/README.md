# LSIO Webtop

![LSIO Webtop](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/lsio-webtop/scripts/assets/logo.png)

**Category:** Workstations
**Type:** Workload Template
**Tags:** `selkies` · `vdi` · `lsio`

---

## Overview

LSIO Webtop is a containerized desktop workstation built on [LinuxServer.io](https://linuxserver.io) images, delivered through the browser via Selkies-GStreamer. It provides a full Linux desktop experience accessible from any web browser without VPN or client software. Webtop supports GPU acceleration and is highly configurable — you can launch any LinuxServer.io Webtop image as a workload, from lightweight browser environments to full desktop systems.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the LSIO Webtop workload type in the workload creation UI. Individual Webtop instances are launched by Kuiper when users create workloads.

---

## Prerequisites

- GPU support requires the **NVIDIA GPU Operator** plugin installed on the cluster
- No additional prerequisites for CPU-only Webtop workloads

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"LSIO Webtop"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the LSIO Webtop workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a Webtop workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `gpu` | boolean | **Yes** | — | Enable GPU passthrough for the workstation |
| `registry` | string | **Yes** | `lscr.io/linuxserver` | Container registry for the Webtop image |
| `repo` | string | **Yes** | `chrome` | LinuxServer.io image to launch (e.g. `chrome`, `firefox`, `ubuntu-mate`, `kde`) |
| `tag` | string | **Yes** | `latest` | Image tag |
| `publicAccess` | boolean | **Yes** | `false` | Disable authentication and allow unauthenticated access |

---

## Notes

- Browse available LinuxServer.io Webtop images at [lscr.io/linuxserver](https://fleet.linuxserver.io/?search=webtop) — the `repo` field maps to the image name (e.g. `chrome`, `ubuntu-kde`)
- Setting `publicAccess` to `true` removes authentication from the workstation endpoint — use only in trusted network environments
- GPU acceleration requires compatible NVIDIA hardware and the **NVIDIA GPU Operator** plugin
- Webtop workstations are stateless by default; add volume mounts via Genesis at workload creation time to persist user data
