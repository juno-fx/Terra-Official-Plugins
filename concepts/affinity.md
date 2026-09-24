# Affinity — Node Placement

**When to use:** the workload must land on specific nodes — GPU-equipped nodes, workstation
nodes, pools backed by particular storage, or dedicated infrastructure.

## Default state

The workload template ships **no affinity and no tolerations**. Scheduling is unconstrained
until you add placement rules. This is intentional — most workloads schedule anywhere.

## Platform facts

- Do **not** add anti-blacklist affinity. Kuiper's lifecycle injects anti-blacklisted-node
  affinity into pod specs at launch (consumption mode) — a chart replicating it would be
  redundant. This is a Kuiper-source fact, not documented in this repo.

## The `.Values.selector` convention

`selector` is a declared (but Kuiper-not-injected) Helm value: a list of `{key, value}` pairs.
A dozen plugins (boinc, gitea, github-runner, helios, jupyter-notebook, lsio-webtop, proxmox,
runtime-cpp/go/js/python, slurm-terminal) range it into `matchExpressions` so node targeting is
configurable per workload without chart edits.

```yaml
# scripts/chart/values.yaml
selector: []

# scripts/chart/templates/workload.yaml — inside spec.template.spec
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            # Match the target node's label — replace with the actual key.
            - key: your-node-label-key
              operator: In
              values:
                - "true"
            {{- if .Values.selector }}
            {{- range .Values.selector }}
            - key: {{ .key | quote }}
              operator: In
              values:
                - {{ .value | quote }}
            {{- end }}
            {{- end }}
```

Reference implementation: `plugins/helios/scripts/chart/templates/workstation.yaml`.

## Tolerations

Tolerations are only needed for **tainted** nodes. Add one only when targeting such nodes,
using the taint key:

```yaml
tolerations:
  - key: "your-taint-key"
    operator: "Exists"
    effect: "NoSchedule"
```

## Gotchas

- `nodeSelectorTerms` entries are **OR'd**, `matchExpressions` inside a term are **AND'd**.
  A wide term next to a narrow one widens scheduling — keep extras inside the same term.
- `nodeSelector` (exact-label match) is simpler than affinity for single-label targeting, but
  a missing label leaves the pod unschedulable instead of falling back.
- GPU workloads: `runtimeClassName: nvidia` is handled by the `gpu` field — see
  `concepts/gpu.md`. Affinity only decides *which* node, not whether the GPU runtime is used.

## See also

- `concepts/scheduling.md` — resources, priorities, workload shape
- `concepts/gpu.md` — GPU field, runtimeClassName, driver prerequisite
- `docs/workload-templates.md` — workload.yaml conventions