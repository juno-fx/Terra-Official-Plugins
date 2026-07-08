# AGENTS.md — Terra Official Plugins

This file provides authoritative guidance for AI agents and automated tools working in this repository.
Read this before making any changes to plugins or tooling.

---

## Repository Purpose

This repository is the official plugin catalog for the **Juno platform** (Terra/Genesis/Kuiper/ArgoCD stack).
Plugins are Helm charts that Terra installs into Kubernetes clusters via ArgoCD `Application` resources.

**Platform component roles:**

| Component | Role |
|-----------|------|
| **Terra** | Plugin marketplace — installs plugins as ArgoCD Applications |
| **ArgoCD** | GitOps engine — syncs Helm charts from this repo into the cluster |
| **Genesis** | Workload template catalog — reads workload template schemas from ConfigMaps |
| **Kuiper** | Workload launcher — renders embedded Helm charts at workload launch time |

All plugins live in `plugins/<plugin-name>/`. Do not create plugins outside this directory.

---

## Plugin Type Taxonomy

There are three distinct plugin types. Identify a plugin's type by examining its files.

### 1. Namespaced Plugin

A standard Helm chart of any contents installed into the user's project namespace. There are no
structural requirements — it can contain any valid Kubernetes objects (Deployments, Jobs, CronJobs,
ConfigMaps, RBAC, etc.) organized however makes sense for the plugin.

**Identifying marker:**
- `terra.yaml` tags array does **not** include `cluster-level`

**Example:** `plugins/ollama/`, `plugins/firefox/`, `plugins/deadline10/`

**Install target:** User's project namespace

---

### 2. Cluster-Level Plugin

Identical to a namespaced plugin mechanically — a standard Helm chart of any contents. The only
difference is that Terra installs it into the `argocd` namespace instead of the user's project
namespace. The plugin is expected to create and manage its own namespaces if needed.

**Identifying marker:**
- `terra.yaml` tags array includes `cluster-level`

**Example:** `plugins/nvidia-gpu-operator/`, `plugins/longhorn/`, `plugins/cert-manager/`

**Install target:** `argocd` namespace

---

### 3. Workload Template

A schema plugin consumed by Genesis and Kuiper. Does **not** deploy a running workload at install time.
Instead, it installs a ConfigMap containing an embedded Helm chart (`scripts/chart/`). Kuiper renders
this embedded chart at workload launch time using the field values defined in `templates/metadata.yaml`.

**Identifying markers:**
- `templates/metadata.yaml` has label `kuiper.juno-innovations.com/chart: "{{ .Release.Name }}-scripts-configmap"`
- `templates/metadata.yaml` has annotation `juno-innovations.com/workload: "<Type>"`
- `templates/metadata.yaml` `data.fields:` is populated with a YAML list
- `scripts/chart/` directory exists containing a nested Helm chart
- `terra.yaml` tags array includes `cluster-level`
- No `templates/wave-1/` directory

**Example:** `plugins/helios/`, `plugins/web-ide/`, `plugins/jupyter-notebook/`

**Install target:** `argocd` namespace

**Directory structure:**

```
plugins/my-template/
├── Chart.yaml
├── terra.yaml                          # tags: [cluster-level], fields: []
├── values.yaml
├── templates/
│   ├── metadata.yaml                   # THE CONTRACT — discovery label + fields schema
│   ├── packaged-scripts.yaml           # GENERATED — never edit
│   └── packaged-scripts-cleanup.yaml   # GENERATED — never edit
└── scripts/
    ├── entrypoint.sh
    └── chart/                          # THE PAYLOAD — embedded Helm chart
        ├── Chart.yaml
        ├── values.yaml                 # Must contain all fields from metadata.yaml
        ├── files/nginx/
        │   └── default.conf            # Nginx sidecar config (auth_request + proxy_pass)
        └── templates/
            ├── statefulset.yaml        # StatefulSet — the running workload
            ├── service.yaml
            ├── ingress.yaml
            └── nginx-configmap.yaml    # Loads files/nginx/default.conf via tpl
```

---

## Critical Rules — Read Before Making Changes

### Rule 1: Always repackage after changing `scripts/`

`templates/packaged-scripts.yaml` and `templates/packaged-scripts-cleanup.yaml` are **generated files**.
They are produced by `make package <plugin>` and contain the entire `scripts/` directory base64-encoded
into a Kubernetes ConfigMap. They must **never** be hand-edited.

