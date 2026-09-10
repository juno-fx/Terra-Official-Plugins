# Domain Route

![Domain Route](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/domain-route/assets/icon.svg?raw=true)

**Category:** Networking
**Type:** Plugin / Application
**Tags:** `networking` · `dns` · `tls` · `ingress`

---

## Overview

Workloads on Orion are published as a path on the platform host. Domain Route publishes one at a hostname you own instead, with a certificate and an optional DNS record, without changing the workload or its plugin.

It also solves the case the platform has no answer for today: an application a user started inside a Helios or Wetty session. Those templates publish a single port, the desktop or the terminal, so an app listening on port 8000 inside the session is unreachable. A Kubernetes Service is only a label selector, so this plugin creates its own Service against the same pod on whatever port the app uses, and routes a hostname to it.

---

## How It Works

**Plugin / Application** - Installed into a project namespace. One install publishes one hostname. Install it again under a different name for a second hostname.

Two kinds of target:

- **workload** matches the pods of a running workload by label and serves any port they listen on, published or not
- **service** points at a Service that already exists in the project

---

## Prerequisites

- A DNS record for the hostname pointing at the cluster ingress address, or the ExternalDNS plugin installed and `publish_dns` enabled so the record is created for you
- The Certificate Issuer plugin installed, if you want TLS
- The application bound to `0.0.0.0` inside the session, not `127.0.0.1`, or nothing outside the pod can reach it

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Domain Route"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `hostname` | **string** · Required<br>Hostname to serve on, for example `app.example.com` |
| `target_kind` | **select** · Required · Default: `workload`<br>`workload` selects pods by label, `service` points at an existing Service |
| `target_name` | **string** · Required<br>Workload instance name, or Service name |
| `target_port` | **int** · Required · Default: `8080`<br>Port to send traffic to. For a workload target this is the container port and does not need to be published. For a service target it is the port on that Service |
| `selector_label` | **select** · Optional · Default: `juno-innovations.com/workstation`<br>Label the target carries. Helios and the runtime templates use `juno-innovations.com/workstation`, most others use `kuiper.juno-innovations.com/kuiper-instance` |
| `path` | **string** · Required · Default: `/`<br>Path prefix served on the hostname |
| `backend_protocol` | **select** · Required · Default: `HTTP`<br>Protocol the target speaks. Helios serves HTTPS |
| `tls_issuer` | **string** · Optional<br>cert-manager ClusterIssuer name. Leave empty to serve without requesting a certificate |
| `publish_dns` | **boolean** · Required · Default: `false`<br>Annotate the route so ExternalDNS creates the record |
| `ingress_class` | **string** · Required · Default: `nginx`<br>Ingress class to publish through |
| `auth` | **select** · Required · Default: `none`<br>`none` leaves authentication to the application, `basic` puts HTTP basic auth in front |
| `basic_auth_secret` | **string** · Optional<br>htpasswd Secret in this project, used when `auth` is `basic` |
| `rate_limit` | **int** · Optional · Default: `0`<br>Requests per second from a single source address. `0` means no limit |
| `allow_cidrs` | **string** · Optional<br>Comma separated CIDR ranges allowed to reach this route |

---

## Serving an App From a Helios or Wetty Session

The common case: a user is working in a session and starts an application on port 8000. Publishing it does not require exposing the session.

1. Note the workload instance name as shown in Hubble
2. Install this plugin into the project with `target_kind: workload`, `target_name` set to that instance, and `target_port` set to the port the application listens on
3. Point the hostname at the cluster ingress address, or set `publish_dns` and let ExternalDNS create the record

The session keeps serving its desktop or terminal on its own authenticated route, on port 3000 for Helios and 3001 for Wetty. Only the port named here is published, and it carries whatever authentication you configure below rather than the platform session gate.

Two things to know per template:

- **Helios** has no NetworkPolicy, so any port works as soon as the application binds `0.0.0.0`
- **Wetty** admits inbound traffic on port 3001 only, and denies all outbound traffic, so its `published_ports` and `allow_egress` fields have to be set on the session before a route to it can work

---

## Finding the Target

For a workload target, `target_name` is the workload instance name as shown in Hubble, and `selector_label` is the label that workload's chart puts on its pods. If a route returns 503, the selector matched nothing:

```bash
kubectl get pods -n <project> --show-labels
```

Pick whichever of the two labels appears there and set `selector_label` to match.

---

## Authentication

A route on a custom domain cannot use the Hubble session gate. The platform session cookie is scoped to the Orion host and is never sent to another domain, so a subrequest against it would reject every caller. That leaves three honest options, and the plugin makes you choose one:

- the application authenticates its own users, which is the right answer for anything with a login of its own
- `auth: basic`, which is enough to keep a development app off the open internet
- `auth: none` with `allow_cidrs` set, when the caller has a known address range

Create the Secret for basic auth with htpasswd:

```bash
htpasswd -c auth <username>
kubectl create secret generic route-basic-auth --namespace <project> --from-file=auth
```

---

## Notes

- Workloads that carry a NetworkPolicy only admit traffic from the ingress controller namespace. Routes created here arrive from exactly that namespace, so they are permitted, while a proxy running inside the project would not be
- An application serving under a sub-path, which most platform workloads do, will not work at `/` on a custom domain. Either set `path` to the prefix the application expects, or use the workload template's own `hostname` field, which reconfigures the application to serve from the root
- The Service created for a workload target is named after the install, so several routes against the same workload on different ports do not collide
- Deleting the install removes the route and the Service, but not the certificate Secret. Remove that by hand if the hostname is gone for good
- Leave `publish_dns` off when the record already exists, otherwise ExternalDNS and whoever owns the zone are both managing the same name
