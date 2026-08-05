# Runtime JS

![Runtime JS](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/runtime-js/assets/icon.png?raw=true)

**Category:** Development
**Type:** Workload Template
**Tags:** `runtime` · `js`

---

## Overview

JavaScript (Node.js) runtime environment for running your own applications on the Juno platform. Point it at a git repository (or code already on disk), define a build command and a run command, and it will clone, install dependencies, and serve your Node.js application — no custom Docker image required.

These runtime plugins are intentionally generic — a fast starting point for the common case: a straightforward repo that builds with the standard tooling and starts a server listening on a port. Projects with heavier requirements (pnpm or modern Yarn, private git repositories, multi-service builds, or apps that can't serve under a path prefix) will need some customization: adjust the build/run commands, point the image fields at a custom image with the right toolchain baked in, or mount code through a volume. See the Notes section below for known limitations and workarounds.

---

## How It Works

**Workload Template** — Installs the Runtime JS workload schema into Genesis. Once installed, the Runtime JS type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision JavaScript (Node.js) applications on demand within a project through **Hubble**.

At launch, the workload starts from the official `node` image and runs a generated startup script that:

1. Clones `git_url` (if set) and checks out `git_ref` — a branch, tag, or commit SHA. If `git_url` is empty, `source_path` is used as the work root instead (for code already available on disk, e.g. via a volume mount).
2. Runs `build_command` (if set) in the work root.
3. Runs `run_command` to start your application.

The application must listen on `port` — startup and liveness probes are TCP checks against it.

> **Note:** `scripts/entrypoint.sh` in this plugin is a stub kept for packaging compatibility — it is never executed at workload launch. The actual startup logic lives in the commands ConfigMap (`scripts/chart/templates/commands-configmap.yaml`), and the workload definition lives in `scripts/chart/`.

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"runtime-js"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the Runtime JS schema is available in **Genesis**. From the Workloads page, author the template — users can then launch their applications on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user launches the application through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry for the runtime image |
| `repo` | **string** · Required · Default: `node`<br>Runtime image repository |
| `tag` | **string** · Required · Default: `24`<br>Runtime image tag (JavaScript (Node.js) version) |
| `git_url` | **string** · Optional<br>Git repository URL to clone (leave empty when using `source_path`) |
| `git_ref` | **string** · Optional · Default: `main`<br>Git reference to check out — branch, tag, or commit SHA |
| `source_path` | **string** · Optional<br>Path to existing code on disk (alternative to git clone) |
| `build_command` | **string** · Optional · Default: `npm install`<br>Build command run in the work root, e.g. `npm install`, `npm ci` |
| `run_command` | **string** · Required · Default: `node main.js`<br>Command that starts your application, e.g. `node main.js`, `npm start` |
| `port` | **int** · Required · Default: `8080`<br>Port your application listens on |
| `network_mode` | **select** · Required · Default: `ingress-auth`<br>How to expose the application (see below) |
| `gpu` | **boolean** · Required<br>Attach a GPU to the workload |

### Network Modes

| Mode | Behavior |
|------|----------|
| `ingress-auth` | Exposes the application through the nginx ingress at `/polaris/<workload-name>/`, authenticated via Hubble |
| `ingress-noauth` | Same ingress path, but **without authentication** — anyone who can reach the ingress can reach the app |
| `clusterip` | No ingress — the application is only reachable in-cluster via its ClusterIP Service |
| `nodeport` | Adds a NodePort Service in addition to the ClusterIP Service for direct node-level access |

---

## Notes

- When exposed via ingress, the application is served under `/polaris/<workload-name>/` (also passed to the container as the `PREFIX` environment variable) — your application must handle or be configured for this path prefix
- `run_command` must start a foreground process that listens on `port`; if nothing listens, the startup probe fails and the workload restarts
- Use `ingress-noauth` only for applications that implement their own authentication or run in trusted network environments
- Private repositories are not supported by the built-in clone step — use `source_path` with a volume mount for private code
- The default `node` image ships with `npm` and classic `yarn` — for repos using `pnpm` or modern Yarn (berry), prepend `corepack enable` to `build_command` (e.g. `corepack enable && pnpm install`)
