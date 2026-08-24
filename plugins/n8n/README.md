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
| `webhooks_public` | **boolean** · Required · Default: `false`<br>Allows public access to the n8n webhook paths, while the editor, REST API, and credential store stay behind authentication |
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

## Notes

- n8n workflows, credentials, and execution history are stored in the persistent volume — data persists across workload restarts
- The `timezone` setting affects when scheduled workflows (cron-based) trigger — set it to match your team's primary timezone
- With `webhooks_public` disabled (the default) every path is behind the Juno session gate, so calls from third-party services are rejected at the ingress before n8n receives them, so enable it for any workflow driven by an inbound webhook
- Enabling `webhooks_public` exposes only `/webhook/`, `/webhook-test/`, and `/webhook-waiting/`; the editor, REST API, and credential store stay authenticated
- Authenticate exposed webhooks in the webhook node itself (header auth, basic auth, or a signature check) and narrow the source with `webhook_allow_cidrs` where the calling platform publishes its IP ranges
- n8n has a fair-code license; for commercial use, review [n8n's licensing terms](https://github.com/n8n-io/n8n/blob/master/LICENSE.md)
- Each workload instance is an isolated n8n environment with its own credential store
