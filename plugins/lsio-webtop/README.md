# LSIO Webtop

![LSIO Webtop](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/lsio-webtop/scripts/assets/logo.png)

**Category:** Workstations
**Type:** Workload Template
**Tags:** `selkies` · `vdi` · `lsio`

---

## Overview

LSIO Webtop is a containerized desktop workstation built on [LinuxServer.io](https://linuxserver.io) images, delivered through the browser via Selkies-GStreamer. It provides a full Linux desktop experience accessible from any web browser without VPN or client software. Webtop supports GPU acceleration and is highly configurable — you can launch any LinuxServer.io Webtop image as a workload, from lightweight browser environments to full desktop systems.

---

## How It Works

**Workload Template** — Installs the LSIO Webtop workload schema into Genesis. Once installed, the Webtop type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own browser-accessible Linux desktop on demand within a project through **Hubble**.

**Access and authentication** — Each instance runs with an nginx sidecar in the same pod. The ingress routes `/<namespace>/webtop/<workload-name>/` to the sidecar, which checks the user's Hubble login before forwarding the request to Webtop. Because authentication happens inside the pod rather than through ingress-controller annotations, it works the same with any ingress controller (ingress-nginx, Traefik, etc.).

---

## Prerequisites

- An ingress controller in the cluster (ingress-nginx, Traefik, etc.)
- GPU support requires the **NVIDIA GPU Operator** plugin installed on the cluster
- No additional prerequisites for CPU-only Webtop workloads

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"LSIO Webtop"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the LSIO Webtop schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision Webtop desktops on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a Webtop desktop through **Hubble**:

| Field | Details |
|-------|---------|
| `gpu` | **boolean** · Required<br>Enable GPU passthrough for the workstation |
| `registry` | **string** · Required · Default: `lscr.io/linuxserver`<br>Container registry for the Webtop image |
| `repo` | **string** · Required · Default: `chrome`<br>LinuxServer.io image to launch (e.g. `chrome`, `firefox`, `ubuntu-mate`, `kde`) |
| `tag` | **string** · Required · Default: `latest`<br>Image tag |
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Registry to pull the nginx sidecar image from |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>Repository to pull the nginx sidecar image from |
| `nginx_tag` | **string** · Required · Default: `alpine`<br>Tag to pull the nginx sidecar image from |
| `publicAccess` | **boolean** · Required · Default: `false`<br>Disable authentication and allow unauthenticated access |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for a LinuxServer.io Webtop image:

| Variable | Description |
|----------|--------------|
| `CUSTOM_USER` | Username for HTTP basic auth in front of the desktop. |
| `PASSWORD` | Password for HTTP basic auth, used together with `CUSTOM_USER`. |
| `DOCKER_MODS` | LinuxServer.io mod(s) to install at container start, e.g. additional apps or tools. |
| `TZ` | Timezone for the desktop session, e.g. `America/New_York`. |

---

## Notes

- Browse available LinuxServer.io Webtop images at [lscr.io/linuxserver](https://fleet.linuxserver.io/?search=webtop) — the `repo` field maps to the image name (e.g. `chrome`, `ubuntu-kde`)
- Authentication is handled by the nginx sidecar, which checks the user's Hubble login
- Setting `publicAccess` to `true` makes the sidecar skip the Hubble login check — use only in trusted network environments
- The workload's network policy only accepts inbound traffic on the nginx sidecar port (8080); Webtop's own ports (3000/3001) are not reachable from elsewhere in the cluster. It sets no egress rules, so outbound access is controlled entirely by your namespace/cluster
- The ingress uses the `nginx` IngressClass by default; Kuiper 4.8.0 and later replaces it with the launching namespace's IngressClass
- GPU acceleration requires compatible NVIDIA hardware and the **NVIDIA GPU Operator** plugin
- Webtop workstations are stateless by default; add volume mounts via Genesis at workload creation time to persist user data
