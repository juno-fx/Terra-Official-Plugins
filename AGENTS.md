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

**The `workload` tag** — every workload template's `terra.yaml` tags array must include `workload`
alongside `cluster-level`. The Terra app store uses this tag to drive its workloads filter, so a
workload template without it will not appear when users filter the store by workloads.

**Only workload template plugins may carry this tag.** Do not add it to a namespaced or cluster-level
plugin — those install a running service directly and are not launchable workloads, so tagging one
puts it in a store filter it does not belong in. If a plugin has no `templates/metadata.yaml` carrying
the `kuiper.juno-innovations.com/chart` label, it does not get the `workload` tag.

**Directory structure:**

```
plugins/my-template/
├── Chart.yaml
├── terra.yaml                          # tags: [cluster-level, workload], fields: []
├── values.yaml
├── templates/
│   ├── metadata.yaml                   # THE CONTRACT — discovery label + fields schema + env_hints: [...]
│   ├── packaged-scripts.yaml           # GENERATED — never edit
│   └── packaged-scripts-cleanup.yaml   # GENERATED — never edit
└── scripts/
    ├── entrypoint.sh
    └── chart/                          # THE PAYLOAD — embedded Helm chart
        ├── Chart.yaml
        ├── values.yaml                 # Must contain all fields from metadata.yaml
        └── templates/
            ├── workstation.yaml        # StatefulSet — the running workload
            ├── service.yaml
            └── ingress.yaml
```

**`env_hints` in `templates/metadata.yaml`** — for workload templates whose
`scripts/chart/templates/workstation.yaml` ranges over `.Values.env` (i.e. the chart actually wires up Genesis's
built-in custom env var field — see the `env` field type in Field Types Reference below), `templates/metadata.yaml`'s
`data:` block may carry an `env_hints:` key (a sibling of `fields:`, using the same string-block-scalar
convention since ConfigMap `data` values must be strings) documenting the upstream image's most commonly used
custom env vars:

```yaml
data:
  fields: |
    - name: ...
  env_hints: |
    - name: EXAMPLE_VAR
      description: What this variable does and when to set it.
```

This lives in `metadata.yaml` rather than `terra.yaml` because it needs to travel through the same ConfigMap
Genesis already reads (label `kuiper.juno-innovations.com/chart`) to reach the workload-launch UI — `terra.yaml`
is install-time only (Rule 5) and Genesis never reads it.

Rules:
- **List only the handful of variables end users would actually set** — not every variable the upstream image
  supports. This is a curated "commonly useful" list, not exhaustive reference documentation.
- **Never list a variable already hardcoded in `workstation.yaml`'s static env block** (e.g. `JUNO_WORKSTATION`,
  `JUNO_PROJECT`, `JUNO_ENVIRONMENT`, `USER`, `HOME`, `UID`/`PUID`, `GID`/`PGID`, `PREFIX`/`SUBFOLDER`) — check that
  file first. A suggested var that collides with a platform-set one is misleading.
- If the upstream image has no well-known custom env vars, set `env_hints: |` followed by an indented
  `[]` rather than omitting the key (see `plugins/proxmox/templates/metadata.yaml`).
- Mirror the same list in the plugin's `README.md`, under a `### Custom Environment Variables` subsection inside
  `## Configuration` (table of `Variable` / `Description`, one row per entry) — see any workload template plugin
  under `plugins/` for the established format.
- Do not add a "don't override" callout to the README — the goal is a short, useful suggestion list, not a
  cautionary reference.
- `template/workload/templates/metadata.yaml` and `template/workload/README.md` carry `TODO` placeholders for
  this — fill them in (or delete down to `env_hints: |` + `[]`) when scaffolding a new workload template.

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

---

## Packaging Workflow

```
scripts/                                    ← edit these files
    └── entrypoint.sh
    └── chart/                              ← workload template embedded Helm chart
        └── templates/workstation.yaml
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
   - `data.env_hints`, if present → suggested custom env vars for the auto-injected `env` field (this
     key exists in the ConfigMap for Genesis to consume; whether Genesis's UI currently reads and displays it is
     outside this repo's control — see the `env_hints` subsection above)
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
    - name: gpu
      description: "Attach a GPU"
      type: boolean
      required: true
  # Optional: suggestions surfaced next to the auto-injected `env` field at workload-launch time.
  # See the `env_hints` subsection above.
  env_hints: |
    - name: EXAMPLE_VAR
      description: "What this variable does and when to set it"
```

**The `juno-innovations.com/workload` annotation must also appear in `scripts/chart/templates/workstation.yaml`**
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

## `scripts/chart/templates/workstation.yaml` — Required Conventions

The StatefulSet that Kuiper deploys must follow these conventions:

