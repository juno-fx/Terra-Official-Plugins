# Proxmox VE (promox)

Workload template plugin that launches a full [Proxmox VE](https://www.proxmox.com/)
hypervisor node as a Juno workload, using [dockur/proxmox](https://github.com/dockur/proxmox).
KVM acceleration, LXC containers, and a pre-configured NAT bridge with DHCP work
out of the box.

## Requirements

- **KVM support on workstation nodes** — the container needs `/dev/kvm` (bare-metal
  nodes or instances with nested virtualization). Most cloud VMs do NOT support this;
  AWS requires `.metal` instances.
- The container runs **privileged** (upstream requirement for KVM + the NAT bridge).
- At least 2 GB RAM and ~32 GB storage per node (defaults: 2 CPU / 2Gi requests,
  32Gi data volume).

## Launch Fields

| Field | Default | Purpose |
|-------|---------|---------|
| registry / repo / tag | `docker.io/dockurr/proxmox:latest` | Image source |
| password | `proxmox` | Web UI `root` password — change it |
| gpu | `false` | Adds `runtimeClassName: nvidia` for GPU passthrough experiments |
| data_size | `32Gi` | `/var/lib/vz` — disk images, ISOs, backups |
| config_size | `1Gi` | `/var/lib/pve-cluster` — PVE configuration |
| persistence_storage_class | cluster default | StorageClass for both volumes |

## Access

- Web UI: exposed through the project ingress at `/polaris/<name>/` (Hubble-authenticated),
  backend HTTPS on port 8006. Login as `root` with the password field value.
- Connection metadata (`username=root,port=8006`) is surfaced in Hubble via the
  `kuiper.juno-innovations.com/connection` annotation.

## Notes

- Proxmox startup can take several minutes on first boot (startup probe allows 15).
- 120s termination grace period matches upstream's `stop_grace_period` so PVE can
  flush state cleanly on shutdown.
- The Proxmox web UI uses absolute asset paths; if the UI misbehaves under the
  `/polaris/<name>/` sub-path, access it via the service directly
  (`kubectl port-forward svc/<name>-promox 8006:8006`) while a path-rewrite
  proxy is evaluated.
