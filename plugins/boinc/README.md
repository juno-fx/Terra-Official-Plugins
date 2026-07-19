# BOINC

**Category:** Computing
**Type:** Workload Template
**Tags:** `computing` · `science` · `distributed-computing`

---

## Overview

BOINC (Berkeley Open Infrastructure for Network Computing) is an open-source volunteer computing platform that uses your computer's CPU/GPU for scientific research — curing diseases, studying climate change, discovering pulsars, and more. This workload template deploys the [LinuxServer.io](https://github.com/linuxserver/docker-boinc) BOINC desktop container, providing a web GUI to manage BOINC client projects and work units.

Each workload provisions a BOINC client with a persistent volume at `/config` to retain configuration across restarts. The web GUI is accessible via browser at the workload's endpoint URL. Optional GPU acceleration is available for compatible BOINC projects.

**Architecture support:** amd64 and arm64 — use tag `latest` (multi-arch) or pin with `arm64v8-latest` for ARM clusters.

---

## How It Works

**Workload Template** — Installs the BOINC schema into Genesis. Once installed, the BOINC type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision BOINC manager instances on demand within a project through **Hubble**. After launch, access the BOINC Manager GUI through the Hubble endpoint list to attach to projects, monitor progress, and configure settings.

---

## Prerequisites

- A **StorageClass** must be available for the BOINC config PVC (mounted at `/config`)
- For GPU-accelerated workloads: **NVIDIA GPU Operator** plugin must be installed and nodes must have the `nvidia` runtime class configured

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"BOINC"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the BOINC schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision BOINC manager instances through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a BOINC instance through **Hubble**:

| Field           | Details                                                                                                             |
|-----------------|---------------------------------------------------------------------------------------------------------------------|
| `registry`      | **string** · Required · Default: `lscr.io`<br>Container registry for the BOINC image                                |
| `repo`          | **string** · Required · Default: `linuxserver/boinc`<br>BOINC image repository                                      |
| `tag`           | **string** · Required · Default: `latest`<br>Image tag — use `latest` for current, `arm64v8-latest` for ARM64       |
| `gpu`           | **boolean** · Required · Default: `false`<br>Attach a GPU; sets `runtimeClassName: nvidia`                          |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the BOINC config PVC mounted at `/config`                       |
| `storage_size`  | **string** · Optional · Default: `10Gi`<br>Size of the BOINC config persistent volume                               |
| `arch`          | **select** · Required · Default: `amd64`<br>Target CPU architecture — `amd64`, `arm64`, or `either` (no constraint) |

### Custom Environment Variables

Genesis has a built-in `env` field for adding arbitrary environment variables at workload launch. These are commonly useful for the BOINC workload:

| Variable      | Description                                               |
|---------------|-----------------------------------------------------------|
| `PASSWORD`    | Password for the BOINC web GUI — enables HTTP basic auth  |
| `TZ`          | Timezone for log timestamps (e.g. `America/New_York`)     |
| `PUID`        | User ID for file permissions on `/config` (default: `99`) |
| `PGID`        | Group ID for file permissions on `/config` (default: `99`) |

---

## Notes

- GPU-accelerated BOINC requires the **NVIDIA GPU Operator** plugin and cluster nodes with NVIDIA GPUs
- The config PVC is mounted at `/config` — BOINC state and project configuration persist across pod restarts
- Access the BOINC web GUI through the workload endpoint in **Hubble** after launch
- The BOINC Manager GUI is used to attach to projects, manage work units, and monitor progress
- This workload uses the LinuxServer.io BOINC image — see the [upstream documentation](https://github.com/linuxserver/docker-boinc) for advanced configuration
- Both `amd64` and `arm64` architectures are supported
