# Plugin Fields

## Top-Level `terra.yaml` Properties

These are the recognized top-level keys in every plugin's `terra.yaml`. They control how Terra
displays and installs the plugin.

| Property | Required | Description |
|----------|----------|-------------|
| `resource_id` | yes | Unique identifier for the plugin (used by Terra internally) |
| `name` | yes | Display name shown in the Terra app store |
| `icon` | yes | Icon URL or identifier |
| `description` | yes | Short description shown in the Terra app store |
| `category` | yes | Category grouping in the Terra app store |
| `tags` | yes | List of tags. Include `cluster-level` for cluster-level plugins |
| `fields` | yes | List of install-time field definitions (can be empty `[]`) |
| `editable` | no | `true` \| `false` — allows users to edit field values after install. Default: `false` |
| `compatibility` | no | Pip-style platform version constraint. Terra blocks install if the running platform version does not meet the constraint. |

### `editable`

When `true`, users can return to the plugin's settings in Terra and change field values after
install. Useful for plugins where configuration changes without a reinstall are expected (e.g.
version upgrades, endpoint changes).

```yaml title="terra.yaml"
editable: true
```

### `compatibility`

A pip-style version constraint string referencing named platform components. This value is shown on
the install form in the Terra frontend — it is informational only. Terra does not perform a runtime
check against the running platform version; no install is blocked based on this value.

```yaml title="terra.yaml"
# Document that genesis-deployment >= 3.0.2 AND orion-deployment >= 3.1.0 are required
compatibility: genesis-deployment>=3.0.2,orion-deployment>=3.1.0
```

Multiple constraints are comma-separated. Supported operators: `>=`, `<=`, `>`, `<`, `==`, `!=`.

---

Terra plugins use two distinct sets of fields:

1. **`terra.yaml` fields** — shown at **install time** in the Terra app store UI
2. **`metadata.yaml` fields** — shown at **workload launch time** in the Genesis workload UI (workload templates only)

The shared types (available in both) are: `string`, `int`, `boolean`, `select`, `multi`.
`metadata.yaml` fields also support additional Kubernetes-aware types not available at install time.
`shared-volume` and `exclusive-volume` are install-time only and cannot be used in `metadata.yaml`.

---

## `terra.yaml` Fields — Install-Time

These fields are defined in `terra.yaml` under the `fields:` key. They are presented to users when
they install the plugin from the Terra app store. The values become Helm values injected into
`templates/` at ArgoCD sync time.

```yaml linenums="1" title="terra.yaml field structure"
fields:
  - name: my_field          # key in values.yaml
    description: "..."      # shown in Terra UI
    required: true          # or false
    type: string            # see type reference below
    default: "value"        # optional pre-filled value
```

---

## `metadata.yaml` Fields — Workload Launch-Time

For workload template plugins only. Defined in `templates/metadata.yaml` under `data.fields:` as a
YAML block scalar. These fields are presented in the Genesis workload creation form. The values become
Helm values passed to `scripts/chart/` by Kuiper at launch time.

```yaml linenums="1" title="metadata.yaml fields structure"
data:
  fields: |
    - name: my_field
      description: "..."
      required: true
      type: string
      default: "value"
```

!!! warning "Field names must match `scripts/chart/values.yaml`"
    Every `name:` in `data.fields:` must exist as a key in `scripts/chart/values.yaml`.
    Mismatches cause silent failures when a workload is launched.

---

## Field Type Reference

### `string`

Simple text input.

```yaml
- name: registry
  description: "Container registry URL"
  type: string
  required: true
  default: "docker.io"
```

---

### `int`

Integer text input.

```yaml
- name: replica_count
  description: "Number of replicas"
  type: int
  required: true
  default: 1
```

---

### `boolean`

True/False toggle.

```yaml
- name: gpu
  description: "Attach a GPU to this workload"
  type: boolean
  required: true
```

---

### `select`

Single-choice dropdown. Requires an `options:` list.

```yaml
- name: version
  description: "Operator version to install"
  type: select
  required: true
  default: "v25.3.4"
  options:
    - "v25.10.1"
    - "v25.3.4"
```

---

### `multi`

Multi-choice select. Requires an `options:` list.

```yaml
- name: features
  description: "Features to enable"
  type: multi
  options:
    - monitoring
    - logging
    - tracing
```

---

### `shared-volume`

Shared PVC picker. Multiple plugins can reference the same volume. The selected PVC
is injected as an object with a `name` key.

