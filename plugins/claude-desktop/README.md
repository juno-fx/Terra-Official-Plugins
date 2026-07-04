# Claude Desktop

![Claude Desktop](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/claude-desktop/assets/logo.png)

**Category:** Workstations
**Type:** Workload Template
**Tags:** `claude` · `desktop` · `vdi` · `selkies`

---

## Overview

Claude Desktop streams the [Claude Desktop app](https://claude.com/download) as a full Linux workstation accessible from any web browser — no client software required. It's built on [LinuxServer.io Webtop](https://docs.linuxserver.io/images/docker-webtop/) images delivered via Selkies-GStreamer, with the Claude Desktop `.deb` installed automatically from Anthropic's official apt repository at container boot and launched fullscreen on desktop startup.

---

## How It Works

**Workload Template** — Installs the Claude Desktop workload schema into Genesis. Once installed, the Claude Desktop type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own browser-accessible Claude Desktop workstation on demand within a project through **Hubble**.

On first boot, a `custom-cont-init.d` script adds Anthropic's apt repository, installs `claude-desktop`, and registers it to autostart with the desktop session. Sign-in and app state persist across restarts via a dedicated `/config` volume — you only need to sign in once.

---

## Prerequisites

- GPU support requires the **NVIDIA GPU Operator** plugin installed on the cluster
- No additional prerequisites for CPU-only workstations
- Outbound internet access from the cluster to `downloads.claude.ai` (apt repository) is required on first boot to install Claude Desktop

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Claude Desktop"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Claude Desktop schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision Claude Desktop workstations on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a Claude Desktop workstation through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `lscr.io/linuxserver`<br>Container registry for the base desktop image |
| `repo` | **string** · Required · Default: `webtop`<br>LinuxServer.io image to launch the desktop from |
| `tag` | **string** · Required · Default: `ubuntu-xfce`<br>Image tag / desktop environment flavor (e.g. `ubuntu-xfce`, `ubuntu-kde`) |
| `gpu` | **boolean** · Required · Default: `false`<br>Attach a GPU for hardware-accelerated rendering |
| `storage_class` | **k8sStorageClass** · Optional<br>Storage class for the persistent config/session volume |
| `storage_size` | **string** · Required · Default: `5Gi`<br>Size of the persistent config/session volume |
| `timezone` | **string** · Optional · Default: `Etc/UTC`<br>Container timezone (TZ database name) |
| `publicAccess` | **boolean** · Required · Default: `false`<br>Disable authentication and allow unauthenticated access |

---

## Notes

- Claude Desktop's Linux support is currently in **beta** and only officially supports Ubuntu/Debian on x64 and arm64 — this is why the plugin defaults to a `ubuntu-xfce` Webtop base rather than another distro flavor
- The app is launched with `--no-sandbox`, since Electron's setuid sandbox does not work in most unprivileged container runtimes
- Setting `publicAccess` to `true` removes authentication from the workstation endpoint — use only in trusted network environments
- The `/config` volume holds the entire desktop home directory, including your signed-in Claude session — deleting it requires signing in again
- GPU acceleration requires compatible NVIDIA hardware and the **NVIDIA GPU Operator** plugin
