# Cloud Instances — Crossplane Workloads

**When to use:** the workload is **cloud infrastructure** — an EC2 instance (or similar
Crossplane-managed cloud resource) running outside the cluster. The workload is a Crossplane
Composite Resource (XR), not a pod and not a VM in the cluster.

**Prerequisite:** `plugins/crossplane/` **and** the matching provider plugin (e.g.
`plugins/crossplane-aws-provider/`) installed (cluster-level), plus a `providerConfig` the XR
references. Without a working provider, the instance stays in an unavailable state.

## Shape — a custom CR, not a StatefulSet

The chart renders a custom composite resource. The reference plugin defines
`EC2Instance` (`crossplane.juno-innovations.com/v1alpha1`) with all configuration in
`spec.parameters`:

```yaml
apiVersion: crossplane.juno-innovations.com/v1alpha1
kind: EC2Instance
metadata:
  name: "{{ .Release.Namespace }}-{{ .Values.name }}-ec2"
  annotations:
    kuiper.juno-innovations.com/aws-remote-connection: "true"
    kuiper.juno-innovations.com/use-private-dns: "false"
    juno-innovations.com/workload: "Virtual Machine"
spec:
  parameters:
    name: "{{ .Release.Namespace }}-{{ .Values.name }}"
    region: {{ .Values.region }}
    amiImageId: {{ .Values.ami_image_id }}
    instanceType: {{ .Values.instance_type }}
    subnetId: {{ .Values.subnet_id }}
    providerConfigRef: {{ .Values.provider_config_ref }}
```

## Launch fields (templates/metadata.yaml)

EC2 fields, all user-supplied at launch: `ami_image_id`, `instance_type` (default `t3.micro`),
`region`, `subnet_id`, `security_group_ids` (list), `block_device_mappings` (list: mount path +
size GB), `delete_on_termination` (boolean, default `true`), `provider_config_ref` (default
`aws-provider-argocd-provider-config`).

## Surfacing the instance — Kuiper's EC2 flow

Kuiper watches the EC2 resource at launch and, once AWS DNS is available:

- builds an **ExternalName Service** from the `kuiper.juno-innovations.com/expose` annotation
  (comma-separated ports, e.g. `22,3389`) — service name is **deterministic**:
  `<name>-ec2-svc`
- computes and writes the `connection` annotation when `kuiper.juno-innovations.com/
  aws-remote-connection: "true"` is set (`use-private-dns` toggles private vs public DNS)

Canonical annotation reference: `concepts/labels-annotations.md` (Crossplane/EC2 table). Annotated
full example: `docs/workload-guides.md` — the `ec2-workstation` guide (`expose`, `aws-remote-connection`,
`use-private-dns`, `adopt` in one chart).

### Adopting the ExternalName Service

The ExternalName Service is created **by Kuiper after launch** — outside the chart. Adopt it so
it is owned and cleaned up with the workload:

```yaml
kuiper.juno-innovations.com/adopt-{{ .Values.name }}-ec2-svc: "Service"
```

The suffix must be the exact deterministic service name. Kuiper patches its ownership label and
tracks it like any chart resource.

## Gotchas

- **No pod** → probes, `automountServiceAccountToken`, image values, resource requests don't apply
  (`concepts/best-practices.md` exception; review against this file instead).
- `adopt-<name>` **requires the deterministic name** — if Kuiper's naming changes, the adoption
  silently stops and the Service orphans on shutdown.
- **delete_on_termination** decides EBS volume lifetime — `false` survives the instance.
- `providerConfigRef` must exist in the cluster or the XR never reconciles; the default in the
  reference plugin assumes ArgocD installed the provider.
- Put the `juno-innovations.com/workload` annotation on the **CR itself** — Hubble categorizes the
  running instance from it.
- The workload annotation must match `metadata.yaml` (`Virtual Machine` in the reference).
- EC2 is region/subnet-bound: the instance appears in AWS, not in the cluster — users connect via
  the ExternalName Service hostname/connection metadata, not a cluster route.

## Reference implementation

`plugins/crossplane-ec2/` (the XR chart + metadata schema); infrastructure plugins
`plugins/crossplane/` + `plugins/crossplane-aws-provider/` (provider + CRDs, install-time).