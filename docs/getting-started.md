# Getting Started

## Prerequisites

To get started with Terra plugins, you need to have the following prerequisites:

- **Helm**: Ensure you have Helm installed on your system. You can download it from the [Helm website](https://helm.sh/docs/intro/install/).
- **Docker**: Docker is used to run Kind. Install Docker from the [Docker website](https://docs.docker.com/get-docker/).
- **Kind**: Kind is used to create a local Kubernetes cluster. You can install it by following the instructions on the [Kind website](https://kind.sigs.k8s.io/docs/user/quick-start/).
- **Devbox**: Devbox is used to manage development environments. You can install it from the [Devbox website](https://www.jetify.com/docs/devbox/installing_devbox/).
- **Git**: Ensure you have Git installed to clone the repository. You can download it from the [Git website](https://git-scm.com/downloads).

## Repository Setup

To set up your Terra plugin repository, follow these steps:

1. **Clone the Terra Official Plugins Repository**: This repository contains the official plugins and serves as a template for your own plugins.

    <!-- termynal -->
    
    ```shell
    $ git clone https://github.com/juno-fx/Terra-Official-Plugins
    $ cd Terra-Official-Plugins
    $ git checkout 999-my-branch
    ```

2. **Activate Devbox**: Juno ships a full Devbox environment to help you get started quickly. Activate it by running:

    <!-- termynal -->
    
    ```shell
    $ devbox shell
    Starting a devbox shell...
    Requirement already satisfied: uv in ./.venv/lib/python3.12/site-packages (0.7.9)
    
    [notice] A new release of pip is available: 24.3.1 -> 25.1.1
    [notice] To update, run: pip install --upgrade pip
    Audited 4 packages in 1ms
    ```

3. **Create Our Plugin**: Juno provides a `Makefile` target that creates the scaffolding for a new plugin. You can use it to create a new plugin:

    <!-- termynal -->
    
    ```shell
    $ make new-plugin my-plugin
   >> Building New Plugin: my-plugin <<
   >> Setting up Plugin: my-plugin <<
   >> New Plugin Setup <<
   >> Added to git <<
   >> Plugin Location: .../Terra-Official-Plugins/plugins/my-plugin <<
   >> Ready to go <<
    ```



## Plugin Structure

Terra plugins follow a standard Helm chart structure with only 1 Terra-specific enhancement:

```shell
repo/
└── plugins/                       # Directory containing all plugins
    └── my-plugin/                 # A plugin directory
         ├── scripts/              # Installation and utility scripts
         ├── templates/            # Helm template files
         ├── .helmignore           # Files to ignore during packaging
         ├── Chart.yaml            # Helm chart metadata
         ├── terra.yaml            # Terra-specific configuration
         └── values.yaml           # Values to pass to your template
```


## Helm

The team behind Terra has chosen Helm as the backend for plugin development and deployment. Helm is a package manager
for Kubernetes that allows you to define, install, and manage Kubernetes applications using Helm Charts. Juno picked
this because it is a well-established and widely used tool in the Kubernetes ecosystem, providing a robust and
flexible way to manage Kubernetes applications as well as open the door to the vast ecosystem of Helm Charts that Terra
can leverage day one.

The Terra team also made the decision to not to "reinvent the wheel" and instead focus on building a simple and
intuitive interface for users to interact with Helm Charts. This means that if you know how to make a Helm Chart, you can
make a Terra plugin. This allows developers to leverage their existing knowledge of Helm and Kubernetes to create
plugins for Terra without needing to learn a new system or framework.

This does mean that you need to know how to make a Helm Chart in order to make a Terra plugin. We do not provide a
complete guide on how to make a Helm Chart, but we do provide some resources to help you get started. The
[Helm Chart Template Guide](https://helm.sh/docs/chart_template_guide/getting_started/) is a great place to start,
and the [Helm Best Practices](https://helm.sh/docs/chart_best_practices/) guide provides some additional tips and tricks
to help you create high-quality Helm Charts.

## ArgoCD Overview

Terra uses ArgoCD as its backend for plugin deployment and management, allowing for a streamlined GitOps workflow.
In order to fully understand the development process, we need to first understand ArgoCD.

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It allows you to manage your Kubernetes
applications using Git repositories as the source of truth. With ArgoCD, you can define your application state in
Git and have ArgoCD automatically sync your Kubernetes cluster to match that state.

Terra deploys its plugins on the backend as ArgoCD Application resources that are populated with the values from
the `terra.yaml` file in each plugin. This allows Terra to manage the high level lifecycle of the Plugin, while
ArgoCD handles the actual deployment, management and clean up of the Kubernetes resources.
