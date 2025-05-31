# Getting Started

# Plugin Structure

Terra plugins follow a standard Helm chart structure with only 1 Terra-specific enhancement:

```shell
plugin-name/
├── scripts/              # Installation and utility scripts
├── templates/            # Helm template files
├── .helmignore           # Files to ignore during packaging
├── Chart.yaml            # Helm chart metadata
├── terra.yaml            # Terra-specific configuration
└── values.yaml           # Values to pass to your template
```

### The terra.yaml File

The terra.yaml file is the only Terra-specific addition required. This file defines inputs that the web 
UI uses to display storage options, connection settings, and configuration parameters.

```yaml linenums="1" title="Example terra.yaml structure"
--8<-- "plugins/deadline10/terra.yaml"
```

### Configuration

#### Plugin Metadata

| Key         | Type             | Description                                                                             |
|-------------|------------------|-----------------------------------------------------------------------------------------|
| resource_id | String           | (Deprecated)                                                                            |
| name        | String           | Release Name used to identify the install                                               |
| icon        | String           | http(s) link to the icon image                                                          |
| description | String           | Brief description of your plugin                                                        |
| category    | String           | The world your plugin is a part of                                                      |
| tags        | Array of Strings | Tags are used for searching and informing Terra what this Plugin is a part of           |
| fields      | Array of Fields  | The UI fields you would like to have injected into your values.yaml file during install |

#### Field Metadata

| Key         | Type             | Description                                                       |
|-------------|------------------|-------------------------------------------------------------------|
| name        | String           | Key in the values.yaml file this will be mapped to                |
| description | String           | Description that will be displayed to the user in the UI on Terra |
| required    | String           | 'true' or 'false' if this field is required                       |
| type        | String           | Options: string, shared-volume, exclusive-volume                  |

#### Field Types

- **string**: A simple text input field
- **shared-volume**: A shared volume input field, allowing multiple plugins to access the same storage
- **exclusive-volume**: An exclusive volume input field, ensuring only this plugin can access the storage

Shared and exclusive volume fields are passed to you from the Genesis Storage system in the following form.

```yaml linenums="1" title="Example plugin/values.yaml structure"
# shared volume schema
my_shared_volume:
  name:
  sub_path:
  container_path:

# exclusive volume schema
my_exclusive_volume:
  name:
```



### Plugin Development Workflow

Terra provides a streamlined development workflow using GitOps practices:

1. **Create Issue and Branch**: Start with a GitHub issue and create a corresponding development branch
2. **Use Makefile Templates**: Utilize provided templates to create plugin scaffolding
3. **Development Environment**: Launch Argo CD pointed to your development branch using make commands
4. **Iterative Development**:
    - Make changes to your plugin
    - Push changes to GitHub branch
    - Argo CD automatically picks up changes for real-time testing
5. **Production Testing**: See exactly how your plugin behaves in production environment
6. **Pull Request**: Submit changes and squash commits to clean up development history

### Development Commands and Workflow

TBD - Insert make command examples and development workflow specifics
TBD - Run through the execution of building an application


## Advanced Features

### Config Packager System

For plugins that need to run ad-hoc scripts without building custom containers:
- Compress icons, desktop files, and installation scripts
- Deploy using base64 encoding
- Avoid maintaining custom container images
- Keep tooling current and manageable

TBD - Insert config packager implementation details

### Bundle Plugins

Create plugin bundles that install multiple related applications together:

TBD - Insert bundle plugin examples and implementation

### Private Plugin Repositories

Companies can build and maintain their own application catalogs:

TBD - Insert private repository setup and configuration

## Testing and Quality Assurance

### Development Testing

TBD - Insert testing framework and procedures

### Production Validation

TBD - Insert production testing and validation processes

## Technical Resources

### Essential Documentation Links

- [Helm Chart Template Guide](https://helm.sh/docs/chart_template_guide/getting_started/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Development Tools

- **Kubernetes**: Core container orchestration platform
- **Argo CD**: GitOps continuous delivery tool
- **Helm**: Package manager for Kubernetes
- **Make**: Build automation for development workflow


