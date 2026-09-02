# V Rising

![V Rising](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/v-rising/assets/logo.png)

**Category:** Gaming
**Type:** Workload Template
**Tags:** `v-rising` · `survival` · `multiplayer` · `vampire`
**Compatibility:** `genesis-deployment>=3.0.0-beta.1` · `orion-deployment>=3.0.0-beta.1`

---

## Overview

The V Rising plugin provides a workload template for running self-hosted [V Rising](https://playvrising.com/) dedicated servers within the Juno platform. Each workload gets its own persistent world storage, its own game and query ports, and an optional RCON admin console.

Stunlock Studios ships the dedicated server ([Steam app `1829350`](https://store.steampowered.com/app/1604030/V_Rising/)) as a **Windows binary only** — there is no native Linux build. The `trueosiris/vrising` image handles this by bundling SteamCMD, Wine and Xvfb: on first boot it pulls the Windows server files with `+@sSteamCmdForcePlatformType windows`, then runs them under Wine on a headless X server. Nothing about the Wine layer is exposed as a workload field — it is entirely internal to the image.

---

## How It Works

**Workload Template** — Installs the V Rising workload schema into Genesis. Once installed, the V Rising type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own server on demand within a project through **Hubble**.

Each launched workload creates:

- A **StatefulSet** running the server under Wine
- Two **PersistentVolumeClaims** — one for the SteamCMD server install (`/mnt/vrising/server`), one for world saves and settings (`/mnt/vrising/persistentdata`)
- A **Service** exposing the UDP game and query ports
- An optional **ClusterIP Service** for RCON when it is enabled

---

## Prerequisites

- Platform versions: `genesis-deployment >= 3.0.0-beta.1`, `orion-deployment >= 3.0.0-beta.1`
- A Kubernetes storage class available in the cluster for the server and world volumes
- **amd64 nodes only** — the server is a Windows x86-64 binary under Wine, so the chart pins `kubernetes.io/arch: amd64`. arm64 nodes cannot run it.
- Nodes with **AVX support** — the server binary requires it. On mixed clusters, use the node affinity fields below to keep the workload off nodes that lack it.
- Roughly **2 CPU cores and 8Gi of memory** per server in practice. Set `cpu` and `memory` accordingly at launch — the platform defaults of `1` / `1Gi` are not enough to run a world.

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"V Rising"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the V Rising schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision V Rising servers on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a V Rising server through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `trueosiris`<br>Container registry for the server image |
| `repo` | **string** · Required · Default: `vrising`<br>Server image repository (bundles SteamCMD, Wine and Xvfb) |
| `tag` | **string** · Required · Default: `latest`<br>Image tag |
| `server_name` | **string** · Required · Default: `Juno V Rising Server`<br>Name shown in the in-game server browser |
| `world_name` | **string** · Required · Default: `world1`<br>World save folder on the data volume — changing it starts a fresh world |
| `game_port` | **int** · Required · Default: `9876`<br>UDP game port clients connect to |
| `query_port` | **int** · Required · Default: `9877`<br>UDP Steam query port — must be `game_port + 1` |
| `service_type` | **select** · Required · Default: `NodePort`<br>`NodePort`, `LoadBalancer` or `ClusterIP`. NodePort auto-derives the external port pair from the instance name |
| `server_password` | **string** · Optional<br>Password players must enter to join. Blank leaves the server open |
| `rcon_enabled` | **boolean** · Required · Default: `false`<br>Enable the RCON admin console on TCP `25575` |
| `rcon_password` | **string** · Optional<br>RCON password — required when RCON is enabled |
| `storage_class` | **k8sStorageClass** · Required<br>Storage class for both volumes |
| `server_storage_size` | **string** · Required · Default: `20Gi`<br>Volume for the SteamCMD server install (~5Gi, grows with each patch) |
| `data_storage_size` | **string** · Required · Default: `10Gi`<br>Volume for world saves, settings and logs |
| `node_affinity_key` | **string** · Optional<br>Node label key. When set, the server only schedules onto nodes carrying this label |
| `node_affinity_value` | **string** · Optional<br>Value paired with the key above. Blank matches any node carrying the key |

### Node Affinity

Both node affinity fields are optional and leaving them blank changes nothing — the workload schedules anywhere.

Set `node_affinity_key` alone to require only that the label is present (`Exists`):

```
node_affinity_key: gaming.example.com/vrising
```

Set both to require an exact value (`In`):

```
node_affinity_key:   gaming.example.com/vrising
node_affinity_value: "true"
```

This is a hard requirement (`requiredDuringSchedulingIgnoredDuringExecution`) — the pod stays `Pending` if no node matches. Any node selectors Kuiper injects through the platform's standard `selector` value are ANDed onto the same term, so a template-level label and a platform-level one both apply.

Pinning to a known node is also how players get one stable address to type. The port pair is already stable — it is derived from the instance name — but `NodePort` answers on *every* node's IP, and with a local-path style StorageClass the pod is tied to whichever node it first landed on anyway.

### Reaching the Server

Players join with **Direct Connect** using the **game port** — the query port is what the client and browser use to *query* the server, not what you dial.

With `service_type: NodePort` (the default) the external port pair is **auto-derived from the instance name**, not chosen by you. The V Rising client queries at `entered-port + 1`, so the two nodePorts must be adjacent; Kubernetes would otherwise assign two random unrelated ports and the query would miss. The chart sums the decimal digit-runs of `sha256(release-name)` and folds the result into `30000..32766`, so `game = N` and `query = N + 1`.

This is a direct port of the approach in the `conan-exiles` plugin in [aldmbmtl/Terra-Games](https://github.com/aldmbmtl/Terra-Games).

The derivation is **deterministic and stable** across ArgoCD syncs and Kuiper re-renders — the same instance name always gets the same pair — and there is deliberately **no user override**. Find the pair with:

```
kubectl get svc <release>-game -n <namespace> -o jsonpath='{.spec.ports[*].nodePort}'
```

then join `<node-ip>:<game nodePort>`. The `kuiper.juno-innovations.com/connection` annotation Hubble reads reports the same pair.

**Collisions:** because the pair is derived rather than allocated, two instances can in principle land on the same ports and the second apply is rejected. Rename the instance to re-derive.

**Server browser visibility:** NodePort cannot help here. The server advertises `game_port`/`query_port` (9876/9877) to the Steam and EOS master servers, and those never match the nodePort mapping — so a browser-listed entry points at the wrong port. Direct Connect is unaffected. For working browser listing you need `LoadBalancer` (where the advertised ports are the real ones) or hostPort.

### Launch-Time Validation

The chart refuses to render, with an explanatory message, when:

- `query_port` is not `game_port + 1` — the server would run but never be listed
- `rcon_enabled` is true with an empty `rcon_password` — would expose the admin console
- `node_affinity_value` is set without `node_affinity_key` — the value alone does nothing
- `storage_class` is empty — would silently fall back to the cluster default StorageClass

Each of these otherwise fails silently at runtime, which is far harder to diagnose than a failed launch.

### Passwords and Visibility

`server_password` and `rcon_password` are optional. When either is set, the chart renders a `Secret` named `<release>-credentials` and the StatefulSet references it with `secretKeyRef` — the values do not appear in the pod spec. This follows the pattern in `plugins/vllm`.

Be clear on what that does and does not buy you: the Secret keeps the passwords out of `kubectl get statefulset -o yaml`, but Kubernetes Secrets are base64-encoded, not encrypted, and anyone who can read Secrets in the namespace can read them. The value also travels through Kuiper as an ordinary Helm value, because the workload field schema has no password or secret type. Treat this as keeping credentials out of casual view, not as secret management.

**Password and visibility are independent knobs.** A password gates *joining*; it does not hide the server. A passworded server still appears in the browser with a lock icon if `HOST_SETTINGS_ListOnSteam` / `HOST_SETTINGS_ListOnEOS` are true. To keep it out of the listing entirely, leave those false — the server is then reachable only by Direct Connect, whether or not it has a password.

### Custom Environment Variables

| Variable | Description |
|----------|-------------|
| `TZ` | Timezone the server clock and log timestamps use, e.g. `America/New_York`. Defaults to `Europe/Brussels`. |
| `BRANCH` | Steam branch to install, for pinning a legacy server build such as `legacy-1.0.x-pc`. Defaults to the current release. |
| `LOGDAYS` | How many days of server logs to keep on the data volume before rotating them out. Defaults to `30`. |
| `HOST_SETTINGS_Description` | Longer server description shown alongside the name in the server browser. |
| `HOST_SETTINGS_MaxConnectedUsers` | Maximum simultaneous players. Defaults to `40`. |
| `HOST_SETTINGS_ListOnMasterServer` | Set to `true` to advertise the server publicly in the in-game browser. |
| `HOST_SETTINGS_ListOnSteam` | Set to `true` to advertise the server through the Steam master server. Needed for the server to appear in the Steam-backed browser listing. |
| `HOST_SETTINGS_ListOnEOS` | Set to `true` to advertise the server through Epic Online Services so friends can find it. |
| `GAME_SETTINGS_GameModeType` | `PvP` or `PvE`. Defaults to `PvP`. |
| `GAME_SETTINGS_ClanSize` | Maximum members per clan. Defaults to `4`. |

Any `ServerHostSettings.json` or `ServerGameSettings.json` key can be reached with the same `HOST_SETTINGS_` / `GAME_SETTINGS_` prefix convention — nested keys join with an underscore, as in `HOST_SETTINGS_Rcon_Password`.

---

## Notes

- `SERVERNAME`, `WORLDNAME`, `GAMEPORT` and `QUERYPORT` are set by the chart from the fields above. Do not also set them as custom environment variables — the chart's values are emitted first and the duplicates would shadow them unpredictably.
- The first boot downloads several gigabytes of server files through SteamCMD and can take a while before the server accepts connections. Subsequent restarts reuse the server volume.
- Game traffic is **UDP**, so it does not go through the platform's nginx ingress. Reach the server through the NodePort or LoadBalancer address, not an HTTP endpoint.
- World data persists across restarts as long as the data volume is retained. The server volume can be deleted safely — it is re-downloaded.
- RCON is off by default. When enabled it is exposed only as a ClusterIP service, reachable from inside the cluster.
- A `NetworkPolicy` restricts RCON (TCP 25575) to pods in the same namespace. The UDP game and query ports stay open to all sources — players are arbitrary external clients. Egress is unrestricted because SteamCMD needs Valve's CDN and the server needs the master servers.
- `tag` defaults to `latest`, which with `imagePullPolicy: IfNotPresent` means a node keeps whatever `latest` it first pulled and two nodes can end up on different builds. For a server whose save format is version-sensitive, pin an explicit tag such as `2.1`.
- No `securityContext` is set, so the container runs as the image default and both PVCs are root-owned. Kuiper's injected `user`/`group`/`puid`/`guid` are unused. This is deliberate pending a live test — SteamCMD and Wine in this image expect to run as root, and forcing a UID is a plausible way to break first boot.
- No readiness or liveness probes. First boot downloads several GB through SteamCMD, so the Service endpoint goes live before the server is listening. Kubernetes cannot probe UDP directly, so a correct probe needs an `exec` against the image — also pending a live test.
- See the [trueosiris/vrising documentation](https://github.com/TrueOsiris/docker-vrising) for the full image reference, and [playvrising.com](https://playvrising.com/) for the game itself.
