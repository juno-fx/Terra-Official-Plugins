# Scheduling — Resources, Priority, Workload Shape

**When to use:** sizing the workload (CPU/memory), setting priorities, or changing how the
StatefulSet is shaped (replicas, hostname). For *where* pods land, see `concepts/affinity.md`.

## Resources — Kuiper-injected keys

`cpu`, `memory`, `cpuLimit`, `memoryLimit` are standard Kuiper-injected values. Wire them to
requests/limits with the guarded pattern (limits only render when set):

```yaml
# scripts/chart/templates/workload.yaml — container spec
resources:
  requests:
    memory: "{{ .Values.memory }}"
    cpu: "{{ .Values.cpu }}"
  {{- if or (or .Values.gpu .Values.memoryLimit) .Values.cpuLimit }}
  limits:
    {{- if .Values.gpu }}
    nvidia.com/gpu: "1"
    {{- end }}
    {{- if .Values.cpuLimit }}
    cpu: "{{ .Values.cpuLimit }}"
    {{- end }}
    {{- if .Values.memoryLimit }}
    memory: "{{ .Values.memoryLimit }}"
    {{- end }}
  {{- end }}
```

- Values are **strings** (`"1"`, `"1Gi"`) — quote them.
- The `gpu` limit (`nvidia.com/gpu: "1"`) belongs to the `gpu` field — see
  `concepts/gpu.md`.
- The template ships the **requests-only** subset of this block
  (`template/workload/scripts/chart/templates/workload.yaml`); the `limits` guards are added
  when probing confirms the workload needs them.

## Replicas

Workload templates are StatefulSets with `replicas: 1`. Most workloads are single-instance;
Kuiper's services, ingress, and labels are built around one pod. Scale up only if the app
supports it (shared storage + multi-writer conflicts apply).

## Hostname

The pod gets `hostname: "{{ .Values.name }}"` — the workload name. Applications that bind to
or derive identity from the hostname rely on this; don't change it to a static value.

## Priority

Add a `k8sPriority` field to `templates/metadata.yaml` to let users pick a
`PriorityClass` at launch:

```yaml
# templates/metadata.yaml — fields list
- name: priority
  description: "Priority class"
  type: k8sPriority
  required: false
```

Then wire it in the pod spec:

```yaml
{{- if .Values.priority }}
priorityClassName: "{{ .Values.priority }}"
{{- end }}
```

Kuiper queries the cluster for available classes — the field's `name` must match the
`values.yaml` key exactly (Rule 3).

## Gotchas

- **Requests without limits** — the template ships requests-only by default; limits appear
  only when `cpuLimit`/`memoryLimit`/`gpu` are set. Users control this per workload.
- `k8sPriority` field values arrive as strings; an unset value renders an empty string — the
  `if` guard above handles it.
- Placement (affinity, tolerations, nodeSelector) is a *scheduling* concern but lives in
  `concepts/affinity.md` — workflow shape and node targeting stay separate concerns.

## See also

- `concepts/affinity.md` — node placement, tolerations, `.Values.selector`
- `concepts/gpu.md` — GPU resource attach
- `concepts/runtime.md` — image, probes, sidecars
- `docs/workload-configuration.md` — field types