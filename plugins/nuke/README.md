# Nuke

![Nuke](https://www.foundry.com/sites/default/files/2021-03/ICON_NUKE-rgb-yellow-01.png)

**Category:** Compositing
**Type:** Namespaced Plugin
**Tags:** `nuke` · `foundry` · `vfx` · `visual-effects` · `color` · `grading` · `animation` · `rendering`

---

## Overview

Nuke is the industry-standard node-based compositing tool from The Foundry, used in VFX and post-production pipelines worldwide. It provides a highly flexible node graph for compositing, color grading, 3D compositing, and rendering. The Nuke plugin downloads and installs a specified Nuke version to a shared persistent volume, making it available to all compositing workstations in your project.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin runs an installer Job that downloads and installs Nuke to the target volume.

---

## Prerequisites

- A valid **The Foundry** Nuke license (floating or node-locked) accessible from workstations
- A shared persistent volume provisioned in your project
- Outbound internet access from the cluster (to download the Nuke installer from The Foundry's servers)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Nuke"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | string | **Yes** | `16.0v5` | Nuke version to install (e.g. `16.0v5`) |
| `destination` | string | **Yes** | `/nuke` | Directory path within the volume for the Nuke installation |
| `install_volume` | shared-volume | **Yes** | — | Shared persistent volume to install Nuke into |

---

## Notes

- Nuke is a **commercial application** — a valid license from [The Foundry](https://www.foundry.com/products/nuke-family/nuke) is required
- The version string must exactly match a release available from The Foundry (e.g. `16.0v5`, `15.1v3`)
- Nuke requires a floating license server accessible from workstation pods; ensure your license server hostname is resolvable and reachable from the cluster network
- The installer downloads directly from The Foundry's distribution servers; ensure the cluster has outbound HTTPS access
