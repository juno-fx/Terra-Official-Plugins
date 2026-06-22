# ArgoCD Dashboard

![ArgoCD Dashboard](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/argocd-dashboard/assets/logo.png?raw=true)

**Category:** Infrastructure
**Type:** Cluster-Level Plugin
**Tags:** `argocd` · `ingress` · `ingress-nginx` · `dashboard`

---

## Overview

The ArgoCD Dashboard plugin embeds the ArgoCD web interface directly into your Genesis instance. It configures an nginx ingress rule that proxies the ArgoCD UI under a sub-path on your Genesis host, giving your team a unified view of both the Juno platform and your GitOps deployments without navigating to a separate URL.

> **HTTPS Required:** This plugin works exclusively with Genesis instances accessible via `https://`. HTTP is not supported.

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace by Terra. This plugin manages cluster-wide ingress resources and is shared across all projects in the cluster.

---

## Prerequisites

- Genesis instance accessible via **HTTPS**
- ArgoCD installed and running in the cluster (standard part of the Juno/Terra platform stack)
- An nginx ingress controller configured in the cluster

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"ArgoCD Dashboard"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

Terra will create an ArgoCD `Application` resource that syncs this plugin into the `argocd` namespace.

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `host` | string | **Yes** | — | The DNS hostname of your Genesis instance (e.g. `genesis.example.com`) |
| `prefix` | string | No | `/argocd` | URL sub-path where the ArgoCD dashboard will be mounted |

---

## Notes

- The dashboard is accessible at `https://<host><prefix>` — for example, `https://genesis.example.com/argocd`
- Changing the `prefix` is rarely necessary; the default `/argocd` works in most deployments
- Authentication is handled by Genesis; no additional login is required for ArgoCD via this plugin
