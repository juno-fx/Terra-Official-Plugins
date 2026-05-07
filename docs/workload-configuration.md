# Configuration Reference

This page covers all configuration options available when authoring a workload template —
field types for the Genesis workload form, Kuiper annotations for lifecycle and UI control,
and ingress authentication patterns.

---

## Field Types

Field definitions live in `templates/metadata.yaml` under `data.fields:`. For the full field
type reference — including both install-time (`terra.yaml`) and workload launch-time
(`metadata.yaml`) types — see [Plugin Fields](plugin-fields.md).

**Key rule:** every field `name:` in `metadata.yaml` must exist as a key in
`scripts/chart/values.yaml`. A missing key causes silent Helm failure at workload launch time.

---

## Ingress Authentication

These are standard nginx ingress annotations — not Kuiper-specific — but required for
platform-integrated authentication on any ingress you expose.

**Workload templates** authenticate via Hubble:

```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-url: "http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/"
  nginx.ingress.kubernetes.io/use-regex: "true"
```

**Namespaced and cluster-level plugins** authenticate via Genesis:

!!! note
    Workload templates must always be tagged `cluster-level` in `terra.yaml` — they are installed
    into the `argocd` namespace by Terra.

```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-url: "http://genesis.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-service/{{ .Release.Name }}/"
  nginx.ingress.kubernetes.io/auth-signin: /unauthorized/
```

---

## Kuiper Annotations

Kuiper reads annotations on Kubernetes resources inside `scripts/chart/templates/` to control
workload lifecycle, endpoint surfacing, and more. All keys use the
`kuiper.juno-innovations.com/` prefix unless noted.

**These annotations only apply to workload template plugins.** Workload templates are always
cluster-level — they are installed into the `argocd` namespace, and Kuiper reads their embedded
`scripts/chart/` at workload launch time. Namespaced and cluster-level plugins are synced directly
by ArgoCD — Kuiper never processes them.

---

### Plugin-Author Annotations

Set these in your `scripts/chart/templates/` to control Kuiper behavior.

#### General

##### `juno-innovations.com/workload`

**Applies to:** StatefulSet (or primary workload resource) in `scripts/chart/templates/`  
**Value format:** any string

Declares the workload category shown in the Hubble UI for running workloads. This annotation must
also appear on `templates/metadata.yaml` with the same value — Genesis reads the `metadata.yaml`
copy to categorize the template in the catalog; Hubble reads the copy on the running StatefulSet
to label the active workload.

```yaml
annotations:
  juno-innovations.com/workload: "Application"
```

---

##### `kuiper.juno-innovations.com/actions`

**Applies to:** any resource  
**Value format:** comma-separated action names

Whitelists the actions callable on a resource via the Kuiper API. Only explicitly listed action
names can be invoked. Prevents arbitrary method dispatch.

```yaml
annotations:
  kuiper.juno-innovations.com/actions: "restart,stop,scale"
```

---

##### `kuiper.juno-innovations.com/connection`

**Applies to:** any resource  
**Value format:** `key=value,key=value`

Connection details surfaced as endpoint metadata in the Hubble UI. Use this to expose credentials,
hostnames, or ports alongside a workload's endpoint list.

```yaml
annotations:
  kuiper.juno-innovations.com/connection: "username=admin,port=5900"
```

---

##### `kuiper.juno-innovations.com/adopt-<name>`

**Applies to:** any resource  
**Value format:** Kubernetes Kind string (e.g. `Service`)

Adopts a deterministically-named resource that was created *outside* the chart into the workload's
owned resource set. The annotation key suffix `<name>` is the name of the resource to adopt; the
value is its Kubernetes Kind. Kuiper patches the ownership label onto it so it is tracked and
cleaned up with the workload.

This is useful for any resource that cannot exist at Helm render time — for example, a Service
that Kuiper creates after resolving EC2 DNS post-launch.

```yaml
# Adopts a Service named "{{ .Release.Name }}-ec2-svc" once Kuiper creates it
annotations:
  kuiper.juno-innovations.com/adopt-{{ .Release.Name }}-ec2-svc: "Service"
```

---

#### Ingress

##### `kuiper.juno-innovations.com/ingress-hide`

**Applies to:** Ingress  
**Value format:** comma-separated URL paths

Hides the listed URL paths from the endpoint list shown in the Hubble UI. Use this to suppress
internal paths like health checks or admin endpoints.

```yaml
annotations:
  kuiper.juno-innovations.com/ingress-hide: "/healthz,/admin,/metrics"
```

---

##### `kuiper.juno-innovations.com/ingress-extras`

**Applies to:** Ingress  
**Value format:** comma-separated sub-paths

Appends extra sub-paths to existing ingress endpoints in the Hubble UI without creating new
Ingress rules. Each extra path is matched to the closest existing ingress path.

```yaml
annotations:
  kuiper.juno-innovations.com/ingress-extras: "/app/index.html,/app/login"
```

---

#### Crossplane / EC2

##### `kuiper.juno-innovations.com/expose`

**Applies to:** Crossplane EC2 Instance  
**Value format:** comma-separated port numbers

Kuiper automatically creates a Kubernetes ExternalName Service exposing the listed ports for the
EC2 instance once its DNS is available, making it reachable from within the cluster.

```yaml
annotations:
  kuiper.juno-innovations.com/expose: "22,3389,5900"
```

