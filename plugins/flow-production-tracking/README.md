# Autodesk Flow Production Tracking

<img src="https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/flow-production-tracking/scripts/assets/flow.png?raw=true" alt="Autodesk Flow Production Tracking" width="80" />

**Category:** Project Management
**Type:** Software Installer
**Tags:** `flow` · `autodesk` · `project-management` · `production-tracking` · `shotgun` · `shotgrid`

---

## Overview

Autodesk Flow Production Tracking (formerly ShotGrid / Shotgun) is a powerful cloud-based project management and production tracking platform built for creative teams. It provides shot tracking, asset management, review tools, scheduling, and reporting across the full production pipeline. The Flow Production Tracking plugin installs version 2.1.0 of the Flow integration toolkit to a shared persistent volume, enabling workstations in your project to connect to your Flow Production Tracking instance.

---

## How It Works

**Software Installer** — When added to a project, Terra installs the Flow Production Tracking integration toolkit to the shared volume you specify. Once complete, the toolkit is available for DCC applications running on project workstations that mount the volume.

---

## Prerequisites

- An active **Autodesk Flow Production Tracking** (ShotGrid) account and site URL
- A shared persistent volume provisioned in your project
- Workstations configured to use the Flow integration (typically via DCC software plugins)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Autodesk Flow Production Tracking"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `install_volume` | **shared-volume** · Required<br>Shared persistent volume to install the Flow toolkit into |
| `destination` | **string** · Optional · Default: `/flow`<br>Directory path within the volume for the installation |

---

## Notes

- This plugin installs version **2.1.0** of the Flow Production Tracking integration toolkit
- An active Autodesk subscription is required to use Flow Production Tracking; visit [Autodesk's website](https://www.autodesk.com/products/flow-production-tracking/) for licensing details
- The integration files installed by this plugin are typically used alongside DCC applications (Maya, Houdini, Nuke, etc.) that have ShotGrid/Flow plugins enabled
- If `destination` is left blank, the toolkit installs to `/flow` on the selected volume
