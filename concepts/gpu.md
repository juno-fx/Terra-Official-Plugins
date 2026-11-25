# GPU — Attaching a GPU to a Workload

**When to use:** the workload needs an NVIDIA GPU (LLM inference, rendering, CUDA compute).

## Prerequisite

`plugins/nvidia-gpu-operator/` (cluster-level plugin) must be installed in the deployment —
it deploys the driver, device plugin, and runtime onto GPU nodes. Without it,
`runtimeClassName: nvidia` leaves the pod stuck in Pending.

## Wiring

1. **Field** (`templates/metadata.yaml`) — boolean, user opts in at launch:

```yaml
- name: gpu
  description: "Attach a GPU to this workload"
  type: boolean
  required: true
```

2. **Runtime class** (`scripts/chart/templates/workload.yaml`, pod spec) — added when probing
   confirms a GPU is needed:

```yaml
{{- if .Values.gpu }}
runtimeClassName: nvidia
{{- end }}
```

3. **Resource limit** — the `gpu` value also gates the `nvidia.com/gpu: "1"` limit inside the
   resources block (see `concepts/scheduling.md`). Both must stay wired to the same `gpu`
   value — the runtime class without the limit under-schedules, the limit without the class
   fails to admit.

Reference: `plugins/runtime-go/scripts/chart/templates/workstation.yaml` +
`plugins/runtime-go/templates/metadata.yaml`.

## Multi-vendor and GPU sharing

The boolean `gpu` field above is the single-vendor (NVIDIA) baseline. A workload that must also
run on AMD GPUs uses a `select` instead — `off` / `nvidia` / `amd` — and gates each vendor's
wiring on the selected value. Quote `"off"` everywhere: bare `off` is YAML 1.1 for `false`.

```yaml
{{- $nvidia := eq (toString .Values.gpu) "nvidia" -}}
{{- $amd := eq (toString .Values.gpu) "amd" -}}
...
{{- if $nvidia }}
runtimeClassName: nvidia           # NVIDIA only; AMD needs no runtime class
{{- end }}
...
limits:
{{- if $nvidia }}
  nvidia.com/gpu: "1"
{{- end }}
{{- if $amd }}
  amd.com/gpu: "1"
{{- end }}
```

A pod requests one vendor only. `amd.com/gpu` needs `plugins/amd-gpu-operator/` installed.

With the HAMi GPU Sharing plugin (`plugins/hami/`) a workload can request a slice instead of a
whole card by adding `<vendor>/gpumem` (MiB) and `<vendor>/gpucores` (0–100) limits beside
`<vendor>/gpu`. Those names are unknown to the plain device plugins, so render them only when
the launch asks for them. `plugins/jupyter-notebook/` reads `HAMI_GPU_MEMORY` (GiB) and
`HAMI_GPU_CORES` from the launch-time `env` list, renders them as limits, and drops them from
the container env — see its `scripts/chart/templates/statefulset.yaml` for the pattern.

## Which node?

Setting `runtimeClassName` alone does not pin the pod to a GPU node — the device plugin's
extended resources do that at admission. If the deployment segregates GPU nodes (labels,
taints), target them explicitly — see `concepts/affinity.md` (`.Values.selector` or
nodeAffinity on the GPU-node label, plus the matching toleration for any taint).

## Gotchas

- **Field default** — keep `gpu` required with no default (the recommended probing default) so
  the user explicitly opts in. A silent default of `false` is fine too; never default to `true`.
- `nvidia.com/gpu` / `amd.com/gpu` limit must be a string `"1"` (whole GPUs only — fractions
  come from HAMi's `gpumem`/`gpucores`, not from this value).
- GPU + affinity: the anti-blacklist affinity Kuiper injects still applies; only add terms
  that narrow to GPU-capable nodes.

## See also

- `concepts/affinity.md` — GPU-node targeting, tolerations
- `concepts/scheduling.md` — resources, limits wiring
- `plugins/nvidia-gpu-operator/`, `plugins/amd-gpu-operator/` — cluster prerequisites
- `plugins/hami/` — GPU sharing (slices) for both vendors