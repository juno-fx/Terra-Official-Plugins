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

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the JupyterLab workload type in the workload creation UI. Individual Jupyter servers are launched by Kuiper when users create workloads.

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

Once installed, the JupyterLab workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a JupyterLab workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `registry` | string | **Yes** | `quay.io/jupyter` | Container registry for the Jupyter image |
| `repo` | string | **Yes** | `datascience-notebook` | Jupyter image repository (must be a Jupyter docker-stacks compatible image) |
| `tag` | string | **Yes** | `lab-4.4.9` | Image tag (version of JupyterLab) |
| `gpu` | boolean | **Yes** | — | Enable GPU access for the notebook server |

---

## Notes

- Use images from the [Jupyter Docker Stacks](https://quay.io/organization/jupyter) such as `datascience-notebook`, `scipy-notebook`, or `tensorflow-notebook` for a pre-configured environment
- To persist notebooks, add a volume mount for `/home/` when creating the workload in Genesis
- GPU support requires the **NVIDIA GPU Operator** plugin to be installed on the cluster
- Notebooks run with the project user's UID/GID — ensure mounted volumes have appropriate permissions
