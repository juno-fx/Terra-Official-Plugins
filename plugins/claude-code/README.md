# Claude Code

![Claude Code](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/claude-code/assets/logo.png)

**Category:** Development
**Type:** Workload Template
**Tags:** `cluster-level`

---

## Overview

Claude Code is Anthropic's AI coding agent, delivered as a browser-accessible web terminal (powered by wetty). Each Claude Code workload is an isolated session with persistent storage for project files and configuration — no local install required.

---

## How It Works

**Workload Template** — Installs the Claude Code workload schema into Genesis. Once installed, the Claude Code type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own coding agent session on demand within a project through **Hubble**.

---

## Prerequisites

- A Kubernetes storage class available in the cluster
- API credentials for Claude (`ANTHROPIC_API_KEY` or equivalent) — set via the workload's environment variables at launch
- Unrestricted outbound network access in the workload's namespace (see Notes) — required for `apt`/`npm`/`pip` installs and the Claude API

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Claude Code"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Claude Code schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision sessions on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a Claude Code session through **Hubble**:

| Field | Details |
|-------|---------|
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Registry to pull the nginx sidecar image from |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>Repository to pull the nginx sidecar image from |
| `nginx_tag` | **string** · Required · Default: `alpine`<br>Tag to pull the nginx sidecar image from |
| `timezone` | **string** · Required · Default: `America/New_York`<br>Timezone for the Claude Code instance |
| `storage_class` | **k8sStorageClass** · Optional<br>Storage class for the persistent `/data` disk |
| `storage_size` | **string** · Required · Default: `10Gi`<br>Storage size for the persistent `/data` disk |
| `cluster_access` | **select** · Optional<br>Kubernetes RBAC access level for the workstation (unset = no cluster access, `readonly-ns`, `admin-ns`) |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for the `claude` CLI (`@anthropic-ai/claude-code`):

| Variable | Description |
|----------|--------------|
| `ANTHROPIC_API_KEY` | Anthropic Console API key used by the `claude` CLI to authenticate. |
| `ANTHROPIC_MODEL` | Overrides the default Claude model used by the CLI. |
| `ANTHROPIC_BASE_URL` | Overrides the API base URL, e.g. to point at a proxy or compatible endpoint. |

---

## Notes

- Claude API credentials are not set via the install-time fields above — configure them as custom environment variables at workload launch (see table above), e.g. `ANTHROPIC_API_KEY`
- The nginx sidecar provides browser-accessible proxying for the wetty terminal interface
- Project files and Claude Code configuration are persisted to the `/data` volume across workload restarts
- The workstation endpoint always authenticates through Hubble — there is no option to disable authentication
- The `cluster_access` field controls whether the workstation can interact with Kubernetes resources — leave unset for no cluster access, use `readonly-ns` for safe exploration, `admin-ns` only when the workstation needs to manage workloads
- The workload's network policy restricts inbound traffic only (ingress). It sets no egress rules, so outbound access is controlled entirely by your namespace/cluster — if it default-denies egress, add your own allow rule for this workload (DNS + internet, or your internal mirrors/proxy if airgapped)
