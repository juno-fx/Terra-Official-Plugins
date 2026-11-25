# Virtual Machines — KubeVirt VM Workloads

**When to use:** the workload is an OS-level **Virtual Machine** — Windows, a legacy OS, or
anything needing a full kernel boot that a container cannot provide. The workload is a KubeVirt
`VirtualMachine` (a VM, not a pod); the running VM is a `VirtualMachineInstance` (VMI).

**Prerequisite:** `plugins/kubevirt/` (cluster-level) must be installed in the deployment, and a
usable storage class must exist — VM disks are real PVC-backed DataVolumes.

## Shape — not a StatefulSet

VM workloads replace the container StatefulSet with three KubeVirt objects:

- `VirtualMachine` (`kubevirt.io/v1`) — `runStrategy: Always`
- `VirtualMachinePreference` (`instancetype.kubevirt.io/v1beta1`) — disk bus, interface model,
  firmware defaults (`prefered_disk_bus`, `efi`, `secure_boot`)
- `dataVolumeTemplates` — the VM's disks, declared inline

Ownership labels follow the container convention where it applies: the VM `template.metadata`
carries `kuiper.juno-innovations.com/vm-instance: "{{ .Values.name }}"` (the VMI label — Services
select it) plus `kuiper.juno-innovations.com/kuiper-instance`; DataVolume templates carry
`kuiper-instance` so they are tracked and cleaned up with the workload.

## Launch fields (templates/metadata.yaml)

| Field | Type | Notes |
|-------|------|-------|
| `storage_class` | `k8sStorageClass` picker | Required — DataVolumes use it; the cluster's classes are queried at launch |
| `mounts` | `list` | Repeatable; `volume` sub-field is a `dataVolume` — only DVs labeled `kuiper.juno-innovations.com/user-created-datavolume` are offered |
| `ports` | `list` | `name`, `type` (`ClusterIP`/`NodePort`/`LoadBalancer`), `vm_port` (inside VM), `service_port` (outside), `protocol` |
| `gpu` + `gpu_device_name` | `boolean` + `string` | Host **device passthrough** by `deviceName` — no `runtimeClassName: nvidia`; the GPU is a host device given to the VMI |
| `secure_boot`, `efi`, `tpm` | `boolean` ×3 | Windows 11 requires **all three**: UEFI firmware + Secure Boot + TPM 2.0 |
| `virtio_drivers` | `boolean` | Mounts the VirtIO drivers ISO (fetched over HTTP) for Windows installs |
| `prefered_disk_bus` | `select` | `virtio` (only option in the reference impl) |

Chart values that are **not** launch fields: `use_cloud_init` + `cloud_init` (cloud-init userData
string — the reference default password is `fedora`; document changing it), `bridge_network`.

## Wiring

- **Disks** — `dataVolumeTemplates` per mount, source `blank` / `http` (ISO URL) / `clone` (source
  PVC by name + namespace; must exist). Access mode `ReadWriteOnce`.
- **Network** — default pod network with `masquerade` interface; setting `bridge_network` bridges
  onto the host.
- **Ports** — one Service per `ports` entry, selector `kuiper.juno-innovations.com/vm-instance`
  (matches the virt-launcher pod), labeled `kuiper-instance` for ownership.
- **Resources** — VM `domain` requests/limits mirror `cpu`/`memory` values; `cpu.cores` +
  `memory.guest` size the guest.

## The console sidecar

Browser access to the VM screen is a **separate Deployment** (`junoinnovations/kubevirt-console:
unstable`), not part of the VMI:

- The console Deployment runs an **nginx auth sidecar** next to the console container. It
  follows the standard sidecar convention (`concepts/runtime.md`) with these differences:
  - **Port `8082`**: the console image already runs its own nginx on `8080` and
    noVNC/websockify on `8081`.
  - **Config at `/etc/nginx/conf.d/nginx.conf`**: mounted via `subPath` from the
    `{{ .Values.name }}-console-nginx` ConfigMap. The file is a bare `server {}` block, not a
    full `nginx.conf`.
  - **Locations**: `/{{ .Release.Namespace }}/kubevirt/{{ .Values.name }}/` (noVNC static files)
    and `…/websockify` (`Upgrade`/`Connection`, 12h read/send timeouts), both with
    `auth_request /auth` against Hubble, proxying to `127.0.0.1:8081`. **Nothing rewrites the
    ingress path**, so these locations must match it exactly.
- Headless Service (`clusterIP: None`, `sessionAffinity: ClientIP`) on `8082` → console
  Deployment (RBAC bound to the console's SA).
- Plain Ingress at `/{{ .Release.Namespace }}/kubevirt/{{ .Values.name }}` → Service port `8082`,
  with no controller annotations. `kuiper.juno-innovations.com/ingress-extras` points at
  `vnc.html?...autoconnect=true&resize=scale` so Hubble lists the console URL.
- NetworkPolicy selects the **console pod only** (`app: {{ .Values.name }}-console`) and admits
  `8082`. Do not select on `kuiper-instance`: the virt-launcher pod carries it too, and a policy
  on it would block the VM's `ports` Services.

## Gotchas

- **No pod** → the pod-centric best-practices bars (probes, `automountServiceAccountToken: false`,
  image values, resource requests, PUID/PGID) do **not** apply — review against
  `concepts/best-practices.md` exceptions and this file instead.
- **Ephemeral by default** — DataVolumes die with the VM; persistence means cloning from an
  existing DataVolume/PVC, not a blank disk.
- Storage class must exist and be offered — `storage_class` is required for a reason.
- `juno-innovations.com/workload: "Virtual Machine"` must appear on `templates/metadata.yaml`
  **and** on the VM resource. (Known quirk: `plugins/vm-ephemeral/` predates this and is missing
  the annotation on its `metadata.yaml`; new VMs must not copy that.)
- Cloud-init default credentials are a foot-gun — force or document a user password.
- Do not run the kube-console without the RBAC + nginx sidecar pieces. The console pod needs its
  ServiceAccount to find the VMI, and without the sidecar the console has no Hubble auth.

## Reference implementation

`plugins/vm-ephemeral/` — full VM chart (vm, preference, dataVolumeTemplates, console deployment
with nginx sidecar, `files/nginx/nginx.conf` + `nginx.yaml`, ingress, network policy, ports
services).