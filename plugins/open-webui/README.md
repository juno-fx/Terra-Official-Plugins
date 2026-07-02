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

**Workload Template** — Installs the Open WebUI workload schema into Genesis. Once installed, the Open WebUI type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own AI chat instance on demand within a project through **Hubble**.

Each launched instance runs two containers in one pod:

- `open-webui` — the Open WebUI application itself (internal port `8081`)
- `nginx` — a reverse-proxy sidecar (port `8080`, exposed via the Service/Ingress) that serves the instance at `/openwebui/<name>/`

Open WebUI has no native support for running behind a URL subpath ([open-webui/open-webui#17257](https://github.com/open-webui/open-webui/issues/17257), [#25797](https://github.com/open-webui/open-webui/discussions/25797)) — it emits root-absolute asset and API paths (`/_app/...`, `/api/...`, `/ws/socket.io/...`, etc.) regardless of where it's mounted. The nginx sidecar works around this by stripping the `/openwebui/<name>/` prefix before proxying to the app, and rewriting those absolute paths back in on the way out (`sub_filter`) so every request the browser makes round-trips back through the same prefix.

This is a workaround, not upstream support, so it's tied to Open WebUI's current asset layout — see [Notes](#notes).

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

Once installed, the Open WebUI schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision Open WebUI instances on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions an Open WebUI instance through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Optional · Default: `ghcr.io/open-webui`<br>Container registry for the Open WebUI image |
| `repo` | **string** · Optional · Default: `open-webui`<br>Open WebUI image repository |
| `tag` | **string** · Required · Default: `0.10.2`<br>Open WebUI image tag. **Pinned** — the nginx sidecar's path rewriting depends on Open WebUI's current asset layout, so bumping this may require updating `scripts/chart/templates/nginx-configmap.yaml` |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the Open WebUI data persistent volume |
| `storage_size` | **string** · Required · Default: `10Gi`<br>Size of the persistent volume for chat history and model config |

The nginx sidecar image (`nginx_registry`/`nginx_repo`/`nginx_tag`) is not user-configurable — it's set in `scripts/chart/values.yaml`.

---

## Notes

- Open WebUI is entirely self-hosted and operates offline once configured — no data is sent to external servers unless you configure an external API backend
- LLM backends (Ollama endpoint URLs, OpenAI API keys) are configured within the Open WebUI application after launch
- Chat history, model settings, and user configuration are persisted to the storage volume
- **Subpath support is a workaround, not upstream Open WebUI functionality.** The `tag` field is pinned deliberately — if you bump it, verify the app still loads correctly at `/openwebui/<name>/` (check the browser console for 404s on `/_app/`, `/api/`, or `/ws/socket.io/` requests missing the prefix) and update the `sub_filter` rules in `scripts/chart/templates/nginx-configmap.yaml` if Open WebUI's asset paths have changed
