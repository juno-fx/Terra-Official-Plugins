# Domain Manager

![Domain Manager](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/domain-manager/assets/icon.svg?raw=true)

**Category:** Networking
**Type:** Dashboard
**Tags:** `cluster-level` · `dashboard` · `networking` · `dns`

---

## Overview

Custom domains fail for boring reasons: the record was never added, it points at an old address, or the certificate is still pending. Domain Manager is a page inside Genesis that answers all three at a glance.

It lists every hostname published from the cluster, whether it comes from an Ingress or a Gateway API HTTPRoute, and for each one shows the record that should exist, whether DNS currently resolves to this cluster, and the state of its certificate.

---

## How It Works

**Dashboard** - Installed once per cluster and embedded in Genesis as an iFrame, gated to admin users.

It reads Ingresses and HTTPRoutes across every namespace and takes the target address from what the ingress controller itself published, in `status.loadBalancer`, or from the parent Gateway's status. That means the record it shows is the address traffic actually arrives on, not a value someone typed into a config file.

For each hostname it resolves the name and compares the answer against that address:

| State | Meaning |
|-------|---------|
| **Pointing here** | The hostname resolves to this cluster and should work |
| **Points at ...** | The hostname resolves somewhere else. Usually an old record, or a proxy in front |
| **No record found** | The name does not resolve at all. The record has not been added yet |

The record column shows `A` when the ingress address is an IP, and `CNAME` when it is a hostname, which is what cloud load balancers publish.

---

## Prerequisites

- An ingress controller that reports a load balancer address on Ingress status, which is standard behaviour
- The Certificate Manager plugin, if you want the certificate column populated

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Domain Manager"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

The page then appears in Genesis at the configured prefix.

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `host` | **string** · Required<br>The DNS name of your Genesis host. Also used to mark which row is the platform host |
| `prefix` | **string** · Required · Default: `/domains`<br>Path the page is served on |
| `registry` | **string** · Required · Default: `docker.io`<br>Registry to pull the image from |
| `repo` | **string** · Required · Default: `python`<br>Image repository |
| `tag` | **string** · Required · Default: `3.13-alpine`<br>Image tag |
| `namespace` | **string** · Required · Default: `domain-manager`<br>Namespace the page runs in, created if absent |

---

## Permissions

The page reads, and only reads:

| Resource | Why |
|----------|-----|
| `ingresses` | The hostnames served and the address the controller publishes |
| `httproutes`, `gateways` | The same, on clusters running the Gateway API |
| `certificates` | Whether cert-manager has issued each certificate |

It has no write permission anywhere, holds no DNS provider credential, and changes nothing. Adding records is done in your DNS provider, or by the ExternalDNS plugin.

---

## Notes

- Hostnames appear once a route exists for them, so publish the workload first and then add the record. The page tells you which record to add
- A row showing an address but no DNS answer usually means the record was added to the wrong zone, or has not propagated yet
- Certificates issued through a DNS-01 challenge can show as pending for a few minutes while the TXT record propagates. That is normal, not a failure
- The page runs the reads on request, so reloading is the refresh
- One row per hostname, not per route. A hostname served by several routes shows the route count instead
