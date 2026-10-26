# vCluster Juno

Deploy a fully isolated virtual cluster ([vCluster](https://www.vcluster.com/)) with a
complete Juno deployment running inside it. Each install creates its own Kubernetes
control plane running ArgoCD and the full Juno stack (Genesis, Titan, Terra, Metrics
Gatherer, Rhea) — true multi-tenancy with full isolation of namespaces, CRDs, and RBAC,
while sharing the host cluster's nodes and storage.

This is a **namespaced** plugin: the vCluster control plane and all supporting
resources are installed into the user's project namespace. Every resource created
by the plugin carries the label
`kuiper.juno-innovations.com/kuiper-instance: <release>` for ownership tracking.

## How It Works

```
Install (Terra)
  │
  ├─ wave 1: ArgoCD Application → loft-sh/vcluster chart
  │            → vCluster control plane (etcd + api-server + syncer)
  │              in the project namespace
  │
  └─ wave 2: Installer Job (project namespace)
               1. waits for the vCluster kubeconfig secret
               2. installs ArgoCD inside the vCluster (server-side apply)
               3. verifies CRDs + controller stability
               4. labels vCluster nodes for Juno scheduling
               5. applies the "juno" ArgoCD Application inside the vCluster
                    → ArgoCD (in vCluster) syncs Genesis-Deployment
                    → Juno ingress syncs back to the host ingress controller
```

The Juno web UI is served through the **host** ingress controller: the Genesis chart
creates an Ingress inside the vCluster, and the vCluster syncer (`sync.toHost.ingresses`)
mirrors it to the host, where the host's ingress controller routes `juno_hostname` to the
synced pods.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Ingress controller on host | nginx assumed by the ingress annotations |
| DNS for `juno_hostname` | Must point at the host ingress controller **before** install |
| DNS for `vcluster_hostname` | Only if exposing the vCluster API; requires ssl-passthrough enabled on the ingress controller (`--enable-ssl-passthrough`) |
| StorageClass on host | vCluster PVCs sync to the host |
| Outbound network | The installer Job pulls the ArgoCD manifest from raw.githubusercontent.com; ArgoCD inside the vCluster pulls charts from github.com and charts.loft.sh |

No CRDs need to be pre-installed on the host — vCluster v0.35.x is a self-contained
Helm chart; its CRDs live inside the virtual cluster's own API server.

## Fields

- **juno_hostname** (required) — DNS name for the Juno web UI.
- **vcluster_hostname** — optionally expose the vCluster Kubernetes API via ingress
  (ssl-passthrough). Leave empty to keep the API internal.
- **auth_type** + credentials — authentication for the Juno instance
  (`basic`, `google`, `cognito`, or `ldap`; fill in the matching credential fields).
- **titan_owner / titan_uid / titan_email** — initial admin identity.
- **sync_host_nodes** — pass real host nodes through to the vCluster
  (default: single virtual node).
- **label_nodes** — label all vCluster nodes with `juno-innovations.com/service=true`
  and `juno-innovations.com/workstation=true` so Juno services and workloads schedule
  (default: true).
- **k8s_version / vcluster_chart_version / argocd_version / genesis_chart_version** —
  version pins.

## Accessing the vCluster API

The kubeconfig is exported to the secret `vc-<release>` in the project namespace
on the host:

```bash
kubectl get secret vc-<release> -n <project-namespace> \
  -o jsonpath='{.data.config}' | base64 -d > vc-kubeconfig
kubectl --kubeconfig=vc-kubeconfig get pods -A
```

If `vcluster_hostname` is set, rewrite the server URL in that kubeconfig to
`https://<vcluster_hostname>` for access from outside the cluster.

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| Installer Job retrying "Waiting for vCluster kubeconfig secret" | vCluster pod not up yet — check pods in the project namespace; image pull for the K8s version can take a few minutes |
| `ghcr.io/loft-sh/kubernetes:<version>: not found` | K8s version tag must be `v`-prefixed (the plugin normalizes this automatically) |
| applicationset-controller CrashLoopBackOff inside vCluster | ArgoCD CRDs were applied client-side and silently rejected (>256KB annotation limit). The installer uses `--server-side` to prevent this; re-run the installer Job if it was bypassed |
| Juno pods Pending inside vCluster | Nodes missing `juno-innovations.com/service=true` label — keep `label_nodes: true`, or label nodes inside the vCluster manually |
| Juno UI unreachable | Check the synced ingress exists on the host (`kubectl get ingress -n <project-namespace>`), DNS resolves to the ingress controller, and TLS is provisioned for the hostname |
| ClusterIP services unreachable *inside* the vCluster | Known vCluster v0.35.x service-proxy limitation for in-vCluster traffic; host-side routing (used for the Juno UI) is unaffected |

## Uninstall

Uninstalling the plugin cascade-deletes the vCluster Application (and with it the
vCluster chart resources); a PostDelete hook sweeps what the cascade doesn't cover —
the vCluster's data PVC and the exported kubeconfig secrets. The project namespace
itself is left untouched. Everything inside the vCluster (ArgoCD, Juno, user
workloads) is destroyed with it.
