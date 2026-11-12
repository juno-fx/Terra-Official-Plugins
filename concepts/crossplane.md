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
size GB), `delete_on_termination` (boolean, default `true`), `ports` (list of `port`, default
`22`), `provider_config_ref` (default
`aws-provider-argocd-provider-config`).

The chart joins `ports` into the `expose` annotation (`"22,3389"`), and omits the annotation when
the list is empty.

## Surfacing the instance — Kuiper's EC2 flow

Kuiper watches the EC2 resource at launch and, once AWS DNS is available:

- builds an **ExternalName Service** from the `kuiper.juno-innovations.com/expose` annotation
  (comma-separated `port` or `port:targetPort` entries, e.g. `22,3389`) — service name is
  **deterministic**:
  `<name>-ec2-svc`
- computes and writes the `connection` annotation when `kuiper.juno-innovations.com/
  aws-remote-connection: "true"` is set (`use-private-dns` toggles private vs public DNS)

### Private subnets — `aws-private-subnet`

An ExternalName Service is only a DNS alias, so it can't reach an instance with no public address.
Set `kuiper.juno-innovations.com/aws-private-subnet: "true"` (the `aws_private_subnet` launch field)
and Kuiper brokers the connection: a selector-less Service (TCP only, named after the instance)
plus an EndpointSlice pointing at the instance's private IP. The EndpointSlice is owned by the
Service, so it is garbage collected with it.

The optional `load_balancer` launch field picks how far that Service reaches:

| `load_balancer` | Service | `connection` server | Use when |
|-----------------|---------|---------------------|----------|
| unset (None) | `ClusterIP` | `<name>.<namespace>.svc` | Only in-cluster clients need the instance |
| `internet-facing` | `LoadBalancer`, public NLB | LB hostname, once assigned | Users connect over the internet |
| `internal` | `LoadBalancer`, internal NLB | LB hostname, once assigned | Users are on a VPN, Direct Connect or peered network |

Picking a value sets `kuiper.juno-innovations.com/aws-load-balancer: "true"`,
`aws-load-balancer-type: nlb`, and the field's value straight into `aws-load-balancer-scheme`.
`internal` also sets `aws-load-balancer-internal: "true"`. Kuiper copies every
`service.beta.kubernetes.io/*` annotation from the Instance onto the Service.

The NLB is created by the cluster's built-in AWS cloud provider (instance targets on NodePorts,
kube-proxy forwards to the EndpointSlice). That provider ignores `aws-load-balancer-scheme` and only
reads `aws-load-balancer-internal`; without it every NLB is internet-facing. The AWS Load Balancer
Controller reads `scheme` instead, so both are set and either one works.

- The field is optional, so Terra sends None when nothing is picked. The template gates on a plain
  `if .Values.load_balancer`, so don't add a sentinel option like "off".
- The cluster nodes must be able to route to the VPC (same VPC, peering, TGW or VPN), or the
  Service comes up but every connection fails.
- The NLB options need an AWS cloud provider in the cluster: built into EKS, or the AWS Load
  Balancer Controller elsewhere. Without one the Service stays `<pending>`.
- Subnets must be tagged for NLB discovery: `kubernetes.io/role/internal-elb: 1` for `internal`,
  `kubernetes.io/role/elb: 1` for `internet-facing` (eksctl tags these automatically).
- The NLB scheme is fixed at creation, and Kuiper only creates the Service once, so changing
  `load_balancer` needs a relaunch.

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