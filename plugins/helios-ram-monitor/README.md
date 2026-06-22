# Helios RAM Monitor

![Helios RAM Monitor](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/helios/scripts/assets/helios-icon.png)

**Category:** Helios Plugin
**Type:** Namespaced Plugin
**Tags:** `ram` · `desktop` · `customization`

---

## Overview

Helios RAM Monitor is a Helios workstation add-on that monitors host server memory usage and notifies users when RAM is critically high. High memory pressure on the host node can trigger workstation eviction by Kubernetes; this plugin gives users advance warning so they can save their work and free up resources before an eviction occurs.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin installs the RAM monitoring scripts as a Helios plugin that attaches to Helios workstations running in the same project.

---

## Prerequisites

- **Helios** workload template installed in the cluster
- Helios workstations must be launched in the same project namespace where this plugin is installed

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Helios RAM Monitor"**
3. Click **Install**
4. Click **Confirm** to deploy (no configuration required)

Once installed, the RAM monitor will run within all Helios workstations in the project and display desktop notifications when host memory is under pressure.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

---

## Notes

- This plugin is a **Helios-specific add-on** and has no effect on non-Helios workloads
- The monitor checks host-level RAM (not container-level memory limits), so it reflects the actual memory pressure on the node running the workstation
- Notifications are displayed inside the Helios desktop environment; users must be actively connected to see them
- This plugin is intended as a user warning tool — it does not automatically stop the workstation or prevent eviction
