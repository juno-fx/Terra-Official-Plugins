# Getting Started

## Prerequisites

To get started with Terra plugins, you need to have the following prerequisites:

- **Helm**: Ensure you have Helm installed on your system. You can download it from the [Helm website](https://helm.sh/docs/intro/install/).
- **Kubectl**: Kubectl is used to talk to kubernetes clusters. You can install it from the [Kubectl website](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/).
- **Git**: Ensure you have Git installed to clone the repository. You can download it from the [Git website](https://git-scm.com/downloads).
- **Make**: Ensure you have Make installed to run the workflows. You can download it from the [Make website](https://www.gnu.org/software/make/).
- **Kind**: Ensure you have Kind installed to run the local cluster for testing. You can download it from the [Kind website](https://kind.sigs.k8s.io/docs/user/quick-start/).
- **Devbox**: Ensure you have Devbox installed to manage your development environment. You can download it from the [Devbox website](https://www.jetify.com/devbox).

## Repository Setup

To set up your Terra plugin repository, follow these steps:

1. **Clone the Terra Official Plugins Repository**: This repository contains the official plugins and serves as a template for your own plugins.

    <!-- termynal -->
    
    ```shell
    $ git clone https://github.com/juno-fx/Terra-Official-Plugins
    $ cd Terra-Official-Plugins
    $ git checkout 999-my-branch
    ```

2. **Activate Devbox Environment**: Terra uses Devbox to manage the development environment. Activate the Devbox shell to ensure all dependencies are available.

    <!-- termynal -->
    
    ```shell
    $ devbox shell
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

4. **Launch Development Environment**: Use `make test-plugin <plugin name>` this will communicate with ArgoCD and create an Application deployment that points to your local system.

    <!-- termynal -->

    ```shell
    $ make test-plugin my-plugin
    >> Deploying my-plugin << 
    Plugin: my-plugin
    TDK Name: ginger
    Git Branch: 354-build-terra-plugin-development-kit
    Namespace (JUNO_PROJECT): tdk
    URL: git://ginger.tdk.svc.cluster.local:9418/Terra-Official-Plugins
    /config/workspace/Terra-Official-Plugins
    [60867] Ready to rumble
    Release "ginger" does not exist. Installing it now.
    NAME: ginger
    LAST DEPLOYED: Wed Sep 17 18:27:12 2025
    NAMESPACE: tdk
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None


    >> Starting Development Shell << 
    >> Press CTRL+D to exit << 
    $ 
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
