# Hermes Agent

![Hermes Agent](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/hermes-agent/scripts/assets/hermes-logo.png?raw=true)

**Category:** AI
**Type:** Workload Template
**Tags:** `llm` · `ai-agent` · `hermes` · `openai-compatible` · `multi-provider` · `webui` · `workload`

---

## Overview

Hermes Agent is an AI agent workload with multi-provider LLM support and a built-in WebUI. It supports OpenRouter, OpenAI, Anthropic, and Ollama as backend providers, making it a flexible self-hosted AI assistant that your team can deploy directly within the Juno platform. Each Hermes workload gets its own persistent storage for conversation history and configuration, and can optionally be granted Kubernetes RBAC access to interact with cluster resources.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the Hermes Agent workload type in the workload creation UI. Individual Hermes instances are launched by Kuiper when users create workloads.

---

## Prerequisites

- API credentials for at least one supported LLM provider (OpenRouter, OpenAI, Anthropic, or a running **Ollama** instance)
- A Kubernetes storage class available in the cluster (for agent state persistence)
- No install-time prerequisites beyond a running Juno platform

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"hermes-agent"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Hermes Agent workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching a Hermes Agent workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `registry` | string | No | `nousresearch` | Container registry for the Hermes image |
| `repo` | string | No | `hermes-agent` | Hermes image repository |
| `tag` | string | No | `latest` | Hermes image tag |
| `cluster_access` | select | No | `none` | Kubernetes RBAC access level for the agent (`none`, `readonly-ns`, `admin-ns`) |
| `persistence_size` | string | No | `1Gi` | Persistent volume size for agent state storage |
| `persistence_storage_class` | k8sStorageClass | No | — | Storage class for the persistent volume |

---

## Notes

- The `cluster_access` field controls whether Hermes can interact with Kubernetes resources — use `readonly-ns` for safe exploration, `admin-ns` only when the agent needs to manage workloads
- LLM provider API keys must be configured at the application level within the Hermes WebUI after launch — they are not set via these fields
- Hermes supports OpenAI-compatible APIs, making it compatible with any provider that follows the OpenAI API specification
