# Plugin Types

While a Terra Plugin can be just about anything, we have organized some of the standard types you can expect to come across.
These standard plugin types can also be seen and integrated into our front-end Terra App Store accessible via Genesis. Please
see below for our different types, along with examples you can reference directly in our official plugins repository.

## Plugin & Application

Our most basic types are our Plugin and Application types. The only difference between these, is an application requires either a "shared-volume" or "exclusive-volume" to install too.
Where a plugin does not require any traditional storage space. You can learn more about our different plugin field types [here](plugin-fields.md).

#### Examples
- **Application**: Firefox
- **Plugin**: theme-enforcer-xfce

## Workstation & Workload

Our Workstation and Workload plugins are intended to be schemas, which can be integrate directly with our Kuiper container orchestration manager. These type of plugins should either have their category, or include a tag
that specifies they either a "workload" or "workstation", this is how it will be categorized in the Terra app store. They should also include a helm chart for the schema install. The schema will then be installed as a configMap. Once the schemas are installed, they can be used to create custom templates via Genesis in our Workstation/Workloads table. Once a template is created
users can launch their workstation or workload within a project deployment. While fundamentally Workstations and Workloads work in the same way, we do provide ways to organize and differentiate them both via the backend, and frontend. For workloads you will want to be sure to include a `juno-innovations.com/workload` annotation in both the metadata.yaml and the charts workstation.yaml.
The metadata annotation is how the Genesis front end knows which table to include the workstation/workload in. The charts workstation.yaml annotation is how Kuiper knows whether or not it is a workstation or workload.
As a reminder, the way these are processed on the backend are no different, and these annotations are simply used for organizing the workstations and workloads in the ui.
Please see below for examples that can be referenced on what these type of plugins look like, and how they can be created/customized to fit your needs.

metadata.yaml annotations example
```yaml linenums="1" title="my-workload/templates/metadata.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{{ .Release.Name }}-terra-metadata"
  annotations:
    juno-innovations.com/workload: "Application"  # mark this as a workload and it's type for the frontend UI
```

workstation.yaml  annotations example
```yaml linenums="1" title="my-workload/scripts/chart/templates/workstation.yaml"
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: "{{ .Values.name }}"
  annotations:
    juno-innovations.com/shared: "none"    # comma separated list of users that can access this workload as read only.
    juno-innovations.com/workload: "Application"  # mark this as a workload and it's type for the frontend UI
    juno-innovations.com/kuiper-state: "{{ .Values._kuiper }}"
```

#### Examples
- **Workload**: ComfyUI
- **Workstation**: Helios


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
