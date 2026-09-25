# Service Exposure — NodePort, LoadBalancer, and No-Ingress Workloads

**When to use:** the workload serves **non-HTTP traffic** — game servers (TCP/UDP), SSH/RDP, LDAP,
custom binary protocols — or needs ports reachable directly on the node. The nginx ingress that
carries platform traffic is **HTTP(S)-only**: it cannot proxy raw game packets. Such workloads
expose via a plain Service instead.

HTTP workloads go to `concepts/ingress.md` (auth, paths, Hubble endpoint visibility). The two can
coexist: a game server can ship an ingress for its web admin alongside a NodePort Service for the
game port.

## Choosing a Service type

| Type | Reachable | When |
|------|-----------|------|
| `ClusterIP` | cluster-internal only | internal APIs, admin ports, rcon-style side channels |
| `NodePort` | `<node-ip>:<nodePort>` on every node | default for non-HTTP exposure; high port 30000–32767 |
| `LoadBalancer` | external IP (MetalLB/cloud LB) | needs a stable external address; implies a nodePort too |

`LoadBalancer` requires `plugins/metallb` (cluster-level) or a cloud load balancer in the cluster.

## nodePort strategies

### a) Auto-assign

Omit `nodePort` — Kubernetes picks a random free port (30000–32767). Fine for single-port needs:

```yaml
spec:
  type: NodePort
  ports:
    - name: game
      port: 25565
      targetPort: 25565
      protocol: TCP
```

Reference: `plugins/minecraft/` (game + separate rcon Service, both NodePort).

### b) Fixed values

User-set `nodePort` fields — explicit, but must be unique **cluster-wide**. Two launches asking
for the same nodePort: Kubernetes rejects the second Service.

```yaml
ports:
  - port: {{ .Values.ldapPort }}
    targetPort: 389
    nodePort: {{ .Values.ldapNodePort }}
```

Reference: `plugins/simple-ldap/`.

### c) Deterministic adjacent range — consecutive ports the client expects

Some clients assume consecutive ports internally — the Conan pinger looks up game-port + 1, mod
listings and RDP-family consoles expect ranges. Kubernetes would otherwise allocate random,
unrelated nodePorts. Derive the base port from a **stable input** so the pair is identical across
ArgoCD syncs and Kuiper re-renders:

```yaml
{{- $sum := 0 -}}
{{- range $i, $run := regexFindAll "[0-9]+" (sha256sum (printf "%s-%s" .Release.Namespace .Values.name)) -1 -}}
{{- $sum = add $sum (int $run) -}}
{{- end -}}
{{- $autoNP := add 30000 (mod $sum 2767) }}
spec:
  ports:
    - name: game
      port: {{ .Values.gamePort }}
      targetPort: game
      protocol: {{ .Values.gameProtocol }}
      nodePort: {{ $autoNP }}
    {{- range $i, $ep := .Values.extraPorts }}
    - name: {{ $ep.name }}
      port: {{ $ep.port }}
      targetPort: {{ $ep.port }}
      protocol: {{ $ep.protocol | default "TCP" }}
      nodePort: {{ add $autoNP (add 1 $i) }}
    {{- end }}
```

Rules:

- **Include `.Release.Namespace` in the hash input** — the pair is only unique if the input is.
  A bare workload name collides across environments sharing a cluster (the external reference uses
  `.Release.Name` alone; namespace-prefix it here).
- **Bound the mod so extras never overflow**: max base = `32767 − (extras + 1)`. The reference
  uses `mod 2767` for exactly one extra port.
- No user override — auto-derived from the stable input, so syncs/re-renders never shuffle ports.

Pattern source: `Terra-Games/plugins/conan-exiles/` (external catalog).

### d) Internal-only ports

Ports users don't need externally (rcon, admin APIs) simply omit `nodePort` — ClusterIP-only
inside a NodePort Service, or their own ClusterIP Service.

## Fields (templates/metadata.yaml)

| Field | Type | Notes |
|-------|------|-------|
| `service_type` | `select` | `ClusterIP` / `NodePort` / `LoadBalancer` — user picks at launch |
| `ports` | `list` | `name`, `port`, `protocol` (`TCP`/`UDP`), optional `nodePort` |
| `gamePort` / `gameProtocol` + `extraPorts` | `int` / `select` / `list` | single main port + stacked extras (adjacent-range shape) |

Every field needs a matching key in `scripts/chart/values.yaml` (Rule 3).

## Surfacing

There is **no Hubble/nginx auth on plain Services** — the backend must protect itself. Surface
reachability via `kuiper.juno-innovations.com/connection` (`concepts/labels-annotations.md`):

- `ClusterIP` — in-cluster name/port are knowable (`<name>.svc`, static port).
- `NodePort` auto-assigned — the port is **not** statically knowable; leave it out of the
  annotation, or use fixed/deterministic ports so it is.
- Deterministic adjacent range — the port IS derivable; the annotation can carry it.

## Gotchas

- nodePorts are unique **cluster-wide**, not per namespace — collision rejects the second Service
  at create time.
- The 30000–32767 range is fixed by the API server (`--service-node-port-range`); not
  configurable per workload.
- Cloud node security groups / firewalls must open the nodePort range or the ports stay
  unreachable.
- `LoadBalancer` IPs may change unless reserved; MetalLB configuration decides.
- Selector must match the pod labels — for workload templates use
  `kuiper.juno-innovations.com/kuiper-instance: "{{ .Values.name }}"`.
- Adjacency derivation must stay deterministic — anything random (`.Values.idx`, timestamps)
  shuffles ports on every re-render and breaks pinned client assumptions.
- `protocol` supports `TCP`, `UDP`, `SCTP`; keep port `name` unique within each Service.

## See also

- `concepts/connection-brokers.md` — same Service mechanics, but selector-less + EndpointSlice for
  **external** backends (no pod).
- `concepts/vm.md` — VM `ports` share the Service types.
- `concepts/ingress.md` — when HTTP + auth + paths fit instead.
- `concepts/labels-annotations.md` — the `connection` annotation.

## Reference implementations

In-repo: `plugins/minecraft` (auto NodePort ×2), `plugins/ollama` (`enable_node_port` value),
`plugins/simple-ldap` (fixed nodePorts), `plugins/runtime-*` (`network_mode` field). Adjacent-range
pattern: `Terra-Games/plugins/conan-exiles` (external catalog — `service_type`, `gamePort`,
`extraPorts`, deterministic N/N+1 pair).