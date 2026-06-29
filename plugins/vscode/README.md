# Visual Studio Code

![VS Code](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/vscode/scripts/assets/vscode.png)

**Category:** Software Development
**Type:** Software Installer
**Tags:** `vscode` · `ide` · `development`

---

## Overview

Visual Studio Code (VS Code) is the open-source AI-powered code editor from Microsoft. It features IntelliSense code completion, integrated Git, debugging, a rich extension ecosystem, and built-in AI coding assistance. The VS Code plugin installs a specified version (or the latest release) of VS Code to a shared persistent volume, making it available to all development workstations in your project.

---

## How It Works

**Software Installer** — When added to a project, Terra downloads and extracts VS Code to the shared volume you specify. Once complete, VS Code is available at that path for every workstation in the project that mounts the volume.

---

## Prerequisites

- A shared persistent volume provisioned in your project
- Workstations with a desktop environment (e.g. **Helios** or **LSIO Webtop**) to run the VS Code GUI
- Outbound internet access from the cluster to download the VS Code release

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"vscode"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **string** · Required · Default: `latest`<br>VS Code version to install. Enter `latest` for the most recent release, or a specific version string (e.g. `1.104.1`). |
| `install_volume` | **shared-volume** · Required<br>Shared persistent volume to install VS Code into |
| `destination` | **string** · Optional · Default: `/vscode`<br>Directory path within the volume for the VS Code installation |

---

## Notes

- Using `latest` as the version will always install the most current VS Code release available at plugin install time
- VS Code is free and open-source (MIT license) — no license key is required
- VS Code extensions are installed per-user and stored in the user's home directory — attach a home directory volume to workstations to persist extensions across sessions
- For a browser-based VS Code experience without a full desktop, consider the **Web IDE** workload template instead
