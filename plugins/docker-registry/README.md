# Docker Registry

Self-hosted Docker container registry, exposed via NodePort for pushing and pulling images from any node in the cluster.

## What This Plugin Deploys

| Resource | Description |
|----------|-------------|
| `Deployment` | Single-replica registry (`docker.io/registry:2`) listening on port 5000 |
| `Service` | NodePort (auto-assigned in the 30000-32767 range) routing to port 5000 |
| `PersistentVolumeClaim` | RWO volume holding registry data at `/var/lib/registry` |
| `ConfigMap` | Registry config with `storage.delete.enabled: true` |
| `kuiper-config` ConfigMap | Kuiper instance metadata (`<release>-kuiper-config`) — lets Kuiper pick up the registry as a workload instance in the namespace |

All resources carry the `kuiper.juno-innovations.com/kuiper-instance` label so Kuiper discovers the registry as a single instance in the namespace.

## Configuration

| Field | Description |
|-------|-------------|
| `size` | Persistent volume size for registry storage (e.g. `10Gi`, `50Gi`) |
| `storageClass` | StorageClass for the registry PVC (empty = cluster default) |
| `user` | User who owns this workload instance — passed into the `kuiper-config` ConfigMap so Kuiper attributes the registry to the right user |

## Usage

### Finding the NodePort

The NodePort is auto-assigned by Kubernetes. The user assigned to the workload sees it directly in Hubble via the **Connect** button on the registry instance in its target namespace — no `kubectl` needed. Alternatively:

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

**Always use the node IP, never `localhost`, from a Docker client.** A client resolving `localhost` tries `::1` first and is refused — the NodePort is served on the node's interfaces, and loopback isn't one of them from a client's perspective. `localhost` only works from inside the cluster (see below).

### Self-Referencing from Launched Workloads

Images pushed to this registry can be pulled by workloads launched through Juno without any registry, DNS, or ingress configuration, using `localhost`:

1. Push the image from any node in the cluster, as shown in [Pushing and Pulling](#pushing-and-pulling):
2. When creating a workload (e.g. in Genesis or Kuiper), reference the image as `localhost:<nodeport>/<repo>:<tag>` — the port is the one shown on the registry instance's Connect button:
   ```
   localhost:<nodeport>/alpine:latest
   ```

This works because **pulling is done by the kubelet on the node where the workload is scheduled**, not by the workload itself. The kubelet resolves `localhost` to its own node, hits that node's NodePort (bound on every node), and kube-proxy routes it straight to the registry pod. No imagePullSecret, no external address, no node-side registry config required.

This path is kubelet-only: external Docker clients must still use `<node-ip>:<nodeport>` with `insecure-registries` as above.

## Storage

`size` and `storageClass` are set at install time. Changing `size` later is not retroactive: the PVC must already use a StorageClass with `allowVolumeExpansion` and you must resize it manually (`kubectl patch pvc`).