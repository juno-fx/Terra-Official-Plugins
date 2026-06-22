# Houdini

![Houdini](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/houdini/scripts/assets/houdini.png)

**Category:** CG
**Type:** Namespaced Plugin
**Tags:** `houdini` · `sidefx` · `vfx` · `usd` · `animation` · `3d` · `simulation` · `rendering` · `effects` · `modeling`

---

## Overview

SideFX Houdini is the industry-standard 3D procedural content creation tool used across film, television, games, and advertising. It is renowned for its node-based workflow and powerful procedural generation capabilities for VFX, simulations, lighting, and animation. The Houdini plugin downloads and installs a specified Houdini version directly from SideFX's servers to a shared persistent volume using your SideFX API credentials.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin runs an installer Job that authenticates with SideFX's API and downloads the specified Houdini build to the target volume.

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

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | string | **Yes** | `20.5.278` | Houdini version to install (e.g. `20.5.278`) |
| `destination` | string | **Yes** | `/houdini` | Directory path within the volume for the installation |
| `client_id` | string | **Yes** | — | SideFX API Client ID for downloading the installer |
| `client_secret` | string | **Yes** | — | SideFX API Client Secret |
| `install_volume` | shared-volume | **Yes** | — | Shared persistent volume to install Houdini into |

---

## Notes

- The `client_id` and `client_secret` are your **SideFX API credentials** — not your SideFX login password. Generate them at [sidefx.com](https://www.sidefx.com/login/?next=/oauth2/applications/)
- Houdini requires a floating license server; ensure your studio's license server is network-accessible from workstation pods
- The installer authenticates with the SideFX API to download a build-specific installer — outbound internet access from the cluster is required
- The version string must exactly match a build available on your SideFX account
