# Affinity — Node and Pod Placement

**When to use:** the workload must land on specific nodes — GPU-equipped nodes, workstation
nodes, pools backed by particular storage, or dedicated infrastructure — or must avoid or
seek co-location with other workloads (node contention, data locality).

## Default state

The workload template ships **no affinity, no tolerations, and no pod placement rules
(avoid/pack)**. Scheduling is unconstrained until you add placement rules. This is intentional
— most workloads schedule anywhere.

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

## Pod placement relationships

Sometimes the placement need is about *other workloads*, not nodes: the workload must not
share a node with its peers, or must ride alongside them. Both patterns are pod-level
affinity in the same `affinity:` block as node placement — independent axes, compose freely.

### Avoid others — `podAntiAffinity`

Do not co-locate with workloads matching a label. Use when pods contend for the same resource
(GPU cards, CPU-heavy batch, render fleets) or when one-per-node is the point (runners).

Soft is the default — scheduling never fails, it just prefers separation:

```yaml
# inside spec.template.spec
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              juno-innovations.com/runner: "true"   # shared role label
          topologyKey: kubernetes.io/hostname
```

`required` only when correctness depends on separation — it can strand pods (single-node
cluster, more pods than nodes):

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            juno-innovations.com/render: "true"     # one render job per node
        topologyKey: kubernetes.io/hostname
```

Reference implementation: `plugins/github-runner/scripts/chart/templates/workstation.yaml` —
runners spread cluster-wide; it adds `namespaceSelector: {}` because runner workloads span
namespaces.

### Pack together — `podAffinity`

Co-locate with a peer workload on the same node — cache/broker next to its consumer,
storage-affine workers, high-bandwidth or low-latency peer traffic. The label must exist on
**both** sides: the workload and the peer chart both declare it on their pod templates:

```yaml
# workload — inside spec.template.spec
affinity:
  podAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              juno-innovations.com/cache: "true"    # match the peer, not itself
          topologyKey: kubernetes.io/hostname
```

```yaml
# peer chart — same label declared on ITS pod template
metadata:
  labels:
    juno-innovations.com/cache: "true"
```

### Wiring rules

- `topologyKey` is required — `kubernetes.io/hostname` is the standard unit for "same node".
- `matchLabels` targets a shared `juno-innovations.com/*` or `kuiper.juno-innovations.com/*`
  label — never `kuiper-instance`: its value is the workload name, unknown at chart time and
  unique per launch, so a static chart cannot reference it.
- Placement labels are declared on the pod template — Kuiper's label injection does not reach
  `spec.template.metadata.labels`.
- `namespaceSelector` omitted = same-namespace matching (default); `{}` = all namespaces
  (cross-namespace fleets, github-runner).
- Most charts pin placement statically (the chart knows its peers). Only if the probe confirms
  users should choose at launch, expose a metadata `select` field (`anywhere` /
  `avoid-others` / `pack-together`) wired to a plain chart-declared values key — distinct from
  `.Values.selector`, which is node targeting only.

## Gotchas

- `nodeSelectorTerms` entries are **OR'd**, `matchExpressions` inside a term are **AND'd**.
  A wide term next to a narrow one widens scheduling — keep extras inside the same term.
- `nodeSelector` (exact-label match) is simpler than affinity for single-label targeting, but
  a missing label leaves the pod unschedulable instead of falling back.
- Pod placement: `preferred` (soft) by default — `required` podAffinity/podAntiAffinity can
  strand pods in a single-node cluster or when the fleet exceeds node count; reserve it for
  correctness-dependent separation/co-location.
- GPU workloads: avoid-others is the common case (device contention across pods); pack GPU
  pods only when the probe confirms a shared-device pattern.
- GPU workloads: `runtimeClassName: nvidia` is handled by the `gpu` field — see
  `concepts/gpu.md`. Affinity only decides *which* node, not whether the GPU runtime is used.

## See also

- `concepts/scheduling.md` — resources, priorities, workload shape
- `concepts/gpu.md` — GPU field, runtimeClassName, driver prerequisite
- `docs/workload-templates.md` — workload.yaml conventions