# n8n

![n8n](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/n8n/scripts/assets/logo.png)

**Category:** Automation
**Type:** Workload Template
**Tags:** `automation` · `workflow` · `integration` · `open-source` · `API` · `data-processing`
**Compatibility:** `genesis-deployment>=3.0.0-beta.1` · `orion-deployment>=3.0.0-beta.1`

---

## Overview

n8n is an open-source workflow automation tool with a visual node-based interface for connecting applications, services, and APIs. With over 400 integrations including Slack, GitHub, Google Sheets, databases, and custom HTTP endpoints, n8n lets your team automate repetitive tasks and data pipelines without writing code. The n8n workload template lets users launch private n8n instances directly from Genesis, with persistent workflow storage.

---

## How It Works

**Workload Template** — Installs the n8n workload schema into Genesis. Once installed, the n8n type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own automation instance on demand within a project through **Hubble**.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 3.0.0-beta.1`, `orion-deployment >= 3.0.0-beta.1`
- A Kubernetes storage class available in the cluster for workflow data persistence

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"n8n"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the n8n schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision n8n instances on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions an n8n instance through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.n8n.io/n8nio`<br>Container registry for the n8n image |
| `repo` | **string** · Required · Default: `n8n`<br>n8n image repository |
| `tag` | **string** · Required · Default: `latest`<br>n8n image tag (version) |
| `timezone` | **string** · Required · Default: `America/New_York`<br>Timezone for the n8n instance (affects scheduled workflow execution) |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the n8n workflow data persistent volume |
| `storage_size` | **string** · Required · Default: `10Gi`<br>Size of the persistent volume for workflow and credential storage |
| `hostname` | **string** · Optional<br>Serve this instance at its own domain, for example `n8n.example.com`, instead of a path on the platform host |
| `tls_issuer` | **string** · Optional<br>cert-manager ClusterIssuer used to obtain the certificate for that domain. Requires the Certificate Issuer plugin |
| `publish_dns` | **boolean** · Optional · Default: `false`<br>Annotate the route so the ExternalDNS plugin creates the DNS record |
| `webhooks_public` | **boolean** · Required · Default: `false`<br>Allows public access to the n8n webhook paths under `/<namespace>/n8n/<workload-name>/`, while the editor, REST API, and credential store stay behind authentication |
| `webhook_rate_limit` | **int** · Optional · Default: `10`<br>Requests per second allowed on the public webhook paths |
| `webhook_allow_cidrs` | **string** · Optional<br>Comma separated CIDR ranges allowed to reach the public webhook paths, e.g. `203.0.113.0/24,198.51.100.7/32`. Leave empty to accept any source |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for n8n:

| Variable | Description |
|----------|--------------|
| `N8N_ENCRYPTION_KEY` | Custom key n8n uses to encrypt stored credentials. Set this to keep credentials decryptable across restarts/re-deploys. |
| `N8N_PROXY_HOPS` | Number of reverse proxies in front of n8n. Set to `2`, one for the cluster ingress controller and one for the nginx sidecar, so webhook nodes see the real caller IP rather than the ingress IP. Add one for any further proxy in front of the ingress controller, such as a cloud load balancer that appends to `X-Forwarded-For`. |
| `EXECUTIONS_DATA_PRUNE` | Prunes old execution records (`true` or `false`). Without pruning, execution history grows until the volume fills. |
| `EXECUTIONS_DATA_MAX_AGE` | Hours of execution history to keep when pruning is enabled (e.g. `336` for two weeks). |
| `N8N_DIAGNOSTICS_ENABLED` | Set to `false` to disable outbound telemetry. |

---

## Serving n8n on Your Own Domain

Set `hostname` and the instance moves off the shared platform path onto a domain of its own. The chart then serves n8n from the root of that host, points `WEBHOOK_URL`, `N8N_HOST` and `N8N_PATH` at it, and redirects the old platform path to the new address so links in Hubble keep working.

Two things follow from that, and both are deliberate:

- Webhook URLs become `https://<hostname>/webhook/<id>`, which is the form every managed n8n host uses, and third-party callers reach them without any extra setup. `webhooks_public` is not used in this mode
- The Hubble session gate cannot apply to another domain, because the platform session cookie is never sent there. n8n's own user management is the gate, so set an owner account on first launch and keep it

Add a DNS record for the hostname pointing at the cluster ingress address before launching, or set `publish_dns` and let ExternalDNS create it. The Domain Manager page shows the exact record and whether it currently resolves.

---

## Notes

- n8n workflows, credentials, and execution history are stored in the persistent volume — data persists across workload restarts
- The `timezone` setting affects when scheduled workflows (cron-based) trigger — set it to match your team's primary timezone
- With `webhooks_public` disabled (the default) every path is behind the Juno session gate, so calls from third-party services are rejected at the ingress before n8n receives them, so enable it for any workflow driven by an inbound webhook
- n8n is served under `/<namespace>/n8n/<workload-name>/`, where `<namespace>` is the environment the workload runs in — this full path is passed to the container as `N8N_PATH`, so the webhook URLs n8n displays in the editor already include it
- Enabling `webhooks_public` exposes only the `webhook/`, `webhook-test/`, and `webhook-waiting/` sub-paths — the full public URL to hand to a third-party service is `https://<host>/<namespace>/n8n/<workload-name>/webhook/<path>`; the editor, REST API, and credential store stay authenticated
- With `hostname` set the whole instance lives on that domain, so the editor, the REST API and the webhooks are all served there and n8n's own login is what protects them
- Authenticate exposed webhooks in the webhook node itself (header auth, basic auth, or a signature check) and narrow the source with `webhook_allow_cidrs` where the calling platform publishes its IP ranges
- n8n has a fair-code license; for commercial use, review [n8n's licensing terms](https://github.com/n8n-io/n8n/blob/master/LICENSE.md)
- Each workload instance is an isolated n8n environment with its own credential store
