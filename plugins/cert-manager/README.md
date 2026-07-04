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

## Issuing Certificates (Required — Not Automatic)

Installing this plugin only installs the cert-manager controller and CRDs. It does **not** issue any certificates by itself — nothing happens until you create two more resources yourself.

Neither this plugin nor cert-manager creates these for you — they're plain Kubernetes manifests you must apply to the cluster yourself, e.g. `kubectl apply -f cluster-issuer.yaml`, or commit them to a repo your GitOps tooling (ArgoCD) watches.

### 1. An Issuer or ClusterIssuer

Tells cert-manager *where* to get certs from and how to prove domain ownership. `Issuer` is namespace-scoped, `ClusterIssuer` works cluster-wide. Example, Let's Encrypt via HTTP-01 challenge:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: you@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

For wildcard certs you need a **DNS-01** challenge instead of HTTP-01 — this requires a `solvers[].dns01` block with credentials for your DNS provider (Route53, Cloudflare, etc.). These credentials are configured independently in the Issuer — cert-manager does not share credentials with the ExternalDNS plugin, even if both target the same DNS provider.

### 2. A certificate request

Either an explicit `Certificate` object, or — more commonly — an annotation on your Ingress:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts: [myapp.example.com]
      secretName: myapp-tls
```

Once both exist, cert-manager sees the annotated Ingress, runs the challenge, fetches the cert, stores it in the named Secret, and auto-renews before expiry. Skip either piece and no certificate ever gets issued.

---

## Notes

- After installation, you must create an `Issuer` or `ClusterIssuer` resource to begin issuing certificates — cert-manager itself does not issue certificates without a configured issuer (see [Issuing Certificates](#issuing-certificates-required--not-automatic) above)
- See the [cert-manager issuer documentation](https://cert-manager.io/docs/configuration/issuers/) for setup guides for Let's Encrypt, self-signed, and other issuers
- Upgrading cert-manager across major versions may require CRD migration — consult the cert-manager upgrade notes before changing `chart_version`
