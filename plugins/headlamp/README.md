# Headlamp

<img src="https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/headlamp/assets/logo.png?raw=true" alt="Headlamp" width="80" />

**Category:** Infrastructure
**Type:** Cluster Service
**Tags:** `dashboard` · `kubernetes` · `web-interface` · `management` · `monitoring` · `admin`

---

## Overview

Headlamp is a web-based Kubernetes dashboard that provides a clean, user-friendly interface for managing Kubernetes clusters. It allows operators and developers to view and interact with cluster resources (Pods, Deployments, Services, ConfigMaps, etc.), perform administrative tasks, and monitor cluster health — all from a browser. Headlamp is extensible via plugins and is designed as a production-ready alternative to the default Kubernetes dashboard.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, the Headlamp dashboard is accessible at the configured URL for anyone with cluster access — no per-project installation needed.

---

## Prerequisites

- A DNS record pointing to your cluster's ingress controller for the Headlamp host
- An nginx ingress controller configured in the cluster

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Headlamp"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `host` | **string** · Required<br>Hostname for the Headlamp dashboard (e.g. `headlamp.example.com`). A DNS record pointing to your cluster's ingress must exist. |
| `prefix` | **string** · Optional · Default: `/`<br>URL sub-path to mount Headlamp under (e.g. `/headlamp`) |

---

## Notes

- You must create a DNS record pointing `host` to your cluster's ingress controller IP before the dashboard is accessible
- Headlamp is free and open-source (Apache 2.0 license)
- Headlamp provides read/write access to Kubernetes resources — ensure access is restricted appropriately for your environment
- For team environments, consider configuring Headlamp with your cluster's OIDC provider for authenticated access
