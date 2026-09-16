# Orion Broker (orion-broker)

Workload template plugin that fronts **externally managed infrastructure** with
the Orion connection broker. It creates **NodePort services** that route
external clients to the backend's exposed ports. No workload pod is deployed —
traffic flows straight through to the external backend.

## How It Works

```
External Client
       │
       └──→ <node-IP>:<auto-assigned NodePort>   ← NodePort service (no selector)
                                                    │ kube-proxy + EndpointSlice
                                                    ▼
                                        Backend IP:443
                                      (Orion broker listener)
```

One NodePort service + matching EndpointSlice is generated per entry in the
`ports` list. Each EndpointSlice (with the `kubernetes.io/service-name` label)
points at the backend IP. NodePorts are **auto-assigned** by Kubernetes
(30000–32767).

## Launch Fields

| Field | Default | Purpose |
|-------|---------|---------|
| `ip` | *required* | IP address of the externally managed backend running the Orion broker (single address for now) |
| `ports` | `[{name: port, service_port: 443, protocol: TCP}]` | Repeatable list of ports to expose from the backend |

Each `ports` entry has:

| Sub-field | Default | Purpose |
|-----------|---------|---------|
| `name` | `port` | Name of the port — used as the Service port name and in `<workload>-port-<name>` resources |
| `service_port` | `443` | Port on the backend (also the Service port) |
| `protocol` | `TCP` | `TCP` or `UDP` |

## Access

External clients connect to each generated service's auto-assigned NodePort
(`kubectl get svc <workload>-port-<name>`). kube-proxy forwards traffic to the
backend's `service_port`, where the Orion broker handles authentication, session
management, and protocol termination.

Inspect the backend targets with:
`kubectl get endpointslice -l kubernetes.io/service-name=<workload>-port-<name>`

## Notes

- To change the backend IP, update `ip` at launch time, or patch the
  EndpointSlice resources afterward (the service definitions stay the same).
- `EndpointSlice` (not legacy `Endpoints`) is used — the Endpoints API is
  deprecated since Kubernetes 1.33. IPv4 backends only for now.