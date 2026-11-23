# Ingress — Routing, Authentication, Endpoint Visibility

**When to use:** exposing the workload over HTTP, wiring platform authentication, or hiding
endpoints from the Hubble UI.

## Path convention

Every workload ingress path starts with the release namespace; a plugin may add its own
segment after it:

```yaml
spec:
  # Kuiper >= 4.8.0 overwrites this with the launching namespace's IngressClass.
  # nginx is the fallback for older deployments.
  ingressClassName: nginx
  rules:
    - host: {{ .Values.host }}
      http:
        paths:
          - path: "/{{ .Release.Namespace }}/{{ .Values.name }}/"
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.name }}
                port:
                  number: 8080   # the nginx sidecar, never the app port
```

The Ingress is **plain and controller-agnostic** — no `nginx.ingress.kubernetes.io/*`
annotations and no `kubernetes.io/ingress.class` annotation. Kuiper annotations
(`ingress-hide`/`ingress-extras`), cert-manager and external-dns annotations are fine.

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

**Workload templates** — authenticate via Hubble **inside the pod**. The Ingress routes to an
nginx sidecar, which runs an `auth_request` against Hubble before proxying to the app on
`127.0.0.1`. Because no ingress-controller annotations are involved, this works the same behind
ingress-nginx, Traefik, or any other controller. In `scripts/chart/files/nginx/nginx.conf`:

```nginx
location /{{ .Release.Namespace }}/{{ .Values.name }}/ {
  auth_request /auth;
  proxy_pass http://127.0.0.1:{{ .Values.port }};
  # ... websocket + forwarding headers — see concepts/runtime.md
}

location = /auth {
  internal;
  proxy_pass http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/;
  proxy_pass_request_body off;
  proxy_set_header Content-Length "";
  proxy_set_header X-Original-URI $request_uri;
}
```

The sidecar container, ConfigMap, port choice and image pinning are in `concepts/runtime.md`.

**Namespaced / cluster-level plugins** — authenticate via Genesis with ingress-nginx annotations
(these plugins are not part of the sidecar pattern):

```yaml
nginx.ingress.kubernetes.io/auth-url: "http://genesis.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-service/{{ .Release.Name }}/"
nginx.ingress.kubernetes.io/auth-signin: /unauthorized/
```

### publicAccess

Workload templates ship a `publicAccess` boolean that **disables** Hubble auth. It gates the
sidecar's `auth_request` — the sidecar itself stays in the path:

```nginx
location /{{ .Release.Namespace }}/{{ .Values.name }}/ {
  {{- if not .Values.publicAccess }}
  auth_request /auth;
  {{- end }}
  proxy_pass http://127.0.0.1:{{ .Values.port }};
}
```

Keep this pattern — some workloads (webhooks, APIs consumed by external systems) must skip
authentication. For a mix of protected and public paths, put `auth_request` on the protected
`location`s only (n8n's public webhook paths add a rate limit and optional CIDR allow list).

### Unauthenticated modes and custom domains

Where a workload offers an explicitly unauthenticated mode (runtime templates'
`network_mode: ingress-noauth`, or a custom `domain` route), the Ingress and Service may route
straight to the app port with no sidecar, and the NetworkPolicy allows that port instead. A
custom domain can never use the Hubble gate — the platform session cookie is not sent to another
host — so only honour a domain from a state that already declares itself unauthenticated.

## NetworkPolicy — lock the pod to the sidecar

Every sidecar workload ships `scripts/chart/templates/network-policy.yaml` admitting traffic
**only on the sidecar port**, so nothing can reach the app port and bypass the login:

```yaml
spec:
  podSelector:
    matchLabels:
      kuiper.juno-innovations.com/kuiper-instance: "{{ .Values.name }}"
  policyTypes:
    - Ingress
  # No `from` — the sidecar enforces auth itself, so any controller namespace is accepted.
  ingress:
    - ports:
        - protocol: TCP
          port: 8080
```

Egress is a per-plugin decision. Some charts add `Egress` with `egress: []` and rely on the
workspace's own network policies (wetty); most leave egress open.

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

The Ingress never rewrites the path — the sidecar receives the full URL and, unless its
`nginx.conf` deliberately rewrites it (n8n uses `rewrite ^/<path>/(.*) /$1 break;`; a trailing
slash on `proxy_pass` also strips the matched prefix, as in vm-ephemeral and web-ide), so does
the app. Every in-container reference must match the ingress path **exactly**:

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

- Never add `nginx.ingress.kubernetes.io/*` annotations to a workload Ingress — not even
  "harmless" timeouts. They work on ingress-nginx and are silently ignored elsewhere. Timeouts,
  `client_max_body_size`, buffering and rewrites go in the sidecar's `nginx.conf`.
- `ingressClassName: nginx` is a fallback: Kuiper ≥ 4.8.0 overwrites it with the launching
  namespace's IngressClass. Use the `spec` field, not the deprecated
  `kubernetes.io/ingress.class` annotation.
- The Ingress backend, Service `port`/`targetPort` and NetworkPolicy port are all the **sidecar**
  port. Pointing any of them at the app port bypasses auth (and the NetworkPolicy then blocks
  the traffic).
- Kuiper annotations (`ingress-hide`/`ingress-extras`) only affect **workload templates** —
  namespaced/cluster plugins are synced by ArgoCD and never pass through Kuiper.

## See also

- `concepts/runtime.md` — nginx sidecar container, config, port, image pinning
- `plugins/wetty/` — simplest sidecar reference; `plugins/n8n/` — rewrites, public paths, rate limits
- `concepts/labels-annotations.md` — full annotation reference
- `docs/workload-configuration.md` — ingress auth patterns