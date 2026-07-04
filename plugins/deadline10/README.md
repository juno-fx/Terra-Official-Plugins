# Deadline 10

![Deadline 10](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/deadline10/scripts/assets/deadline10client.png)

**Category:** Rendering Management
**Type:** Software Installer
**Tags:** `deadline10` · `render-farm` · `distributed-computing` · `Thinkbox` · `AWS`

---

## Overview

AWS Thinkbox Deadline 10 is industry-standard render farm management software for distributed computing. The Deadline plugin installs the Deadline 10 client to a shared persistent volume so that render workstations in your project can submit and monitor render jobs. Deadline 10 connects to your existing Deadline Repository to manage rendering queues, priorities, and machine allocation across your studio's compute farm.

---

## How It Works

**Software Installer** — When added to a project, Terra downloads and installs the Deadline 10 client to the volumes you configure. Once complete, the Deadline client is available to all workstations in the project that mount the install volume.

---

## Prerequisites

- An existing Deadline 10 Repository accessible from the cluster (provided by your studio or AWS infrastructure)
- A dedicated **exclusive** persistent volume for the Deadline database
- A **shared** persistent volume for the Deadline installation files
- A valid Deadline 10 installer download URL (from AWS Thinkbox)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Deadline 10"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `url` | **string** · Required<br>Direct download URL for the Deadline 10 installer |
| `database_volume` | **exclusive-volume** · Required<br>Exclusive persistent volume for the Deadline database |
| `install_volume` | **shared-volume** · Required<br>Shared persistent volume where Deadline client files will be installed |
| `destination` | **string** · Required<br>Directory path within the install volume for the Deadline installation |
| `custom_plugins_path` | **string** · Optional<br>Path to custom Deadline plugins to include |

---

## Notes

- Deadline 10 requires a valid license from AWS Thinkbox — ensure your studio's license server is reachable from the cluster
- The `database_volume` must be exclusive to this plugin instance; do not share it with other plugins
- The installer download URL must be a direct link to the Deadline 10 installer package; outbound internet access from the cluster is required
- Custom plugins specified in `custom_plugins_path` will be included in the installation alongside the standard Deadline plugins
