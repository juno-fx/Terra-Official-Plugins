# Hermes Agent

![Hermes Agent](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/hermes-agent/scripts/assets/hermes-logo.png?raw=true)

**Category:** AI
**Type:** Workload Template
**Tags:** `llm` · `ai-agent` · `hermes` · `openai-compatible` · `multi-provider` · `webui` · `workload`

---

## Overview

Hermes Agent is an AI agent workload with multi-provider LLM support and a built-in WebUI. It supports OpenRouter, OpenAI, Anthropic, and Ollama as backend providers, making it a flexible self-hosted AI assistant that your team can deploy directly within the Juno platform. Each Hermes workload gets its own persistent storage for conversation history and configuration, and can optionally be granted Kubernetes RBAC access to interact with cluster resources.

---

## How It Works

**Workload Template** — Installs the Hermes Agent workload schema into Genesis. Once installed, the Hermes Agent type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own agent instance on demand within a project through **Hubble**.

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

Once installed, the Hermes Agent schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision agent instances on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions an agent instance through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Optional · Default: `nousresearch`<br>Container registry for the Hermes image |
| `repo` | **string** · Optional · Default: `hermes-agent`<br>Hermes image repository |
| `tag` | **string** · Optional · Default: `latest`<br>Hermes image tag |
| `cluster_access` | **select** · Optional · Default: `none`<br>Kubernetes RBAC access level for the agent (`none`, `readonly-ns`, `admin-ns`) |
| `persistence_size` | **string** · Optional · Default: `1Gi`<br>Persistent volume size for agent state storage |
| `persistence_storage_class` | **k8sStorageClass** · Optional<br>Storage class for the persistent volume |

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for Hermes Agent's multi-provider setup:

| Variable | Description |
|----------|--------------|
| `ANTHROPIC_API_KEY` | Anthropic Console API key, used when the agent is configured to use Claude models. |
| `OPENAI_API_KEY` | API key for OpenAI or any OpenAI-compatible endpoint (also used for local Ollama setups). |
| `OPENROUTER_API_KEY` | OpenRouter API key for flexible access to many hosted models. |
| `HERMES_MODEL` | Overrides the default model used by the agent. |

---

## Notes

- The `cluster_access` field controls whether Hermes can interact with Kubernetes resources — use `readonly-ns` for safe exploration, `admin-ns` only when the agent needs to manage workloads
- LLM provider API keys are not set via the install-time fields above — configure them either as custom environment variables at workload launch (see table above) or at the application level within the Hermes WebUI after launch
- Hermes supports OpenAI-compatible APIs, making it compatible with any provider that follows the OpenAI API specification
