# ArgoCD Dashboard

![ArgoCD Dashboard](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/argocd-dashboard/assets/logo.png?raw=true)

**Category:** Infrastructure
**Type:** Cluster Service
**Tags:** `argocd` · `ingress` · `dashboard`
**Bundle:** Orion Essentials

---

## Overview

The ArgoCD Dashboard plugin embeds the ArgoCD web interface directly into your Genesis instance. It publishes the ArgoCD UI under a sub-path on your Genesis host, giving your team a unified view of both the Juno platform and your GitOps deployments without navigating to a separate URL.

> **HTTPS Required:** This plugin works exclusively with Genesis instances accessible via `https://`. HTTP is not supported.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, the ArgoCD dashboard is available to anyone with access to the Genesis URL — no per-project installation needed.

**Access and authentication** — The ingress routes `<prefix>` to a small nginx proxy deployed by this plugin, which checks the user's Genesis login before forwarding the request to `argocd-server`. Because authentication happens in the proxy rather than through ingress-controller annotations, it works the same with any ingress controller (ingress-nginx, Traefik, etc.). ArgoCD's own login is disabled by this plugin, so the proxy is the gate for both the UI and the ArgoCD API.

---

## Prerequisites

- Genesis instance accessible via **HTTPS**
- ArgoCD installed and running in the cluster (standard part of the Juno/Terra platform stack)
- An ingress controller serving the Genesis host (ingress-nginx, Traefik, etc.)
- **Traefik:** a default TLS certificate (`TLSStore`) — without one, the dashboard's streaming connections fail after Traefik reloads with `ERR_CERT_AUTHORITY_INVALID`

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"ArgoCD Dashboard"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

Terra will activate the ArgoCD dashboard for your cluster.

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `host` | **string** · Required<br>The DNS hostname of your Genesis instance (e.g. `genesis.example.com`) |
| `prefix` | **string** · Optional · Default: `/argocd`<br>URL sub-path where the ArgoCD dashboard will be mounted |
| `ingressClass` | **string** · Optional · Default: `nginx`<br>IngressClass for the dashboard route — use the same class as your Genesis ingress (e.g. `traefik`). Set `default` to use the cluster's default IngressClass |

---

## Notes

- This plugin is included in the **Orion Essentials** bundle — you can install the ArgoCD Dashboard, Helios, and the Prometheus Stack together in one step from Terra
- The dashboard is accessible at `https://<host><prefix>` — for example, `https://genesis.example.com/argocd`
- Changing the `prefix` is rarely necessary; the default `/argocd` works in most deployments
- Authentication is handled by Genesis; no additional login is required for ArgoCD via this plugin
- If `ingressClass` doesn't match a controller in the cluster, the route is never served and the dashboard returns 404
