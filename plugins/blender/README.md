# Blender

<img src="https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/blender/scripts/assets/blender.png?raw=true" alt="Blender" width="80" />

**Category:** CG
**Type:** Software Installer
**Tags:** `blender` · `vfx` · `usd` · `animation` · `3d` · `simulation` · `rendering` · `effects` · `modeling`

---

## Overview

Blender is a free and open-source 3D creation suite licensed under the GNU GPL. It supports the full 3D pipeline — modeling, rigging, animation, simulation, rendering, compositing, motion tracking, and video editing. The Blender plugin installs a chosen version of Blender to a shared persistent volume so that all workstations in a project can access the same installation.

---

## How It Works

**Software Installer** — When added to a project, Terra runs an installer that downloads and extracts Blender to the shared volume you specify. Once complete, Blender is available at that path for every workstation in the project that mounts the volume.

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

Terra will download and extract Blender to the target volume.

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **string** · Required<br>Blender version to install (e.g. `4.5.1`) |
| `install_volume` | **shared-volume** · Required<br>The shared persistent volume to install Blender into |
| `destination` | **string** · Optional · Default: `/blender`<br>Directory path within the volume where Blender will be installed |

---

## Notes

- Blender is licensed under the **GNU GPL** and is free to use commercially
- The installer downloads Blender from the official Blender release servers; outbound internet access from the cluster is required
- If `destination` is left blank, Blender installs to `/blender` on the selected volume
- To upgrade Blender, reinstall the plugin with the new version — the installer will overwrite the existing installation at the destination path
