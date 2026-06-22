# Miniconda

![Miniconda](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/miniconda/scripts/assets/logo.png)

**Category:** Development
**Type:** Namespaced Plugin
**Tags:** `miniconda` · `python`

---

## Overview

The Miniconda plugin provides a lightweight, self-contained Python environment management solution for project workstations. It installs Miniconda to a shared persistent volume, creates a named conda environment with a specified Python version, and optionally installs additional packages. All workstations in the project that mount the shared volume can immediately use the managed conda environment without any additional setup.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin runs an installer Job that downloads Miniconda, installs it to the target volume, and creates the configured conda environment.

---

## Prerequisites

- A shared persistent volume provisioned in your project
- Outbound internet access from the cluster (to download the Miniconda installer and conda packages)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Miniconda"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `install_volume` | shared-volume | **Yes** | — | Shared persistent volume to install Miniconda into |
| `destination` | string | No | `/miniconda` | Directory path within the volume for the Miniconda installation |
| `environment_name` | string | **Yes** | `base` | Name of the conda environment to create |
| `python_version` | string | **Yes** | `3.12` | Python version to use in the conda environment (e.g. `3.10`, `3.11`, `3.12`) |
| `packages` | string | No | `""` | Space-separated list of additional conda/pip packages to install (e.g. `numpy pandas scikit-learn`) |
| `source_url` | string | No | Miniconda official URL | Custom URL to the Miniconda installer script (overrides the default download source) |

---

## Notes

- Miniconda is a minimal installer for conda — it includes only conda, Python, and a small set of useful packages. Additional packages are installed via the `packages` field or within workstations using `conda install`
- The `source_url` field is useful for air-gapped environments that mirror installer scripts internally
- To use the conda environment from workstations, activate it with `conda activate <environment_name>` or reference the full path at `<destination>/envs/<environment_name>/bin/python`
