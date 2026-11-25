# Helios

![Helios](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/helios/assets/logo.png)

**Category:** Workstations
**Type:** Workload Template
**Tags:** `kasm` · `vdi` · `juno`
**Bundle:** Orion Essentials

---

## Overview

Helios is the flagship containerized workstation from Juno Innovations. It provides a full-featured Linux desktop environment delivered through the browser — no VPN or client software required. Helios workstations support GPU acceleration, plugin mounting, and the full Juno workstation ecosystem (including Helios plugins like auto-shutdown and RAM monitoring). Each Helios workload is an isolated, personal desktop environment that users can launch on demand from Genesis.

---

## How It Works

**Workload Template** — Installs the Helios workstation schema into Genesis. Once installed, the Helios type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own personal desktop on demand within a project through **Hubble**.

**Access and authentication** — Each workstation runs with an nginx sidecar in the same pod. The ingress routes `/<namespace>/helios/<workload-name>/` to the sidecar, which checks the user's Hubble login before forwarding the request to Helios. Because authentication happens inside the pod rather than through ingress-controller annotations, it works the same with any ingress controller (ingress-nginx, Traefik, etc.).

---

## Prerequisites

- GPU support requires the **NVIDIA GPU Operator** plugin to be installed if GPU workstations are needed
- Helios plugin add-ons (**Helios Auto Shutdown**, **Helios RAM Monitor**) are optional but recommended for production deployments

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Helios"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Helios schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision workstations on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a workstation through **Hubble**:

