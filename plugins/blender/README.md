# Blender

![Blender](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/blender/scripts/assets/blender.png?raw=true)

**Category:** CG
**Type:** Namespaced Plugin
**Tags:** `blender` · `vfx` · `usd` · `animation` · `3d` · `simulation` · `rendering` · `effects` · `modeling`

---

## Overview

Blender is a free and open-source 3D creation suite licensed under the GNU GPL. It supports the full 3D pipeline — modeling, rigging, animation, simulation, rendering, compositing, motion tracking, and video editing. The Blender plugin installs a chosen version of Blender to a shared persistent volume so that all workstations in a project can access the same installation.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin runs an installer Job that places Blender into a shared volume accessible to project workstations.

---

## Prerequisites

- A shared persistent volume provisioned in your project (created via a storage plugin such as **Storage NFS**, **Storage HostPath**, or **Longhorn**)
- Workstations with access to the shared volume mount path

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Blender"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

Terra will deploy an installer Job into your project namespace that downloads and extracts Blender to the target volume.

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | string | **Yes** | — | Blender version to install (e.g. `4.5.1`) |
| `install_volume` | shared-volume | **Yes** | — | The shared persistent volume to install Blender into |
| `destination` | string | No | `/blender` | Directory path within the volume where Blender will be installed |

---

## Notes

- Blender is licensed under the **GNU GPL** and is free to use commercially
- The installer downloads Blender from the official Blender release servers; outbound internet access from the cluster is required
- If `destination` is left blank, Blender installs to `/blender` on the selected volume
- To upgrade Blender, reinstall the plugin with the new version — the installer will overwrite the existing installation at the destination path