**After any change to `scripts/` or `scripts/chart/` for any plugin, you MUST run:**

```bash
make package <plugin-name>
```

Failure to do this will result in the old scripts being deployed, with no error message from Terra or ArgoCD.
This is the most common source of bugs in this repository.

**To verify all plugins are packaged:**

```bash
make verify
```

This will hard-fail listing every plugin with stale packages.

### Rule 2: The 1MiB ConfigMap limit

Kubernetes enforces a 1MiB limit on ConfigMap data. The entire `scripts/` directory (gzip-compressed,
then base64-encoded) must fit within this limit. `make package` automatically runs `make check-size`
to warn at 900KB and error at 1MiB. If you add large files to `scripts/` or `scripts/chart/`,
check the size:

```bash
make check-size <plugin-name>
```

**Never add large binaries, media files, or uncompressed data to `scripts/`.** Trim unnecessary files
from `scripts/chart/` if approaching the limit.

### Rule 3: `metadata.yaml` is the workload template contract

For workload template plugins, `templates/metadata.yaml` defines two things:

1. **Discovery** — the `kuiper.juno-innovations.com/chart` label tells Genesis this is a workload template
2. **Schema** — the `data.fields:` YAML block defines the parameters shown in the Genesis workload UI,
   which become Helm values passed to `scripts/chart/` by Kuiper at launch time

**Field names in `data.fields:` must exactly match value names in `scripts/chart/values.yaml`.**
Adding a field without a corresponding value in `values.yaml` will cause Helm template rendering to fail
when a workload is launched.

### Rule 4: Never modify generated files

These files are always overwritten by `make package` — do not edit them:

- `plugins/*/templates/packaged-scripts.yaml`
- `plugins/*/templates/packaged-scripts-cleanup.yaml`

### Rule 5: `terra.yaml` fields are install-time only

Fields in `terra.yaml` are shown to users in the Terra app store **at install time**. They become Helm
values passed to `templates/` at ArgoCD sync time. They are **not** the same as workload template fields
in `templates/metadata.yaml`, which are shown at **workload launch time**.

---

## File Ownership Map

| File/Directory | Authored | Generated | Notes |
|----------------|----------|-----------|-------|
| `plugins/*/Chart.yaml` | ✓ | | Helm chart metadata |
| `plugins/*/terra.yaml` | ✓ | | Terra UI descriptor |
| `plugins/*/values.yaml` | ✓ | | Helm default values |
| `plugins/*/templates/*.yaml` | ✓ | | Helm templates (except packaged-scripts*) |
| `plugins/*/templates/packaged-scripts.yaml` | | ✓ | Generated by `make package` |
| `plugins/*/templates/packaged-scripts-cleanup.yaml` | | ✓ | Generated by `make package` |
| `plugins/*/scripts/` | ✓ | | Source scripts — edit these |
| `plugins/*/scripts/chart/` | ✓ | | Workload template Helm chart (workload plugins only) |
| `plugins/*/scripts/chart/files/nginx/` | ✓ | | Nginx sidecar config — edit `default.conf` |
| `plugins/*/scripts/chart/templates/*.yaml` | ✓ | | Helm templates for the embedded chart |
| `plugins/*/scripts/chart/templates/nginx-configmap.yaml` | ✓ | | Thin wrapper loading `files/nginx/` via `tpl` |

---

## Packaging Workflow

```
scripts/                                    ← edit these files
    └── entrypoint.sh
    └── chart/                              ← workload template embedded Helm chart
        └── templates/statefulset.yaml
            make package <plugin>
                ↓ tar --owner=0 ... -czf scripts.tar scripts/
                ↓ base64 -w 0 scripts.tar
                ↓ inject into ConfigMap YAML
templates/packaged-scripts.yaml             ← generated, committed to git
templates/packaged-scripts-cleanup.yaml     ← generated, committed to git
                ↓ ArgoCD syncs
ConfigMap in argocd namespace               ← Genesis reads packaged_scripts.base64
                ↓ Genesis catalog API
Kuiper receives base64 chart string
                ↓ b64decode → tar extract → helm template
Workload manifests applied to cluster
```

---

## Workload Template — Full Data Flow

