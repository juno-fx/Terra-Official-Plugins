# ExternalDNS

![ExternalDNS](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/external-dns/assets/logo.png)

**Category:** Networking
**Type:** Cluster Service
**Tags:** `cluster-level` · `dns` · `networking`

---

## Overview

ExternalDNS synchronizes exposed Kubernetes Services and Ingresses with external DNS providers, currently AWS Route53 and Cloudflare. Once installed, DNS records are created and kept up to date automatically based on hostnames discovered from cluster resources, instead of managing them by hand.

For provider setup details, see the [ExternalDNS documentation](https://kubernetes-sigs.github.io/external-dns/).

---

## How It Works

**Cluster Service** - Installed once per cluster by an administrator, as an ArgoCD `Application` delegating to the upstream `external-dns` Helm chart. Once active, ExternalDNS watches the configured `sources` (Services, Ingresses, etc.) across the cluster and manages matching DNS records in the configured provider.

This plugin locks ExternalDNS down to **opt-in only**, see [Opting an Ingress In](#opting-an-ingress-in-required) below. Nothing gets a DNS record unless it's explicitly annotated.

---

## Prerequisites

- An account/zone with the target DNS provider (a Route53 hosted zone, or a Cloudflare zone)
- For AWS with IRSA: an OIDC-enabled cluster (EKS) and an IAM role trust policy configured for the `external-dns` ServiceAccount. Clusters without OIDC federation use a credentials Secret instead, see [Credentials](#credentials)
- For Cloudflare: an API token with `Zone:Read` and `DNS:Edit` permissions, stored in a Secret, see [Credentials](#credentials)

---

## Installation

1. Create the credential Secret, unless you are using IRSA, see [Credentials](#credentials)
2. Open **Terra** and navigate to the **Plugin Marketplace**
3. Search for **"ExternalDNS"**
4. Click **Install**
5. Fill in the configuration fields below
6. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `chart_version` | **string** · Required · Default: `1.21.1`<br>The external-dns Helm chart version to install |
| `provider` | **select** · Required · Default: `aws`<br>DNS provider to sync records to. Options: `aws`, `cloudflare` |
| `sources` | **multi** · Required · Default: `service, ingress`<br>Kubernetes resource types to watch for hostnames. Options: `service`, `ingress`, `gateway-httproute`, `gateway-grpcroute`, `istio-gateway`, `istio-virtualservice`, `node` |
| `domain_filters` | **string** · Optional<br>Comma-separated list of domains to manage (e.g. `example.com,example.org`). Leave empty to manage every zone visible to the provider |
| `txt_owner_id` | **string** · Required · Default: `default`<br>Unique identifier written into TXT registry records, must be unique per external-dns instance sharing the same zones |
| `policy` | **select** · Required · Default: `upsert-only`<br>`upsert-only` never deletes DNS records when the backing resource is removed; `sync` also deletes them |
| `aws_role_arn` | **string** · Optional<br>IAM role ARN annotated onto the ServiceAccount for IRSA (AWS provider only). When set, the secret fields are ignored |
| `secret_namespace` | **string** · Optional · Default: `external-dns`<br>Namespace external-dns is installed into, and where the credential Secret must exist |
| `secret_name` | **string** · Optional<br>Name of the credential Secret. Required for Cloudflare |
| `secret_key` | **string** · Optional<br>Key inside that Secret holding the credential |
| `annotation_filter` | **string** · Required · Default: `external-dns.alpha.kubernetes.io/enable=true`<br>Only resources carrying this annotation are considered. See [Opting an Ingress In](#opting-an-ingress-in-required) |
| `extra_values` | **string** · Optional<br>Additional raw Helm values (YAML) merged into the chart, use for anything not covered above (e.g. Cloudflare `zone_id_filter`/`proxied`, legacy API key+email auth) |

---

## Credentials

The plugin never takes a credential as a form value. You create a Secret, then point the plugin at it with three fields: `secret_namespace`, `secret_name` and `secret_key`. Only one Secret is used, depending on the provider.

`secret_namespace` is also the namespace external-dns runs in. A pod can only read Secrets from its own namespace, so the Secret and external-dns always live together. Keep the default, `external-dns`, unless you have a reason to move it.

### AWS

With IRSA on EKS, set `aws_role_arn` and leave the secret fields empty. They are ignored when a role is set.

Without IRSA, store a credentials file under a single key, in the same format the Crossplane AWS Provider plugin uses:

```bash
kubectl create namespace external-dns
kubectl create secret generic aws-dns-credentials \
  --namespace external-dns \
  --from-literal=credentials="[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY"
```

Then set `secret_name` to `aws-dns-credentials` and `secret_key` to `credentials`. The file is mounted read only into the container and read through `AWS_SHARED_CREDENTIALS_FILE`.

The IAM user needs `route53:ChangeResourceRecordSets` on the hosted zones it manages, plus `route53:ListHostedZones` and `route53:ListResourceRecordSets`.

### Cloudflare

Store the API token under a single key:

```bash
kubectl create namespace external-dns
kubectl create secret generic cloudflare-api-token \
  --namespace external-dns \
  --from-literal=api-token=YOUR_TOKEN
```

Then set `secret_name` to `cloudflare-api-token` and `secret_key` to `api-token`. The token needs `Zone:Read` and `DNS:Edit`, scoped to the zones external-dns should manage.

---

## Opting an Ingress In (Required)

This plugin ships `annotation_filter` set to `external-dns.alpha.kubernetes.io/enable=true`. ExternalDNS will **ignore every Ingress/Service by default**, even if its host matches `domain_filters`, unless it carries this exact annotation:

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

Without this annotation, no DNS record gets created, no matter what else is configured. This is intentional, it prevents every Ingress in the cluster from silently getting a public DNS record the moment this plugin is installed.

Workload templates that publish a custom hostname set this annotation for you when `publish_dns` is enabled, so nothing extra is needed for those.

---

## Notes

- Ingresses/Services need `external-dns.alpha.kubernetes.io/enable: "true"` set to get picked up at all, see [Opting an Ingress In](#opting-an-ingress-in-required) above. Widen `annotation_filter` only if you want every matching host in the cluster to get a record
- `policy: sync` will delete DNS records when their backing Service/Ingress is removed, only enable this once you trust the setup, `upsert-only` is the safer default
- `txt_owner_id` must be unique if you run more than one ExternalDNS instance against the same DNS zone, otherwise the two instances will fight over ownership of the same records
- IRSA (`aws_role_arn`) only works on clusters with an IAM OIDC provider configured (standard on EKS). If `secret_namespace` is changed, the role's trust policy must name the new namespace, since the ServiceAccount moves with it
- Route53 has no region flag. The AWS SDK still expects a region in its environment, so on the credentials Secret and node credential paths the plugin sets `AWS_DEFAULT_REGION` to `us-east-1`, the region Route53 signs requests in. On EKS with IRSA the pod identity webhook injects the region, and the plugin leaves it alone
- Installing with the Cloudflare provider and no Secret, or naming a Secret without a key, stops the install with a message saying what to set, rather than deploying a pod that crash loops on missing credentials
- On a cluster running the Gateway API, add `gateway-httproute` to `sources`. Routes created as HTTPRoutes are invisible to ExternalDNS otherwise, and the upstream chart grants the matching RBAC on `gateways` and `httproutes` automatically once that source is selected
- `extra_values` is merged in as raw Helm values alongside the structured fields above, see the [chart's values.yaml](https://github.com/kubernetes-sigs/external-dns/blob/master/charts/external-dns/values.yaml) for the full set of options it accepts
