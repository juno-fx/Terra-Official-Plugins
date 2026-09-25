# Docker Registry

Self-hosted Docker container registry, exposed via NodePort for pushing and pulling images from any node in the cluster.

## What This Plugin Deploys

| Resource | Description |
|----------|-------------|
| `Deployment` | Single-replica registry (`docker.io/registry:2`) listening on port 5000 |
| `Service` | NodePort (auto-assigned in the 30000-32767 range) routing to port 5000 |
| `PersistentVolumeClaim` | RWO volume holding registry data at `/var/lib/registry` |
| `ConfigMap` | Registry config with `storage.delete.enabled: true` (required if garbage collection is enabled later) |
| `kuiper-config` ConfigMap | Kuiper instance metadata (`<release>-kuiper-config`) — lets Kuiper pick up the registry as a workload instance in the namespace |

All resources carry the `kuiper.juno-innovations.com/kuiper-instance` label so Kuiper discovers the registry as a single instance in the namespace.

## Configuration

| Field | Description |
|-------|-------------|
| `size` | Persistent volume size for registry storage (e.g. `10Gi`, `50Gi`) |
| `storageClass` | StorageClass for the registry PVC (empty = cluster default) |

## Usage

### Finding the NodePort

The NodePort is auto-assigned by Kubernetes. Find it after install:

```bash
kubectl get svc -n <project-namespace> <release-name> -o jsonpath='{.spec.ports[0].nodePort}'
```

### Pushing and Pulling

The registry speaks plaintext HTTP, so every Docker client pushing or pulling must list the registry as insecure. Configure the Docker daemon on each client:

```json
{ "insecure-registries": ["<node-ip>:<nodeport>"] }
```

Then push and pull using the node address and assigned port:

```bash
docker pull alpine:latest
docker tag alpine:latest <node-ip>:<nodeport>/alpine:latest
docker push <node-ip>:<nodeport>/alpine:latest
docker pull <node-ip>:<nodeport>/alpine:latest
```

## Storage

`size` and `storageClass` are set at install time. Changing `size` later is not retroactive: the PVC must already use a StorageClass with `allowVolumeExpansion` and you must resize it manually (`kubectl patch pvc`).