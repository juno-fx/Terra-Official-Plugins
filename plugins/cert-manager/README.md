# Certificate Manager

![Certificate Manager](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/cert-manager/assets/logo.png)

**Category:** Infrastructure
**Type:** Cluster Service
**Tags:** `cluster-level`

---

## Overview

Certificate Manager (cert-manager) automates the management and issuance of TLS certificates in Kubernetes. It integrates with a wide range of certificate issuers — including Let's Encrypt, HashiCorp Vault, Venafi, and self-signed CAs — and keeps certificates renewed automatically before they expire. Once installed, other plugins and workloads can request certificates by creating `Certificate` or `Issuer` resources.

For a full list of supported issuers, see the [cert-manager documentation](https://cert-manager.io/docs/configuration/issuers/).

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, any plugin or workload in the cluster can request a TLS certificate automatically — no per-project setup needed.

---

## Prerequisites

- A DNS record or ACME challenge mechanism reachable from the cluster (required when using Let's Encrypt or similar ACME issuers)
- No prior cert-manager installation in the cluster (this plugin manages its own CRD lifecycle)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Certificate Manager"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `chart_version` | **string** · Required · Default: `v1.19.1`<br>The cert-manager Helm chart version to install |

---

## Notes

- After installation, you must create an `Issuer` or `ClusterIssuer` resource to begin issuing certificates — cert-manager itself does not issue certificates without a configured issuer
- See the [cert-manager issuer documentation](https://cert-manager.io/docs/configuration/issuers/) for setup guides for Let's Encrypt, self-signed, and other issuers
- Upgrading cert-manager across major versions may require CRD migration — consult the cert-manager upgrade notes before changing `chart_version`
