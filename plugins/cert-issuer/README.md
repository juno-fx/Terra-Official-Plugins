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
- No existing ClusterIssuer with the name you choose. Check with `kubectl get clusterissuer`. Many clusters already have one called `letsencrypt-prod`, and if so this install takes it over, replaces its configuration, and deletes it on uninstall, which breaks every certificate that renews through it. Pick another name instead
- For HTTP-01, a hostname already resolving to the cluster ingress address
- For DNS-01, a credential Secret in the cert-manager namespace, see [Credentials](#credentials), or IRSA for Route53

---

## Installation

1. For DNS-01, create the credential Secret first, see [Credentials](#credentials)
2. Open **Terra** and navigate to the **Plugin Marketplace**
3. Search for **"Certificate Issuer"**
4. Click **Install**
5. Fill in the configuration fields below
6. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `issuer_name` | **string** · Required · Default: `letsencrypt-prod`<br>Name of the ClusterIssuer. This is the value workloads put in their `tls_issuer` field. Must not already exist on the cluster, see [Prerequisites](#prerequisites) |
| `email` | **string** · Required<br>Contact address registered with the ACME account, used for account and policy notices. Let's Encrypt stopped sending expiry warnings in June 2025, so renewal relies on cert-manager |
| `acme_server` | **select** · Required · Default: production<br>Let's Encrypt production or staging directory |
| `solver` | **select** · Required · Default: `http01`<br>`http01` or `dns01` |
| `ingress_class` | **string** · Optional · Default: `nginx`<br>Ingress class used to serve the HTTP-01 challenge |
| `dns_provider` | **select** · Optional · Default: `cloudflare`<br>`cloudflare` or `route53`, used only with `dns01` |
| `secret_namespace` | **string** · Optional · Default: `cert-manager`<br>Namespace the credential Secret is created in. Must be the namespace cert-manager runs in |
| `secret_name` | **string** · Optional<br>Name of the credential Secret in `secret_namespace`. Required for Cloudflare. For Route53, leave empty to use ambient credentials such as IRSA |
| `secret_key` | **string** · Optional<br>Key holding the Cloudflare API token. Route53 reads fixed key names, see [Credentials](#credentials) |
| `aws_hosted_zone_id` | **string** · Optional<br>Route53 hosted zone id. Leave empty to let cert-manager discover the zone |

---

## Credentials

The plugin never takes a credential as a form value. For DNS-01 you create a Secret, then point the plugin at it with `secret_namespace`, `secret_name` and `secret_key`.

`secret_namespace` has to be the namespace cert-manager runs in, `cert-manager` when installed from Terra, which is the default. A ClusterIssuer's Secret references carry no namespace of their own: cert-manager always reads them from its own namespace, so a Secret created anywhere else is never found. The field is there so the Secret's location is stated in the form, as it is for the other plugins that take a credential Secret, not because the Secret can live elsewhere.

### Cloudflare

Store the API token under a single key:

```bash
kubectl create secret generic cloudflare-api-token \
  --namespace cert-manager \
  --from-literal=api-token=YOUR_TOKEN
```

Then set `secret_name` to `cloudflare-api-token` and `secret_key` to `api-token`. The token needs `Zone:Read` and `DNS:Edit` on the zones being certified, nothing else.

### Route53

cert-manager needs the access key id and the secret access key as two separate values, so the Secret holds both under these fixed key names:

```bash
kubectl create secret generic aws-dns-credentials \
  --namespace cert-manager \
  --from-literal=aws_access_key_id=YOUR_ACCESS_KEY \
  --from-literal=aws_secret_access_key=YOUR_SECRET_KEY
```

Then set `secret_name` to `aws-dns-credentials`. `secret_key` is not used for Route53.

On EKS with IRSA, leave `secret_name` empty and cert-manager uses the role attached to its own ServiceAccount.

The IAM identity needs `route53:GetChange`, `route53:ChangeResourceRecordSets` and `route53:ListResourceRecordSets` on the zone, plus `route53:ListHostedZonesByName` when `aws_hosted_zone_id` is left empty.

cert-manager does not share credentials with the ExternalDNS plugin even when both talk to the same provider, so each holds its own Secret in its own namespace.

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
- Route53 has no regional endpoints, but the AWS SDK still wants a region to sign requests, so the issuer sets `us-east-1`. cert-manager ignores it on EKS with IRSA, where the pod identity webhook provides the region
- Choosing Cloudflare without naming a Secret and key stops the install with a message saying what to set, rather than deploying an issuer that can never become ready
