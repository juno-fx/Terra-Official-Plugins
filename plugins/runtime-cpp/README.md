# Runtime C++

![Runtime C++](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/runtime-cpp/assets/icon.svg?raw=true)

**Category:** Development
**Type:** Workload Template
**Tags:** `runtime` · `cpp`

---

## Overview

C++ runtime environment for running your own applications on the Juno platform. Point it at a git repository (or code already on disk), define a build command and a run command, and it will clone, compile, and serve your C++ application — no custom Docker image required.

These runtime plugins are intentionally generic — a fast starting point for the common case: a straightforward repo that builds with the standard tooling and starts a server listening on a port. Projects with heavier requirements (CMake or other build systems, private git repositories, multi-service builds, or apps that can't serve under a path prefix) will need some customization: adjust the build/run commands, point the image fields at a custom image with the right toolchain baked in, or mount code through a volume. See the Notes section below for known limitations and workarounds.

---

## How It Works

**Workload Template** — Installs the Runtime C++ workload schema into Genesis. Once installed, the Runtime C++ type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision C++ applications on demand within a project through **Hubble**.

At launch, the workload starts from the official `gcc` image and runs a generated startup script that:

1. Clones `git_url` (if set) and checks out `git_ref` — a branch, tag, or commit SHA. If `git_url` is empty, `source_path` is used as the work root instead (for code already available on disk, e.g. via a volume mount).
2. Runs `build_command` (if set) in the work root.
3. Runs `run_command` to start your application.

The application must listen on `port` — startup and liveness probes are TCP checks against it.

> **Note:** `scripts/entrypoint.sh` in this plugin is a stub kept for packaging compatibility — it is never executed at workload launch. The actual startup logic lives in the commands ConfigMap (`scripts/chart/templates/commands-configmap.yaml`), and the workload definition lives in `scripts/chart/`.

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"runtime-cpp"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Runtime C++ schema is available in **Genesis**. From the Workloads page, author the template — users can then launch their applications on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user launches the application through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry for the runtime image |
| `repo` | **string** · Required · Default: `gcc`<br>Runtime image repository |
| `tag` | **string** · Required · Default: `16`<br>Runtime image tag (C++ version) |
| `git_url` | **string** · Optional<br>Git repository URL to clone (leave empty when using `source_path`) |
| `git_ref` | **string** · Optional · Default: `main`<br>Git reference to check out — branch, tag, or commit SHA |
| `source_path` | **string** · Optional<br>Path to existing code on disk (alternative to git clone) |
| `build_command` | **string** · Optional · Default: `g++ -o app main.cpp`<br>Build command run in the work root, e.g. `g++ -o app main.cpp` or `make` |
| `run_command` | **string** · Required · Default: `./app`<br>Command that starts your application, e.g. `./app` |
| `port` | **int** · Required · Default: `8080`<br>Port your application listens on |
| `network_mode` | **select** · Required · Default: `ingress-auth`<br>How to expose the application (see below) |
| `hostname` | **string** · Optional<br>Serve the application at its own domain, for example `shop.example.com`, instead of a path on the platform host. Requires `network_mode` `ingress-noauth` |
| `tls_issuer` | **string** · Optional<br>cert-manager ClusterIssuer used to obtain the certificate for that domain |
| `publish_dns` | **boolean** · Optional · Default: `false`<br>Annotate the route so the ExternalDNS plugin creates the DNS record |
| `gpu` | **boolean** · Required<br>Attach a GPU to the workload |

### Network Modes

| Mode | Behavior |
|------|----------|
| `ingress-auth` | Exposes the application through the nginx ingress at `/<namespace>/polaris/<workload-name>/`, authenticated via Hubble |
| `ingress-noauth` | Same ingress path, but **without authentication** — anyone who can reach the ingress can reach the app |
| `clusterip` | No ingress — the application is only reachable in-cluster via its ClusterIP Service |
| `nodeport` | Adds a NodePort Service in addition to the ClusterIP Service for direct node-level access |

### Example Application

A working example for every runtime lives in [`aldmbmtl/runtimes`](https://github.com/aldmbmtl/runtimes). Each language has its own
top-level directory in that repository, so the build and run commands must point at `cpp/`:

| Field | Value |
|-------|-------|
| `git_url` | `https://github.com/aldmbmtl/runtimes.git` |
| `build_command` | `g++ -o app cpp/main.cpp` |
| `run_command` | `./app` |

The example is a minimal socket HTTP server that reads `PREFIX` and listens on port `8080`, matching the default `port`.

`build_command` and `run_command` are evaluated independently, each starting from the repository root — a
`cd` in one does not carry over to the other.

---

## Serving on Your Own Domain

With `network_mode` set to `ingress-noauth`, setting `hostname` publishes the application at the root of that domain rather than under a path on the platform host. `PREFIX` becomes `/`, so an application that reads it serves its own links correctly, and the platform path redirects to the new address.

The `ingress-noauth` requirement is not arbitrary. The platform session cookie is scoped to the Orion host and is never sent to another domain, so the Hubble gate cannot protect a custom domain. Rather than publish an unprotected route from a mode that claims to be authenticated, a hostname set under `ingress-auth` changes nothing.

Add a DNS record pointing the hostname at the cluster ingress address, or set `publish_dns` and let the ExternalDNS plugin create it. The Domain Manager page shows the record to add and whether it currently resolves.

---

## Notes

- When exposed via ingress, the application is served under `/<namespace>/polaris/<workload-name>/`, where `<namespace>` is the environment the workload runs in. This full path is passed to the container as the `PREFIX` environment variable — your application must handle or be configured for this path prefix
- `run_command` must start a foreground process that listens on `port`; if nothing listens, the startup probe fails and the workload restarts
- Use `ingress-noauth` only for applications that implement their own authentication or run in trusted network environments
- Private repositories are not supported by the built-in clone step — use `source_path` with a volume mount for private code
- The default `gcc` image ships with `g++` and `make`, but **not** `cmake` — for CMake-based projects, prepend an install step to `build_command` (e.g. `apt-get update && apt-get install -y cmake && cmake -B build && cmake --build build`) or point `registry`/`repo`/`tag` at a custom image that includes CMake
