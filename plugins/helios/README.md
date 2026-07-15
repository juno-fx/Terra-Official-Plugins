# Helios

![Helios](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/helios/scripts/assets/helios-icon.png)

**Category:** Workstations
**Type:** Workload Template
**Tags:** `kasm` · `vdi` · `juno`
**Bundle:** Orion Essentials

---

## Overview

Helios is the flagship containerized workstation from Juno Innovations. It provides a full-featured Linux desktop environment delivered through the browser — no VPN or client software required. Helios workstations support GPU acceleration, plugin mounting, and the full Juno workstation ecosystem (including Helios plugins like auto-shutdown and RAM monitoring). Each Helios workload is an isolated, personal desktop environment that users can launch on demand from Genesis.

---

## How It Works

**Workload Template** — Installs the Helios workstation schema into Genesis. Once installed, the Helios type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own personal desktop on demand within a project through **Hubble**.

---

## Prerequisites

- GPU support requires the **NVIDIA GPU Operator** plugin to be installed if GPU workstations are needed
- Helios plugin add-ons (**Helios Auto Shutdown**, **Helios RAM Monitor**) are optional but recommended for production deployments

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Helios"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Helios schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision workstations on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a workstation through **Hubble**:

| Field | Details |
|-------|---------|
| `gpu` | **boolean** · Required<br>Enable GPU passthrough for the workstation |
| `registry` | **string** · Required · Default: `junoinnovations`<br>Container registry to pull the Helios image from |
| `repo` | **string** · Required · Default: `helios`<br>Helios image repository |
| `tag` | **string** · Required · Default: `unstable-rocky-9`<br>Helios image tag (OS flavour and version) |
| `enableAPI` | **boolean** · Required · Default: `false`<br>Enable system-to-system communication via the Helios API |
| `rheaRepo` | **string** · Required · Default: `rhea`<br>Repository for the Rhea sidecar image |
| `rheaTag` | **string** · Required · Default: `v1.2.3`<br>Rhea sidecar image tag |
| `publicAccess` | **boolean** · Required · Default: `false`<br>Disable authentication and allow unauthenticated access to the workstation |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for a Helios workstation:

| Variable | Description |
|----------|--------------|
| `PASSWORD` | Password set for the user to log into the desktop session directly. |
| `SUDO` | Grants the user sudo access on the container. |
| `SELKIES_FRAMERATE` | Streaming framerate for the desktop session, as a range (e.g. `15-60`) or fixed value (e.g. `30`). |
| `DISABLE_VGL` | Disables the VirtualGL wrapper around the desktop session; apps needing it must be launched manually via `vglrun`. |
| `REMOTE_PROTOCOL` | if set to "dcv" Helios will run Nice DCV rather than Selkies. |

---

## Notes

- This plugin is included in the **Orion Essentials** bundle — you can install Helios, the Prometheus Stack, and the ArgoCD Dashboard together in one step from Terra
- Setting `publicAccess` to `true` removes authentication from the workstation endpoint — use only in trusted network environments
- The `tag` field controls the OS and desktop flavour of the workstation; consult the Juno documentation for available image tags
- Helios workstations are scheduled on nodes labelled `juno-innovations.com/workstation: "true"` — ensure your cluster has workstation nodes configured
- Helios plugin add-ons (auto-shutdown, RAM monitoring) must be installed separately and will automatically attach to Helios workloads
