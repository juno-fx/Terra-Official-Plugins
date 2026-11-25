# Configuration Reference

This page covers all configuration options available when authoring a workload template —
field types for the Genesis workload form, Kuiper annotations for lifecycle and UI control,
and ingress authentication patterns.

> Tables on this page mirror `AGENTS.md` (authoritative quick reference) and
> `concepts/labels-annotations.md` — keep all three in sync.

---

## Field Types

Field definitions live in `templates/metadata.yaml` under `data.fields:`. For the full field
type reference — including both install-time (`terra.yaml`) and workload launch-time
(`metadata.yaml`) types — see [Plugin Fields](plugin-fields.md).

**Key rule:** every field `name:` in `metadata.yaml` must exist as a key in
`scripts/chart/values.yaml`. A missing key causes silent Helm failure at workload launch time.

---

## Ingress Authentication

### Workload templates — nginx sidecar

Workload templates authenticate via Hubble **inside the pod**, not through ingress-controller
annotations. Each HTTP workload runs an nginx sidecar next to the application container:

```
Ingress (plain)  →  Service :8080  →  nginx sidecar :8080  →  auth_request → Hubble
                                              │
                                              └→ proxy_pass → app on 127.0.0.1:<port>
```

Because the Ingress carries no controller-specific annotations, the workload behaves the same
behind ingress-nginx, Traefik, or any other controller. The Ingress sets
`ingressClassName: nginx` as a fallback; Kuiper 4.8.0 and later replaces it with the launching
namespace's IngressClass.

The sidecar config lives in `scripts/chart/files/nginx/nginx.conf` and is rendered with `tpl`
into a `<name>-nginx` ConfigMap (`scripts/chart/templates/nginx.yaml`):

```nginx title="scripts/chart/files/nginx/nginx.conf (excerpt)"
location /{{ .Release.Namespace }}/{{ .Values.name }}/ {
  {{- if not .Values.publicAccess }}
  auth_request /auth;
  {{- end }}
  proxy_pass http://127.0.0.1:{{ .Values.port }};
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
}

location = /auth {
  internal;
  proxy_pass http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/;
  proxy_pass_request_body off;
  proxy_set_header Content-Length "";
  proxy_set_header X-Original-URI $request_uri;
}
```

The rest of the pattern:

- **Service and Ingress backend** target the sidecar port (`8080` by default; `8081`/`8082`
  when the app already uses `8080`), never the application port.
- **NetworkPolicy** (`scripts/chart/templates/network-policy.yaml`) admits traffic only on the
  sidecar port, so the application cannot be reached around the login.
- **Image fields** `nginx_registry`, `nginx_repo` and `nginx_tag` are launch fields in
  `metadata.yaml`, with a pinned tag by default.
- **Timeouts, upload limits, buffering and rewrites** are set in `nginx.conf`
  (`proxy_read_timeout`, `client_max_body_size`, `proxy_buffering`, `rewrite`). Never add them to
  the Ingress as `nginx.ingress.kubernetes.io/*` annotations.

The scaffold created by `make new-plugin` (`template/workload/`) ships the full pattern and is
the canonical example. Existing plugins predate parts of it, so copy from the scaffold.

### Namespaced and cluster-level plugins — Genesis

Namespaced and cluster-level plugins authenticate via Genesis with standard ingress-nginx
annotations:

!!! note
    Workload templates must always be tagged `cluster-level` in `terra.yaml` — they are installed
    into the Genesis namespace (`argocd` by default) by Terra.

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
  kuiper.juno-innovations.com/ingress-hide: "/{{ .Release.Namespace }}/myapp/{{ .Values.name }}/healthz,/{{ .Release.Namespace }}/myapp/{{ .Values.name }}/admin"
```

**Applies to:** Ingress  
**Value format:** comma-separated URL paths — each must be the **full** rendered path

Hides the listed URL paths from the endpoint list shown in the Hubble UI. Use this to suppress
internal paths like health checks or admin endpoints.

Matching is an exact string comparison against the path in the Ingress rule, so a bare sub-path
like `/healthz` will not match a rule at `/<namespace>/myapp/<name>/healthz` — it silently hides
nothing. Always write the complete path.

---

```yaml
annotations:
  kuiper.juno-innovations.com/ingress-extras: "/{{ .Release.Namespace }}/myapp/{{ .Values.name }}/index.html"
```

**Applies to:** Ingress  
**Value format:** comma-separated paths — each must **start with** an existing ingress path

Appends extra sub-paths to existing ingress endpoints in the Hubble UI without creating new
Ingress rules. Each extra path is matched to the longest existing ingress path it starts with,
and the remainder is appended to that endpoint.

Because matching is by prefix, an extra must begin with the full rendered ingress path. A bare
sub-path like `/index.html` starts with no existing rule and is dropped without warning.

---

#### Interconnects

!!! note "Requires Orion Projects v4.8.1 or later"
    Interconnects require Kuiper v4.7.1, which ships with Orion Projects v4.8.1 (Genesis v6.1.0). Earlier
    versions ignore these annotations and do not return an `interconnects` list.

```yaml
annotations:
  kuiper.juno-innovations.com/interconnect-mcp: "http://{{ .Release.Name }}:8080/mcp-server/http"
```

**Applies to:** Service  
**Value format:** connection endpoint string

Advertises a named connection point on the workload for other systems to consume, for example an
MCP server endpoint an AI agent can connect to. The annotation key suffix `<name>` becomes the
interconnect name, and the value is its endpoint. A Service can declare any number of interconnects.
Annotations with a blank value are ignored.

---

```yaml
annotations:
  kuiper.juno-innovations.com/interconnect-description-mcp: "Connect to this workload's MCP server"
```

**Applies to:** Service  
**Value format:** any string

Optional human readable description for the interconnect with the matching `<name>`. A description
is only used when an `interconnect-<name>` annotation with the same name exists on the Service.

Kuiper returns interconnects from its `/all` endpoint in two places: on each Service resource that
declares them, and collected into a top level `interconnects` list on the workload covering every
Service in that workload. The two annotations above produce:

```json
"interconnects": [
  {
    "name": "mcp",
    "endpoint": "http://my-release:8080/mcp-server/http",
    "description": "Connect to this workload's MCP server"
  }
]
```

Like all Kuiper annotations, interconnect values are returned in plain text. Do not put secrets in them.

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

When set, Kuiper uses the private address instead of `publicDnsName`: `privateDnsName` for the
ExternalName Service, and the private IP for the connection annotation. Use for instances only
reachable via private networking.

---

```yaml
annotations:
  kuiper.juno-innovations.com/aws-load-balancer: "true"
  service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

**Applies to:** Crossplane EC2 Instance  
**Value format:** `"true"`

When set, Kuiper skips the ExternalName Service and creates a `LoadBalancer` Service plus an
EndpointSlice pointing at the instance's private IP. Every `service.beta.kubernetes.io/*`
annotation on the Instance is copied onto the Service. The connection annotation uses the load
balancer's address and the Service ports. See `concepts/crossplane.md` for the access modes.
