# Ingress — Routing, Authentication, Endpoint Visibility

**When to use:** exposing the workload over HTTP, wiring platform authentication, or hiding
endpoints from the Hubble UI.

## Path convention

Every workload ingress path starts with the release namespace; a plugin may add its own
segment after it:

```yaml
- path: "/{{ .Release.Namespace }}/{{ .Values.name }}/"
  pathType: Prefix
  backend:
    service:
      name: {{ .Values.name }}
      port:
        number: {{ .Values.port }}
```

The template starts with **no segment**. Many catalog workload charts add one — the heritage
segment is `polaris` (web-ide, proxmox, helios, boinc, jupyter-notebook, lsio-webtop,
runtime-python/go/js/cpp); other charts choose their own (gitea → `/gitea/`, k9s → `/k9s/`).

The rule nginx enforces: **host + path must be unique cluster-wide**. Two environments sharing
a hostname both rendering `/polaris/<name>/` collide — the second launch is rejected by the
ingress admission webhook. An environment with its own hostname satisfies uniqueness via the
host alone, but the namespace segment is harmless where redundant and **required** where not —
include it always. Whatever segment (or none) the chart renders, keep it consistent across
every in-container reference below.

## Authentication

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

### publicAccess

Workload templates ship a `publicAccess` boolean that **disables** Hubble auth:

```yaml
{{- if not .Values.publicAccess }}
nginx.ingress.kubernetes.io/auth-url: "http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/"
{{- end }}
```

Keep this pattern — some workloads (webhooks, APIs consumed by external systems) must skip
authentication.

## Endpoint visibility — ingress-hide / ingress-extras

| Annotation | Match | Use |
|------------|-------|-----|
| `kuiper.juno-innovations.com/ingress-hide` | **exact string** against the rendered path | hide internal paths (`/healthz`, admin UIs) from the Hubble endpoint list |
| `kuiper.juno-innovations.com/ingress-extras` | **prefix** match, appends remainder | surface sub-paths without adding Ingress rules |

`ingress-hide` values must be the **full namespaced path**, not a bare sub-path:

```yaml
kuiper.juno-innovations.com/ingress-hide: "/{{ .Release.Namespace }}/{{ .Values.name }}/healthz"
kuiper.juno-innovations.com/ingress-extras: "/{{ .Release.Namespace }}/{{ .Values.name }}/index.html"
```

## The no-rewrite gotcha

No chart sets `rewrite-target` — nginx routes to the pod and the container receives the full
URL. Every in-container reference must match the ingress path **exactly**:

| Where | Example |
|-------|---------|
| `PREFIX` env | `value: "/{{ .Release.Namespace }}/{{ .Values.name }}/"` |
| nginx sidecar | `location /{{ .Release.Namespace }}/{{ .Values.name }}/ { … }` |
| App base-url flags | `--baseURL`, `--ServerApp.base_url`, `ROOT_URL` |
| Gateway API | `HTTPRoute` `URLRewrite` value |

Changing the ingress alone routes correctly then **404s in the app** — it fails *after*
looking like it worked. Update all four in the same pass. If the chart renders a segment
(`/ns/<segment>/<name>/`), every reference carries it too.

## Gotchas

- `kubernetes.io/ingress.class: nginx` (template) — required for the platform's nginx
  ingress controller.
- Service `port` (`number: {{ .Values.port }}` template) must match the container's
  `containerPort`.
- Kuiper annotations (`ingress-hide`/`ingress-extras`) only affect **workload templates** —
  namespaced/cluster plugins are synced by ArgoCD and never pass through Kuiper.

## See also

- `concepts/runtime.md` — nginx sidecar pattern, probes
- `concepts/labels-annotations.md` — full annotation reference
- `docs/workload-configuration.md` — ingress auth patterns