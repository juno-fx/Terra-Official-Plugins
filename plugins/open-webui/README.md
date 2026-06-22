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

## How It Works

**Workload Template** — Adds the Open WebUI AI chat type to Genesis. Once installed, users can launch their own private Open WebUI instance directly from the Genesis workload screen. Each instance has its own chat history and model configuration.

---

## Prerequisites

- Platform versions: `genesis-deployment >= 3.0.0-beta.1`, `orion-deployment >= 3.0.0-beta.1`
- For Ollama backend: the **Ollama** plugin installed in the same project
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

| Field | Details |
|-------|---------|
| `registry` | **string** · Optional · Default: `ghcr.io/open-webui`<br>Container registry for the Open WebUI image |
| `repo` | **string** · Optional · Default: `open-webui`<br>Open WebUI image repository |
| `tag` | **string** · Optional · Default: `main`<br>Open WebUI image tag |
| `webtop_registry` | **string** · Required · Default: `lscr.io/linuxserver`<br>Registry for the Webtop browser sidecar image |
| `webtop_repo` | **string** · Required · Default: `chromium`<br>Webtop browser sidecar image repository |
| `webtop_tag` | **string** · Required · Default: `latest`<br>Webtop browser sidecar image tag |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the Open WebUI data persistent volume |
| `storage_size` | **string** · Required · Default: `10Gi`<br>Size of the persistent volume for chat history and model config |

---

## Notes

- Open WebUI is entirely self-hosted and operates offline once configured — no data is sent to external servers unless you configure an external API backend
- The Webtop sidecar provides an embedded Chromium browser for the web interface
- LLM backends (Ollama endpoint URLs, OpenAI API keys) are configured within the Open WebUI application after launch
- Chat history, model settings, and user configuration are persisted to the storage volume
