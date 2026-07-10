# JupyterLab Notebook

![JupyterLab](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/jupyter-notebook/scripts/assets/logo.png)

**Category:** Data Science
**Type:** Workload Template
**Tags:** `workload` · `data-science` · `development`

---

## Overview

JupyterLab is the latest web-based interactive development environment for notebooks, code, and data. Its flexible interface allows users to configure and arrange workflows in data science, scientific computing, computational journalism, and machine learning. The JupyterLab workload template lets users launch personal Jupyter instances directly from Genesis using any Jupyter-compatible Docker image.

> **Storage Note:** Notebook data is **not persisted** by default unless you attach storage mounts for `/home/` at workload launch time. Notebooks run as your project's user and inherit their UIDs. The home directory is expected to be mounted at `/home/<username>`.

---

## How It Works

**Workload Template** — Installs the JupyterLab workload schema into Genesis. Once installed, the JupyterLab type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own notebook server on demand within a project through **Hubble**.

---

## Prerequisites

- A compatible Jupyter Docker image (see the [Jupyter Docker Stacks](https://quay.io/organization/jupyter) for ready-to-use images)
- Persistent storage (recommended) configured as a volume mount for `/home/` to preserve notebooks across sessions

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"jupyter-notebook"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the JupyterLab schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision notebook servers on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a notebook server through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `quay.io/jupyter`<br>Container registry for the Jupyter image |
| `repo` | **string** · Required · Default: `datascience-notebook`<br>Jupyter image repository (must be a Jupyter docker-stacks compatible image) |
| `tag` | **string** · Required · Default: `lab-4.4.9`<br>Image tag (version of JupyterLab) |
| `gpu` | **boolean** · Required<br>Enable GPU access for the notebook server |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for a Jupyter Docker Stacks image:

| Variable | Description |
|----------|--------------|
| `GRANT_SUDO` | Grants the notebook user passwordless sudo, useful for installing OS packages with apt from within the notebook's terminal. |
| `RESTARTABLE` | Runs Jupyter in a restart loop so quitting or a kernel restart doesn't kill the container. |
| `DOCKER_STACKS_JUPYTER_CMD` | Launches a different frontend (`notebook`, `nbclassic`, `retro`) instead of the default JupyterLab. |

---

## Notes

- Use images from the [Jupyter Docker Stacks](https://quay.io/organization/jupyter) such as `datascience-notebook`, `scipy-notebook`, or `tensorflow-notebook` for a pre-configured environment
- To persist notebooks, add a volume mount for `/home/` when creating the workload in Genesis
- GPU support requires the **NVIDIA GPU Operator** plugin to be installed on the cluster
- Notebooks run with the project user's UID/GID — ensure mounted volumes have appropriate permissions
