# Helios Auto Shutdown

![Helios Auto Shutdown](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/helios/scripts/assets/helios-icon.png)

**Category:** Helios Plugin
**Type:** Namespaced Plugin
**Tags:** `shutdown` · `desktop` · `customization`

---

## Overview

Helios Auto Shutdown is a Helios workstation add-on that automatically triggers shutdown of idle Helios workstations via Kuiper. When the workstation detects that the user has been idle for a configured period, it signals Kuiper to stop the workload — helping free up cluster resources and reduce costs in deployments where workstations should not run unattended indefinitely.

The idle timeout is controlled by the `IDLE_TIME` environment variable set on the workstation at launch time.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin installs the auto-shutdown scripts as a Helios plugin that attaches to Helios workstations running in the same project.

---

## Prerequisites

- **Helios** workload template installed in the cluster
- Helios workstations must be launched in the same project namespace where this plugin is installed

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Helios Auto Shutdown"**
3. Click **Install**
4. Click **Confirm** to deploy (no configuration required)

Once installed, the auto-shutdown behaviour will be active for all Helios workstations in the project. Set the `IDLE_TIME` environment variable when creating workloads in Genesis to control the idle timeout duration.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Runtime Configuration

The shutdown behaviour is controlled via environment variables set on the Helios workload at launch time:

| Environment Variable | Description |
|----------------------|-------------|
| `IDLE_TIME` | Duration of user inactivity before shutdown is triggered (e.g. `30m`, `1h`) |

---

## Notes

- This plugin is a **Helios-specific add-on** and has no effect on non-Helios workloads
- The `IDLE_TIME` value is set in the workload's environment variables in Genesis at launch time
- Auto-shutdown sends a shutdown signal through Kuiper, which performs a clean workload termination
