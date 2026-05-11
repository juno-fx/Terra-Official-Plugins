<br />
<p align="center">
    <img src="docs/assets/logos/terra/terra-color-W.png"/>
    <h3 align="center">Terra Official Plugins</h3>
    <p align="center">
        Opening Up the World of Kubernetes.
    </p>
</p>

---

This repository is the official plugin catalog for the **Juno platform**. Plugins are Helm charts that
[Terra](https://juno-fx.github.io/Orion-Documentation/) installs into Kubernetes clusters via ArgoCD.

Read the **[Full Documentation](https://juno-fx.github.io/Terra-Official-Plugins/)**.

---

## Plugin Types

Choose the right type before you start:

| Type | When to use                                                                              | Example |
|------|------------------------------------------------------------------------------------------|---------|
| **Namespaced** | Deploy a service into a project namespace                                                | `plugins/ollama/` |
| **Cluster-level** | Install cluster-wide operators or infrastructure — installed into the `argocd` namespace | `plugins/nvidia-gpu-operator/` |
| **Workload Template** | Provide a reusable workload schema for Genesis/Kuiper — requires the `cluster-level` tag | `plugins/helios/` |

**Not sure?** Ask yourself:
- Does it run inside a user's project? → **Namespaced**
- Does it install cluster-wide (CRDs, operators, storage)? → **Cluster-level**
- Do users launch individual workloads from it? → **Workload Template**

---

## Quick Start

```bash
# 1. Enter the dev environment
devbox shell

# 2. Create a new plugin (interactive — prompts for type)
make new-plugin

# 3. Edit your plugin files
#    See docs/ for what to change per plugin type

# 4. If your plugin has a scripts/ directory, package it
make package <plugin-name>

# 5. Test locally with a Kind cluster
make test <plugin-name>

# 6. Verify nothing is stale before pushing
make verify
```

---

## Key Commands

| Command | Description |
|---------|-------------|
| `make new-plugin` | Interactive scaffolding — creates correct boilerplate for your plugin type |
| `make package <name>` | **Required** after any `scripts/` change — bundles scripts into a ConfigMap |
| `make verify` | Checks all plugins have up-to-date packages — runs in CI on every push |
| `make check-size <name>` | Checks packaged size against the 1MiB Kubernetes ConfigMap limit |
| `make watch <name>` | Auto-repackages when `scripts/` changes — useful during development |
| `make test <name>` | Deploys plugin to a local Kind cluster with ArgoCD |
| `make lint` | Helm lint all plugins |
| `make down` | Destroys the local Kind cluster |

---

## The Packaging Rule

> **If you change anything in `scripts/` or `scripts/chart/`, you MUST run `make package <plugin-name>`.**

The `templates/packaged-scripts.yaml` file is generated — it contains `scripts/` base64-encoded into a
Kubernetes ConfigMap. If you skip repackaging, the old version deploys silently with no error.

`make verify` catches this and will fail CI if any plugin has stale packages.

---

## Repository Layout

```
plugins/                          # All plugins live here
├── ollama/                       # Namespaced plugin example
├── nvidia-gpu-operator/          # Cluster-level plugin example
└── helios/                       # Workload template example (cluster-level)

template/                         # Scaffolding boilerplate
├── namespaced/                   # Boilerplate for namespaced plugins
├── cluster/                      # Boilerplate for cluster-level plugins
└── workload/                     # Boilerplate for workload template plugins

docs/                             # MkDocs documentation site
hack/                             # Developer scripts
bundles/                          # Multi-plugin bundle definitions
```

---

## Contributing

See [CONTRIBUTING](docs/contributing.md) and the [full docs](https://juno-fx.github.io/Terra-Official-Plugins/).

For agentic/automated workflows, read [AGENTS.md](AGENTS.md) first.
