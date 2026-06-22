# RustDesk

![RustDesk](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/rustdesk/scripts/assets/rustdesk.png)

**Category:** VDI
**Type:** Namespaced Plugin
**Tags:** `remote-desktop` · `rustdesk` · `remote-access`

---

## Overview

RustDesk is a fast, open-source remote desktop and remote support tool written in Rust. It provides low-latency remote access to desktops with end-to-end encryption, working both with its own relay servers and peer-to-peer connections. The RustDesk plugin installs RustDesk version 1.4.0 to a shared persistent volume, enabling remote desktop access from workstations in your project.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin runs an installer Job that places the RustDesk client and server components on the configured shared volume.

---

## Prerequisites

- A shared persistent volume provisioned in your project
- A RustDesk relay server (either self-hosted or the public RustDesk relay) accessible from workstations

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"RustDesk"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `install_volume` | shared-volume | **Yes** | — | Shared persistent volume to install RustDesk into |
| `destination` | string | **Yes** | — | Directory path within the volume for the RustDesk installation |

---

## Notes

- This plugin installs **RustDesk version 1.4.0**
- RustDesk is free and open-source (AGPL-3.0 license) — no license key is required for self-hosted use
- To use RustDesk, workstations need access to a relay server; configure the relay server address within the RustDesk application settings after installation
- For a fully self-hosted setup, consider running RustDesk Server alongside this client installation
