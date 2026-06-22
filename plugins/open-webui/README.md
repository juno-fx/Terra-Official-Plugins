# Open WebUI

![Open WebUI](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/open-webui/scripts/assets/logo.png)

**Category:** AI
**Type:** Workload Template
**Tags:** `AI` · `development` · `Machine-learning`
**Compatibility:** `genesis-deployment>=3.0.0-beta.1` · `orion-deployment>=3.0.0-beta.1`

---

## Overview

Open WebUI is an extensible, feature-rich, self-hosted AI platform designed to operate entirely offline. It supports multiple LLM backends including Ollama and OpenAI-compatible APIs, features a built-in RAG (Retrieval-Augmented Generation) inference engine, and provides a polished chat interface for interacting with AI models. The Open WebUI workload template lets users launch personal AI chat environments directly from Genesis, with full offline capability.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show the Open WebUI workload type in the workload creation UI. Individual Open WebUI instances are launched by Kuiper when users create workloads.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 3.0.0-beta.1`, `orion-deployment >= 3.0.0-beta.1`
- For Ollama backend: the **Ollama** plugin installed in the same project namespace
- A Kubernetes storage class available for persistent chat history and configuration storage

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Open WebUI"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Open WebUI workload type will appear in **Genesis** when users create new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching an Open WebUI workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `registry` | string | No | `ghcr.io/open-webui` | Container registry for the Open WebUI image |
| `repo` | string | No | `open-webui` | Open WebUI image repository |
| `tag` | string | No | `main` | Open WebUI image tag |
| `webtop_registry` | string | **Yes** | `lscr.io/linuxserver` | Registry for the Webtop browser sidecar image |
| `webtop_repo` | string | **Yes** | `chromium` | Webtop browser sidecar image repository |
| `webtop_tag` | string | **Yes** | `latest` | Webtop browser sidecar image tag |
| `storage_class` | k8sStorageClass | **Yes** | — | Storage class for the Open WebUI data persistent volume |
| `storage_size` | string | **Yes** | `10Gi` | Size of the persistent volume for chat history and model config |

---

## Notes

- Open WebUI is entirely self-hosted and operates offline once configured — no data is sent to external servers unless you configure an external API backend
- The Webtop sidecar provides an embedded Chromium browser for the web interface
- LLM backends (Ollama endpoint URLs, OpenAI API keys) are configured within the Open WebUI application after launch
- Chat history, model settings, and user configuration are persisted to the storage volume
