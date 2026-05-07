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

**These annotations only apply to workload template plugins.**

---

### Plugin-Author Annotations

Set these in your `scripts/chart/templates/` to control Kuiper behavior.

#### General

---

```yaml
annotations:
  juno-innovations.com/workload: "Application"
```

**Applies to:** StatefulSet (or primary workload resource) in `scripts/chart/templates/`  
**Value format:** any string

Declares the workload category shown in the Hubble UI for running workloads. This annotation must
also appear on `templates/metadata.yaml` with the same value — Genesis reads the `metadata.yaml`
copy to categorize the template in the catalog; Hubble reads the copy on the running StatefulSet
to label the active workload.

---

```yaml
annotations:
  kuiper.juno-innovations.com/actions: "restart,stop,scale"
```

**Applies to:** any resource  
**Value format:** comma-separated action names

Whitelists the actions callable on a resource via the Kuiper API. Only explicitly listed action
names can be invoked. Prevents arbitrary method dispatch.

---

```yaml
annotations:
  kuiper.juno-innovations.com/connection: "username=admin,port=5900"
```

**Applies to:** any resource  
**Value format:** `key=value,key=value`

Connection details surfaced as endpoint metadata in the Hubble UI. Use this to expose credentials,
hostnames, or ports alongside a workload's endpoint list.

---

#### NodePort Auto-Detection

No annotation required. If any Service in the workload's resources is of type `NodePort`, Kuiper
automatically detects the assigned port after the workload launches and surfaces it in the Hubble UI
alongside the workload's other endpoints.

---

```yaml
# Adopts a Service named "{{ .Release.Name }}-ec2-svc" once Kuiper creates it
annotations:
  kuiper.juno-innovations.com/adopt-{{ .Release.Name }}-ec2-svc: "Service"
```

**Applies to:** any resource  
**Value format:** Kubernetes Kind string (e.g. `Service`)

Adopts a deterministically-named resource that was created *outside* the chart into the workload's
owned resource set. The annotation key suffix `<name>` is the name of the resource to adopt; the
value is its Kubernetes Kind. Kuiper patches the ownership label onto it so it is tracked and
cleaned up with the workload.

This is useful for any resource that cannot exist at Helm render time — for example, a Service
that Kuiper creates after resolving EC2 DNS post-launch.

---

#### Ingress

```yaml
annotations:
  kuiper.juno-innovations.com/ingress-hide: "/healthz,/admin,/metrics"
```

**Applies to:** Ingress  
**Value format:** comma-separated URL paths

Hides the listed URL paths from the endpoint list shown in the Hubble UI. Use this to suppress
internal paths like health checks or admin endpoints.

---

```yaml
annotations:
  kuiper.juno-innovations.com/ingress-extras: "/app/index.html,/app/login"
```

**Applies to:** Ingress  
**Value format:** comma-separated sub-paths

Appends extra sub-paths to existing ingress endpoints in the Hubble UI without creating new
Ingress rules. Each extra path is matched to the closest existing ingress path.

---

#### Crossplane

```yaml
annotations:
  kuiper.juno-innovations.com/expose: "22,3389,5900"
```

**Applies to:** Crossplane EC2 Instance  
**Value format:** comma-separated port numbers

Kuiper automatically creates a Kubernetes ExternalName Service exposing the listed ports for the
EC2 instance once its DNS is available, making it reachable from within the cluster.

---

```yaml
annotations:
  kuiper.juno-innovations.com/aws-remote-connection: "true"
```

**Applies to:** Crossplane EC2 Instance  
**Value format:** `"true"`

Triggers Kuiper to compute and write the `kuiper.juno-innovations.com/connection` annotation onto
the EC2 Instance object once EC2 DNS is available. Required for connection details to appear in
Hubble for EC2-backed workloads.

---

```yaml
annotations:
  kuiper.juno-innovations.com/use-private-dns: "true"
```

**Applies to:** Crossplane EC2 Instance  
**Value format:** `"true"`

When set, Kuiper uses `privateDnsName` instead of `publicDnsName` when building the ExternalName
Service and writing the connection annotation. Use for instances only reachable via private
networking.
