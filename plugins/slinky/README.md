# Slinky

![Slinky](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/slinky/assets/logo.png)

**Category:** Compute
**Type:** Cluster Service
**Tags:** `slurm` `hpc` `scheduler` `batch` `operator` `cluster-level`

---

## Overview

[Slinky](https://slurm.schedmd.com/slinky.html) is SchedMD's toolkit for running [Slurm](https://slurm.schedmd.com/) and
Kubernetes together. This plugin installs the **slurm-operator** half of Slinky: a Kubernetes operator that deploys and
manages a real Slurm cluster — `slurmctld`, `slurmd` compute nodes, login nodes, and `slurmrestd` — as pods on your
existing Kubernetes nodes.

The result is a fully functional Slurm cluster that users interact with exactly as they would on bare metal: `sbatch`,
`srun`, `squeue`, `sinfo`, `sacct`, MPI, job dependencies, fairshare, preemption and QoS all work normally. Kubernetes
supplies the hardware and the lifecycle management; Slurm supplies the batch scheduler.

---

## How It Works

**Slinky does not translate Slurm jobs into Kubernetes Jobs.** It is not a dashboard and it has no web UI. It runs
Slurm itself, containerized, under an operator.

The operator introduces Custom Resources that describe the pieces of a Slurm cluster, and reconciles them into pods:

| Custom Resource | What it becomes |
|-----------------|-----------------|
| `Controller` | The `slurmctld` control plane pod, with a PVC for state-save data |
| `NodeSet` | A set of homogeneous `slurmd` compute node pods (scaled like a StatefulSet, or one-per-node like a DaemonSet) |
| `LoginSet` | Login / submit node pods running `sshd` + `sackd` + SSSD — the front door for users |
| `RestApi` | A `slurmrestd` pod exposing the Slurm REST API |
| `Accounting` | A `slurmdbd` pod for job accounting (optional, needs a database) |

A job submitted with `sbatch` from a login pod is scheduled by `slurmctld` onto a `slurmd` pod and runs there. The
Kubernetes scheduler is not involved in placing that job — it only placed the `slurmd` pods themselves. The operator
watches in the other direction too: before it scales in or upgrades a `NodeSet`, it drains the corresponding Slurm
nodes so running jobs are not killed.

**Cluster Service** — Installed once per cluster by an administrator. The operator is a cluster singleton; the Slurm
cluster it manages lives in its own namespace and can be re-installed for additional clusters (see
[Multiple Slurm Clusters](#multiple-slurm-clusters)).

### What this plugin installs

Three ArgoCD Applications plus the accounting database, ordered by sync wave:

| Wave | Resource | Chart / Kind | Namespace |
|------|----------|--------------|-----------|
| 0 | `<release>-slinky-crds` | `slurm-operator-crds` | `slinky` |
| 1 | `<release>-slinky-operator` | `slurm-operator` | `slinky` |
| 1 | `mariadb` | `StatefulSet` + `Service` + `Secret` (only when `accounting_enabled`) | `cluster_namespace` |
| 2 | `<release>-slurm` | `slurm` | `cluster_namespace` (default `slurm`) |

The three charts come from SchedMD's OCI registry at `ghcr.io/slinkyproject/charts`. The wave ordering matters: the
CRDs must be established before the operator, and both before any Slurm custom resource; the database must be up
before `slurmdbd` tries to connect.

**The `<release>-` prefix stops at the `Application`.** The plugin pins `fullnameOverride: slurm`, so the objects
inside `cluster_namespace` have fixed names whatever the release is called — `slurm-controller-0`,
`slurm-login-slinky`, `slurm-worker-slinky`, `slurm-restapi`. That is why the `kubectl` examples below carry no
release prefix.

The plugin does **not** create `cluster_namespace` — you create it yourself before installing, since it must already
exist to hold the required `sssd_secret`. That also means uninstalling the plugin never deletes your directory
Secret, the accounting database, or the controller's state-save volume.

### What this plugin does *not* install

Slinky's other half, **slurm-bridge**, does the reverse of the operator: it registers Slurm as a Kubernetes scheduler
so that Kubernetes `Pods`, `Jobs` and `JobSets` are translated into Slurm jobs for scheduling, with `slurm-bridge`
binding the resulting pods to whichever nodes Slurm allocated. That is the piece people are usually thinking of when
they ask about "converting" between the two systems.

It is deliberately deferred rather than ruled out. `slurm-bridge` needs **Kubernetes v1.35 or newer**, an
already-running Slurm cluster, a manually created JWT secret, and specific
[DRA](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/) drivers for CPU and GPU.
It also allocates whole nodes exclusively per pod, and native `cpu` requests do not activate CPU DRA — pods must
explicitly request `deviceclass.resource.kubernetes.io/dra.cpu` instead, which changes how workloads must be written.

The version floor is met on current deployments, so adding it later is a matter of appetite for those constraints, not
of cluster capability. It builds on this plugin: install Slinky first, then `slurm-bridge` against the resulting
cluster.

---

## Prerequisites

### Required: the directory Secret

`sssd_secret` names a Secret holding an `sssd.conf` — the config the login node uses to resolve and authenticate your
users. It must exist **before you install**, in `cluster_namespace`, under the key `sssd.conf`.

You do not need to create a file. Fill in the five marked values and paste the whole block:

```sh
kubectl create namespace slurm

kubectl create secret generic slurm-sssd-conf -n slurm --from-file=sssd.conf=/dev/stdin <<'EOF'
[sssd]
services = nss,pam
domains = LDAP

[nss]
filter_groups = root,slurm
filter_users = root,slurm
default_shell = /bin/bash
fallback_homedir = /home/%u

[pam]

[domain/LDAP]
id_provider = ldap
auth_provider = ldap

# ---- CHANGE THESE ----
ldap_uri = ldaps://ldap.example.com:636
ldap_search_base = dc=example,dc=org
ldap_default_bind_dn = cn=admin,dc=example,dc=org
ldap_default_authtok = CHANGEME
# ----------------------

ldap_schema = rfc2307
ldap_user_name = uid

# Verify the directory's certificate.
ldap_tls_reqcert = demand

# For a private or self-signed CA, set ldap_ca_secret on the plugin and use:
#   ldap_tls_cacert = /etc/ssl/ldap-ca/ca.crt

# --- If your directory only speaks plain ldap:// on 389 ---
# Replace the two lines above with the three below. SSSD allows *lookups* over an
# unencrypted connection but refuses to send *passwords*, so without the third
# line `getent passwd <user>` succeeds while every login fails — and the error it
# logs is the misleading "No available servers for service 'LDAP' / SSSD is
# offline". Every user's password then crosses the network in cleartext, which is
# what the option name is warning you about.
#
#   ldap_id_use_start_tls = false
#   ldap_tls_reqcert = never
#   ldap_auth_disable_tls_never_use_in_production = true

cache_credentials = true
enumerate = true
EOF
```

Then set `sssd_secret` to `slurm-sssd-conf` at install time.

Nothing is written to disk — `/dev/stdin` streams the config straight into `kubectl`, and the contents are stored in
the Secret. There is no file to keep or clean up. Do note that the block lands in your shell history with the bind
password in it: prefix the command with a space (zsh skips those with `HIST_IGNORE_SPACE`), or run `set +o history`
first.

**Why a Secret rather than plugin fields?** SSSD requires the bind password inside `sssd.conf` itself — it cannot read
it from a Secret or environment variable. If the plugin collected the password as a field, it would be rendered into
the ArgoCD `Application` spec in plaintext, readable by anyone with ArgoCD access. Passing the assembled file as a
Secret keeps the credential out of every intermediate resource.

> The Secret lives in a namespace **you** create and own, not one this plugin creates. Uninstalling the plugin
> removes the Slurm resources inside it but leaves the namespace, this Secret, the accounting database and the
> controller's state-save volume in place — so a reinstall picks up where it left off.

### Securing a self-hosted or LAN directory

**A self-signed certificate is fully supported** — you do not need a publicly trusted CA. Set `ldap_ca_secret` and
SSSD will verify the certificate properly:

```sh
# ca.crt is the CA that signed your LDAP server's certificate.
# For a genuinely self-signed certificate, that is the server certificate itself.
kubectl create secret generic ldap-ca -n slurm --from-file=ca.crt=./ca.crt
```

Set `ldap_ca_secret` to `ldap-ca`, and use this in your `sssd.conf`:

```ini
ldap_uri = ldaps://directory.example.internal:636
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/ssl/ldap-ca/ca.crt
```

That is a fully verified TLS connection. There is no reason to weaken it for a private CA.

#### If the directory has no TLS at all

Then the only way SSSD will authenticate is with `ldap_auth_disable_tls_never_use_in_production = true`, which sends
every user's password across the network in cleartext. Nothing in this plugin can make that safe — the fix is on the
directory itself:

1. Enable TLS on the LDAP server (`ldaps://` on 636, or StartTLS on 389). A self-signed certificate is fine; see
   above.
2. Store password **hashes** (`{SSHA}`), never plaintext. If `userPassword` is readable as the password itself, then
   read access to the directory exposes every account regardless of transport security.

**Symptom cheat-sheet.** `getent passwd <user>` works but login fails → SSSD is refusing unencrypted auth (see above).
`getent` returns nothing → missing POSIX attributes (see below). `id: cannot find name for group ID N` after login →
harmless; add a matching `posixGroup` to the directory if you want the name resolved.

**Your directory entries need POSIX attributes** — `objectClass: posixAccount` with `uidNumber`, `gidNumber` and
ideally `homeDirectory`. Without them the bind succeeds but users do not resolve and SSH rejects the login. The
`default_shell` and `fallback_homedir` lines above cover directories that omit `loginShell`/`homeDirectory`. Check
with:

```sh
ldapsearch -x -LLL -H <ldap_uri> -D "<bind_dn>" -W \
  -b "<search_base>" "(objectClass=posixAccount)" uid uidNumber gidNumber
```

### Also required

- **Kubernetes v1.29 or newer** (Slinky v1.2 compatibility matrix)
- **A default StorageClass**, or a StorageClass named in `storage_class` — the controller persists `slurmctld`
  state-save data to a PVC, and the accounting database needs one too
- **One schedulable node per compute node** — `slurmd` pods have a required anti-affinity on `kubernetes.io/hostname`,
  so `worker_replicas` above your node count leaves the surplus pods `Pending`. On a single-node cluster, use `1`

### Conditional

- **NVIDIA GPU Operator plugin** if `worker_gpus` is greater than `0`
- **MetalLB plugin** (or another load balancer controller) *only* if you change `login_service_type` to
  `LoadBalancer` — the default `ClusterIP` needs nothing

Nothing else is required — in particular, **cert-manager is not needed**. The accounting database is deployed by this
plugin and the operator's webhook certificate is self-signed in-cluster, so there are no external dependencies.

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Slinky"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

Three fields are required: `chart_version`, `sssd_secret` (the directory config Secret, which must exist before you
install — see [Prerequisites](#prerequisites)), and `login_service_type` (only because Terra requires a value for
every `select`; the `ClusterIP` default is almost always right). Everything else has a working default.

Every install deploys a Slurm cluster and a login node. The login node is the submit host the Slurm Terminal workload
connects to; it is `ClusterIP` by default, so nothing is exposed outside the cluster.

| Field | Details |
|-------|---------|
| `chart_version` | **select** · Required · Default: `1.2.1`<br>Version applied to all three Slinky charts |
| `install_crds` | **boolean** · Optional · Default: `true`<br>Install the Slinky CRDs. Set `false` on any additional install so it does not contend with the first one over cluster-scoped CRDs |
| `install_operator` | **boolean** · Optional · Default: `true`<br>Install the operator and webhook into the `slinky` namespace. The operator is a cluster singleton |
| `cluster_namespace` | **string** · Required · Default: `slurm`<br>Namespace for the Slurm cluster. Use a distinct value per cluster — see [Multiple Slurm Clusters](#multiple-slurm-clusters) |
| `worker_replicas` | **int** · Optional · Default: `2`<br>Number of `slurmd` compute node pods. Supports scale-to-zero. Cannot exceed your schedulable node count — see [Also required](#also-required) |
| `worker_cpu` | **string** · Optional · Default: `2`<br>CPU request and limit per compute node. Becomes the node's CPU count in Slurm |
| `worker_memory` | **string** · Optional · Default: `4Gi`<br>Memory request and limit per compute node. Becomes the node's `RealMemory` in Slurm |
| `worker_gpus` | **int** · Optional · Default: `0`<br>NVIDIA GPUs per compute node. Above `0` this also sets `GresTypes=gpu`, `Gres=gpu:<n>` and `gres.conf` `AutoDetect=nvidia`. It stays an integer rather than a toggle because Slurm needs the per-node count to build `Gres` — see [GPU compute nodes](#gpu-compute-nodes) |
| `storage_class` | **string** · Optional · Default: *(empty)*<br>StorageClass for the `slurmctld` state-save PVC. Empty uses the cluster default |
| `login_service_type` | **select** · Required · Default: `ClusterIP`<br>How the login node's SSH port is exposed. `ClusterIP` suffices when users connect via the Slurm Terminal workload; use `LoadBalancer` or `NodePort` only for SSH from outside the cluster. Terra requires a value for every `select`, so keep the default unless you need external SSH |
| `login_ssh_public_key` | **string** · Optional · Default: *(empty)*<br>An SSH public key for root on the login node. Only usable for direct `ssh -i` from outside the cluster — the Slurm Terminal workload authenticates by password, so this grants no access through the browser terminal |
| `accounting_enabled` | **boolean** · Optional · Default: `false`<br>Deploy `slurmdbd` plus a bundled MariaDB — see [Accounting](#accounting) |
| `accounting_db_secret` | **string** · Optional · *(no default)*<br>Secret in `cluster_namespace` holding the accounting DB password under key `password`. **Required when accounting is enabled** — create it first. Passed by reference, so the password never appears in an ArgoCD `Application` spec |
| `ldap_ca_secret` | **string** · Optional · *(no default)*<br>Secret in `cluster_namespace` holding your LDAP CA under key `ca.crt`, mounted at `/etc/ssl/ldap-ca/ca.crt`. Use this for a private or self-signed certificate — with it, verification stays on (`reqcert = demand`) |
| `sssd_secret` | **string** · **Required** · *(no default)*<br>Name of a Secret in `cluster_namespace` holding `sssd.conf`. **Create it before installing** — see [Prerequisites](#prerequisites). Without it no one can log in |
| `home_pvc` | **string** · Optional · *(no default)*<br>Name of a **ReadWriteMany** PVC in `cluster_namespace`, mounted at `/home` on the login node and every compute node. Without it a batch job writes its output on whichever compute node ran it, where you cannot read it — see [Home directories](#home-directories) |

---

## Using the Cluster

### From the Slurm Terminal workload (how end users get in)

Install the companion **[Slurm Terminal](../slurm-terminal/README.md)** plugin. It adds a workload template that users
launch from Hubble: a browser terminal that SSHes into this cluster's login node and drops them at a shell where
`sbatch` and friends work.

That workload holds no Slurm credentials of its own — it borrows the login node deployed here, which already has
`slurm.conf` and the auth key. Users sign in as themselves against the directory configured in
[User Identity on the Login Node](#user-identity-on-the-login-node), so job ownership and fairshare attribute
correctly. This is why `login_service_type` defaults to `ClusterIP`: nothing outside the cluster needs to reach it.

### Over SSH from outside the cluster

Only if you set `login_service_type` to `LoadBalancer` (or `NodePort`) and provided `login_ssh_public_key`:

```sh
SLURM_LOGIN_IP="$(kubectl get svc -n slurm slurm-login-slinky -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
SLURM_LOGIN_PORT="$(kubectl get svc -n slurm slurm-login-slinky -o jsonpath='{.status.loadBalancer.ingress[0].ports[0].port}')"
ssh -p "${SLURM_LOGIN_PORT:-22}" "root@${SLURM_LOGIN_IP}"
```

### From the REST API

`slurmrestd` is deployed with the cluster and is a genuine HTTP API — the right choice for scripted submission, since
it needs only a JWT and `curl`, with no Slurm binaries anywhere.

### From the controller pod

No SSH or load balancer required — useful for a quick smoke test:

```sh
kubectl exec -n slurm slurm-controller-0 -- sinfo
kubectl exec -n slurm slurm-controller-0 -- srun hostname
```

### Standard Slurm commands

```sh
sinfo                      # partition and node state
srun hostname              # run an interactive job
sbatch --wrap="sleep 60"   # submit a batch job
squeue                     # queued and running jobs
sacct                      # accounting records (requires accounting_enabled)
```

All compute nodes land in a single partition named `all`, which is the default partition with no time limit.

### Scaling compute nodes

Edit `worker_replicas` in Terra, or scale the `NodeSet` directly. The operator drains Slurm nodes before terminating
their pods, so running jobs are not lost:

```sh
kubectl scale nodeset -n slurm slurm-worker-slinky --replicas=8
```

---

## GPU compute nodes

`worker_gpus` is GPUs *per compute node*, and it is a count rather than a toggle because Slurm's GRES model needs the
number: above `0` it sets `GresTypes=gpu`, `Gres=gpu:<n>` and `gres.conf` `AutoDetect=nvidia`. Get the count wrong and
Slurm over- or under-subscribes GPUs on every `--gres=gpu:N` job.

Placement follows from the count — each `slurmd` pod requests `nvidia.com/gpu: <n>`, and Kubernetes only schedules a
pod onto a node advertising that resource, so no `nodeSelector` is needed.

**Taints are the exception,** since an extended-resource request grants no toleration. If your GPU nodes are tainted
(`kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints`), the pods stay `Pending` regardless of
`worker_gpus`. Add what they need under `nodesets.slinky.podSpec` in `templates/wave-2/slurm.app.yaml` — it accepts any
`corev1.PodSpec` field, so the same block covers `nodeSelector` and `priorityClassName` for steering compute nodes at
a particular node pool:

```yaml
podSpec:
  runtimeClassName: nvidia
  tolerations:
    - key: "juno-innovations.com/workstation"
      operator: "Exists"
      effect: "NoSchedule"
```

---

## Multiple Slurm Clusters

The CRDs and the operator are cluster-wide singletons; a Slurm cluster is not. To run a second, independent Slurm
cluster, install this plugin again with:

- `install_crds` → `false`
- `install_operator` → `false`
- `cluster_namespace` → a namespace not already in use
- `sssd_secret` → a Secret you have created in *that* namespace

The single operator installed by the first release reconciles every Slurm cluster in the Kubernetes cluster.

---

## Accounting

Setting `accounting_enabled` to `true` deploys `slurmdbd`, which unlocks `sacct`, fairshare and QoS — **and a MariaDB
database alongside it**. No external database, and no additional plugin, is required.

A StorageClass on its own is not sufficient here: `slurmdbd` needs something speaking the MySQL wire protocol, not
just a volume. The bundled database is a single-replica `StatefulSet` whose PVC uses the same `storage_class` field as
the controller, fixed at 8Gi — compact enough that Slurm accounting records take years to fill it.

The names it uses are deliberately chosen to match the Slurm chart's default `accounting.storageConfig`, so the two
sides wire themselves together with no further configuration:

| Setting | Value |
|---------|-------|
| Host | `mariadb` (Service in `cluster_namespace`) |
| Port | `3306` |
| Database | `slurm_acct_db` |
| User | `slurm` |
| Password | Secret named by `accounting_db_secret`, key `password` |

Create the password Secret before enabling accounting:

```sh
kubectl create secret generic slurm-accounting-db -n slurm --from-literal=password='<choose one>'
```

Then set `accounting_enabled` and `accounting_db_secret`. The install fails fast with a clear message if the Secret
name is missing. Both MariaDB and `slurmdbd` read the password from that Secret by reference, so it never passes
through this chart or the ArgoCD `Application`.

> **Choose the password once.** It is applied when the database initialises. Changing the Secret later will not
> update the credential already stored inside MariaDB, and `slurmdbd` will then fail to connect.

The database is further constrained: it runs as a non-root user with all capabilities dropped, has CPU and memory
limits, no ServiceAccount token, and a NetworkPolicy that only permits connections from inside `cluster_namespace`.

The database is intended for Slurm's accounting records only — the root account is randomised and unused, and the
Service is reachable only from within the namespace.

---

## User Identity on the Login Node

By default the login node knows only local accounts, so `login_ssh_public_key` is the only way in. To let ordinary
users sign in, supply an `sssd.conf` as a **Secret** and name it in `sssd_secret`.

The plugin takes only the Secret's *name*. It never sees your directory credentials, so they never appear in an
ArgoCD `Application` spec — and because you author the file, you control the TLS settings rather than inheriting
defaults from this chart.

### Create the Secret

See [Prerequisites](#prerequisites) for a single paste-able command. The Secret must live in `cluster_namespace` under
the key `sssd.conf`, because the LoginSet's `sssdConfRef` is an ordinary Kubernetes Secret reference and those cannot
cross namespaces.

### Your entries need POSIX attributes

SSSD creates **Unix accounts** on the login node, so directory entries must carry `objectClass: posixAccount` with
`uidNumber`, `gidNumber`, `homeDirectory` and `loginShell`. A directory that only backs application login often has
just `uid` and `userPassword`, which is enough to authenticate but not enough to build a Unix user.

The failure mode is quiet: the bind succeeds, `id <user>` returns nothing, and SSH rejects the login. Check one
existing entry before wiring this up:

```sh
kubectl exec -n slurm deploy/slurm-login-slinky -- getent passwd <user>
```

### Home directories

SSSD resolves users; it does not create their home directories. Point `home_pvc` at the **ReadWriteMany** PVC backing
your existing home export and the directories are already there. It is mounted at `/home` on the login node *and* on
every compute node, which is also what makes a batch job's output readable afterwards.

Without `home_pvc`, `/home` is the login pod's ephemeral filesystem — lost on restart, invisible to jobs.

If a directory is missing, the user logs in fine but lands in `/` with `cd ~` failing and `sbatch` unable to write its
output file. That happens for users added after the export was provisioned, since nothing here runs `pam_mkhomedir`.
Create one by hand with:

```sh
kubectl exec -n slurm deploy/slurm-login-slinky -- sh -c \
  'install -d -m 700 -o <uidNumber> -g <gidNumber> /home/<user>'
```

### Compute nodes do not get SSSD by default

The Slurm chart only wires `sssd.conf` into `slurmd` pods when a NodeSet sets `ssh.enabled`. This matters less than it
sounds: the `slurmd` image ships `nss_slurm`, which serves the job's *own* user out of the Slurm job step, so `id`
inside a job resolves your name with no directory on the node at all. What you lose is lookups for anyone else — a
colleague's file shows a bare uid under `ls -l`.

Check with `srun stat /etc/sssd/sssd.conf`. If your users need cross-user resolution — or `ssh` into an allocated
node, `pam_slurm_adopt`, or an ssh-based MPI launcher — enable SSH on the NodeSet so it receives the same `sssd.conf`,
by adding this under `nodesets.slinky` in `templates/wave-2/slurm.app.yaml`:

```yaml
ssh:
  enabled: true
```

### Using the Simple LDAP plugin

The Simple LDAP plugin deploys OpenLDAP as Service `simple-ldap` in namespace `simple-ldap`, so the in-cluster URI is
`ldap://simple-ldap.simple-ldap.svc.cluster.local:389` and the base DN derives from its `domain` field
(`example.org` becomes `dc=example,dc=org`). Create users there as `posixAccount` entries via phpLDAPadmin.

Pointing both Juno and Slurm at the same directory means job ownership, fairshare and accounting attribute to the
right person. Note that this is a **separate authentication** — there is no SSO from Hubble, so users enter their
directory password at the SSH prompt, and Juno's group/role mapping does not translate into Unix groups or Slurm
associations (those are managed with `sacctmgr`).

---

## Notes

- Slinky v1.2 requires Kubernetes v1.29+ and ships Slurm 26.05 container images
- The operator chart mints its own 10-year self-signed webhook CA, and Helm regenerates that keypair on every render.
  The plugin pins the first one with `ignoreDifferences` plus the `RespectIgnoreDifferences=true` sync option — both
  are needed, since `ignoreDifferences` alone hides the drift without stopping the next sync from overwriting it. To
  use cert-manager instead, set `certManager.enabled: true` in `templates/wave-1/operator.app.yaml` and drop both
- `slurmctld` state-save is fixed at 4Gi and the accounting database at 8Gi — both are ample, and neither is exposed
  as a field to keep the install form focused
- The operator drains Slurm nodes before scale-in and rolling upgrades, so in-flight jobs survive `NodeSet` changes
- `slurmctld` HA is achieved by Kubernetes restarting the controller pod, which is typically faster than a backup
  controller taking over — no shared filesystem is required
- Slurm configuration changes are detected and applied without restarting the control plane; propagation is bounded by
  the kubelet's ConfigMap sync frequency (60s by default)
- Compute node pods carry Slurm node state (Idle, Allocated, Mixed, Drain, Down …) as pod conditions, so
  `kubectl get pods` reflects what `sinfo` reports
- Uninstalling the plugin leaves the Slinky CRDs in place, so a second Slurm cluster is never torn out from under a
  running job. This needs both `prune: false` *and* the absence of a `resources-finalizer` on that `Application` —
  deleting a CRD would garbage-collect every Slurm CR in the cluster. Remove them by hand if you are decommissioning
  Slinky entirely
- For deeper configuration (topology, Pyxis, prolog/epilog scripts, IMEX, SR-IOV, autoscaling), see the
  [Slinky documentation](https://slinky.schedmd.com/) and the
  [slurm-operator docs](https://github.com/SlinkyProject/slurm-operator/tree/main/docs)