1. **Plugin install:** Terra creates an ArgoCD `Application` pointing at `plugins/<name>/`. ArgoCD syncs, creating:
   - `<release>-terra-metadata` ConfigMap — carries the `kuiper.juno-innovations.com/chart` label and `fields:` schema
   - `<release>-scripts-configmap` ConfigMap — carries `packaged_scripts.base64` (the base64 gzip tarball of `scripts/`)

2. **Genesis catalog:** Genesis lists all ConfigMaps in the `argocd` namespace with label `kuiper.juno-innovations.com/chart`.
   For each, it reads:
   - `data.fields` → the schema presented in the workload creation UI
   - `data.chart` → name of the scripts ConfigMap
   - Then fetches that scripts ConfigMap and reads `packaged_scripts.base64`

3. **Workload launch (Kuiper):** User creates a workload in Genesis. Kuiper receives the base64 chart string,
   decodes it, extracts `scripts/chart/`, runs `helm template` with the user-provided field values,
   and applies the rendered manifests.

---

## `metadata.yaml` Anatomy — Workload Template

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{{ .Release.Name }}-terra-metadata"
  labels:
    # REQUIRED: tells Genesis this is a workload template. Value must point to the scripts ConfigMap.
    kuiper.juno-innovations.com/chart: "{{ .Release.Name }}-scripts-configmap"
  annotations:
    # REQUIRED: workload category shown in Genesis UI and Hubble.
    # Valid values: Application | Terminal | Workspace | Server | Virtual Machine
    juno-innovations.com/workload: "Application"
data:
  # REQUIRED: must match the label value above.
  chart: "{{ .Release.Name }}-scripts-configmap"
  # Optional: shown in Genesis catalog.
  description: "Human-readable description"
  # REQUIRED: schema for the Genesis workload creation form.
  # Each entry becomes a Helm value passed to scripts/chart/ by Kuiper.
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
    - name: publicAccess
      description: "Allow public access (disable authentication)"
      type: boolean
      required: true
      default: false
    - name: nginx_registry
      description: "Registry to pull the nginx sidecar image from"
      type: string
      required: true
      default: "docker.io"
    - name: nginx_repo
      description: "Repository to pull the nginx sidecar image from"
      type: string
      required: true
      default: "nginx"
    - name: nginx_tag
      description: "Tag to pull the nginx sidecar image from"
      type: string
      required: true
      default: "alpine"
```

**The `juno-innovations.com/workload` annotation must also appear in `scripts/chart/templates/statefulset.yaml`**
on the StatefulSet metadata — this is how Hubble categorizes the running workload in its UI.

**Valid `juno-innovations.com/workload` values:**

| Value | Used for |
|-------|---------|
| `Application` | General GUI applications |
| `Terminal` | Shell / terminal workloads |
| `Workspace` | Full desktop or IDE environments |
| `Server` | Headless server workloads |
| `Virtual Machine` | KubeVirt VM workloads |

---

## `scripts/chart/values.yaml` — Standard Kuiper-Injected Keys

Kuiper always injects these keys when rendering the embedded chart. They must be present in
`scripts/chart/values.yaml` or Helm rendering will fail. Do not remove them from the scaffold.

```yaml
# Kuiper-injected standard values — do not remove
name: my-template
user:
group:
cpu: "1"
memory: "1Gi"
cpuLimit: null
memoryLimit: null
idx: 0
guid: 0
puid: 0
host:
pullSecret:
session:
volumeMounts: []
volumes: []
env:
  - name: JUNO
    value: "true"
