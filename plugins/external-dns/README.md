# ExternalDNS

![ExternalDNS](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/external-dns/assets/logo.png)

**Category:** Networking
**Type:** Cluster Service
**Tags:** `cluster-level` · `dns` · `networking`

---

## Overview

ExternalDNS synchronizes exposed Kubernetes Services and Ingresses with external DNS providers — currently AWS Route53 and Cloudflare. Once installed, DNS records are created and kept up to date automatically based on hostnames discovered from cluster resources, instead of managing them by hand.

For provider setup details, see the [ExternalDNS documentation](https://kubernetes-sigs.github.io/external-dns/).

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator, as an ArgoCD `Application` delegating to the upstream `external-dns` Helm chart. Once active, ExternalDNS watches the configured `sources` (Services, Ingresses, etc.) across the cluster and manages matching DNS records in the configured provider.

This plugin locks ExternalDNS down to **opt-in only** — see [Opting an Ingress In](#opting-an-ingress-in-required) below. Nothing gets a DNS record unless it's explicitly annotated.

---

## Prerequisites

- An account/zone with the target DNS provider (a Route53 hosted zone, or a Cloudflare zone)
- For AWS with IRSA: an OIDC-enabled cluster (EKS) and an IAM role trust policy configured for the `external-dns` ServiceAccount — vanilla k3s/kubeadm clusters without OIDC federation should use `extra_values` to inject static AWS credentials instead
- For Cloudflare: an API token with `Zone:Read` and `DNS:Edit` permissions

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"ExternalDNS"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `chart_version` | **string** · Required · Default: `1.21.1`<br>The external-dns Helm chart version to install |
| `provider` | **select** · Required · Default: `aws`<br>DNS provider to sync records to. Options: `aws`, `cloudflare` |
| `sources` | **multi** · Required · Default: `service, ingress`<br>Kubernetes resource types to watch for hostnames. Options: `service`, `ingress`, `istio-gateway`, `istio-virtualservice`, `node` |
| `domain_filters` | **string** · Optional<br>Comma-separated list of domains to manage (e.g. `example.com,example.org`). Leave empty to manage every zone visible to the provider |
| `txt_owner_id` | **string** · Required · Default: `default`<br>Unique identifier written into TXT registry records — must be unique per external-dns instance sharing the same zones |
| `policy` | **select** · Required · Default: `upsert-only`<br>`upsert-only` never deletes DNS records when the backing resource is removed; `sync` also deletes them |
| `aws_role_arn` | **string** · Optional<br>IAM role ARN annotated onto the ServiceAccount for IRSA (AWS provider only) |
| `aws_region` | **string** · Optional · Default: `us-east-1`<br>AWS region (AWS provider only) |
| `cloudflare_api_token` | **string** · Optional<br>Cloudflare API token with `Zone:Read` and `DNS:Edit` permissions (Cloudflare provider only) |
| `extra_values` | **string** · Optional<br>Additional raw Helm values (YAML) merged into the chart — use for anything not covered above (e.g. Cloudflare `zone_id_filter`/`proxied`, legacy API key+email auth, static AWS keys) |

---

## Opting an Ingress In (Required)

This plugin hardcodes `annotationFilter: "external-dns.alpha.kubernetes.io/enable=true"` — not configurable via a field. ExternalDNS will **ignore every Ingress/Service by default**, even if its host matches `domain_filters`, unless it carries this exact annotation:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/enable: "true"
spec:
  rules:
    - host: myapp.example.com
      ...
```

Without this annotation, no DNS record gets created, no matter what else is configured. This is intentional — it prevents every Ingress in the cluster from silently getting a public DNS record the moment this plugin is installed.

---

## Notes

- Ingresses/Services need `external-dns.alpha.kubernetes.io/enable: "true"` set to get picked up at all — see [Opting an Ingress In](#opting-an-ingress-in-required) above. This is hardcoded, not a configurable field
- `policy: sync` will delete DNS records when their backing Service/Ingress is removed — only enable this once you trust the setup, `upsert-only` is the safer default
- `txt_owner_id` must be unique if you run more than one ExternalDNS instance against the same DNS zone, otherwise the two instances will fight over ownership of the same records
- IRSA (`aws_role_arn`) only works on clusters with an IAM OIDC provider configured (standard on EKS). On clusters without OIDC federation, supply static AWS credentials via `extra_values` instead
- `cloudflare_api_token` is injected as a plain env var value on the ExternalDNS container (not a Kubernetes Secret) — same tradeoff this repo already makes for the Twingate plugin's `api_key` field
- `extra_values` is merged in as raw Helm values alongside the structured fields above — see the [chart's values.yaml](https://github.com/kubernetes-sigs/external-dns/blob/master/charts/external-dns/values.yaml) for the full set of options it accepts
