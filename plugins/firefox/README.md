# Firefox

![Firefox](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/firefox/scripts/assets/firefox.png?raw=true)

**Category:** Web
**Type:** Namespaced Plugin
**Tags:** `firefox` · `browser`

---

## Overview

The Firefox plugin installs the Mozilla Firefox web browser to a shared persistent volume in your project. Once installed, Firefox is available to all workstations that mount the shared volume, enabling web browsing from within containerized desktop environments.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin runs an installer Job that downloads and extracts Firefox to the configured shared volume.

---

## Prerequisites

- A shared persistent volume provisioned in your project
- Workstations with a desktop environment (e.g. **Helios** or **LSIO Webtop**) that can launch GUI applications

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Firefox"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `install_volume` | shared-volume | **Yes** | — | Shared persistent volume to install Firefox into |
| `destination` | string | No | `/apps/firefox` | Directory path within the volume for the Firefox installation |

---

## Notes

- Firefox is installed by default to `/apps/firefox` on the selected volume
- The installer downloads Firefox directly from Mozilla's release servers; outbound internet access from the cluster is required
- Firefox is free and open-source software (MPL 2.0 license) — no license key is needed