selector:
plugins: []
_kuiper:
```

User-facing fields from `metadata.yaml` are added below these standard keys.

---

## `scripts/chart/templates/statefulset.yaml` — Required Conventions

The StatefulSet that Kuiper deploys must follow these conventions:

- **`juno-innovations.com/workload` annotation** — must match `metadata.yaml` value
- **`kuiper.juno-innovations.com/kuiper-instance` label** — on metadata, pod template, and as `matchLabels` selector. This is Kuiper's primary discovery mechanism.
- **Nginx sidecar** — container named `nginx` on port 8080, using `{{ .Values.nginx_registry }}/{{ .Values.nginx_repo }}:{{ .Values.nginx_tag }}` as the image with minimal resource requests (64Mi memory, 50m CPU). Mounts nginx ConfigMap at `/etc/nginx/conf.d/default.conf`.
- **Nginx ConfigMap** — define a ConfigMap named `{{ .Values.name }}-nginx` with `default.conf` loaded from `files/nginx/default.conf` via `tpl`.
- **Optional node selection** — use `{{- if .Values.selector }}` around an `affinity.nodeAffinity` block to support custom node selectors. No hardcoded workstation affinity is required.
- **Standard env vars** — set `JUNO_WORKSTATION`, `JUNO_PROJECT`, `USER`, `HOME`, `PREFIX` as defined in the Kuiper-injected values.

The nginx config lives in an external file at `files/nginx/default.conf` and is loaded via:

```yaml
data:
  default.conf: |
{{ tpl (.Files.Get "files/nginx/default.conf") . | indent 4 }}
```

See `plugins/filebrowser/scripts/chart/templates/statefulset.yaml` for a minimal reference, or `plugins/gitea/scripts/chart/templates/statefulset.yaml` for the full pattern with dedicated `nginx_registry`/`nginx_repo`/`nginx_tag` fields.

---

## `terra.yaml` Top-Level Properties

| Property | Required | Description |
|----------|----------|-------------|
| `resource_id` | yes | Unique identifier for the plugin (used by Terra internally) |
| `name` | yes | Display name shown in the Terra app store |
| `icon` | yes | Icon URL or identifier shown in the Terra app store |
| `description` | yes | Short description shown in the Terra app store |
| `category` | yes | Category grouping in the Terra app store |
| `tags` | yes | List of tags. Include `cluster-level` for cluster-level plugins |
| `fields` | yes | List of install-time field definitions (can be empty `[]`) |
| `editable` | no | `true` \| `false` — allows users to edit field values after install. Default: `false` |
| `compatibility` | no | Pip-style platform version constraint string. Terra blocks install if not met. Example: `genesis-deployment>=3.0.2,orion-deployment>=3.1.0` |

---

## Kuiper Annotations Reference

Annotations are set on Kubernetes resources inside `scripts/chart/templates/` to control how Kuiper
manages the workload. All keys use the `kuiper.juno-innovations.com/` prefix unless noted.

**These annotations only apply to workload template plugins.** Namespaced and cluster-level plugins
are synced directly by ArgoCD and never pass through Kuiper — annotations have no effect there.

### Nginx Sidecar Authentication

Authentication is handled by an **nginx sidecar container** inside the workload pod, not by ingress
annotations. The sidecar uses nginx's `auth_request` module to validate every request against the
platform auth service before proxying to the app container.

```
Request → Ingress (plain route, no auth annotations) → Service → Pod
                                                              └─ nginx sidecar (port 8080)
                                                                   ├─ auth_request → Hubble/Genesis
                                                                   └─ proxy_pass → 127.0.0.1:APP_PORT
                                                              └─ app container
```

**Workload templates** — authenticate via Hubble. Sidecar nginx config at `files/nginx/default.conf`:

```nginx
location /plugin/{{ .Values.name }}/ {
    auth_request /auth;
    proxy_pass http://127.0.0.1:APP_PORT;
}

