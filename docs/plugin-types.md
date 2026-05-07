# Plugin Types

While a Terra Plugin can be just about anything, we have organized the standard types you will encounter.
These types integrate directly into the Juno platform stack — Terra, Genesis, and Kuiper each behave
differently depending on plugin type.

---

## Choosing a Plugin Type

| Type | When to use | Install target | Example |
|------|-------------|----------------|---------|
| **Plugin / Application** | Any K8s workload in a user's namespace — Deployment, Job, StatefulSet, anything | User project namespace | `ollama`, `firefox`, `deadline10` |
| **Cluster-level** | Cluster-wide infrastructure installed into the `argocd` namespace — must be tagged `cluster-level` in `terra.yaml` | `argocd` namespace | `nvidia-gpu-operator`, `longhorn` |
| **Workload Template** | Provide a reusable workload schema for Genesis/Kuiper — requires the `cluster-level` tag | `argocd` namespace | `helios`, `web-ide` |
| **Dashboard** | Embed a web UI as an iFrame in Genesis | User project namespace | `argocd-dashboard` |

Not sure which to use? Ask:

- Does it install K8s objects into a user's project? → **Plugin / Application**
- Does it need to install into the cluster root (`argocd` ns) and manage its own namespaces? → **Cluster-level**
- Do users launch individual workloads from it (desktops, notebooks, terminals)? → **Workload Template**
- Is it just a web UI you want to embed in Genesis? → **Dashboard**

---

## Plugin & Application

A standard Helm chart of **any contents**. Deploys any valid Kubernetes objects (Deployments, Jobs,
CronJobs, StatefulSets, ConfigMaps, RBAC, etc.) into the user's project namespace. There is no required
directory structure beyond the standard Helm chart layout.

The only difference between a **Plugin** and an **Application** is that an Application requires a volume
field (`shared-volume` or `exclusive-volume`) in `terra.yaml`, giving users a storage location for the
app's data.

**Identifying marker:** no `cluster-level` tag in `terra.yaml`

**Examples:** `plugins/ollama/`, `plugins/firefox/`, `plugins/deadline10/`

---

## Cluster-Level

Identical to a namespaced plugin mechanically — a standard Helm chart of any contents. The only
difference is the install target: Terra installs cluster-level plugins into the `argocd` namespace
instead of the user's project namespace. The plugin is expected to create and manage its own namespaces
if needed.

A common pattern is to include an ArgoCD `Application` resource that delegates to an upstream Helm chart,
but this is a convention, not a requirement. Any valid Kubernetes objects work.

**Identifying marker:** `terra.yaml` tags array includes `cluster-level`

**Examples:** `plugins/nvidia-gpu-operator/`, `plugins/longhorn/`, `plugins/cert-manager/`

```yaml linenums="1" title="terra.yaml — cluster-level tag"
tags:
  - cluster-level
```

---

## Workload Template

A schema plugin consumed by **Genesis** and **Kuiper**. Does not deploy a running workload at install time.
Instead, it installs a ConfigMap containing an embedded Helm chart (`scripts/chart/`). When a user creates
a workload in Genesis, Kuiper renders that embedded chart using the values the user provided.

**Identifying markers:**
- `templates/metadata.yaml` has label `kuiper.juno-innovations.com/chart: "{{ .Release.Name }}-scripts-configmap"`
- `templates/metadata.yaml` has annotation `juno-innovations.com/workload: "<Type>"`
- `templates/metadata.yaml` `data.fields:` is populated with a YAML schema list
- `scripts/chart/` directory exists containing a nested Helm chart
- `terra.yaml` tags array includes `cluster-level`
- No `templates/wave-1/` directory

**Examples:** `plugins/helios/`, `plugins/web-ide/`, `plugins/jupyter-notebook/`, `plugins/wetty/`

For a complete deep-dive, see [Workload Templates](workload-templates.md).

### `metadata.yaml` — The Workload Template Contract

The `templates/metadata.yaml` ConfigMap does two jobs:

1. **Discovery** — the `kuiper.juno-innovations.com/chart` label tells Genesis to include this plugin
   in its workload catalog.
2. **Schema** — the `data.fields:` block defines the parameters shown in the Genesis workload-creation UI.
   These values become Helm values passed to `scripts/chart/` by Kuiper at launch time.

```yaml linenums="1" title="Workload template metadata.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{{ .Release.Name }}-terra-metadata"
  labels:
    # Tells Genesis this is a workload template
    kuiper.juno-innovations.com/chart: "{{ .Release.Name }}-scripts-configmap"
  annotations:
    # Workload category in Genesis UI and Hubble
    # Valid values: Application | Terminal | Workspace | Server | Virtual Machine
    juno-innovations.com/workload: "Application"
data:
  chart: "{{ .Release.Name }}-scripts-configmap"
  description: "My workload description"
  fields: |
    - name: registry
      description: "Container registry"
      type: string
      required: true
      default: "docker.io"
    - name: repo
      description: "Image repository"
      type: string
      required: true
    - name: tag
      description: "Image tag"
      type: string
      required: true
      default: "latest"
    - name: gpu
      description: "Attach a GPU"
      type: boolean
      required: true
```

!!! warning "Field names must match `values.yaml`"
    Every `name:` in `fields:` must have a matching key in `scripts/chart/values.yaml`.
    A mismatch causes Helm template rendering to fail silently when a workload is launched.

!!! warning "Annotation required on StatefulSet too"
    The `juno-innovations.com/workload` annotation must also appear on the StatefulSet in
    `scripts/chart/templates/workstation.yaml`. This is how Hubble categorizes the running workload.

### `scripts/chart/` — The Embedded Helm Chart

For workload templates, `scripts/` contains a full Helm chart at `scripts/chart/`. This is the workload
definition. It is packaged by `make package`, stored as a base64 blob in a ConfigMap, and rendered by
Kuiper at workload launch time.

```
scripts/
├── entrypoint.sh              # Required for packaging; not executed at launch
└── chart/
    ├── Chart.yaml
    ├── values.yaml            # All field names from metadata.yaml must exist here
    └── templates/
        ├── workstation.yaml   # StatefulSet — the running workload
        ├── service.yaml       # ClusterIP Service
        └── ingress.yaml       # nginx Ingress with Hubble auth
```

!!! danger "Repackage after every change"
    After any change to `scripts/` or `scripts/chart/`, you must run:
    ```bash
    make package <plugin-name>
    ```
    The `templates/packaged-scripts.yaml` file is generated — edits to it are overwritten.
    See [Packaging](advanced.md#terra-packaging) for full details.

---

## Dashboards

Dashboards embed a web UI directly into the Genesis interface via an iFrame. Any plugin with a `dashboard`
category or tag is treated as a dashboard. They also support permission gating.

```yaml linenums="1" title="Dashboard metadata.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-terra-metadata
data:
  chart: "{{ .Chart.Name }}"
  ingress: "{{ .Values.prefix }}"
  permission: "admin"  # only admin users can access this iFrame
```

**Examples:** `plugins/argocd-dashboard/`, `plugins/headlamp/`

---

## Bundles

Bundles install multiple plugins together. Defined in the `bundles/` directory.
See [Repositories](repositories.md#bundles) for details.
