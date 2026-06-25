# PyCharm

![PyCharm](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/pycharm/scripts/assets/pycharm.png?raw=true)

**Category:** Software Development
**Type:** Software Installer
**Tags:** `pycharm` · `ide` · `python` · `development` · `jetbrains`

---

## Overview

PyCharm is the professional Python IDE from JetBrains, offering intelligent code completion, on-the-fly error detection, powerful refactoring tools, integrated debugging, and support for web frameworks like Django and FastAPI. The PyCharm plugin installs a specified version of PyCharm to a shared persistent volume, making it available to all development workstations in your project.

---

## How It Works

**Software Installer** — When added to a project, Terra downloads and extracts PyCharm to the shared volume you specify. Once complete, PyCharm is available at that path for every workstation in the project that mounts the volume.

---

## Prerequisites

- A shared persistent volume provisioned in your project
- A valid JetBrains PyCharm license (Community Edition is free; Professional Edition requires a subscription)
- Workstations with a desktop environment (e.g. **Helios** or **LSIO Webtop**) to run the PyCharm GUI

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"pycharm"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `version` | **string** · Required · Default: `2025.2`<br>PyCharm version to install (e.g. `2025.2`, `2024.3`) |
| `install_volume` | **shared-volume** · Required<br>Shared persistent volume to install PyCharm into |
| `destination` | **string** · Optional · Default: `/pycharm`<br>Directory path within the volume for the PyCharm installation |

---

## Notes

- The installer downloads PyCharm from JetBrains' release servers; outbound internet access from the cluster is required
- PyCharm Community Edition is free and open-source; PyCharm Professional requires a JetBrains subscription or license server
- The version string must match an available JetBrains release (e.g. `2025.2`, `2024.3.3`)
- If `destination` is left blank, PyCharm installs to `/pycharm` on the selected volume
- To activate PyCharm Professional, use the JetBrains license activation dialog within the application at first launch
