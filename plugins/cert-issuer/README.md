# Certificate Issuer

![Certificate Issuer](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/cert-issuer/assets/icon.svg?raw=true)

**Category:** Infrastructure
**Type:** Cluster Service
**Tags:** `cluster-level` · `networking` · `tls` · `dns`

---

## Overview

The Certificate Manager plugin installs the cert-manager controller, but cert-manager issues nothing until a `ClusterIssuer` exists. This plugin creates that issuer from the app store, so a cluster can go from a fresh cert-manager install to issuing Let's Encrypt certificates without applying YAML by hand.

Once installed, any Ingress in the cluster can request a certificate by carrying the `cert-manager.io/cluster-issuer` annotation and a `tls` block. Workload templates that support custom domains reference this issuer through their `tls_issuer` field.

---

## How It Works

**Cluster Service** - Installed once per cluster by an administrator. It creates a single `ClusterIssuer` and, when a DNS-01 challenge is used, the Secret holding the provider credential.

Two challenge types are supported:

- **HTTP-01** serves a token over port 80 on the hostname being certified. The hostname must already resolve to this cluster before a certificate can be issued. It cannot issue wildcard certificates.
- **DNS-01** proves ownership by writing a TXT record, so the hostname does not need to resolve yet, and it is the only option that can issue a wildcard certificate such as `*.apps.example.com`. It needs a credential for the DNS provider.

---

## Prerequisites

- The Certificate Manager plugin installed and healthy
- For HTTP-01, a hostname already resolving to the cluster ingress address
- For DNS-01, an API token for Cloudflare, or an access key or IRSA role for Route53

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Certificate Issuer"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `issuer_name` | **string** · Required · Default: `letsencrypt-prod`<br>Name of the ClusterIssuer. This is the value workloads put in their `tls_issuer` field |
| `email` | **string** · Required<br>Contact address registered with the ACME account, used for expiry warnings |
| `acme_server` | **select** · Required · Default: production<br>Let's Encrypt production or staging directory |
| `solver` | **select** · Required · Default: `http01`<br>`http01` or `dns01` |
| `ingress_class` | **string** · Optional · Default: `nginx`<br>Ingress class used to serve the HTTP-01 challenge |
| `dns_provider` | **select** · Optional · Default: `cloudflare`<br>`cloudflare` or `route53`, used only with `dns01` |
| `dns_secret_name` | **string** · Optional<br>Existing Secret in the cert-manager namespace holding the credential. Leave empty to have the plugin create one from `dns_token` |
| `dns_secret_key` | **string** · Optional · Default: `token`<br>Key inside that Secret |
| `dns_token` | **string** · Optional<br>Cloudflare API token or AWS secret access key, used only when `dns_secret_name` is empty |
| `aws_region` | **string** · Optional · Default: `us-east-1`<br>Region for the route53 provider |
| `aws_hosted_zone_id` | **string** · Optional<br>Route53 hosted zone id. Leave empty to let cert-manager discover the zone |
| `aws_access_key_id` | **string** · Optional<br>Access key id for route53. Leave empty on EKS to use IRSA or node credentials |
| `cert_manager_namespace` | **string** · Required · Default: `cert-manager`<br>Namespace cert-manager runs in, where challenge credentials are read from |

---

## Credentials

`dns_token` is written into the plugin's Helm values, which means it is visible in the ArgoCD Application spec. Terra has no secret field type yet, so for anything holding a production DNS credential, create the Secret out of band and reference it with `dns_secret_name` instead:

```bash
kubectl create secret generic cloudflare-api-token \
  --namespace cert-manager \
  --from-literal=token=<your token>
```

The Cloudflare token needs `Zone:Read` and `DNS:Edit` on the zones being certified. Nothing else.

cert-manager does not share credentials with the ExternalDNS plugin even when both talk to the same provider, so each holds its own token.

---

## Requesting a Certificate

Annotate an Ingress and give it a `tls` block:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts: [app.example.com]
      secretName: app-tls
```

cert-manager runs the challenge, writes the certificate into `app-tls`, and renews it before expiry.

---

## Notes

- Test with the staging directory first. Production Let's Encrypt limits duplicate certificates to five per week, and a misconfigured issuer can burn through that while you debug
- Check progress with `kubectl describe clusterissuer <name>` and `kubectl get certificate -A`. A certificate stuck in `False` usually means the challenge cannot be reached, not that the issuer is wrong
- Wildcard certificates require `dns01`. HTTP-01 has no way to prove ownership of every name under a domain
- The issuer is cluster wide, so one install serves every project and every workload
- Changing `issuer_name` after workloads reference it leaves those workloads pointing at an issuer that no longer exists. Keep the name stable
