# JupyterLab Notebook

![JupyterLab](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/jupyter-notebook/assets/logo.png)

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
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Registry to pull the nginx sidecar image from |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>Repository to pull the nginx sidecar image from |
| `nginx_tag` | **string** · Required · Default: `alpine`<br>Tag to pull the nginx sidecar image from |
| `gpu` | **boolean** · Required · Default: `false`<br>Attach one GPU to the notebook. The notebook holds the whole GPU while it runs. |
| `gpu_vendor` | **select** · Optional · Default: `nvidia` · Options: `nvidia`, `amd`<br>Which vendor's GPU to request when `gpu` is on: `nvidia` renders `nvidia.com/gpu` (NVIDIA GPU Operator), `amd` renders `amd.com/gpu` (AMD GPU Operator). Ignored when `gpu` is off. |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for a Jupyter Docker Stacks image:

| Variable | Description |
|----------|--------------|
| `GRANT_SUDO` | Set to `yes` (or `1`; `true` is ignored) to grant the notebook user passwordless sudo, useful for installing OS packages with apt from within the notebook's terminal. |
| `RESTARTABLE` | Runs Jupyter in a restart loop so quitting or a kernel restart doesn't kill the container. |
| `DOCKER_STACKS_JUPYTER_CMD` | Launches a different frontend (`notebook`, `nbclassic`, `retro`) instead of the default JupyterLab. |

---

## Notes

- Use images from the [Jupyter Docker Stacks](https://quay.io/organization/jupyter) such as `datascience-notebook`, `scipy-notebook`, or `tensorflow-notebook` for a pre-configured environment
- To persist notebooks, add a volume mount for `/home/` when creating the workload in Genesis
- `gpu` on with `gpu_vendor: nvidia` requires the **NVIDIA GPU Operator** plugin on the cluster
- `gpu` on with `gpu_vendor: amd` requires the **AMD GPU Operator** plugin on the cluster. A pod can request one vendor only; on a mixed cluster the admin presets `gpu_vendor` per template (or users pick at launch)
- With `gpu_vendor: amd`, a start-up hook makes the injected `/dev/kfd` and `/dev/dri/*` device nodes usable by the notebook user (root-owned nodes are opened to `0666` inside the container; host-group-owned nodes get the user added to that group). This relies on the Jupyter docker-stacks `start.sh` hook directory, so use a docker-stacks based image. ROCm user-space libraries are not part of the default images. Install a PyTorch ROCm wheel whose ROCm generation matches the node (e.g. `pip install torch --index-url https://download.pytorch.org/whl/rocm7.2`); a plain `pip install torch` gives the CUDA build, and a mismatched ROCm generation can segfault on first kernel launch (seen with a `rocm7.0` wheel on a Strix Halo node running a 7.2 kernel)
- Notebooks run with the project user's UID/GID — ensure mounted volumes have appropriate permissions