- **Node affinity** — target nodes with label `juno-innovations.com/workstation: "true"`
- **Toleration** — tolerate taint `juno-innovations.com/workstation: NoSchedule`
- **`juno-innovations.com/workload` annotation** — must match `metadata.yaml` value
- **Plugin mounts** — range over `.Values.plugins` to mount Helios plugin scripts
- **Standard env vars** — set `JUNO_WORKSTATION`, `JUNO_WORKSPACE` (formerly `JUNO_PROJECT`, still set for backwards compatibility), `USER`, `HOME`, `PREFIX`

See `plugins/helios/scripts/chart/templates/workstation.yaml` for the full reference implementation.

---

## `terra.yaml` Top-Level Properties

| Property | Required | Description |
|----------|----------|-------------|
| `resource_id` | yes | Unique identifier for the plugin (used by Terra internally) |
| `name` | yes | Display name shown in the Terra app store |
| `icon` | yes | Icon URL or identifier shown in the Terra app store |
| `description` | yes | Short description shown in the Terra app store |
| `category` | yes | Category grouping in the Terra app store |
| `tags` | yes | List of tags. Include `cluster-level` for cluster-level plugins. Include `workload` **only** for workload template plugins — it drives the Terra app store's workloads filter |
| `fields` | yes | List of install-time field definitions (can be empty `[]`) |
| `editable` | no | `true` \| `false` — allows users to edit field values after install. Default: `false` |
| `compatibility` | no | Pip-style platform version constraint string. Terra blocks install if not met. Example: `genesis-deployment>=3.0.2,orion-deployment>=3.1.0` |

---

## Kuiper Annotations Reference

Annotations are set on Kubernetes resources inside `scripts/chart/templates/` to control how Kuiper
manages the workload. All keys use the `kuiper.juno-innovations.com/` prefix unless noted.

**These annotations only apply to workload template plugins.** Namespaced and cluster-level plugins
are synced directly by ArgoCD and never pass through Kuiper — annotations have no effect there.

### Ingress Path Convention

Workload ingress paths should start with the release namespace:

```yaml
- path: "/{{ .Release.Namespace }}/<prefix>/{{ .Values.name }}/"
```

`<prefix>` is the plugin's own segment (`polaris`, `gitea`, `k9s`, …).

The rule nginx actually enforces is that **host + path must be unique cluster-wide** — object names are
namespaced, routing rules are not. So two environments sharing a hostname that both render
`/polaris/<name>/` collide, and the second to launch is rejected by the ingress admission webhook.

An environment given its own hostname (`<env>.example.com`) satisfies uniqueness through the host alone
and does not strictly need the namespace segment. Include it anyway: this catalog is installed into many
deployments, and a plugin author cannot know whether a given environment gets its own DNS or shares one.
The prefix is harmless where it is redundant and required where it is not.

Nothing rewrites the path before it reaches the pod — no chart sets `rewrite-target` — so the container
receives the full URL and **every in-container reference must match the ingress path exactly**:

| Where | Example |
|-------|---------|
| `PREFIX` env | `value: "/{{ .Release.Namespace }}/polaris/{{ .Values.name }}/"` |
| nginx sidecar | `location /{{ .Release.Namespace }}/polaris/{{ .Values.name }}/ { … }` |
| App base-url flags | `--baseURL`, `--ServerApp.base_url`, `ROOT_URL` |
| Gateway API | `HTTPRoute` `URLRewrite` value |

Changing the ingress alone routes the request to the pod, which then 404s because it is still serving at
the old prefix — it fails *after* appearing to work.

`ingress-hide` matches by **exact string** against the rendered path, so hide values must be the full
namespaced path, not a bare sub-path. `ingress-extras` matches by prefix and appends the remainder.

### Ingress Authentication (nginx)

Standard nginx ingress annotations required for platform-integrated authentication. Not Kuiper-specific.

**Workload templates** — authenticate via Hubble:
```yaml
nginx.ingress.kubernetes.io/auth-url: "http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/"
nginx.ingress.kubernetes.io/use-regex: "true"
```

**Namespaced / cluster-level plugins** — authenticate via Genesis:
```yaml
nginx.ingress.kubernetes.io/auth-url: "http://genesis.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-service/{{ .Release.Name }}/"
nginx.ingress.kubernetes.io/auth-signin: /unauthorized/
```

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

### Kuiper-Managed Annotations (do not set)

These are written by Kuiper itself at runtime. Do not set them in your Helm charts.

