# Labels & Annotations — Kuiper's Plugin-Author Reference

**When to use:** enabling Kuiper features on chart resources — actions, connections, adopted
resources, plugin scripts, ingress endpoint visibility, EC2 exposure.

All keys use the `kuiper.juno-innovations.com/` prefix. **These only apply to workload
template plugins** — namespaced and cluster-level plugins are synced by ArgoCD and never pass
through Kuiper.

> Mirrors the tables in AGENTS.md (the quick reference). Keep both in sync.

## Plugin-author — set these in charts

### General

| Annotation | Applies To | Value | What it enables |
|------------|-----------|-------|-----------------|
| `kuiper.juno-innovations.com/actions` | any resource | comma-separated names | Whitelist of callable actions (`restart,stop,scale`). Only listed actions work via the Kuiper API. |
| `kuiper.juno-innovations.com/connection` | any resource | `key=value,key=value` | Endpoint metadata surfaced in the Hubble UI (`username=admin,port=5900`). |
| `kuiper.juno-innovations.com/adopt-<name>` | any resource | Kubernetes Kind | Adopt a deterministically-named resource created **outside** the chart (suffix = resource name, value = Kind). Kuiper patches the ownership label so it is tracked and cleaned up with the workload. Canonical use: the ExternalName Service Kuiper creates post-launch for an EC2 instance. |
| `kuiper.juno-innovations.com/plugin` (**label**) | ConfigMap | `"true"` | Marks a ConfigMap as plugin scripts (e.g. a Helios init script). Kuiper discovers labeled ConfigMaps and makes them available to workloads via the `plugins:` value that workload charts range over (mounted at `/etc/helios/init.d/<name>/<file>`). Canonical example: `plugins/helios-auto-shutdown/templates/wave-1/plugin.yaml`. |

### Ingress

| Annotation | Value | What it enables |
|------------|-------|-----------------|
| `kuiper.juno-innovations.com/ingress-hide` | comma-separated full paths | Hide paths from the Hubble endpoint list (exact match — use the full rendered path). |
| `kuiper.juno-innovations.com/ingress-extras` | comma-separated sub-paths | Append sub-paths to the endpoint list without adding Ingress rules (prefix match). |

Full detail + examples: `concepts/ingress.md`.

### Crossplane / EC2

| Annotation | Applies To | Value | What it enables |
|------------|-----------|-------|-----------------|
| `kuiper.juno-innovations.com/expose` | Crossplane EC2 Instance | comma-separated ports | Kuiper auto-creates an ExternalName Service exposing these ports once EC2 DNS is available. |
| `kuiper.juno-innovations.com/aws-remote-connection` | Crossplane EC2 Instance | `"true"` | Kuiper computes and writes the `connection` annotation once EC2 DNS is available. |
| `kuiper.juno-innovations.com/use-private-dns` | Crossplane EC2 Instance | `"true"` | Use `privateDnsName` instead of `publicDnsName` for the ExternalName Service and connection annotation. |

## Kuiper-managed — do not set

Kuiper writes these at runtime. **Do not set them in charts**:

| Annotation | Description |
|------------|-------------|
| `kuiper.juno-innovations.com/kuiper-instance` (label) | Ownership label injected on every resource at launch; used as the selector for discovery and deletion. |
| `kuiper.juno-innovations.com/hidden` | Marks internal Kuiper ConfigMaps as hidden from API responses. |
| `kuiper.juno-innovations.com/delete-protection` | Resources Kuiper orphans rather than deletes on shutdown. |
| `kuiper.juno-innovations.com/container-path` | Mount target path inside the container (PVCs Kuiper manages). |
| `kuiper.juno-innovations.com/sub-path` | Sub-directory within a PVC to mount. |
| `kuiper.juno-innovations.com/mount-access` | JSON array of Juno usernames/groups permitted to use a mount. |
| `kuiper.juno-innovations.com/service-provisioned` | Idempotency flag — ExternalName Service for EC2 already created. |
| `kuiper.juno-innovations.com/connection-provisioned` | Idempotency flag — connection annotation for EC2 already written. |
| `kuiper.juno-innovations.com/user-created-datavolume` | Written on DataVolume clones; selector for the `dataVolume` field type. |
| `juno-innovations.com/kuiper-instance` | **Deprecated** legacy ownership label — auto-migrated to the `kuiper.juno-innovations.com/` prefix on first read. |

### The one exception — `kuiper-instance` on pod templates

The workload template **does** declare `kuiper.juno-innovations.com/kuiper-instance:
"{{ .Values.name }}"` on the StatefulSet selector, its pod `template.metadata.labels`, and
the Service selector. This is not a violation:

- Kuiper's injection reaches **top-level resource metadata only** — never
  `spec.template.metadata.labels`.
- The StatefulSet selector must match its pod template labels, so the chart must declare the
  label on the pod template itself, using the same value Kuiper injects.
- The identical-key/identical-value merge at launch is a no-op.

Never set it on resources with a *different* value, and never rely on injection to set pod
template labels.

## Platform annotations — out of scope

The platform sets its own annotations at runtime outside this repo's scope. Do not document
or set them in plugins.

## Gotchas

- Annotations on namespaced/cluster plugins have **no effect** — Kuiper never processes those
  charts.
- `actions` values must match what the resource kind supports — a whitelisted action that
  doesn't exist for the kind is inert.
- `adopt-<name>` requires the external resource's name to be deterministic — the chart cannot
  adopt a randomly-named resource.
- `plugin` is a **label**, not an annotation — `labels: kuiper.juno-innovations.com/plugin: "true"`.

## See also

- `concepts/ingress.md` — endpoint visibility detail
- `concepts/storage.md` — Kuiper-managed mount annotations context
- AGENTS.md — Kuiper Annotations Reference (canonical tables)