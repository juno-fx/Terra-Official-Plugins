# Helios

![Helios](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/helios/scripts/assets/helios-icon.png)

**Category:** Workstations
**Type:** Workload Template
**Tags:** `kasm` · `vdi` · `juno`

---

## Overview

Helios is the flagship containerized workstation from Juno Innovations. It provides a full-featured Linux desktop environment delivered through the browser — no VPN or client software required. Helios workstations support GPU acceleration, plugin mounting, and the full Juno workstation ecosystem (including Helios plugins like auto-shutdown and RAM monitoring). Each Helios workload is an isolated, personal desktop environment that users can launch on demand from Genesis.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the Helios workstation type in the workload creation UI. Each user's workstation is launched independently by Kuiper when they create a workload.

---

## Prerequisites

- The Juno platform stack (Terra, Genesis, Kuiper, ArgoCD) must be running
- GPU support requires the **NVIDIA GPU Operator** plugin to be installed if GPU workstations are needed
- Helios plugin add-ons (**Helios Auto Shutdown**, **Helios RAM Monitor**) are optional but recommended for production deployments

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Helios"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Helios workstation type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a Helios workstation in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `gpu` | boolean | **Yes** | — | Enable GPU passthrough for the workstation |
| `registry` | string | **Yes** | `junoinnovations` | Container registry to pull the Helios image from |
| `repo` | string | **Yes** | `helios` | Helios image repository |
| `tag` | string | **Yes** | `unstable-rocky-9` | Helios image tag (OS flavour and version) |
| `enableAPI` | boolean | **Yes** | `false` | Enable system-to-system communication via the Helios API |
| `rheaRepo` | string | **Yes** | `rhea` | Repository for the Rhea sidecar image |
| `rheaTag` | string | **Yes** | `v1.2.3` | Rhea sidecar image tag |
| `publicAccess` | boolean | **Yes** | `false` | Disable authentication and allow unauthenticated access to the workstation |

---

## Notes

- Setting `publicAccess` to `true` removes authentication from the workstation endpoint — use only in trusted network environments
- The `tag` field controls the OS and desktop flavour of the workstation; consult the Juno documentation for available image tags
- Helios workstations are scheduled on nodes labelled `juno-innovations.com/workstation: "true"` — ensure your cluster has workstation nodes configured
- Helios plugin add-ons (auto-shutdown, RAM monitoring) must be installed separately and will automatically attach to Helios workloads
