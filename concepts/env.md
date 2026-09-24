# Env — Environment Variables

**When to use:** the workload needs configurable environment variables — user-set, suggested,
or platform-provided.

## User-set env vars — `.Values.env`

Kuiper auto-injects an `env` field into every workload schema. The chart ranges it into the
container:

```yaml
# scripts/chart/templates/workload.yaml — container env
{{- range .Values.env }}
- name: {{ .name | quote }}
  value: {{ .value | quote }}
{{- end }}
```

Ships in the template — keep it. Users set vars at launch; the workload renders them.

## Suggested vars — `env_hints` in `templates/metadata.yaml`

For workloads whose chart ranges over `.Values.env`, `metadata.yaml` documents the upstream
image's *commonly useful* custom vars so the launch UI can surface them next to the env field:

```yaml
data:
  fields: |
    - name: ...
  env_hints: |
    - name: EXAMPLE_VAR
      description: "What this variable does and when to set it"
```

Rules:

- **Curated list** — only vars end users would actually set. Not exhaustive upstream docs.
- **Never list a var already set by the platform** at runtime — a suggested var that collides
  with a platform-set one is silently shadowed.
- No well-known custom vars → `env_hints: |` with an indented `[]`
  (reference: `plugins/proxmox/templates/metadata.yaml`).
- Mirror the list in the plugin `README.md` under `### Custom Environment Variables` — the two
  must stay identical.

## Platform context — pass-through vars, wire only what the image consumes

The platform knows the workload's user, project, environment, and ingress path. These vars are
the **mechanisms** for handing that context to a container — the chart wires one **only when the
upstream image is actually built to read it** (check the image README, Dockerfile, or entrypoint).
They are not a checklist every workload must fulfill; wiring a var an image ignores just ships dead
env and false documentation.

| Variable | Value | Wire when |
|----------|-------|-----------|
| `JUNO_WORKSTATION` | `{{ .Values.name }}` — workload name | informational — consumers vary |
| `JUNO_PROJECT` | namespace (fieldRef) — legacy name, still set | the image reads it |
| `JUNO_WORKSPACE` | namespace (fieldRef) | the image reads it |
| `JUNO_ENVIRONMENT` | namespace (fieldRef) | the image reads it |
| `USER` | `{{ .Values.user }}` | linuxserver.io-style images building config under `HOME` |
| `HOME` | `/home/{{ .Values.user }}` | linuxserver.io-style images building config under `HOME` |
| `UID` | `{{ .Values.puid }}` | linuxserver.io-style entrypoints (su-exec / chown to the user ID) |
| `GID` | `{{ .Values.guid }}` | linuxserver.io-style entrypoints (su-exec / chown to the group ID) |
| `PREFIX` | ingress path — see `concepts/ingress.md` | base-path-aware apps; the runtime-* plugins read it |

Rules:

- **Trigger is the image, not the workload** — "the app deals with users or paths" does not
  justify wiring; the image must actually consume the variable.
- Wire with the exact values above; never shadow them in `.Values.env` or `env_hints`.
- If the upstream image's config needs one of these names for a *different* purpose, the image
  is incompatible with the platform convention — pick another mechanism (extra args, config
  file) rather than shadowing.

`plugins/helios/` wires the full set in `workstation.yaml` — that chart is the feature-complete
reference, not the baseline (the template ships `env: []`).

## Gotchas

- `env_hints` entries are suggestions, not requirements — users can set any var the image
  supports.
- `env_hints` in `metadata.yaml` and the README fall out of sync easily — update both
  together.
- Field names in `metadata.yaml` must match `values.yaml` keys exactly (Rule 3) — the `env`
  value list is no exception: the chart's range consumes `.Values.env` as-is.

## See also

- `concepts/runtime.md` — image, command, probes
- `concepts/ingress.md` — `PREFIX` path coupling
- `docs/workload-configuration.md` — field types, env_hints