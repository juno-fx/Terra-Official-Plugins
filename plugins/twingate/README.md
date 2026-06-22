# Twingate

![Twingate](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/twingate/scripts/assets/twingate.png)

**Category:** Networking
**Type:** Cluster-Level Plugin
**Tags:** `zero-trust` · `vpn` · `twingate`
**Editable:** Yes

---

## Overview

Twingate is a Zero Trust Network Access (ZTNA) solution that replaces traditional VPNs with a modern, identity-based access model. The Twingate Kubernetes Operator integrates your cluster into a Twingate network, enabling private, authenticated access to cluster services for users and devices — without exposing services publicly or managing firewall rules. Access is controlled per-user and per-service through the Twingate admin console.

For setup instructions, see the [Twingate Kubernetes Operator Getting Started guide](https://github.com/Twingate/kubernetes-operator/wiki/Getting-Started).

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. The Twingate Operator manages cluster-wide resources and communication with the Twingate control plane.

---

## Prerequisites

- A Twingate account with an active network
- An API key, Network Slug, and Remote Network ID from the Twingate admin console
- Network Slug is visible in the Twingate admin console URL
- Remote Network ID is shown in the URL when you select a Remote Network in the admin console

---

## Installation

1. Gather your credentials from the [Twingate admin console](https://www.twingate.com/)
2. Open **Terra** and navigate to the **Plugin Marketplace**
3. Search for **"twingate"**
4. Click **Install**
5. Fill in the configuration fields below
6. Click **Confirm** to deploy

After deployment, follow the [Twingate operator guide](https://github.com/Twingate/kubernetes-operator/wiki/Getting-Started) to configure Resources and access policies.

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `api_key` | string | **Yes** | — | Twingate API Key from the admin console |
| `network` | string | **Yes** | — | Twingate Network Slug (visible in the admin console URL) |
| `remote_network_id` | string | **Yes** | — | Twingate Remote Network ID (from the URL when selecting a Remote Network) |

---

## Notes

- This plugin is **editable** — you can rotate the API key and update network settings after install via Terra
- After installation, define Twingate `Resource` objects to specify which cluster services are accessible to which users
- Twingate uses a connector running in the cluster to broker connections; the connector must have outbound internet access to reach the Twingate control plane
- Users access cluster services through the Twingate client app (desktop or mobile) — no VPN client configuration is required
