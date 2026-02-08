# Advanced

Terra provides several advanced features to enhance the plugin itself. These features allow developers to create more 
complex and powerful plugins that can be used in other ways.

## Metadata ConfigMap

Terra allows you to define a `ConfigMap` that contains metadata about your plugin. This `ConfigMap` can be used to store
additional information about your plugin that can be accessed by other plugins or applications via the Terra REST API. 

To use this feature, you can define the `metadata` field in your `plugins/<plugin name>/templates/metadata.yaml` file:

```yaml linenums="1" title="plugins/nuke/templates/metadata.yaml"
--8<-- "plugins/nuke/templates/metadata.yaml"
```

Terra will find the Release Name with postfix `-terra-metadata` and load the data from the `ConfigMap` into the plugin's 
metadata. This allows you to store additional information via the Terra REST API.

## Dashboards
Dashboards are special type of plugin that can be directly integrated into your Genesis front-end experience via an iFrame. 
Any Terra plugin whose category or tags include "dashboard". These plugins also allow for special permission handling.
Updating your plugins metadata.yaml the _permission_ field can be set to a specific titan group. Which will only allow users assigned
to that Titan group access to the plugin.

```yaml linenums="1" title="my-plugin/templates/metadata.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-terra-metadata
data:
  chart: "{{ .Chart.Name }}"
  ingress: "{{ .Values.prefix }}"
  permission: "admin"  # only allow admin users access to this iFrame app
```


#### Examples
- **Dashboard**: argocd-dashboard


## Bundles
Bundles are a way to install multiple plugins in one convenient and easy to setup bundle.
You can learn more about how to create a bundle  [here](repositories.md#bundles).

#### Examples
- **Bundle**: orion-essentials

## ArgoCD Sync Waves

In Kubernetes, the concept of "dependencies" is really not possible. ArgoCD allows you to define "sync waves" to control
the order in which resources are applied. This allows you to define dependencies between resources and ensure that they are
applied in the correct order. This is done by applying the `argocd.argoproj.io/sync-wave` annotation to the resources
you want to control the order of. For example:

Sync Wave 1

```yaml linenums="1" title="Setup Directories Job"
--8<-- "plugins/deadline10/templates/wave-1/setup-directories-job.yaml"
```

Sync Wave 2

```yaml linenums="1" title="Download Installer"
--8<-- "plugins/deadline10/templates/wave-2/downloader.yaml"
```

## Terra Packaging

In some cases, it is just easier to write a script that does the installation for you. Terra allows you to "package" a 
"scripts" directory that contains any kind of data you need to run your plugin. For example, you may want to run an 
installation script that downloads a binary or runs a series of commands to set up your plugin and then install an 
image as an icon. This can be down by creating a "scripts" directory in your plugins root directory. Terra will then
take that directory and all of its contents and tar it up and then base64 encode it. This base64 encoded string will be
added to a ConfigMap called `{{ .Release.Name }}-scripts-configmap` and `{{ .Release.Name }}-scripts-configmap-cleanup`.
You can then mount these ConfigMaps in your plugin's templates and use the scripts as needed. Here is an example:

Packaged Script ConfigMap

```yaml linenums="1" title="Packaged Scripts ConfigMap"
--8<-- "plugins/deadline10/templates/packaged-scripts.yaml"
```

Mounted Job

```yaml linenums="1" title="Install Job Example"
--8<-- "plugins/deadline10/templates/wave-2/downloader.yaml"
```

!!! danger "Scripts Directory Limitations"
    The scripts directory is not a full-fledged file system. It is a ConfigMap that is mounted as a volume in your plugin's
    templates. This means that you cannot use it to store large files or directories. It is meant for small scripts and
    configuration files that are needed to run your plugin.

!!! danger "Size Limitations"
    The scripts directory is limited to 1MB in size. This is a hard limit imposed by Kubernetes ConfigMaps. If you need to
    store larger files, you will need to use a different method, such as storing the files in a remote location and downloading
    them during the plugin's installation process.

!!! danger "Repackage Scripts"
    Every time you make a change to the scripts directory, you will need to run `make package <plugin name>` to update the
    ConfigMap. This will repackage the scripts directory and update the ConfigMap with the new base64 encoded string. You will
    then need to push the changes to the remote branch for ArgoCD to pick up the changes.

    !!! info "TDK"
        The TDK will automatically do this for you if you are running the development environment with `make deploy`.

### Security Considerations

The scripts directory is a powerful feature that allows you to run custom scripts during the plugin's installation process.
However, it is important to be aware of the security implications of using this feature. The scripts directory is encoded
and essentially obfuscated. When Terra loads your plugin, it will NOT use the pre-packaged scripts that are pre-encoded in the
ConfigMap in the git source code. It will instead repackage the scripts directory and encode it again. This means that
the scripts stored in plain text in the git repository will be guaranteed to be the ones run by Terra. This is done to ensure
that the scripts are always up-to-date and to prevent any potential security issues or malicious code from being executed
during the plugin's installation process.

This is not the case when running locally on your system. When you run `make test-plugin <plugin name>`, ArgoCD will use the 
pre-packaged scripts that are pre-encoded in the ConfigMap in the git source code. This is one of the drawbacks of the development 
workflow. Please exercise caution when using the scripts directory and ensure that you are not introducing any security vulnerabilities 
into your plugin. Always review the scripts you are adding to the directory and ensure they are safe to run in a production environment.
