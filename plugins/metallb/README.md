# MetalLB

![MetalLB](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/metallb/assets/logo.png)

**Category:** Networking
**Type:** Cluster Service
**Tags:** `cluster-level`, `networking`, `load-balancer`

---

## Overview

MetalLB is a bare-metal LoadBalancer implementation for Kubernetes. Clusters running outside a
cloud provider have no native `LoadBalancer` service implementation — MetalLB fills that gap,
assigning real external IPs from a pool you control and announcing them to the network either
via Layer 2 (ARP/NDP) or BGP.

For full details, see the [MetalLB documentation](https://metallb.io/).

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, any `Service`
of type `LoadBalancer` created anywhere in the cluster is automatically assigned an IP from the
configured address pool and advertised to the network — no per-project setup needed.

This plugin installs the upstream MetalLB Helm chart via an ArgoCD `Application`, then creates an
`IPAddressPool` plus a `L2Advertisement` or `BGPPeer`/`BGPAdvertisement` (depending on `mode`) from
the fields you provide at install time.

---

## Prerequisites

- A dedicated block of IPs on your cluster's network that no other device or DHCP server will hand out
- For `layer2` mode: the pool's IPs must be on the same L2 segment as the cluster nodes
- For `layer2` mode with `kube-proxy` in IPVS mode: `strictARP: true` must be set on the `kube-proxy`
  ConfigMap (a cluster-level prerequisite outside this plugin's control)
- For `bgp` mode: an upstream router configured to peer with the cluster nodes and accept routes for
  the configured ASNs
- **K3s clusters:** disable K3s's built-in `ServiceLB` (Klipper) before installing this plugin — both
  it and MetalLB try to satisfy `LoadBalancer` Services, and leaving both enabled causes them to fight
  over the same Services. Add `--disable servicelb` to the K3s server flags (or `disable: servicelb`
  in `/etc/rancher/k3s/config.yaml`) and restart the `k3s` service
- No prior MetalLB installation in the cluster

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"MetalLB"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `chart_version` | **string** · Required · Default: `0.14.9`<br>The MetalLB Helm chart version to install |
| `mode` | **select** (`layer2`, `bgp`) · Required · Default: `layer2`<br>Advertisement mode used to announce LoadBalancer IPs |
| `address_pool` | **string** · Required<br>One or more IP ranges or CIDRs, comma-separated (e.g. `192.168.1.240-192.168.1.250` or `10.0.0.0/24,10.0.1.0/28`) |
| `bgp_my_asn` | **int** · Optional · Default: `64512`<br>ASN MetalLB uses when peering. Only used when `mode` is `bgp` |
| `bgp_peer_asn` | **int** · Optional · Default: `64512`<br>ASN of the upstream BGP router peer. Only used when `mode` is `bgp` |
| `bgp_peer_address` | **string** · Optional<br>IP address of the upstream BGP router to peer with. Only used when `mode` is `bgp` |

---

## Notes

- **`bgp` mode is unverified on our hardware** — only `layer2` mode has been tested against our
  clusters so far. If you use `bgp`, validate peering and route advertisement against your own
  router before relying on it
- Switching `mode` after install replaces the advertisement resource (`L2Advertisement` or
  `BGPPeer`/`BGPAdvertisement`) but keeps the same `IPAddressPool`
- IPs already leased to running Services are not affected by changing `address_pool`, but new
  ranges only apply to newly created Services until existing ones are recreated
- See the [MetalLB configuration docs](https://metallb.io/configuration/) for advanced topics like
  multiple pools, BGP communities, and per-Service IP requests
- If you're pointing at your Orion deployment via a local `hosts` file entry rather than DNS, note
  that installing this plugin gives the ingress controller a new `LoadBalancer` IP from
  `address_pool` — update that `hosts` entry to match, or it will keep resolving to the old address
