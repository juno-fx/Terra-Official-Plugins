# Simple LDAP

![Simple LDAP](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/simple-ldap/scripts/assets/logo.png)

**Category:** Identity & Security
**Type:** Cluster-Level Plugin
**Tags:** `ldap` · `openldap` · `directory-service`
**Editable:** Yes

---

## Overview

Simple LDAP deploys a self-hosted OpenLDAP directory server alongside a phpLDAPadmin web management interface. It provides a straightforward LDAP directory service for storing user accounts, groups, and organizational data — suitable for integrating with Juno platform authentication or other internal services that require LDAP-based identity management. Both LDAP (TCP) and the phpLDAPadmin web UI are exposed via NodePort for external access.

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. The LDAP server and web UI are cluster-wide services accessible from any namespace.

---

## Prerequisites

- Available NodePort values in the range `30000–32767` (two ports required: one for LDAP and one for phpLDAPadmin)
- All cluster nodes must be accessible on the configured NodePort values for external LDAP and admin UI access

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Simple LDAP"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `domain` | string | **Yes** | `example.org` | LDAP domain name (e.g. `yourcompany.com`). Automatically converted to a base DN. |
| `adminPassword` | string | **Yes** | — | LDAP admin password |
| `organization` | string | **Yes** | — | Organization name displayed in the LDAP directory |
| `ldapPort` | int | **Yes** | `389` | Internal LDAP ClusterIP port (standard is 389) |
| `ldapNodePort` | int | **Yes** | — | External NodePort for LDAP access (must be in range `30000–32767`) |
| `adminNodePort` | int | **Yes** | — | External NodePort for phpLDAPadmin web UI (must be in range `30000–32767`) |
| `openldapCpu` | string | No | `500m` | CPU request for the OpenLDAP container |
| `openldapMemory` | string | No | `256Mi` | Memory request for the OpenLDAP container |
| `openldapCpuLimit` | string | No | — | CPU limit for the OpenLDAP container (no limit if empty) |
| `openldapMemoryLimit` | string | No | — | Memory limit for the OpenLDAP container (no limit if empty) |
| `adminCpu` | string | No | `200m` | CPU request for the phpLDAPadmin container |
| `adminMemory` | string | No | `128Mi` | Memory request for the phpLDAPadmin container |
| `adminCpuLimit` | string | No | — | CPU limit for the phpLDAPadmin container (no limit if empty) |
| `adminMemoryLimit` | string | No | — | Memory limit for the phpLDAPadmin container (no limit if empty) |
| `openldapRepo` | string | No | `docker.io` | Registry for the OpenLDAP image |
| `openldapImage` | string | No | `osixia/openldap` | OpenLDAP image name |
| `openldapTag` | string | No | `latest` | OpenLDAP image tag |
| `adminRepo` | string | No | `docker.io` | Registry for the phpLDAPadmin image |
| `adminImage` | string | No | `osixia/phpldapadmin` | phpLDAPadmin image name |
| `adminTag` | string | No | `latest` | phpLDAPadmin image tag |
| `storageSize` | string | No | `1Gi` | Persistent volume size for LDAP directory data |
| `storageClass` | string | No | — | StorageClass for the LDAP data PVC (uses cluster default if empty) |

---

## Notes

- This plugin is **editable** — you can update resource limits, image tags, and storage settings after install via Terra
- The admin password is stored in plain text in the Terra UI — there is no masked input type available; restrict access to Terra accordingly
- The phpLDAPadmin web UI is accessible at `http://<any-node-ip>:<adminNodePort>` after deployment
- LDAP connections are available at `ldap://<any-node-ip>:<ldapNodePort>` — consider using a Tailscale or Twingate VPN plugin to restrict access to trusted networks
