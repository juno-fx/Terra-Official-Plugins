# Slurm Terminal

![Slurm Terminal](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/slurm-terminal/scripts/assets/logo.png)

**Category:** Compute
**Type:** Workload Template
**Tags:** `slurm` `hpc` `terminal` `batch` `cluster-level` `workload`

---

## Overview

A browser terminal onto a Slurm cluster deployed by the [Slinky](../slinky/README.md) plugin. Each user launches
their own session from Hubble, signs in as themselves, and gets an ordinary shell on the Slurm login node — where
`sbatch`, `srun`, `squeue`, `sinfo` and `sacct` all work normally.

Administrators install this plugin and configure the template in Genesis; end users launch it from Hubble.

---

## How It Works

**The terminal pod contains no Slurm software and no Slurm credentials.** It runs
[wetty](https://github.com/butlerx/wetty) in SSH mode and connects to the Slurm login node (a `LoginSet`, deployed by
the Slinky plugin) over SSH:

```
namespace: <user's project>              namespace: slurm

  browser ──▶ Ingress ──▶ [wetty pod] ──ssh──▶ [LoginSet pod]
              (Hubble auth)   thin client       sackd + sshd + sssd
                                                slurm.conf + slurm.key
                                                        │
                                                        ▼
                                                  [slurmctld] ──▶ [slurmd × N]
```

This matters because Slurm's CLI tools are not HTTP clients — `sbatch` and `srun` speak Slurm's own binary RPC
protocol, authenticate with a shared cluster key, and in `srun`'s case the client process itself becomes part of the
running job. A pod can only do that with the Slurm binaries, `slurm.conf`, and the auth key present locally.

Rather than replicate all three into every user's namespace, this template borrows the login node that already has
them. The consequences:

- **No `slurm.key` outside the `slurm` namespace.** That key is a cluster-wide credential — anyone holding it can
  impersonate any Slurm user. It never leaves the namespace it was created in.
- **Users authenticate as themselves.** SSSD on the login node decides who they are, so job ownership, fairshare and
  accounting all attribute correctly. Configure the directory with the Slinky plugin's `sssd_secret` field.
- **No version coupling.** The terminal image does not have to track the Slurm release, because it contains no Slurm.
- **Egress is locked down.** A NetworkPolicy permits exactly two things out of the pod: cluster DNS, and TCP to the
  login node. Nothing else.

### One template, many users

This is a single template that serves everyone. Kuiper renders it per launch with the launching user's identity
injected (`.Values.user` and `.Values.name`), so each session gets its own pod and defaults to SSHing out as the user
who launched it. Nothing about a specific user is baked into the template.

Unlike the Wetty and Helios templates, the uid/gid Kuiper passes go unused — nothing runs as the user *inside* this
pod, so there is no local account to create. The identity that matters is the one SSSD resolves on the login node.
`.Values.user` pre-fills the username rather than enforcing it: wetty exposes a `/ssh/<username>` route, so a user can
sign in as any account whose directory password they know, as they could over plain SSH.

---

## Prerequisites

- **Slinky plugin** installed
- **A directory for user identity** — an `sssd.conf` Secret named in the Slinky plugin's `sssd_secret` field, e.g.
  pointing at the Simple LDAP plugin. Without it the login node knows only local accounts and no one can sign in. See
  [the Slinky README](../slinky/README.md#required-the-directory-secret) for a paste-able example
- **Home directories** — set the Slinky plugin's `home_pvc`. Without one the terminal still opens, but the user lands
  in `/` with `cd ~` failing. See [Home directories](../slinky/README.md#home-directories)
- Network connectivity from the user's project namespace to the Slurm namespace on the login port (the bundled
  NetworkPolicy allows this; a stricter cluster-wide policy could still block it)

---

## Installation

Administrators install the plugin once:

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Slurm Terminal"**
3. Click **Install**

The template then appears in **Genesis** for configuration, and users launch sessions from **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

| Field | Details |
|-------|---------|
| `slurmNamespace` | **string** · Required · Default: `slurm`<br>Namespace the Slurm cluster runs in. Only change this if you run more than one Slurm cluster — the login node's name is fixed, so the namespace is the only thing that distinguishes them |
| `registry` | **string** · Required · Default: `wettyoss`<br>Registry for the terminal image |
| `repo` | **string** · Required · Default: `wetty`<br>Repository for the terminal image |
| `tag` | **string** · Required · Default: `2.5`<br>Tag for the terminal image |
| `nginx_registry` | **string** · Required · Default: `docker.io`<br>Registry for the nginx sidecar image |
| `nginx_repo` | **string** · Required · Default: `nginx`<br>Repository for the nginx sidecar image |
| `nginx_tag` | **string** · Required · Default: `1.29.3`<br>Tag for the nginx sidecar image |
| `ingressNamespace` | **string** · Required · Default: `ingress-nginx`<br>Namespace of the ingress controller, used by the NetworkPolicy |

### Custom Environment Variables

None. This pod is a thin SSH client — the shell a user actually works in runs on the Slurm login node, so anything
affecting the session belongs in that node's profile rather than in workload environment variables.

---

## Where It Connects

Always `slurm-login-slinky.<slurmNamespace>.svc.cluster.local:22`.

The Slinky plugin pins `fullnameOverride: slurm` on the Slurm chart, so the login node's name never inherits the
Terra release name. That is why there is no service-name field to fill in or get wrong — the only thing you would
change is `slurmNamespace`, and only if you run more than one Slurm cluster.

## Using the Session

Launch the workload from Hubble and open it. You are prompted for your directory password, then land on the login
node:

```sh
sinfo                      # partition and node state
srun hostname              # run an interactive job
sbatch --wrap="sleep 60"   # submit a batch job
squeue                     # queued and running jobs
sacct                      # accounting records (needs accounting enabled in Slinky)
```

Jobs run under your own Slurm identity, so `squeue --me` and fairshare behave as expected.

---

## Notes

- The session is not persistent — closing the browser drops the SSH connection and kills anything in the foreground,
  `srun` and `salloc` included. Submit long work with `sbatch` instead. The login image ships neither `tmux` nor
  `screen`, so the usual "run it in tmux" answer needs one added to that image first
- Home directories come from the Slinky plugin's `home_pvc`, mounted at `/home` on the login node and every compute
  node. Set it before anyone relies on file output from `sbatch`
- For scripted or automated submission, use `slurmrestd` — the Slinky plugin deploys it, and it is a genuine HTTP API
  needing only a JWT and `curl`, with no Slurm binaries and no terminal
- The ingress is always authenticated via Hubble. There is deliberately no option to disable it: this terminal is a
  gateway to the Slurm cluster, so exposing it unauthenticated is never the right choice
- The pod runs with no ServiceAccount token, `allowPrivilegeEscalation: false`, and all Linux capabilities dropped
  (nginx keeps only `CHOWN`/`SETUID`/`SETGID`, which its image needs to start)
