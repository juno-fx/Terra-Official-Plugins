# Wetty

![Wetty](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/wetty/scripts/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `development` · `workload`
**Compatibility:** `genesis-deployment>=1.5.0` · `orion-deployment>=1.5.0`

---

## Overview

Wetty (Web + tty) provides a terminal emulator accessible directly from the browser over HTTP/HTTPS. It gives users a full interactive shell in their project environment without requiring SSH access or a desktop environment. The Wetty workload template lets users launch browser-based terminal sessions directly from Genesis, with support for custom packages, Terra RBAC roles, and optional public access modes.

---

## How It Works

**Workload Template** — Installs the Wetty workload schema into Genesis. Once installed, the Wetty type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision browser-accessible shell sessions on demand within a project through **Hubble**.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 1.5.0`, `orion-deployment >= 1.5.0`

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"wetty"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Wetty schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision terminal sessions on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a terminal session through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `wettyoss`<br>Container registry for the Wetty image |
| `repo` | **string** · Required · Default: `wetty`<br>Wetty image repository |
| `tag` | **string** · Required · Default: `2.5`<br>Wetty image tag |
| `packages` | **string** · Optional · Default: `vim`<br>Space-separated list of additional packages to install at startup |
| `terra_role` | **k8sServiceAccount** · Optional<br>A Terra plugin-level service account role to assign to the terminal (grants Kubernetes RBAC permissions within the project) |
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Container registry for the nginx proxy image |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>nginx proxy image repository |
| `nginx_tag` | **string** · Required · Default: `1.29.3`<br>nginx proxy image tag |
| `publicAccess` | **boolean** · Required · Default: `false`<br>Disable authentication and allow unauthenticated browser access to the terminal |
| `published_ports` | **string** · Optional<br>Extra container ports the ingress controller may reach, comma separated, for example `8000,8080`. Needed to publish an application running inside the session |
| `allow_egress` | **boolean** · Optional · Default: `false`<br>Allow outbound traffic from the session. Off by default, which blocks all egress including DNS |

### Custom Environment Variables

Wetty is a plain tmux/bash shell rather than an application with its own configuration surface — Genesis lets you add arbitrary environment variables to the workload, and these are commonly useful for anything run in the terminal session:

| Variable | Description |
|----------|--------------|
| `TZ` | Timezone for the shell session, e.g. `America/New_York`. |
| `EDITOR` | Default text editor invoked by CLI tools (e.g. `vim`, `nano`). |

---

## Publishing an App Running in the Session

The terminal is served on port 3001 and the NetworkPolicy admits traffic on that port only, so an application started inside the session on another port is unreachable from outside the pod even with a route pointing at it. The failure looks like a timeout rather than an error, which makes it hard to place.

List the ports in `published_ports` and the policy will admit them as well. From there, the Domain Route plugin publishes the port at a hostname with TLS.

The same policy blocks all outbound traffic, including DNS, so an application that calls an API, clones a repository or installs a package needs `allow_egress` turned on as well. Both are off by default, so a session stays as locked down as it is today unless you ask for otherwise.

The terminal keeps its own authenticated route throughout. Publishing an application port does not expose the terminal, and `publicAccess` stays off.

A session serving an application therefore looks like this:

| Field | Value |
|-------|-------|
| `published_ports` | `8000`, the port your application listens on |
| `allow_egress` | `true` if the application needs to reach anything outside the cluster |
| `publicAccess` | left off, the terminal stays authenticated |

then one Domain Route install pointing at the session on port 8000.

---

## Notes

- Setting `publicAccess` to `true` removes all authentication from the terminal — use only in isolated or trusted network environments
- The `terra_role` field assigns a Kubernetes ServiceAccount to the terminal pod, allowing CLI tools in the terminal to interact with Kubernetes resources at the specified permission level
- The `packages` field installs system packages via `apt-get` at workload startup; include any CLI tools your terminal users need
- Wetty is ideal for quick administrative shell access, running scripts, and interacting with cluster resources via `kubectl` or `helm`
