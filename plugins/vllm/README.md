# vLLM

![vLLM](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/vllm/assets/logo.png)

**Category:** AI
**Type:** Workload Template
**Tags:** `llm` · `machine-learning` · `gpu` · `inference`

---

## Overview

vLLM is a fast, open-source LLM inference engine with PagedAttention, continuous batching, and speculative decoding. This workload template deploys an OpenAI-compatible API server that can serve any HuggingFace model. Each launch creates a vLLM container with an nginx sidecar for path rewriting, backed by a persistent model cache volume.

---

## How It Works

**Workload Template** — Installs the vLLM schema into Genesis. Once installed, the vLLM type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own inference server on demand within a project through **Hubble**.

---

## Prerequisites

- **NVIDIA GPU Operator** plugin must be installed for GPU-accelerated inference
- A **StorageClass** must be available for the model cache PVC (50Gi default)
- Cluster nodes must have GPUs and the `nvidia` runtime class configured
- For gated models, a **HuggingFace Hub token** with access to the model

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"vLLM"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the vLLM schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision inference servers on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a vLLM server through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry for the vLLM image |
| `repo` | **string** · Required · Default: `vllm/vllm-openai`<br>vLLM image repository |
| `tag` | **string** · Required · Default: `0.14.1`<br>vLLM image tag |
| `model` | **string** · Required<br>HuggingFace model name to serve (e.g. `Qwen/Qwen3.6-35B-A3B-FP8`) |
| `served_model_name` | **string** · Optional<br>Override the model name returned in API responses |
| `hf_token` | **string** · Optional · Sensitive<br>HuggingFace Hub token for gated models — stored as a Kubernetes Secret and injected as `HF_TOKEN` |
| `gpu` | **boolean** · Required · Default: `false`<br>Enable GPU acceleration; sets `runtimeClassName: nvidia` |
| `gpu_count` | **int** · Optional · Default: `1`<br>Number of GPUs to allocate |
| `max_model_len` | **string** · Optional · Default: `262144`<br>Maximum sequence length (`--max-model-len`) |
| `max_num_batched_tokens` | **string** · Optional · Default: `16384`<br>Maximum number of batched tokens (`--max-num-batched-tokens`) |
| `max_num_seqs` | **string** · Optional · Default: `64`<br>Maximum number of sequences per batch (`--max-num-seqs`) |
| `gpu_memory_utilization` | **string** · Optional · Default: `0.9`<br>Fraction of GPU memory allocated to the KV cache (`--gpu-memory-utilization`) |
| `quantization` | **string** · Optional<br>Quantization method — e.g. `fp8`, `awq`, `gptq`. Leave empty for native precision. |
| `enable_prefix_caching` | **boolean** · Optional · Default: `true`<br>Enable prefix caching for faster generation on repeated prompts (`--enable-prefix-caching`) |
| `enable_auto_tool_choice` | **boolean** · Optional · Default: `false`<br>Enable automatic tool choice in chat completions (`--enable-auto-tool-choice`) |
| `tool_call_parser` | **string** · Optional<br>Tool call parser type (e.g. `qwen3_coder`) |
| `reasoning_parser` | **string** · Optional<br>Reasoning parser type (e.g. `qwen3`) |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for the model cache PVC |
| `storage_size` | **string** · Optional · Default: `50Gi`<br>Size of the model cache PVC |

---

## Notes

- GPU-accelerated inference requires the **NVIDIA GPU Operator** plugin to be installed on the cluster
- The model cache PVC is mounted at `/models` and set as `HF_HUB_CACHE` — downloaded models persist across container restarts
- For gated models (e.g. Llama, Mistral), set `hf_token` to a HuggingFace token that has accepted the model license — the token is stored in a Kubernetes Secret and injected as the `HF_TOKEN` environment variable
- The nginx sidecar rewrites the path prefix: requests to `/vllm/<workload-name>/v1/...` are forwarded to vLLM at `/v1/...` on port 8001 — the API is fully OpenAI-compatible
- Health checks use `/health` on port 8001 with a generous startup grace period (3600s max) to account for model loading time
- vLLM runs as non-root with `fsGroup: 1000`
- Supported actions via Hubble: `restart`, `stop`
- Telemetry is disabled (`HF_HUB_DISABLE_TELEMETRY: true`)
