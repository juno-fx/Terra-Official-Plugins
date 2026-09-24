# Best Practices — The Plugin Quality Bar

**When to use:** every plugin authoring session, before packaging. `concepts/probing.md` decides
**what** features a workload gets; this doc decides **how well** those features are done and what
baseline hygiene every plugin meets.

**Enforcement:** running the review checklist at the end of this doc is **required before
`make package` and `make verify`**. The check is **advisory** — it states issues and makes
recommendations, and it blocks nothing. The author makes the final call on every finding; nothing
here is an automated gate.

## Tiers

| Tier | Meaning |
|------|---------|
| **MUST** | Without it the plugin is broken, unsafe, or violates a platform contract. Flags as a critical issue; the check never blocks — the author makes the final call. |
| **SHOULD** | Strong default. Deviating is allowed only when the workload genuinely needs it — document the deviation in the plugin README. |
| **Consider** | Situational. Apply when the workload's characteristics call for it. |

Type markers — `[WT]` workload template, `[NS]` namespaced, `[CL]` cluster-level. Unmarked rules
apply to all three types.

## Baseline — every plugin, always

### Delivery

- [MUST] `make package <plugin>` after every `scripts/` change (Rule 1 — the top bug source)
- [MUST] `make verify` clean, `helm lint` clean, packaged size under the 1MiB ConfigMap limit
- [MUST] `Chart.yaml` version bumped on every material change
- [MUST] Generated files (`templates/packaged-scripts*.yaml`) never hand-edited
- [MUST] Commit `scripts/` and the regenerated packaged files together
- [SHOULD] README: what the plugin does, why it exists, config table, gotchas

### Correctness

- [MUST] Every field `name:` in `terra.yaml` (install-time) or `metadata.yaml` (launch-time) exists
  as a key in `values.yaml` (Rule 3) — a mismatch fails at launch, not at install
- [MUST] Deterministic resource names — no random suffixes, no timestamps
- [MUST] Jobs safe to re-render/re-run — no state corruption or resource leaks on Helm upgrade or
  sync-failure retry
- [Consider] `readOnlyRootFilesystem` when the app supports it

### Security

- [MUST] No secrets in charts, READMEs, or labels — credentials only via user-supplied `values`
  fields or `pullSecret`
- [MUST] Least-privilege RBAC; [WT]/[NS] never cluster-scoped
- [MUST] Web workloads auth-protected by default — `publicAccess` is explicit opt-in for trusted
  networks only
- [WT] [MUST] Internal paths (`/admin`, `/metrics`, `/healthz`…) hidden from the Hubble endpoint
  list via `ingress-hide`
- [SHOULD] Non-root run-time pattern (PUID/PGID, linuxserver.io style — these are container
  user/group IDs, not env vars; see `concepts/env.md` for how they relate to platform-set vars)

### Assets

- [MUST] Logo/icon in `assets/`, never `scripts/` (the whole `scripts/` tree ships inside the 1MiB
  ConfigMap)
- [MUST] `terra.yaml` `icon` and README badges reference the root `assets/` path

## Feature quality — per probing confirmation

Applied when probing confirms the feature. The template baseline stays as shipped; each feature
arrives as a small, concept-backed addition.

Non-container workloads — KubeVirt VMs, Crossplane instances, and connection brokers have no pod,
so the pod-centric bars (probes, `automountServiceAccountToken: false`, image values, resource
requests, PUID/PGID) do not apply. Review those charts against `concepts/vm.md`,
`concepts/crossplane.md`, `concepts/connection-brokers.md` instead.

### Image & runtime → `concepts/runtime.md`

- [MUST] Image reference built from `registry`/`repo`/`tag` values — never a hardcoded full image
- [SHOULD] Pin a known-good tag by default; `latest` allowed but documented (mind
  `imagePullPolicy: IfNotPresent`)
- [SHOULD] `pullSecret` wiring when the image lives in a private registry
- [MUST] `automountServiceAccountToken: false` stays; cluster API access → least-privilege Service
  Account ([WT] `k8sServiceAccount` picker)
- [SHOULD] Run as non-root (PUID/PGID run-time pattern); root only when the workload genuinely
  needs it (desktop, privileged ops) — deliberate and documented
- [Consider] `command`/`args` only to override a broken upstream default — never to add features

### Probes → `concepts/runtime.md`

- [MUST] Every web-serving workload: `startupProbe` + `livenessProbe` via `httpGet` on a real,
  **unauthenticated** health endpoint. A liveness path behind auth returns 401 and the pod
  restart-loops
- [SHOULD] TCP probe fallback only when the app exposes no HTTP health endpoint — document that it
  proves port-accept, not readiness
- [Consider] `readinessProbe` only when multi-replica or the app must not receive traffic mid-boot
- [MUST] Probed port == `containerPort`; change them together

The template ships no probes — they are author-added per workload. This MUST therefore applies at
authoring time to web workloads, not to the scaffold.

### Resources & scheduling → `concepts/scheduling.md`, `concepts/affinity.md`

- [MUST] `requests` always present (template baseline)
- [SHOULD] `limits` when the workload is bounded or the namespace is multi-tenant; memory limits
  mean OOMKill — set with headroom
- [MUST] Replicas honest: 1 for stateful; >1 only with readiness and no shared-state assumption
- [MUST] Affinity only when the workload must land somewhere specific — via `.Values.selector` or
  `nodeAffinity` on a real node label; never hardcoded node names
