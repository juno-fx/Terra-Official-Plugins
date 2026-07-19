# BOINC

**Category:** Computing
**Type:** Workload Template
**Tags:** `computing` · `science` · `distributed-computing`

---

## Overview

BOINC (Berkeley Open Infrastructure for Network Computing) is an open-source volunteer computing platform that uses your computer's CPU/GPU for scientific research — curing diseases, studying climate change, discovering pulsars, and more. This workload template deploys a BOINC client that connects to a project of your choice and begins processing work units.

Each workload instance provisions a BOINC client with a persistent volume at `/var/lib/boinc` to retain work-in-progress across restarts. Optional GPU support is available via the `nvidia` runtime class.

---

## How It Works

**Workload Template** — Installs the BOINC schema into Genesis. Once installed, the BOINC type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision BOINC compute nodes on demand within a project through **Hubble**.

---

## Prerequisites

- A **StorageClass** must be available for the BOINC data PVC
- For GPU-accelerated workloads: **NVIDIA GPU Operator** plugin must be installed and nodes must have the `nvidia` runtime class configured
- A BOINC **weak account key** for the target project (obtain this from the project's website)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"BOINC"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the BOINC schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision BOINC compute nodes through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a BOINC node through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry for the BOINC image |
| `repo` | **string** · Required · Default: `osgiliath/boinc`<br>BOINC image repository |
| `tag` | **string** · Required · Default: `nvidia`<br>BOINC image tag — use `nvidia` for CUDA GPU support |
| `project_url` | **string** · Required<br>BOINC project URL (e.g. `https://universeathome.pl/universe/`) |
| `account_key` | **string** · Required<br>Weak account key for authenticating with the project |
| `gpu` | **boolean** · Required · Default: `false`<br>Attach a GPU; sets `runtimeClassName: nvidia` |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the BOINC data PVC mounted at `/var/lib/boinc` |
| `storage_size` | **string** · Optional · Default: `10Gi`<br>Size of the BOINC data persistent volume |
| `arch` | **select** · Required · Default: `amd64`<br>Target CPU architecture — `amd64`, `arm64`, or `either` (no constraint) |

### Custom Environment Variables

The BOINC client image has no commonly used custom environment variables beyond the project URL and account key configured above.

---

## Notes

- GPU-accelerated BOINC requires the **NVIDIA GPU Operator** plugin and cluster nodes with NVIDIA GPUs
- The data PVC is mounted at `/var/lib/boinc` — BOINC state and work units persist across pod restarts
- To check BOINC status or attach to additional projects, exec into the pod and use `boinccmd`
- This workload runs as a headless compute service — there is no web UI