| Annotation | Description |
|------------|-------------|
| `kuiper.juno-innovations.com/kuiper-instance` | Primary ownership label injected onto every resource at launch. Used as the label selector for all discovery and deletion. |
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
| Missing `juno-innovations.com/workload` annotation | Workload not categorized in Hubble | Add annotation to both `metadata.yaml` and `workstation.yaml` |
| Scripts directory exceeds 1MiB | ArgoCD sync fails silently | `make check-size`, trim `scripts/` |
| Hand-editing `packaged-scripts.yaml` | Overwritten next `make package` | Edit `scripts/` instead, then repackage |
| `env_hints` entry duplicates a var already hardcoded in `workstation.yaml` | Misleading docs — the suggested var is silently shadowed by the platform-set one | Check `workstation.yaml`'s static env block before adding to `metadata.yaml` |
| `env_hints` in `metadata.yaml` and `README.md` fall out of sync | Docs disagree with what Genesis actually suggests | Keep both lists identical; update together |
| Ingress path omits `{{ .Release.Namespace }}` | Passes in a single-environment cluster; once a second environment shares the hostname, launches fail with an admission-webhook 400 (`host … and path … is already defined in ingress <ns>/<name>`) part-way through, leaving a partial workload to clean up | Prefix the path with `/{{ .Release.Namespace }}/` (see Ingress Path Convention) |
| Ingress path changed without updating the in-container path | nginx routes to the pod correctly, then the app 404s or serves a page whose assets all 404 — fails *after* looking like it worked | Update `PREFIX`, nginx `location`/`rewrite`/`sub_filter`, `--baseURL`/`ROOT_URL`/`base_url` and `HTTPRoute` rewrites in the same pass |

---

## Known Quirks

- `plugins/helios/` and `plugins/vm-ephemeral/` are missing the `juno-innovations.com/workload`
  annotation on their `templates/metadata.yaml`. They function as workload templates but will not be
  categorized correctly in Hubble. This is a known gap from before the annotation convention was established.

- `make verify` was disabled in earlier versions of this repo (`echo "Verify is disabled"`). It is now
  re-enabled with full stale-package detection. CI runs it on every push to `plugins/**`.

- The `packaged-scripts-template.yaml` and `packaged-scripts-template-cleanup.yaml` files in `template/`
  are the base templates used by `make package`. Do not modify them unless changing the bootstrap script behavior
  for all plugins.

---

## Adding a New Plugin — Checklist

1. `make new-plugin` — follow interactive prompts
2. Edit `terra.yaml` — set `name`, `description`, `category`, `icon`, `fields`
3. Edit `Chart.yaml` — bump version if needed
4. **Namespaced:** add your Kubernetes objects to `templates/resources.yaml` (any valid K8s manifests)
5. **Cluster-level:** add your Kubernetes objects to `templates/resources.yaml` (ArgoCD `Application` delegating to upstream chart is a common pattern)
6. **Workload template:**
   - Edit `terra.yaml` — add `workload` to `tags` so the plugin appears in the app store's workloads filter
   - Edit `templates/metadata.yaml` — set `description`, tune `fields:`
   - Edit `scripts/chart/values.yaml` — ensure all field names are present as keys
   - Edit `scripts/chart/templates/workstation.yaml` — set correct image, ports, probes; set `juno-innovations.com/workload` annotation to match `metadata.yaml`
   - Edit `scripts/chart/templates/service.yaml` — set correct `port`/`targetPort`
   - Edit `scripts/chart/templates/ingress.yaml` — add Hubble auth annotations (`nginx.ingress.kubernetes.io/auth-url` pointing to Hubble, `use-regex: "true"`) and set the path to
     `/{{ .Release.Namespace }}/<prefix>/{{ .Values.name }}/` (see Ingress Path Convention)
   - Make every in-container reference to that path match it exactly — `PREFIX`, nginx sidecar `location`/`rewrite`/`sub_filter`, `--baseURL`/`ROOT_URL`/`base_url`, `HTTPRoute` rewrites. The ingress does not rewrite the path away
   - If `workstation.yaml` ranges over `.Values.env`, edit `templates/metadata.yaml`'s `env_hints:` key (or set it to `|` + `[]`)
     and mirror it in `README.md` under `### Custom Environment Variables` — see the `env_hints` guidance above
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
| `docs/workload-templates.md` | Overview — what workload templates are, full data flow diagram, directory structure, `metadata.yaml` anatomy, `values.yaml` matching, `workstation.yaml` conventions, packaging, authoring checklist, common mistakes |
| `docs/workload-configuration.md` | Configuration reference — field types (links to `plugin-fields.md`), ingress authentication patterns, full Kuiper annotations reference with per-annotation examples, quick-reference table |
| `docs/workload-guides.md` | Annotated examples — `simple-app` (StatefulSet + Service + Ingress with all plugin-author annotations) and `ec2-workstation` (Crossplane EC2 + `adopt` pattern) |
| `docs/plugin-fields.md` | Full field type reference for both `terra.yaml` (install-time) and `metadata.yaml` (workload launch-time) fields |
| `docs/plugin-types.md` | Plugin type comparison, decision tree, identifying markers |
| `docs/workflow.md` | Contributor workflow — branching, CI, deploy process |
| `docs/advanced.md` | Packaging internals — how `make package` works, ConfigMap bootstrap |
