# Terra Repositories

Terra repositories are Git repositories that contain one or more plugins and bundles. They serve as a central location
for managing and distributing Terra plugins, allowing users to easily install, update, and manage their plugins through 
the Terra UI.

## Official Repositories

The official Terra repositories are maintained by the Juno team and contain a collection of plugins and bundles that are
known to work well together. These repositories are regularly updated with new plugins and bundles, providing users with
the latest features and improvements.

| Name                   | Maintainer       | Repo URL                                          |
|------------------------|------------------|---------------------------------------------------|
| Official Terra Plugins | Juno Innovations | https://github.com/juno-fx/Terra-Official-Plugins |

## Community Repositories

Community repositories are not maintained by the Juno team but are created and managed by the community. These
repositories can contain plugins and bundles that are not part of the official repositories, allowing users to share
their own plugins and contributions with the Terra community. Community repositories can be added to Terra in the same
way as official repositories, but users should exercise caution when installing from non-official sources to ensure the
plugins are safe and compatible with their environment.

## Repository Structure

### Plugins

Terra repositories are added as "Sources" to Terra via its UI. You can learn more about this in the UI 
[here](https://juno-fx.github.io/Orion-Documentation/terra/terra/). A Terra repository is a Git repository that contains 
one or more plugins. Plugins are loaded from the `plugins/` directory in the repository and every Plugin is required to 
have a valid `terra.yaml` file. Terra will automatically detect and load plugins from the repository, making them 
available for installation and management.

### Bundles

Bundles are a way to group multiple plugins together. They are defined in the `bundles/` directory of the repository.
Bundles are YAML files that specify a collection of plugins and their configurations as well as potentially pinned versions 
that are known to work together. This allows users to install multiple related plugins at once, simplifying the installation 
process for complex applications or pipelines.

### Folder Structure

This is the general skeleton of a Terra repository.

```shell
repository-name/
├── plugins/                 # Directory containing all plugins
│   └── <plugin name>/       # A plugin directory
│      ├── terra.yaml        # Terra-specific configuration
│      ├── templates/        # Helm template files
│      ├── .helmignore       # Files to ignore during packaging
│      ├── Chart.yaml        # Helm chart metadata
│      └── values.yaml       # Values to pass to your template
├── bundles/                 # Directory containing all plugins
│   └── <bundle name>.yaml   # Plugin bundle file
└── README.md                # Repository documentation
```


