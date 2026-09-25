# Custom Domains

Workloads are published as a path on the platform host, `/<namespace>/<app>/<name>/`. That is the right default: one hostname, one certificate, and every workload reachable behind the Hubble session gate.

It is the wrong shape for anything a third party has to reach. A client site, an API consumed by a front end hosted elsewhere, or a mobile backend all need a hostname of their own. This page describes the convention plugins use to support that, and the pieces that have to be in place around it.

---

## The Fields

A workload template that supports custom domains declares three fields, and nothing renders differently until the first one is set.

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `domain` | string | empty | Domain to publish under. The workload is served at `<name>.<domain>`. Empty keeps the platform path |
| `tls_issuer` | string | empty | cert-manager ClusterIssuer used for the certificate |
| `publish_dns` | boolean | `false` | Annotate the route so ExternalDNS creates the record |

The hostname is derived from the workload name rather than typed, so two workloads launched from one template do not land on the same address, and naming the workload at launch is how an address like `my-app.example.com` is chosen next to `my-app-dev.example.com`. Workload names are unique within a project, not across a cluster, so the same name in two projects on the same domain still collides.

With `domain` empty, the chart renders exactly what it rendered before the fields existed. That is the property to preserve when adding this to a plugin, and it is worth proving with a `helm template` diff rather than assuming it.

---

## What the Chart Does

When a domain is set, the chart's existing Ingress changes shape rather than a second one being added. There is one routing object per workload, and switching a workload into domain mode updates it in place.

**The Ingress moves to the domain.** The same object, in the same `ingress.yaml`, serves `<name>.<domain>` at `/`, gains a `tls` block and the cert-manager annotation when an issuer is named, and the ExternalDNS annotation when `publish_dns` is on. No ingress class is set, so the route follows the cluster default. With no domain it renders exactly as it always did:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name }}-ingress
  {{- if .Values.domain }}
  {{- if or .Values.tls_issuer .Values.publish_dns }}
  annotations:
    {{- if .Values.tls_issuer }}
    cert-manager.io/cluster-issuer: {{ .Values.tls_issuer }}
    {{- end }}
    {{- if .Values.publish_dns }}
    external-dns.alpha.kubernetes.io/enable: "true"
    {{- end }}
  {{- end }}
  {{- else }}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/auth-url: "..."
  {{- end }}
spec:
  {{- if and .Values.domain .Values.tls_issuer }}
  tls:
    - hosts:
        - {{ .Values.name }}.{{ .Values.domain }}
      secretName: {{ .Values.name }}-tls
  {{- end }}
  rules:
    - host: {{ if .Values.domain }}{{ .Values.name }}.{{ .Values.domain }}{{ else }}{{ .Values.host }}{{ end }}
      http:
        paths:
          - path: {{ if .Values.domain }}"/"{{ else }}"/{{ .Release.Namespace }}/<prefix>/{{ .Values.name }}/"{{ end }}
            ...
```

**The application is told it now lives at the root.** An application can only serve one base path at a time, so this is not optional. Whatever the chart uses to communicate the prefix has to switch to `/`: `PREFIX` for the runtime templates, `N8N_PATH` and `WEBHOOK_URL` for n8n. Any sidecar that rewrites the prefix has to serve the root instead.

**The platform path goes away.** Because the one Ingress now points at the domain, the old prefix is no longer routed, which is correct: once the application serves the root it could not answer on the prefix anyway. Hubble lists the domain endpoint instead. Do not reach for a controller-specific redirect annotation to keep the old path alive, since the catalog is moving off a hardcoded ingress class.

---

## Authentication

A custom domain cannot use the Hubble session gate. The platform session cookie is scoped to the Orion host and is never sent to another domain, so an `auth-url` subrequest on a custom domain rejects every caller, including legitimate ones.

There is no way around that inside the chart, so plugins make the exposure explicit instead:

| Plugin | Requirement | Why |
|--------|-------------|-----|
| n8n | none | n8n has its own user management, which is the gate on that domain |
| Runtime templates | `network_mode` must be `ingress-noauth` | The mode already states the application is served without the platform gate |
| Sessions (Helios, Wetty) | publish through Domain Route | The session itself keeps its gated route; only the application port gets a hostname, with the application's login, basic auth, or a CIDR allow list in front |

Where an application has no login of its own, put one in front of the route with the Domain Route plugin's `auth: basic`, or restrict the caller with a CIDR allow list.

---

## Serving an Application From a Session

A workload template's `domain` field publishes the workload itself. It does not cover the other common case: a user working in a Helios or Wetty session who starts an application on some port and wants it reachable, the way it would be on a VPS.

That case needs no change to the session's chart. A Service is only a label selector, so the Domain Route plugin creates its own Service against the session's pods on the application's port and routes a hostname to it. The session keeps serving its desktop or terminal on its existing authenticated route, and only the named port is published.

Two constraints decide whether this works for a given template:

- the application must bind `0.0.0.0` inside the session rather than `127.0.0.1`, or nothing outside the pod can reach it
- a NetworkPolicy on the workload must admit the port. Helios has none, so any port works. Jupyter admits any port from the proxy namespace. Wetty admits port 3001 only, so its `published_ports` field has to list the extra port. Its egress rule is not a problem, since NetworkPolicies only add allows and the workspace's own rules already permit egress

A template that restricts ports in a NetworkPolicy should expose a field for the extra ones, rather than requiring the policy to be edited by hand.

---

## The Supporting Plugins

| Plugin | Role |
|--------|------|
| **Certificate Manager** | Installs cert-manager. On its own it issues nothing |
| **Certificate Issuer** | Creates the ClusterIssuer named in `tls_issuer`. HTTP-01, or DNS-01 for wildcards |
| **ExternalDNS** | Creates DNS records for routes carrying the enable annotation |
| **Domain Route** | Publishes a hostname for a workload whose chart has no `domain` field, or for an application listening inside a Helios or Wetty session. See above |
| **Domain Manager** | A page in Genesis listing published hostnames, the record each needs, and whether it resolves |

A working setup needs Certificate Manager and Certificate Issuer. ExternalDNS is optional: without it, add the record by hand, which the Domain Manager page spells out for you.

---

## Wildcard or Per Host

Two ways to run this, and they are not exclusive.

**A wildcard** covers `*.example.com` with one DNS record and one certificate, which is exactly the shape the derived `<name>.<domain>` scheme produces. Every workload gets a hostname immediately, no DNS API call happens at launch, and no provider credential sits in the launch path. Wildcard certificates require a DNS-01 challenge, so the issuer needs provider credentials once, at cluster level. This is the better default.

**Per host** puts a workload on any domain, including one a client owns. It needs a record for each hostname, created by hand or by ExternalDNS, and a certificate per host, which HTTP-01 can issue. This is what makes handing a system over to a client possible.

---

## Adding This to a Plugin

1. Add `domain`, `tls_issuer` and `publish_dns` to `scripts/chart/values.yaml` and to `templates/metadata.yaml`
2. Extend the existing `ingress.yaml` with `if` blocks so the one Ingress serves `<name>.<domain>` when a domain is set, guarded on whatever makes the exposure explicit for that workload
3. Switch the base path the application is given, and the sidecar configuration if there is one
4. Keep one Ingress object per workload rather than adding a second file, so switching modes updates it in place
5. Diff `helm template` with default values against the previous revision. It must be identical
6. Run `make package <plugin>` and document the fields in the plugin README
