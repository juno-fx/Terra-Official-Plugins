# EmberGen

![EmberGen](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/embergen/scripts/assets/embergen.png?raw=true)

**Category:** CG
**Type:** Software Installer
**Tags:** `embergen` · `vfx` · `3d` · `simulation` · `effects` · `volumetrics` · `realtime` · `gpu` · `particles`

---

## Overview

EmberGen is a real-time volumetric effects and VFX tool from JangaFX designed for artists and studios. It specializes in creating stunning GPU-accelerated visual effects including fire, smoke, explosions, and other fluid simulations — all rendered in real time. The EmberGen plugin installs a chosen version to a shared persistent volume, making the application available to all GPU-equipped workstations in your project.

---

## How It Works

**Software Installer** — When added to a project, Terra downloads and installs EmberGen to the shared volume you specify. Once complete, EmberGen is available at that path for every workstation in the project that mounts the volume.

---

## Prerequisites

- A shared persistent volume provisioned in your project
- GPU-enabled workstations (EmberGen requires GPU acceleration for real-time simulation)
- A valid EmberGen license from JangaFX

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"EmberGen"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **string** · Required<br>EmberGen version to install (e.g. `1.2.4`) |
| `install_volume` | **shared-volume** · Required<br>Shared persistent volume to install EmberGen into |
| `destination` | **string** · Optional · Default: `/embergen`<br>Directory path within the volume for the installation |

---

## Notes

- EmberGen is a **commercial application** — a valid license from [JangaFX](https://jangafx.com/) is required
- GPU acceleration is essential for real-time simulation; workstations without GPUs will not run EmberGen at production quality
- The installer downloads EmberGen from JangaFX servers; outbound internet access is required from the cluster
- If `destination` is left blank, EmberGen installs to `/embergen` on the selected volume
