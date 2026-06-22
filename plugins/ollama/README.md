# Ollama

![Ollama](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/ollama/scripts/assets/logo.jpg)

**Category:** AI
**Type:** Namespaced Plugin
**Tags:** `llm` · `machine-learning`
**Editable:** Yes

---

## Overview

Ollama makes it easy to run large language models (LLMs) locally within your cluster. It provides a simple API and CLI for downloading, running, and managing open-source models like Llama, Mistral, Gemma, and dozens more. The Ollama plugin installs Ollama to a shared persistent volume and exposes it as a service within your project namespace. GPU acceleration is supported for significantly faster inference.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin runs an installer Job to set up Ollama and creates a long-running service that serves the Ollama API to workstations in the project.

---

## Prerequisites

- A shared persistent volume provisioned in your project (for model storage — models can be several GB each)
- For GPU acceleration: the **NVIDIA GPU Operator** plugin installed on the cluster and a GPU-equipped node in the cluster

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"ollama"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `gpu` | boolean | **Yes** | `false` | Enable GPU acceleration for model inference |
| `runtime` | string | No | `""` | Container runtime for GPU access (e.g. `nvidia`). Leave empty for CPU-only. |
| `destination` | string | **Yes** | `ollama` | Directory path within the volume for Ollama data (no leading slash) |
| `install_volume` | shared-volume | **Yes** | — | Shared persistent volume to store Ollama models and data |
| `enable_node_port` | boolean | **Yes** | `false` | Expose a NodePort for the Ollama API (allows access from outside the cluster). You will need to retrieve the assigned port from Kubernetes directly. |

---

## Notes

- This plugin is **editable** — you can update GPU settings and node port exposure after install via Terra
- Models are downloaded on demand when first requested via the Ollama API or CLI — ensure the persistent volume has enough capacity for your intended models (models range from ~1GB to 70GB+)
- The `destination` field must **not** include a leading slash (e.g. use `ollama`, not `/ollama`)
- Ollama is accessible within the cluster at the service ClusterIP address; workstations can connect to it using its Kubernetes service DNS name
- For integration with **Open WebUI**, install that plugin and point it at the Ollama service endpoint
