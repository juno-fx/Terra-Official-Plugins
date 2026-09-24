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

Web apps that must serve at a path (not a root domain) use an nginx sidecar to route the
ingress path to the app. Reference: `plugins/web-ide/scripts/chart/templates/nginx.yaml` +
`workstation.yaml` (nginx container next to the app container).

**Critical:** the ingress does **not** rewrite the path — nginx `location`, the `PREFIX` env,
and any app base-URL must all match the ingress path exactly. See `concepts/ingress.md`.

## Gotchas

- `automountServiceAccountToken: false` ships in the template — don't remove it unless the
  workload genuinely needs the pod identity to call the API.
- Missing `readinessProbe`: TCP startup + liveness cover most cases; add readiness when the
  app must not receive traffic mid-boot (multi-replica only).
- `imagePullPolicy: IfNotPresent` — do not set `Always` on a `latest` tag unless the image
  genuinely changes tag-in-place.

## See also

- `concepts/ingress.md` — path matching for sidecar-based apps
- `concepts/env.md` — environment variable wiring
- `concepts/scheduling.md` — resources, probes-adjacent workload shape
- `docs/workload-templates.md` — workload.yaml conventions