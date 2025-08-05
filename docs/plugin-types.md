# Plugin Types

While a Terra Plugin can be just about anything, we have organized some of the standard types you can expect to come across.
These standard plugin types can also be seen and integrated into our front-end Terra App Store accessible via Genesis.Please
see below for our different types, along with examples you can reference directly in our official plugins repository.

## Plugin & Application

Our most basic types are our Plugin and Application types. The only difference between these, is an application requires either a "shared-volume" or "exclusive-volume" to install too.
Where a plugin does not require any traditional storage space. You can learn more about our different plugin field types [here](plugin-fields.md).

#### Examples
- **Application**: Firefox
- **Plugin**: theme-enforcer-xfce

## Workstation & Workload

Our Workstation and Workload plugins are intended to be schemas, which can be integrate directly with our Kuiper container orchestration manager. These type of plugins should either have their category, or include a tag
that specifies they either a "workload" or "workstation". They should include a helm chart for the schema install. The schema will then be installed as a configMap. Once the schemas are installed, they can be used to create custom templates via Genesis in our Workstation/Workloads table. Once a template is created
users can launch their workstation or workload within a project deployment. While fundamentally Workstations and Workloads work in the same way, we do provide ways to organize and differentiate them both via the backend, and frontend.
Please see below for examples that can be referenced on what these type of plugins look like, and how they can be created/customized to fit your needs.

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
- **Dashboard**: argocd-ingress


## Bundles
Bundles are a way to install multiple plugins in one convenient and easy to setup bundle.
You can learn more about how to create a bundle  [here](repositories.md#bundles).

#### Examples
- **Bundle**: orion-essentials
