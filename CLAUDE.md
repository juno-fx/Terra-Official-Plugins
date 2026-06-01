# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Official plugin catalog for the **Juno platform**. Plugins are Helm charts Terra installs into Kubernetes clusters via ArgoCD. Three plugin types exist — the type determines how Terra installs it and how Kuiper/Genesis interacts with it.

## Dev Environment

```bash
devbox shell          # enter dev environment (required for kind, inotify-tools, etc.)
```

## Key Commands

```bash
make new-plugin                   # interactive scaffolding for new plugin
make package <plugin-name>        # REQUIRED after any scripts/ change
make verify                       # check all plugins have up-to-date packages (also runs in CI)
make check-size <plugin-name>     # verify packaged size < 1MiB ConfigMap limit
make watch <plugin-name>          # auto-repackage on scripts/ changes during dev
make lint                         # helm lint all plugins
make test <plugin-name>           # deploy to local Kind cluster via ArgoCD
make down                         # destroy local Kind cluster
make docs                         # serve MkDocs docs locally (needs .venv active)
```

## Plugin Types

### 1. Namespaced Plugin
Helm chart installed into the user's project namespace. No `cluster-level` in `terra.yaml` tags.
Example: `plugins/ollama/`, `plugins/firefox/`

### 2. Cluster-Level Plugin
Same as namespaced but installed into `argocd` namespace. Has `cluster-level` tag in `terra.yaml`. Must manage its own namespaces.
Example: `plugins/nvidia-gpu-operator/`, `plugins/longhorn/`

### 3. Workload Template
Schema plugin consumed by Genesis/Kuiper. Installs a ConfigMap containing an embedded Helm chart (`scripts/chart/`). Kuiper renders this chart at workload launch time.
Identifying markers: `templates/metadata.yaml` with `kuiper.juno-innovations.com/chart` label, `scripts/chart/` directory, `cluster-level` tag.
Example: `plugins/helios/`, `plugins/web-ide/`

## Critical Rule: Always Repackage

`templates/packaged-scripts.yaml` and `templates/packaged-scripts-cleanup.yaml` are **generated** — never hand-edit them.

After **any** change to `scripts/` or `scripts/chart/`:
```bash
make package <plugin-name>
```

Forgetting this deploys the old scripts silently. `make verify` catches stale packages and fails CI.

## Workload Template Architecture

```
scripts/chart/values.yaml       ← field names must exactly match metadata.yaml fields
templates/metadata.yaml         ← Genesis discovery (kuiper.juno-innovations.com/chart label) + field schema
templates/packaged-scripts.yaml ← GENERATED: base64-gzip of scripts/ in a ConfigMap
```

`scripts/chart/values.yaml` must always include the Kuiper-injected standard keys (`name`, `user`, `group`, `cpu`, `memory`, `cpuLimit`, `memoryLimit`, `idx`, `guid`, `puid`, `host`, `pullSecret`, `session`, `volumeMounts`, `volumes`, `env`, `selector`, `plugins`, `_kuiper`). Do not remove them.

`workstation.yaml` StatefulSets must:
- Target nodes with label `juno-innovations.com/workstation: "true"` (node affinity)
- Tolerate taint `juno-innovations.com/workstation: NoSchedule`
- Set `juno-innovations.com/workload` annotation matching `metadata.yaml`

See `plugins/helios/scripts/chart/templates/workstation.yaml` for the reference implementation.

## Ingress Auth Patterns

Workload templates (auth via Hubble):
```yaml
nginx.ingress.kubernetes.io/auth-url: "http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/"
nginx.ingress.kubernetes.io/use-regex: "true"
```

Namespaced/cluster-level plugins (auth via Genesis):
```yaml
nginx.ingress.kubernetes.io/auth-url: "http://genesis.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-service/{{ .Release.Name }}/"
nginx.ingress.kubernetes.io/auth-signin: /unauthorized/
```

## `terra.yaml` vs `metadata.yaml` Fields

- `terra.yaml` fields → shown in Terra app store **at install time** → become Helm values for `templates/`
- `metadata.yaml` fields → shown in Genesis UI **at workload launch time** → become Helm values for `scripts/chart/`

Field `name:` in `metadata.yaml` must exactly match the key in `scripts/chart/values.yaml`.

## Packaging Internals

`make package` does: `tar -czf scripts.tar scripts/ | base64 -w 0` → injects into ConfigMap YAML. The 1MiB Kubernetes ConfigMap limit applies to the **compressed+base64** result. `make package` auto-runs `make check-size`; it warns at 900KB and errors at 1MiB.

## AGENTS.md

Contains the authoritative reference for all annotations, field types, `terra.yaml` schema, workload template data flow, and common mistakes. Read it before making significant changes.