| Field | Details |
|-------|---------|
| `gpu` | **boolean** · Required<br>Enable GPU passthrough for the workstation |
| `registry` | **string** · Required · Default: `junoinnovations`<br>Container registry to pull the Helios image from |
| `repo` | **string** · Required · Default: `helios`<br>Helios image repository |
| `tag` | **string** · Required · Default: `unstable-rocky-9`<br>Helios image tag (OS flavour and version) |
| `enableAPI` | **boolean** · Required · Default: `false`<br>Enable system-to-system communication via the Helios API |
| `rheaRepo` | **string** · Required · Default: `rhea`<br>Repository for the Rhea sidecar image |
| `rheaTag` | **string** · Required · Default: `v1.2.3`<br>Rhea sidecar image tag |
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Registry to pull the nginx sidecar image from |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>Repository to pull the nginx sidecar image from |
| `nginx_tag` | **string** · Required · Default: `1.30.7-alpine`<br>Tag to pull the nginx sidecar image from |
| `publicAccess` | **boolean** · Required · Default: `false`<br>Disable authentication and allow unauthenticated access to the workstation |
| `dcvLoadBalancer` | **boolean** · Required · Default: `false`<br>Creates a LoadBalancer service exposing Nice DCV on port 8443/tcp (dcv-tcp) for native DCV clients (add QUIC with `dcvQuic`), and sets `REMOTE_PROTOCOL=dcv` on the workstation. Requires the `PASSWORD` environment variable, set at launch (Hubble → Advanced) or in the template's env; it is needed to sign in through the load balancer, and without it DCV does not listen on 8443 even though the load balancer is created. A password set in the template is shared by every workstation launched from it. DCV enforces its own login; the Helios web port stays behind the Hubble login. When `false`, the workstation is reached only through the ingress. Some providers (e.g. GKE, Azure) make the load balancer public by default, which puts the DCV login on the internet; use an internal load balancer annotation (see the examples below) or a VPN where possible |
| `dcvQuic` | **boolean** · Required · Default: `false`<br>Also exposes Nice DCV on port 8443/udp (dcv-udp) for QUIC (only used when `dcvLoadBalancer` is `true`). The Helios image always listens for QUIC; this opens the port on the load balancer and network policy. The load balancer must support TCP and UDP on the same port. On AWS this needs the AWS Load Balancer Controller installed and its annotations set (see [AWS](#aws) below); the built-in AWS cloud provider cannot create a mixed TCP/UDP load balancer and the service stays pending. Enable QUIC in the DCV client's connection settings to use it |
| `loadBalancerAnnotations` | **list** · Optional · Default: empty<br>Extra annotations added to the DCV LoadBalancer service (only used when `dcvLoadBalancer` is `true`). Each entry has a `key` and a `value`; any cloud provider's load balancer annotations work. Example for CoreWeave: key `service.beta.kubernetes.io/coreweave-load-balancer-type`, value `public` |

### LoadBalancer Annotation Examples

Common entries for `loadBalancerAnnotations`, by provider. Add one list entry per annotation; check your provider's documentation for the full set.

| Provider | Key | Value | Effect |
|----------|-----|-------|--------|
| CoreWeave | `service.beta.kubernetes.io/coreweave-load-balancer-type` | `public` | Gives the load balancer a public IP |
| AWS | See [AWS](#aws) below | | |
| GKE | `networking.gke.io/load-balancer-type` | `Internal` | VPC-only load balancer |
| Azure | `service.beta.kubernetes.io/azure-load-balancer-internal` | `true` | VNet-only load balancer |
| MetalLB | `metallb.io/address-pool` | name of an `IPAddressPool` | Allocates the IP from a specific pool (older MetalLB: `metallb.universe.tf/address-pool`) |

#### AWS

AWS load balancers come from either the cluster's built-in AWS cloud provider or the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/). TCP works with both. UDP (`dcvQuic`) works only with the AWS Load Balancer Controller, because the built-in provider cannot create a load balancer with TCP and UDP on the same port.

| Key | Built-in provider (TCP) | AWS Load Balancer Controller (TCP, or TCP + UDP) |
|-----|-------------------------|--------------------------------------------------|
| `service.beta.kubernetes.io/aws-load-balancer-type` | `nlb` | `external` |
| `service.beta.kubernetes.io/aws-load-balancer-scheme` | `internet-facing` or `internal` | `internet-facing` or `internal` |
| `service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled` | `true` (recommended) | `true` (recommended) |
| `service.beta.kubernetes.io/aws-load-balancer-nlb-target-type` | not used | `ip` or `instance` |
| `service.beta.kubernetes.io/aws-load-balancer-enable-tcp-udp-listener` | not used | `true` when `dcvQuic` is on |

- **type**: `nlb` provisions the NLB through the built-in provider. `external` hands the service to the AWS Load Balancer Controller instead.
- **scheme**: `internet-facing` for a public load balancer in public subnets, `internal` for a VPC-only one in private subnets.
- **cross-zone**: recommended whenever the load balancer spans more than one availability zone. The workstation pod runs in a single zone; without cross-zone, clients routed to another zone can fail to connect. It can be skipped when the load balancer uses subnets in only one zone. Cross-zone traffic is billed as inter-AZ data transfer.
- **target type**: `ip` sends traffic straight to the pod (EKS with the Amazon VPC CNI); `instance` goes through a NodePort on the nodes.
- **tcp-udp listener**: combines 8443 TCP and UDP into one TCP_UDP listener. Without it the controller creates a TCP-only listener and QUIC traffic is dropped at the load balancer.

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for a Helios workstation:

| Variable | Description                                                                                                        |
|----------|--------------------------------------------------------------------------------------------------------------------|
| `PASSWORD` | Password set for the users terminal session. Required to sign in through the DCV load balancer (`dcvLoadBalancer`); not needed for DCV in the browser through Hubble. Available to all users at launch (Hubble → Advanced). |
| `SUDO` | Grants the user sudo access on the container.                                                                      |
| `SELKIES_FRAMERATE` | Streaming framerate for the desktop session, as a range (e.g. `15-60`) or fixed value (e.g. `30`).                 |
| `DISABLE_VGL` | Disables the VirtualGL wrapper around the desktop session; apps needing it must be launched manually via `vglrun`. |
| `REMOTE_PROTOCOL` | if set to "dcv" Helios will run Nice DCV rather than Selkies.                                                      |

---

## Notes

- This plugin is included in the **Orion Essentials** bundle — you can install Helios, the Prometheus Stack, and the ArgoCD Dashboard together in one step from Terra
- Setting `publicAccess` to `true` removes authentication from the workstation endpoint — use only in trusted network environments
- Workstations are served at `/<namespace>/helios/<workload-name>/`
- The workload's network policy only accepts inbound traffic on the nginx sidecar port (8080); Helios' own port is not reachable from elsewhere in the cluster. It sets no egress rules, so outbound access is controlled entirely by your namespace/cluster
- The workstation's ingress uses the `nginx` IngressClass by default; Kuiper 4.8.0 and later replaces it with the launching namespace's IngressClass
- The `tag` field controls the OS and desktop flavour of the workstation; consult the Juno documentation for available image tags
- Helios workstations are scheduled on nodes labelled `juno-innovations.com/workstation: "true"` — ensure your cluster has workstation nodes configured
- Helios plugin add-ons (auto-shutdown, RAM monitoring) must be installed separately and will automatically attach to Helios workloads