!!! warning "Install-time only"
    `shared-volume` is only valid in `terra.yaml`. It cannot be used in `metadata.yaml` workload launch fields.

```yaml
# terra.yaml
- name: install_volume
  description: "Shared storage volume"
  type: shared-volume
  required: true
```

```yaml
# values.yaml
install_volume: {}
```

```yaml
# templates/wave-1/deployment.yaml
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: {{ .Values.install_volume.name }}
```

---

### `exclusive-volume`

Exclusive PVC picker. A plugin using this type can only be installed into one project at a time —
Terra enforces that no other plugin instance claims the same volume. Usage is otherwise identical to
`shared-volume`.

!!! warning "Install-time only"
    `exclusive-volume` is only valid in `terra.yaml`. It cannot be used in `metadata.yaml` workload launch fields.

```yaml
- name: install_volume
  description: "Exclusive storage volume"
  type: exclusive-volume
  required: true
```

---

### `env` *(metadata.yaml only)*

Environment variable input. This field type is **automatically injected for all workload schemas** —
you do not need to define it. It is shown in the Genesis workload creation form and allows users to
set environment variables that are passed directly into the workload.

---

### `multi-line` *(metadata.yaml only)*

Multi-line text input. Renders a text area in the Genesis UI.

```yaml
- name: config
  description: "Custom configuration block"
  type: multi-line
  required: false
```

---

### `list` *(metadata.yaml only)*

A repeatable group of sub-fields. Users can add multiple entries. Each entry is rendered as a group
of the nested fields. Requires a `fields:` list.

!!! warning "No nested lists"
    You cannot nest a `list` field inside another `list` field.

```yaml
- name: ports
  description: "Ports to expose from the workload"
  required: false
  type: list
  fields:
    - name: name
      description: "Port name"
      type: string
      required: true
      default: "http"
    - name: port
      description: "Port number"
      type: int
      required: true
      default: 8080
    - name: protocol
      description: "Protocol"
      type: select
      required: true
      default: "TCP"
      options:
        - TCP
        - UDP
```

---

### `k8sStorageClass` *(metadata.yaml only)*

Kubernetes storage class picker. Presents available storage classes from the cluster.

```yaml
- name: storage_class
  description: "Storage class for the workload's disk"
  type: k8sStorageClass
  required: true
```

---

### `k8sPriority` *(metadata.yaml only)*

Kubernetes PriorityClass picker. Queries the cluster for all available PriorityClass names.

```yaml
- name: priority
  description: "Scheduling priority for the workload"
  type: k8sPriority
  required: false
```

---

### `k8sIngressClass` *(metadata.yaml only)*

Kubernetes IngressClass picker. Queries the cluster for all available IngressClass names.

```yaml
- name: ingress_class
  description: "Ingress class to use for the workload"
  type: k8sIngressClass
  required: false
```

---

### `k8sServiceAccount` *(metadata.yaml only)*

Kubernetes service account picker. Presents available service accounts from the namespace.

```yaml
- name: terra_role
  description: "Service account to attach to the workload"
  type: k8sServiceAccount
  required: false
```

---

### `dataVolume` *(metadata.yaml only)*

KubeVirt DataVolume picker. Used in VM workload templates to select boot disk images.

```yaml
- name: volume
  description: "Boot disk volume"
  type: dataVolume
  required: false
```

---

## Type Availability Summary

| Type | `terra.yaml` | `metadata.yaml` |
|------|:---:|:---:|
| `string` | ✓ | ✓ |
| `int` | ✓ | ✓ |
| `boolean` | ✓ | ✓ |
| `select` | ✓ | ✓ |
| `multi` | ✓ | ✓ |
| `shared-volume` | ✓ | — |
| `exclusive-volume` | ✓ | — |
| `env` | — | auto |
| `multi-line` | — | ✓ |
| `list` | — | ✓ |
| `k8sPriority` | — | ✓ |
| `k8sStorageClass` | — | ✓ |
| `k8sIngressClass` | — | ✓ |
| `k8sServiceAccount` | — | ✓ |
| `dataVolume` | — | ✓ |

!!! warning "Unknown field types on older Genesis"
    If a `metadata.yaml` field uses a type that is not recognized by the running Genesis version,
    the workload template is silently unavailable in the catalog — it will not appear for users.
    Genesis logs an error internally but throws no exception. Always test new field types against
    your target platform version.

!!! info "Evolving support"
    Not all Genesis and Terra release versions support every field type. Types are added as the platform
    evolves. Check the [Orion Documentation](https://juno-fx.github.io/Orion-Documentation/) for
    version-specific field support.