location = /auth {
    internal;
    proxy_pass http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/;
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header X-Original-URI $request_uri;
    proxy_set_header Upgrade "";
    proxy_set_header Connection "";
}
```

**Namespaced / cluster-level plugins** — authenticate via Genesis:

```nginx
location = /auth {
    internal;
    proxy_pass http://genesis.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-service/{{ .Release.Name }}/;
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header X-Original-URI $request_uri;
    proxy_set_header Upgrade "";
    proxy_set_header Connection "";
}
```

**Conditional auth** — wrap `auth_request` in a Helm conditional for plugins that support public access:

```yaml
{{- if not .Values.publicAccess }}
auth_request /auth;
{{- end }}
```

The nginx config is loaded from an external file into a ConfigMap via `tpl`:

```yaml
data:
  default.conf: |
{{ tpl (.Files.Get "files/nginx/default.conf") . | indent 4 }}
```

The ingress itself carries no nginx annotations — only a conditional `ingressClassName`:

### Plugin-Author Annotations

These are set by plugin authors in their Helm chart templates.

#### General

| Annotation | Applies To | Value Format | Description |
|------------|-----------|--------------|-------------|
| `kuiper.juno-innovations.com/actions` | any resource | comma-separated action names | Whitelist of callable actions on a resource (e.g. `restart,stop,scale`). Only listed actions are callable via the Kuiper API. |
| `kuiper.juno-innovations.com/connection` | any resource | `key=value,key=value` | Connection details surfaced as endpoint metadata in the Hubble UI (e.g. `username=admin,port=5900`). |
| `kuiper.juno-innovations.com/adopt-<name>` | any resource | Kubernetes Kind (e.g. `Service`) | Adopts a deterministically-named resource created **outside** the chart into the workload. The suffix `<name>` is the resource name; value is its Kind. Kuiper patches the ownership label onto it so it is tracked and cleaned up with the workload. Canonical use: adopting the ExternalName Service Kuiper creates post-launch for an EC2 instance. |

#### Ingress

| Annotation | Applies To | Value Format | Description |
|------------|-----------|--------------|-------------|
| `kuiper.juno-innovations.com/ingress-hide` | Ingress | comma-separated URL paths | Hides listed paths from the endpoint list in Hubble (e.g. `/admin,/metrics`). |
| `kuiper.juno-innovations.com/ingress-extras` | Ingress | comma-separated sub-paths | Appends extra sub-paths to existing ingress endpoints in Hubble without adding new Ingress rules. |

#### Crossplane / EC2

| Annotation | Applies To | Value Format | Description |
|------------|-----------|--------------|-------------|
| `kuiper.juno-innovations.com/expose` | Crossplane EC2 Instance | comma-separated port numbers | Kuiper auto-creates a Kubernetes ExternalName Service exposing these ports once EC2 DNS is available. |
| `kuiper.juno-innovations.com/aws-remote-connection` | Crossplane EC2 Instance | `"true"` | Triggers Kuiper to compute and write the `connection` annotation once EC2 DNS is available. |
| `kuiper.juno-innovations.com/use-private-dns` | Crossplane EC2 Instance | `"true"` | Use `privateDnsName` instead of `publicDnsName` when building the ExternalName Service and connection annotation. |

---

### Plugin-Author Labels

These labels are set by plugin authors on their resources. They are Kuiper's primary mechanism for workload discovery.

| Label | Applies To | Value Format | Description |
|-------|-----------|--------------|-------------|
| `kuiper.juno-innovations.com/kuiper-instance` | all resources | workload instance name | **Required.** Kuiper's primary discovery and ownership label. Every resource in a workload (StatefulSet, Service, Ingress, ConfigMap, PVC, RBAC) must carry this label. Used as `label_selector` for all Kuiper `list`/`watch` operations. |
| `kuiper.juno-innovations.com/plugin` | ConfigMap | `"true"` | Marks ConfigMaps as plugins in the Kuiper config API. |
| `kuiper.juno-innovations.com/user-created-datavolume` | DataVolume | `"true"` | Marks DataVolume clones as user-created. Used by the `dataVolume` field type in Genesis UI. |
| `juno-innovations.com/kuiper-instance` | any resource | workload instance name | **Deprecated.** Legacy ownership label. Kuiper reads this as fallback and auto-patches resources with the new `kuiper.juno-innovations.com/kuiper-instance` label. |

### Kuiper-Managed Annotations (do not set)

These are written by Kuiper itself at runtime. Do not set them in your Helm charts.

| Annotation | Description |
|------------|-------------|
| `kuiper.juno-innovations.com/hidden` | Marks internal Kuiper ConfigMaps as hidden from API responses. |
| `kuiper.juno-innovations.com/delete-protection` | Set by Kuiper on resources it wants to orphan rather than delete on workload shutdown. |
| `kuiper.juno-innovations.com/container-path` | Mount target path inside the container. Set by Kuiper on PVCs it manages. |
| `kuiper.juno-innovations.com/sub-path` | Sub-directory within a PVC to mount. Set by Kuiper on PVCs it manages. |
| `kuiper.juno-innovations.com/mount-access` | JSON array of Juno usernames or group names permitted to use a mount. Set by Kuiper. |
| `kuiper.juno-innovations.com/service-provisioned` | Idempotency flag — ExternalName Service for EC2 instance already created. |
| `kuiper.juno-innovations.com/connection-provisioned` | Idempotency flag — connection annotation for EC2 instance already written. |
| `kuiper.juno-innovations.com/user-created-datavolume` | Written on DataVolume clones. Used as the label selector for the `dataVolume` field type in Genesis UI. |
| `juno-innovations.com/kuiper-instance` | **Deprecated.** Legacy ownership label. Migrated to the `kuiper.juno-innovations.com/` prefix automatically on first read. |

---

## Field Types Reference

### `terra.yaml` fields (install-time, Terra UI)

| Type | Description | Extra keys |
|------|-------------|------------|
| `string` | Text input | `default` |
| `int` | Integer input | `default` |
| `boolean` | True/False toggle | `default` |
| `select` | Single-choice dropdown | `options: [...]` |
| `multi` | Multi-choice select | `options: [...]` |
| `shared-volume` | Shared PVC picker (multiple plugins can share) | — |
| `exclusive-volume` | Exclusive PVC picker (single plugin only) | — |

### `metadata.yaml` fields (workload launch-time, Genesis UI)

All types above plus:

| Type | Description | Extra keys |
|------|-------------|------------|
| `env` | Environment variable input — auto-injected for all schemas; users set env vars for the workload | — |
| `multi-line` | Multi-line text input | — |
| `list` | Repeatable group of sub-fields. **Cannot nest a `list` inside a `list`.** | `fields: [...]` |
| `k8sPriority` | K8s PriorityClass picker — queries cluster for available classes | — |
| `k8sStorageClass` | K8s StorageClass picker — queries cluster for available classes | — |
| `k8sIngressClass` | K8s IngressClass picker — queries cluster for available classes | — |
| `k8sServiceAccount` | K8s ServiceAccount picker — queries cluster, returns namespace-mapped dict | — |
| `dataVolume` | KubeVirt DataVolume picker — only returns DVs with label `kuiper.juno-innovations.com/user-created-datavolume` | — |

---

## Make Targets Reference

| Target | Usage | Description |
|--------|-------|-------------|
| `make new-plugin` | interactive | Create a new plugin with type-aware scaffolding |
| `make package <name>` | `make package ollama` | Repackage scripts/ into ConfigMap YAML |
| `make verify` | `make verify` | Check all plugins have up-to-date packages (CI) |
| `make check-size <name>` | `make check-size helios` | Check packaged size vs 1MiB limit |
| `make watch <name>` | `make watch helios` | Auto-repackage on scripts/ changes (dev) |
| `make test <name>` | `make test ollama` | Deploy to local Kind cluster via ArgoCD |
| `make test-plugin <name>` | `make test-plugin helios` | TDK workflow: deploy to live cluster |
| `make test-catalog` | `make test-catalog` | TDK workflow: test full catalog |
| `make deploy` | `make deploy` | Deploy changed plugins to live cluster |
| `make lint` | `make lint` | Helm lint all plugins |
| `make docs` | `make docs` | Serve docs site locally |
| `make down` | `make down` | Destroy local Kind cluster |

---

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Forgot `make package` after editing `scripts/` | Old behavior in cluster; no error | `make package <plugin>` |
| `make verify` failing in CI | CI fails with stale package list | `make package` each listed plugin |
| `fields:` name doesn't match `values.yaml` key | Workload launch fails with Helm error | Align field `name:` with values.yaml key |
| Missing `kuiper.juno-innovations.com/chart` label | Plugin not visible in Genesis catalog | Add label to `templates/metadata.yaml` |
| Missing `juno-innovations.com/workload` annotation | Workload not categorized in Hubble | Add annotation to both `metadata.yaml` and `statefulset.yaml` |
| Scripts directory exceeds 1MiB | ArgoCD sync fails silently | `make check-size`, trim `scripts/` |
| Hand-editing `packaged-scripts.yaml` | Overwritten next `make package` | Edit `scripts/` instead, then repackage |
| Auth still in ingress annotations instead of sidecar | Sidecar config missing; no auth enforced | Move `auth_request` to nginx configmap, remove annotations from ingress |
| Inline nginx config in YAML string instead of `files/` | Harder to edit, no syntax highlighting | Move to `files/nginx/default.conf`, load via `{{ tpl (.Files.Get ...) . }}` |
| Using deprecated `juno-innovations.com/app│user│session│shared│kuiper-state│owner` labels | Bloated manifests, no effect on any platform component | Remove them. Only use `kuiper.juno-innovations.com/kuiper-instance` and `kuiper.juno-innovations.com/`-prefixed annotations. |
| `ingressClassName` hardcoded instead of conditional | Users can't switch ingress class | Use `{{- if .Values.ingressClassName }}` conditional |
| Service name doesn't use `{{ .Release.Name }}` | Possible naming collisions | Standardize to `{{ .Release.Name }}` with port name `http` |

---

## Known Quirks

- `plugins/helios/` and `plugins/vm-ephemeral/` were previously missing the `juno-innovations.com/workload`
  annotation on their `templates/metadata.yaml`. This has been fixed. `plugins/filebrowser/` was also
  missing this annotation and has been fixed.

- `make verify` was disabled in earlier versions of this repo (`echo "Verify is disabled"`). It is now
  re-enabled with full stale-package detection. CI runs it on every push to `plugins/**`.

- The `packaged-scripts-template.yaml` and `packaged-scripts-template-cleanup.yaml` files in `template/`
  are the base templates used by `make package`. Do not modify them unless changing the bootstrap script behavior
  for all plugins.

- Conditional `publicAccess` support (allowing unauthenticated access via `{{- if not .Values.publicAccess }}`) is
  now included in the workload template scaffold. The `publicAccess` field and conditional wrapper in
  `files/nginx/default.conf` are generated by `make new-plugin`. Plugins with secrets or user data should
  keep auth enabled (default).

---

## Adding a New Plugin — Checklist

1. `make new-plugin` — follow interactive prompts
2. Edit `terra.yaml` — set `name`, `description`, `category`, `icon`, `fields`
3. Edit `Chart.yaml` — bump version if needed
4. **Namespaced:** add your Kubernetes objects to `templates/resources.yaml` (any valid K8s manifests)
5. **Cluster-level:** add your Kubernetes objects to `templates/resources.yaml` (ArgoCD `Application` delegating to upstream chart is a common pattern)
6. **Workload template:**
   - Edit `templates/metadata.yaml` — set `description`, tune `fields:`
   - Edit `scripts/chart/values.yaml` — ensure all field names are present as keys
   - Edit `scripts/chart/templates/statefulset.yaml` — set correct image, ports, probes; set `juno-innovations.com/workload` annotation to match `metadata.yaml`; nginx sidecar is pre-configured
   - Edit `scripts/chart/files/nginx/default.conf` — replace `APP_PORT` with the app's container port
   - Edit `scripts/chart/templates/service.yaml` — use `{{ .Release.Name }}` as name, port name `http`, target `8080`
   - Edit `scripts/chart/templates/ingress.yaml` — conditional `ingressClassName`, path `/plugin/{{ .Values.name }}/`
7. `make package <plugin-name>` — **required** for any plugin with a `scripts/` directory
8. `make check-size <plugin-name>` — verify under 1MiB
9. `make verify` — confirm nothing is stale
10. `make test <plugin-name>` or `make test-plugin <plugin-name>` — deploy and test
11. Commit both `scripts/` changes AND the updated `templates/packaged-scripts*.yaml` files

---

## Documentation Reference

Human-readable docs live in `docs/`. Key pages for workload template authors:

| File | Contents |
|------|----------|
| `docs/workload-templates.md` | Overview — what workload templates are, full data flow diagram, directory structure, `metadata.yaml` anatomy, `values.yaml` matching, `statefulset.yaml` conventions, packaging, authoring checklist, common mistakes |
| `docs/workload-configuration.md` | Configuration reference — field types (links to `plugin-fields.md`), ingress authentication patterns, full Kuiper annotations reference with per-annotation examples, quick-reference table |
| `docs/workload-guides.md` | Annotated examples — `simple-app` (StatefulSet + Service + Ingress with all plugin-author annotations) and `ec2-workstation` (Crossplane EC2 + `adopt` pattern) |
| `docs/plugin-fields.md` | Full field type reference for both `terra.yaml` (install-time) and `metadata.yaml` (workload launch-time) fields |
| `docs/plugin-types.md` | Plugin type comparison, decision tree, identifying markers |
| `docs/workflow.md` | Contributor workflow — branching, CI, deploy process |
| `docs/advanced.md` | Packaging internals — how `make package` works, ConfigMap bootstrap |