---

##### `kuiper.juno-innovations.com/aws-remote-connection`

**Applies to:** Crossplane EC2 Instance  
**Value format:** `"true"`

Triggers Kuiper to compute and write the `kuiper.juno-innovations.com/connection` annotation onto
the EC2 Instance object once EC2 DNS is available. Required for connection details to appear in
Hubble for EC2-backed workloads.

```yaml
annotations:
  kuiper.juno-innovations.com/aws-remote-connection: "true"
```

---

##### `kuiper.juno-innovations.com/use-private-dns`

**Applies to:** Crossplane EC2 Instance  
**Value format:** `"true"`

When set, Kuiper uses `privateDnsName` instead of `publicDnsName` when building the ExternalName
Service and writing the connection annotation. Use for instances only reachable via private
networking.

```yaml
annotations:
  kuiper.juno-innovations.com/use-private-dns: "true"
```

---

### Kuiper-Managed Annotations (do not set)

These are written by Kuiper itself at runtime. Do not set them in your Helm charts — they will be
overwritten or ignored.

| Annotation | Description |
|------------|-------------|
| `kuiper.juno-innovations.com/kuiper-instance` | Primary ownership label injected onto every resource at launch. Used as the label selector for all resource discovery and deletion. |
| `kuiper.juno-innovations.com/hidden` | Marks internal Kuiper ConfigMaps as hidden from API responses. |
| `kuiper.juno-innovations.com/delete-protection` | Kuiper sets this on resources it wants to orphan rather than delete on workload shutdown. |
| `kuiper.juno-innovations.com/container-path` | Mount target path inside the container. Set by Kuiper on PVCs it manages. |
| `kuiper.juno-innovations.com/sub-path` | Sub-directory within a PVC to mount. Set by Kuiper on PVCs it manages. |
| `kuiper.juno-innovations.com/mount-access` | JSON array of Juno usernames or group names permitted to use a mount. Set by Kuiper. |
| `kuiper.juno-innovations.com/service-provisioned` | Idempotency flag — ExternalName Service for an EC2 instance has already been created. |
| `kuiper.juno-innovations.com/connection-provisioned` | Idempotency flag — connection annotation for an EC2 instance has already been written. |
| `kuiper.juno-innovations.com/user-created-datavolume` | Applied to DataVolume clones by Kuiper. Used as the label selector for the `dataVolume` field type in the Genesis workload UI. |
| `juno-innovations.com/kuiper-instance` | **Deprecated.** Legacy ownership label. Automatically migrated to the `kuiper.juno-innovations.com/` prefix on first read. |

---

### Annotations Quick Reference

| Annotation | Set By | Applies To | Purpose |
|------------|--------|-----------|---------|
| `nginx.ingress.kubernetes.io/auth-url` | plugin author | Ingress | Platform auth — Hubble (workload templates) or Genesis (other plugins) |
| `nginx.ingress.kubernetes.io/use-regex` | plugin author | Ingress | Required alongside auth-url for workload templates |
| `nginx.ingress.kubernetes.io/auth-signin` | plugin author | Ingress | Redirect on auth failure — used with Genesis auth pattern |
| `kuiper.juno-innovations.com/actions` | plugin author | any | Whitelist callable actions |
| `kuiper.juno-innovations.com/connection` | plugin author or Kuiper | any | Connection details in Hubble UI |
| `kuiper.juno-innovations.com/adopt-<name>` | plugin author | any | Adopt externally-created resource into workload |
| `kuiper.juno-innovations.com/ingress-hide` | plugin author | Ingress | Hide paths from Hubble endpoint list |
| `kuiper.juno-innovations.com/ingress-extras` | plugin author | Ingress | Append sub-paths to endpoints in Hubble UI |
| `kuiper.juno-innovations.com/expose` | plugin author | EC2 Instance | Ports for auto-created ExternalName Service |
| `kuiper.juno-innovations.com/aws-remote-connection` | plugin author | EC2 Instance | Trigger connection annotation on EC2 |
| `kuiper.juno-innovations.com/use-private-dns` | plugin author | EC2 Instance | Use private DNS for EC2 endpoints |
| `kuiper.juno-innovations.com/kuiper-instance` | Kuiper | all resources | Primary ownership label |
| `kuiper.juno-innovations.com/hidden` | Kuiper | ConfigMap | Hide from API responses |
| `kuiper.juno-innovations.com/delete-protection` | Kuiper | any | Orphan instead of delete on shutdown |
| `kuiper.juno-innovations.com/container-path` | Kuiper | PVC | Container mount path |
| `kuiper.juno-innovations.com/sub-path` | Kuiper | PVC | Sub-directory within PVC to mount |
| `kuiper.juno-innovations.com/mount-access` | Kuiper | PVC | Juno usernames/groups permitted to use the mount |
| `kuiper.juno-innovations.com/service-provisioned` | Kuiper | EC2 Instance | Idempotency flag |
| `kuiper.juno-innovations.com/connection-provisioned` | Kuiper | EC2 Instance | Idempotency flag |
| `kuiper.juno-innovations.com/user-created-datavolume` | Kuiper | DataVolume | Genesis dataVolume field selector |
| `juno-innovations.com/kuiper-instance` | (legacy) | all resources | Deprecated ownership label |
