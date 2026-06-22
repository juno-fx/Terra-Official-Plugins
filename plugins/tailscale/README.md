# Tailscale

![Tailscale](https://tailscale.gallerycdn.vsassets.io/extensions/tailscale/vscode-tailscale/1.0.0/1698786256133/Microsoft.VisualStudio.Services.Icons.Default)

**Category:** Networking
**Type:** Cluster-Level Plugin
**Tags:** `wireguard` · `vpn` · `tailscale`
**Editable:** Yes

---

## Overview

Tailscale is a WireGuard-based VPN operator that creates a secure, zero-configuration mesh network between your devices and cluster. The Tailscale Kubernetes Operator integrates your cluster into your Tailscale tailnet, enabling private access to cluster services without exposing them publicly — and allowing cluster workloads to reach external services on your tailnet. It simplifies secure remote access without managing firewall rules or traditional VPN gateways.

For full usage documentation, see the [Tailscale Kubernetes Operator guide](https://tailscale.com/kb/1236/kubernetes-operator).

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. The Tailscale Operator manages cluster-wide resources and integration with the Tailscale coordination server.

---

## Prerequisites

- A Tailscale account with an active tailnet
- OAuth client credentials (Client ID and Secret) generated from the [Tailscale admin console](https://login.tailscale.com/admin/settings/oauth)
- The OAuth client must have the `devices:write` scope to allow the operator to register cluster services as Tailscale devices

---

## Installation

1. Generate OAuth credentials in the [Tailscale admin console](https://login.tailscale.com/admin/settings/oauth)
2. Open **Terra** and navigate to the **Plugin Marketplace**
3. Search for **"tailscale"**
4. Click **Install**
5. Fill in the configuration fields below
6. Click **Confirm** to deploy

After deployment, read the [Tailscale Kubernetes Operator documentation](https://tailscale.com/kb/1236/kubernetes-operator) for instructions on exposing services to your tailnet.

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `client_id` | string | **Yes** | — | Tailscale OAuth Client ID |
| `client_secret` | string | **Yes** | — | Tailscale OAuth Client Secret |

---

## Notes

- This plugin is **editable** — you can rotate OAuth credentials after install via Terra
- After installation, expose cluster services to your tailnet by annotating Services with `tailscale.com/expose: "true"`
- Tailscale requires outbound connectivity to the Tailscale coordination server (`login.tailscale.com`) from the cluster
- ACLs and device approval policies are managed in the Tailscale admin console and apply to cluster devices as well as your other tailnet members
