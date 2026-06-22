# Minecraft

![Minecraft](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/minecraft/scripts/assets/icon.png)

**Category:** Gaming
**Type:** Workload Template
**Tags:** `minecraft` · `sandbox` · `multiplayer` · `block-building`
**Compatibility:** `genesis-deployment>=3.0.0-beta.1` · `orion-deployment>=3.0.0-beta.1`

---

## Overview

The Minecraft plugin provides a workload template for launching self-hosted Minecraft server instances directly from the Genesis workload UI. Each Minecraft workload gets its own persistent world storage and can be configured with any Minecraft server image from the popular `itzg/minecraft-server` Docker image family — supporting Java Edition, Bedrock, PaperMC, Forge, Fabric, and many more modpacks.

---

## How It Works

**Workload Template** — Adds the Minecraft server type to Genesis. Once installed, users can launch their own Minecraft server directly from the Genesis workload screen, with its own persistent world storage.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 3.0.0-beta.1`, `orion-deployment >= 3.0.0-beta.1`
- A Kubernetes storage class available in the cluster for world data persistence

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Minecraft"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Minecraft workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a Minecraft workload in **Genesis**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `itzg`<br>Container registry for the Minecraft server image |
| `repo` | **string** · Required · Default: `minecraft-server`<br>Minecraft server image repository |
| `tag` | **string** · Required · Default: `latest`<br>Image tag (controls server version and type) |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the world data persistent volume |
| `storage_size` | **string** · Required · Default: `10Gi`<br>Size of the persistent volume for world data |

---

## Notes

- The `itzg/minecraft-server` image family supports many server types (Java, Bedrock, PaperMC, Forge, Fabric) controlled via environment variables — configure server type and version through Genesis workload environment variables at launch time
- World data persists across workload restarts as long as the persistent volume is retained
- Multiplayer access requires a NodePort or LoadBalancer service — configure port exposure through Genesis workload settings
- See the [itzg/minecraft-server documentation](https://docker-minecraft-server.readthedocs.io/) for available image tags and environment variables