- [MUST] Never replicate Kuiper's anti-blacklist affinity injection
  (`concepts/affinity.md` — Kuiper-source fact)
- [SHOULD] Tolerations only for real taints, matching the taint key
- [SHOULD] Pod placement (avoid others / pack together) only with a probe-confirmed reason —
  node contention or locality; `preferred` (soft) over `required` unless correctness depends
  on it (`concepts/affinity.md`)
- [Consider] `k8sPriority` for preemption-critical workloads

### Storage → `concepts/storage.md`

- [WT] [MUST] Launch-time mounts via Kuiper `volumeMounts`/`volumes` values — never hardcoded PVC
  names
- [NS]/[CL] [MUST] Install-time storage via terra `shared-volume`/`exclusive-volume` fields
- [SHOULD] Access mode honest: RWO for single-pod, RWX only when truly shared
- [Consider] [WT] `k8sStorageClass` picker when storage class choice matters
- [SHOULD] Stateless-vs-persistent decision written in the README

### GPU → `concepts/gpu.md`

- [MUST] Default off — never default `gpu` to `true`
- [MUST] `runtimeClassName: nvidia` and the `nvidia.com/gpu` limit wired to the same `gpu` value
- [SHOULD] Driver prerequisite (`plugins/nvidia-gpu-operator`) documented in the README

### Operability

- [SHOULD] `connection` annotation surfaces credentials/ports in the Hubble endpoint list
- [SHOULD] `actions` whitelist deliberate — only actions that make sense for the app
  (`restart`/`stop`/`scale`)
- [WT] [SHOULD] `env_hints` and the README `### Custom Environment Variables` mirror identical
- [WT] [SHOULD] Platform env vars wired only when the upstream image consumes them — dead vars are
  false documentation (`concepts/env.md`)
- [WT] [MUST] `PREFIX`/in-container path references match the ingress path exactly
  (`concepts/ingress.md` — nothing rewrites the path)

### UX [WT]

- [MUST] `juno-innovations.com/workload` annotation on both `metadata.yaml` and the StatefulSet,
  value matching the Genesis category
- [SHOULD] Fields: honest `required`/`optional`, sane defaults, actionable descriptions

## Type minimums

**[WT]**
- Ownership label `kuiper.juno-innovations.com/kuiper-instance` on the StatefulSet selector, pod
  template labels, and Service selector
- Ingress (HTTP workloads): Hubble auth (`auth-workstation`, `use-regex: "true"`), path
  `/{{ .Release.Namespace }}/{{ .Values.name }}/` (optional plugin segment);
  non-HTTP workloads (game, LDAP, raw TCP/UDP): Service NodePort/LoadBalancer — no ingress
  (`concepts/service-exposure.md`)
- Standard Kuiper-injected keys present in `values.yaml` (AGENTS.md list — do not remove)
- `scripts/chart/` packaged (`make package`)

**[NS]**
- Web UIs authenticate via Genesis (`/api/auth-service/<release>/` + `auth-signin: /unauthorized/`)
- Non-HTTP workloads expose via Service NodePort/LoadBalancer — no ingress (`concepts/service-exposure.md`)
- Install-time terra fields carry configuration; `shared-volume`/`exclusive-volume` for storage
  installers
- No Kuiper annotations — ArgoCD synced directly, they have no effect

**[CL]**
- Creates and manages its own namespaces; install target is `argocd`
- ArgoCD `Application` delegating to an upstream chart is the common pattern
- RBAC scoped to what the plugin manages — no wildcard cluster-admin
- No Kuiper annotations (same reason as `[NS]`)

## Anti-patterns

- Decorative TCP probes — green while dead
- Affinity or pod placement (avoid/pack) for no reason — most workloads schedule anywhere
- Secret in an env-var default — leaks into chart, README, and labels
- Field without a `values.yaml` key — fails at launch, not at install
- README/`env_hints` drift — docs disagree with what Genesis suggests
- Forgot `make package` — old scripts deploy silently (top bug source)

## Review checklist

Condensed from the tiers above. **Required before `make package` / `make verify`; the output is
advisory** — state issues, recommend, block nothing. The author makes the final decision on every
item; a documented deviation (README note) satisfies an item the author deliberately skips:

- [ ] `make verify` + `helm lint` clean; packaged; version bumped
- [ ] Scripts change → packaged files regenerated and committed together
- [ ] Every field has a `values.yaml` key; [WT] standard injected keys present
- [ ] No secrets; least-privilege RBAC; web auth protected by default
- [ ] Web workload: real `httpGet` probes on an unauthenticated endpoint
- [ ] Requests present; limits if bounded; replicas honest
- [ ] No affinity unless required; no avoid/pack placement without a probe-confirmed
      reason; no anti-blacklist replication
- [ ] Storage via platform values, not hardcoded PVCs
- [ ] GPU (if any): default off, both wirings on the same value
- [ ] [WT] annotations: workload ×2, `kuiper-instance` ×3, `actions`/`connection` deliberate,
      `env_hints` mirrored
- [ ] [WT] exposure deliberate: ingress for HTTP, Service NodePort/LoadBalancer for non-HTTP
      (`concepts/service-exposure.md`)
- [ ] README complete