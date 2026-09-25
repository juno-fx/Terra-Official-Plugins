# NFS Server

Self-hosted NFSv4 server, exposed via NodePort and backed by a configurable StorageClass. Creates an orphaned Persistent Volume pointing at `localhost` so the share is picked up automatically by the storage UI.

## What This Plugin Deploys

| Resource | Description |
|----------|-------------|
| `Deployment` | Single-replica NFS server (`gists/nfs-server`, multi-arch kernel-mode NFSv4) exporting `/nfsshare` (as the v4 pseudo-root) on port 2049 |
| `Service` | NodePort — the port you specify via the `port` field (default `32049`) routes to the NFS server |
| `PersistentVolumeClaim` | Backing store for the share, created from `size` + `storageClass` |
| `PersistentVolume` | **Orphaned** PV (`<release>-pv`) — `nfs.server: localhost`, `path: /`, with `port=<nodeport>` in `mountOptions`. No PVC claims it; the storage UI picks it up automatically |

The PV is cluster-scoped, so this is a cluster-level plugin. Only one instance per cluster is expected.

## Configuration

| Field | Description |
|-------|-------------|
| `size` | Size of the share and its backing volume (e.g. `10Gi`, `50Gi`) |
| `storageClass` | StorageClass backing the NFS server's data (empty = cluster default) |
| `port` | NodePort the NFS server listens on (`30000`-`32767`) |

## How Mounting Works

The PV's `nfs.server` is **`localhost`** — not a node IP. When a pod claims the PV, the kubelet on the pod's node runs `mount.nfs localhost:/ -o port=<nodeport>`. `localhost` resolves to the node itself, the NodePort rule (bound on every node) routes it to the NFS server pod, and the mount lands on the exported share (the server exports `/nfsshare` with `fsid=0`, so it appears as the NFSv4 pseudo-root `/`). No external IP, no ingress, no DNS.

Because it rides the NodePort, `mount.nfs` must be told which port to use — that's what the PV's `mountOptions` entry does:

```yaml
mountOptions:
  - "port=32049"
```

### Caveat: IPv6 `localhost` resolution

If the kubelet's `mount.nfs` resolves `localhost` to `::1` first and the cluster's NodePort rules don't listen on IPv6 loopback, the mount can fail at attach time. If you hit that, pin the PV server to `127.0.0.1` instead of `localhost` — same self-reference semantics, no `::1` ambiguity.

## Usage

### Finding the Share

The share appears in the storage UI as an unbound Persistent Volume — no manual action needed. Claim it from any PVC (or let the storage UI pick it) and mount it from a pod.

### Creating a Claim Manually

A PVC requesting `ReadWriteMany` with a capacity at or below `size` binds to the PV:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-share
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
```

## Storage

`size` and `storageClass` are set at install time. The backing PVC is created from them; changing `size` later is not retroactive — you must resize the PVC manually (`kubectl patch pvc`) and the StorageClass must allow expansion.

**If `storageClass` is left empty, the cluster MUST have a default StorageClass.** Otherwise the server's own data PVC (classless, same size, RWX) can bind the orphaned `localhost` PV, and the deployment deadlocks mounting itself through a NodePort that never comes up.

The server exports `rw` with NFS's default `root_squash` — root processes on clients write as `nobody`. Regular workload UIDs keep their identity.

## Node Requirements

- Nodes must have the `nfsd` kernel module **loaded** (most distros load it at boot; enable it or `modprobe nfsd` otherwise) — the `gists/nfs-server` container does not load it itself.
- The backing StorageClass must **not** be overlayfs-backed (e.g. k3s default `local-path` can land on overlay). OverlayFS does not support NFS export — use an ext4/xfs-backed class such as Longhorn if you see export failures at mount time.