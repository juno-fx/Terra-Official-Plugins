# Simple LDAP

<img src="https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/simple-ldap/scripts/assets/logo.png" alt="Simple LDAP" width="80" />

**Category:** Identity & Security
**Type:** Cluster Service
**Tags:** `ldap` · `openldap` · `directory-service`
**Editable:** Yes

---

## Overview

Simple LDAP deploys a self-hosted OpenLDAP directory server alongside a phpLDAPadmin web management interface. It provides a straightforward LDAP directory service for storing user accounts, groups, and organizational data — suitable for integrating with Juno platform authentication or other internal services that require LDAP-based identity management. Both LDAP (TCP) and the phpLDAPadmin web UI are exposed via NodePort for external access.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, the LDAP server and phpLDAPadmin web interface are accessible via the configured NodePorts to any system or user on your network.

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

| Field | Details |
|-------|---------|
| `domain` | **string** · Required · Default: `example.org`<br>LDAP domain name (e.g. `yourcompany.com`). Automatically converted to a base DN. |
| `adminPassword` | **string** · Required<br>LDAP admin password |
| `organization` | **string** · Required<br>Organization name displayed in the LDAP directory |
| `ldapPort` | **int** · Required · Default: `389`<br>Internal LDAP ClusterIP port (standard is 389) |
| `ldapNodePort` | **int** · Required<br>External NodePort for LDAP access (must be in range `30000–32767`) |
| `adminNodePort` | **int** · Required<br>External NodePort for phpLDAPadmin web UI (must be in range `30000–32767`) |
| `openldapCpu` | **string** · Optional · Default: `500m`<br>CPU request for the OpenLDAP container |
| `openldapMemory` | **string** · Optional · Default: `256Mi`<br>Memory request for the OpenLDAP container |
| `openldapCpuLimit` | **string** · Optional<br>CPU limit for the OpenLDAP container (no limit if empty) |
| `openldapMemoryLimit` | **string** · Optional<br>Memory limit for the OpenLDAP container (no limit if empty) |
| `adminCpu` | **string** · Optional · Default: `200m`<br>CPU request for the phpLDAPadmin container |
| `adminMemory` | **string** · Optional · Default: `128Mi`<br>Memory request for the phpLDAPadmin container |
| `adminCpuLimit` | **string** · Optional<br>CPU limit for the phpLDAPadmin container (no limit if empty) |
| `adminMemoryLimit` | **string** · Optional<br>Memory limit for the phpLDAPadmin container (no limit if empty) |
| `openldapRepo` | **string** · Optional · Default: `docker.io`<br>Registry for the OpenLDAP image |
| `openldapImage` | **string** · Optional · Default: `osixia/openldap`<br>OpenLDAP image name |
| `openldapTag` | **string** · Optional · Default: `latest`<br>OpenLDAP image tag |
| `adminRepo` | **string** · Optional · Default: `docker.io`<br>Registry for the phpLDAPadmin image |
| `adminImage` | **string** · Optional · Default: `osixia/phpldapadmin`<br>phpLDAPadmin image name |
| `adminTag` | **string** · Optional · Default: `latest`<br>phpLDAPadmin image tag |
| `storageSize` | **string** · Optional · Default: `1Gi`<br>Persistent volume size for LDAP directory data |
| `storageClass` | **string** · Optional<br>StorageClass for the LDAP data PVC (uses cluster default if empty) |

---

## Notes

- This plugin is **editable** — you can update resource limits, image tags, and storage settings after install via Terra
- The admin password is stored in plain text in the Terra UI — there is no masked input type available; restrict access to Terra accordingly
- The phpLDAPadmin web UI is accessible at `http://<any-node-ip>:<adminNodePort>` after deployment
- LDAP connections are available at `ldap://<any-node-ip>:<ldapNodePort>` — consider using a Tailscale or Twingate VPN plugin to restrict access to trusted networks
