# Runtime — Image, Command, Probes, Sidecars

**When to use:** configuring what actually runs in the container — image, pull credentials,
command/args, health probes, extra containers.

## Image

The template ships `registry` / `repo` / `tag` fields wired to the image string:

```yaml
# scripts/chart/templates/workload.yaml — container
image: "{{ .Values.registry }}/{{ .Values.repo }}:{{ .Values.tag }}"
imagePullPolicy: IfNotPresent
```

- `registry`/`repo`/`tag` must be fields in `templates/metadata.yaml` (they are).
- Keep the three-way split — users override per workload without chart edits.

## Private registries

The `pullSecret` value (injected by Kuiper when the user supplies credentials) renders
`imagePullSecrets`:

```yaml
{{- if .Values.pullSecret }}
imagePullSecrets:
  - name: "{{ .Values.pullSecret }}"
{{- end }}
```

## Command / args

Extend the container in `workload.yaml`:

```yaml
command: ["/entrypoint.sh"]
args: ["--port", "3000"]
```

Default the entrypoint in the image when possible; add `command`/`args` only when the upstream
image needs override. Use the same `{{ .Values.<field> }}` pattern if users must configure them.

## Probes

Probes are added when probing shows the app needs them (slow cold start, health endpoint).
TCP probes are the cheap baseline — they only prove the port accepts connections, not that the
app is ready:

```yaml
ports:
  - containerPort: {{ .Values.port }}
startupProbe:
  tcpSocket:
    port: {{ .Values.port }}
  initialDelaySeconds: 5
  failureThreshold: 60
  periodSeconds: 2
livenessProbe:
  tcpSocket:
    port: {{ .Values.port }}
  failureThreshold: 24
  periodSeconds: 5
```

- The probed port **must match `containerPort`** (template default `{{ .Values.port }}`).
  Change both together.
- Slow-starting apps: raise `startupProbe.failureThreshold` rather than removing it.
- An HTTP app with a real health endpoint should upgrade to an `httpGet` probe (path, port).

## Sidecars — the nginx auth pattern

Every HTTP workload template runs an nginx sidecar in the same pod. The Ingress routes to the
sidecar; the sidecar enforces the Hubble login (`auth_request`) and proxies to the app on
`127.0.0.1`. This removes any dependency on ingress-nginx annotations. The scaffold
(`template/workload/`) ships it and is the canonical implementation. Existing plugins predate
parts of the convention, so cite them only for a specific extra: `plugins/helios/` (HTTPS
upstream, streaming), `plugins/n8n/` (rewrites, public webhook paths, rate limits),
`plugins/vm-ephemeral/` (websocket timeouts, non-default port).

### The four pieces

**1. Config** — `scripts/chart/files/nginx/nginx.conf`, a full config templated with Helm values:

```nginx
events {}
http {
  server {
    listen 8080;
    listen [::]:8080;

    # Redirect the slashless path so the browser URL gains the slash and relative assets resolve.
    location = /{{ .Release.Namespace }}/{{ .Values.name }} {
      # Relative Location; an absolute one would carry the sidecar's http://...:8080.
      absolute_redirect off;
      return 301 $uri/;
    }

    location /{{ .Release.Namespace }}/{{ .Values.name }}/ {
      {{- if not .Values.publicAccess }}
      auth_request /auth;
      {{- end }}
      proxy_pass http://127.0.0.1:{{ .Values.port }};
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      # Pass through the controller's scheme; $scheme here is always http.
      proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
    }

    location = /auth {
      internal;
      proxy_pass http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/;
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";
      proxy_set_header X-Original-URI $request_uri;
    }
  }
}
```

**2. ConfigMap** — `scripts/chart/templates/nginx.yaml` renders the file with `tpl`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{{ .Values.name }}-nginx"
data:
  nginx.conf: |
{{ tpl (.Files.Get "files/nginx/nginx.conf") . | indent 4 }}
```

**3. Container** — in `workload.yaml`, next to the app container:

```yaml
containers:
  - name: nginx
    image: "{{ .Values.nginx_registry }}/{{ .Values.nginx_repo }}:{{ .Values.nginx_tag }}"
    imagePullPolicy: IfNotPresent
    ports:
      - containerPort: 8080
        name: nginx
    resources:
      requests:          # small fixed requests; the best-practices requests MUST covers the sidecar too
        cpu: "50m"
        memory: "64Mi"
    volumeMounts:
      - name: nginx
        mountPath: /etc/nginx/nginx.conf
        subPath: nginx.conf
  # - name: <app> ...
volumes:
  - name: nginx
    configMap:
      name: "{{ .Values.name }}-nginx"
```

**4. Routing** — Service, Ingress backend and NetworkPolicy all target the sidecar port (see
`concepts/ingress.md`).

### Image fields

`nginx_registry`, `nginx_repo` and `nginx_tag` are user-facing launch fields: declare them in
`templates/metadata.yaml` `fields:`, add them to `scripts/chart/values.yaml` (Rule 3), and list
them in the README launch-fields table. Defaults are `docker.io` / `nginx` / a **pinned** tag
(currently `1.30.7` or `1.30.7-alpine`). On version bumps, keep each plugin's existing Debian or
Alpine variant, and update `values.yaml`, `metadata.yaml` and the README together.

### Port

The sidecar listens on `8080` by default. If the app already uses `8080`, move the sidecar to
`8081` or `8082` (open-webui, runtime-*, vm-ephemeral) and change `listen`, `containerPort`,
Service, Ingress backend and NetworkPolicy together. Document the reserved port in the README
Notes so users don't configure the app onto it.

### Behaviour that used to be ingress annotations

| Need | In `nginx.conf` |
|------|-----------------|
| Long-lived websockets (terminals, VNC, notebooks) | `proxy_read_timeout` / `proxy_send_timeout` on the websocket `location` |
| Large uploads | `client_max_body_size 0;` (nginx defaults to 1m) |
| Streaming responses (LLM output, logs) | `proxy_buffering off;` |
| HTTPS upstream (self-signed app cert) | `proxy_pass https://127.0.0.1:<port>; proxy_ssl_verify off;` |
| Strip the path prefix for apps that can't take a base URL | `rewrite ^/<path>/(.*) /$1 break;` or a trailing slash on `proxy_pass` |
| Public sub-paths, rate limits, allow lists | separate `location` without `auth_request`; `limit_req`, `allow`/`deny` (n8n) |

A `proxy_set_header` inside a `location` drops every server-level `proxy_set_header`, so repeat
`Host` and the forwarding headers there.

**Critical:** the ingress does **not** rewrite the path — nginx `location`, the `PREFIX` env,
and any app base-URL must all match the ingress path exactly. See `concepts/ingress.md`.

### Other sidecars

Sidecars beyond the nginx auth sidecar (e.g. the kubevirt-console sidecar in `concepts/vm.md`)
are added per workload after probing.

## Gotchas

- `automountServiceAccountToken: false` ships in the template — don't remove it unless the
  workload genuinely needs the pod identity to call the API.
- Missing `readinessProbe`: TCP startup + liveness cover most cases; add readiness when the
  app must not receive traffic mid-boot (multi-replica only).
- `imagePullPolicy: IfNotPresent` — do not set `Always` on a `latest` tag unless the image
  genuinely changes tag-in-place.

## See also

- `concepts/ingress.md` — path matching, sidecar auth, NetworkPolicy
- `concepts/env.md` — environment variable wiring
- `concepts/scheduling.md` — resources, probes-adjacent workload shape
- `docs/workload-templates.md` — workload.yaml conventions