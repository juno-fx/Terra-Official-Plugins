# Houdini

![Houdini](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/houdini/scripts/assets/houdini.png)

**Category:** CG
**Type:** Software Installer
**Tags:** `houdini` · `sidefx` · `vfx` · `usd` · `animation` · `3d` · `simulation` · `rendering` · `effects` · `modeling`

---

## Overview

SideFX Houdini is the industry-standard 3D procedural content creation tool used across film, television, games, and advertising. It is renowned for its node-based workflow and powerful procedural generation capabilities for VFX, simulations, lighting, and animation. The Houdini plugin downloads and installs a specified Houdini version directly from SideFX's servers to a shared persistent volume using your SideFX API credentials.

---

## How It Works

**Software Installer** — When added to a project, Terra authenticates with SideFX's API using your credentials and downloads the specified Houdini build to the shared volume you choose. Once complete, Houdini is available at that path for every workstation in the project that mounts the volume.

---

## Prerequisites

- A valid **SideFX** account with API access (Client ID and Client Secret from [sidefx.com](https://www.sidefx.com/))
- A valid Houdini license (Commercial, Indie, or Education) accessible from the cluster's license server
- A shared persistent volume provisioned in your project

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Houdini"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **string** · Required · Default: `20.5.278`<br>Houdini version to install (e.g. `20.5.278`) |
| `destination` | **string** · Required · Default: `/houdini`<br>Directory path within the volume for the installation |
| `client_id` | **string** · Required<br>SideFX API Client ID for downloading the installer |
| `client_secret` | **string** · Required<br>SideFX API Client Secret |
| `install_volume` | **shared-volume** · Required<br>Shared persistent volume to install Houdini into |

---

## Notes

- The `client_id` and `client_secret` are your **SideFX API credentials** — not your SideFX login password. Generate them at [sidefx.com](https://www.sidefx.com/login/?next=/oauth2/applications/)
- Houdini requires a floating license server; ensure your studio's license server is network-accessible from workstation pods
- The installer authenticates with the SideFX API to download a build-specific installer — outbound internet access from the cluster is required
- The version string must exactly match a build available on your SideFX account
