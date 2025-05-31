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

3. **Create Our Plugin**: Juno provides a `Makefile` that automates most of the Plugin workflow for you. Create a plugin by running:

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



