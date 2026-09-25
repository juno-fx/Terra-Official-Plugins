# Connection Brokers — Fronting Externally-Managed Infrastructure

**When to use:** the workload is a **pure proxy to externally-managed infrastructure** — a VDI
broker, an appliance, an external gateway. There is **no workload pod**: Kubernetes only routes
traffic to a backend that lives outside the cluster.

This is the "Server"-shaped special case: the chart renders Services and EndpointSlices, nothing
else. The reference plugin (`plugins/orion-broker`) fronts an Orion connection broker by IP.

## Shape — selector-less Service + EndpointSlice

Per `ports` entry, two resources:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ $.Values.name }}-port-{{ .name }}
spec:
  type: NodePort          # port auto-assigned from 30000–32767
  ports:
    - name: {{ .name }}   # must match the EndpointSlice port name — kube-proxy maps by name
      protocol: {{ .protocol }}
      port: {{ .service_port }}
      targetPort: {{ .service_port }}
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: {{ $.Values.name }}-port-{{ .name }}
  labels:
    kubernetes.io/service-name: {{ $.Values.name }}-port-{{ .name }}   # must equal the Service name
addressType: IPv4
ports:
  - name: {{ .name }}
    protocol: {{ .protocol }}
    port: {{ .service_port }}
endpoints:
  - addresses:
      - "{{ $.Values.ip }}"
```

- **Selector-less on purpose** — traffic routes to the EndpointSlice's backend IP, not to a pod.
- **NodePorts auto-assign** (30000–32767) — no manual nodePort.
- **EndpointSlice, not `Endpoints`** — the Endpoints API is deprecated since Kubernetes 1.33.
- Traffic flows straight through; nothing rewrites or terminates it.

## Launch fields (templates/metadata.yaml)

| Field | Type | Notes |
|-------|------|-------|
| `ip` | `string` | Required. IP of the externally-managed backend (single address for now) |
| `ports` | `list` | `name` (Service/EndpointSlice port name), `service_port` (backend + Service port), `protocol` (`TCP`/`UDP`) |

## Surfacing

The NodePorts are reachable on the cluster's nodes — the user dials `<node-ip>:<nodeport>`.
There is no Ingress (TCP/UDP passthrough — nginx would terminate HTTP), so the Hubble endpoint
list shows nothing by default. The reference implementation sets **no**
`kuiper.juno-innovations.com/connection` annotation — consider adding one
(`port=<nodePort>…` is not statically knowable with auto-assign; the backend's control-plane
details like `username=` still are) so Hubble surfaces the broker's reachability info.

## Gotchas

- **No pod** → probes, `automountServiceAccountToken`, image values, resource requests, PUID/PGID
  don't apply (`concepts/best-practices.md` exception).
- Port `name` mismatch between Service and EndpointSlice silently breaks routing (kube-proxy
  matches by name).
- The `kubernetes.io/service-name` label must equal the Service name **exactly**.
- IPv4 backends only (current reference; `addressType: IPv4`).
- **Auth is the backend's job** — there is no nginx, no Hubble auth; whatever the broker speaks
  must protect itself.
- Changing the backend IP: patch the EndpointSlice (services stay), or relaunch with a new `ip`.
- Ownership: the Services/EndpointSlices are plain top-level resources — Kuiper's injected
  `kuiper-instance` label covers cleanup; don't hand-set it on these.

## Reference implementation

`plugins/orion-broker/` — chart renders only `ports.yaml` (Services + EndpointSlices); category
`Server`, `juno-innovations.com/workload: "Server"` on `metadata.yaml`.