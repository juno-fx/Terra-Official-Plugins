# Configuration

## terra.yaml

The terra.yaml file is the only Terra-specific addition required. This file defines inputs that the web 
UI uses to display storage options, connection settings, and configuration parameters.

```yaml linenums="1" title="Example terra.yaml structure"
--8<-- "plugins/deadline10/terra.yaml"
```

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


## Field Types

- **string**: A simple text input field
- **shared-volume**: A shared volume input field, allowing multiple plugins to access the same storage
- **exclusive-volume**: An exclusive volume input field, ensuring only this plugin can access the storage

### String

Pretend you have a simple Plugin that just needs to receive a string value from the user. Let's say you need to know the 
uid of the user that should own the application on disk.

1. Define the field in your `terra.yaml`:

    ```yaml linenums="1" title="my-plugin/terra.yaml"
    fields:
      - name: user_uid
        description: "The UID of the user that should own the application on disk"
        required: true
        type: string
    ```

2. In your `values.yaml`, you can set a default value or leave it empty:

    ```yaml linenums="1" title="my-plugin/values.yaml"
    user_uid: ""
    ```
   
    !!! note "Default Value and IDE Autocompletion"
        This is actually not needed for Terra to function, but it is good practice to have a 
        default value or an empty string to avoid errors. It also allows many IDEs to auto 
        complete for the values in the templates directory.

3. In your chart's template, you can access this value using Helm's templating syntax:

    ```yaml linenums="1" title="my-plugin/templates/configmap.yaml"
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: my-config
    data:
      user_uid: {{ .Values.user_uid | quote }}
    ```

For most cases, the String type can satisfy your needs. Yaml in general will evaluate even integers are strings, so you 
can use it for any string value you need to pass to your templates.

!!! note "Boolean Values"
    We do plan on adding a boolean type in the future, but for now, you can use strings like "true" or "false"

### Shared Volume

Shared Volumes are flagged by Genesis to be mounted by all workstations launched in the target project. This means
Terra can be used to install software to shared volumes that can be run by multiple workstations. This is useful for
example when you want to install something like an AppImage that can be run by any workstation in the project. This
means you can keep the software installed only once and all workstations can continue to be small in size.

Storage volumes are managed upstream by the Genesis Storage system. This means you can request the user select
the shared volume via dropdown in the UI, and the volume will be passed to you as a value in the `values.yaml` 
file. While the user does only have to make a single selection, Terra will take all the information about the 
volume from Genesis and hand it to you. This means you will receive the following structure in your `values.yaml`:

```yaml linenums="1" title="Example my-plugin/values.yaml structure"
# shared volume schema
my_shared_volume:  # key that is defined in terra.yaml
  name: # name of the Persistent Volume Claim
  sub_path: # any kind of network prefix on a network share for example
  container_path: # configured container path that is mounted into the workstations
```

To use this setup, you can follow these steps:

1. Define the field in your `terra.yaml`:

    ```yaml linenums="1" title="my-plugin/terra.yaml"
    fields:
      - name: my_shared_volume
        description: "The shared volume to use for this plugin"
        required: true
        type: shared-volume
    ```
   
2. In your `values.yaml`, you can set a default value or leave it empty:

    ```yaml linenums="1" title="my-plugin/values.yaml"
    my_shared_volume:
      name: ""
      sub_path: ""
      container_path: ""
    ```
   
    !!! note "Default Value and IDE Autocompletion"
        This is actually not needed for Terra to function, but it is good practice to have a 
        default value or an empty string to avoid errors. It also allows many IDEs to auto 
        complete for the values in the templates directory.

3. In your chart's template, you can access this value using Helm's templating. For example by mounting a pod:

    ```yaml linenums="1" title="my-plugin/templates/pod.yaml"
    apiVersion: v1
    kind: Pod
    metadata:
      name: my-pod
    spec:
      containers:
        - name: my-container
          image: my-image
          volumeMounts:
            - name: shared-volume
              subPath: {{ .Values.my_shared_volume.sub_path | quote }}
              mountPath: {{ .Values.my_shared_volume.container_path | quote }}
      volumes:
        - name: shared-volume
          persistentVolumeClaim:
            claimName: {{ .Values.my_shared_volume.name | quote }}
    ```
   
### Exclusive Volume

Exclusive Volumes are flagged by Genesis to be mounted by only a single Pod. This is normally used for databases
or other applications that require exclusive access to the storage. This means Terra can be used to install
Kubernetes services such as PostgreSQL, MySQL, or MongoDB that require exclusive access to the storage. This extends
Terra to do far more than install single applications, but also to install entire services that normally would require
a full Helm chart to be written. This feature alone opens up the world of Kubernetes to Terra users, allowing them
to install complex services with ease.

Storage volumes are managed upstream by the Genesis Storage system. This means you can request the user select
the exclusive volume via dropdown in the UI, and the volume will be passed to you as a value in the `values.yaml`
file. While the user does only have to make a single selection, Terra will take all the information about the
volume from Genesis and hand it to you. This means you will receive the following structure in your `values.yaml`:

```yaml linenums="1" title="Example my-plugin/values.yaml structure"
# exclusive volume schema
my_exclusive_volume:  # key that is defined in terra.yaml
  name: # name of the Persistent Volume Claim
```

To use this setup, you can follow these steps:

1. Define the field in your `terra.yaml`:

    ```yaml linenums="1" title="my-plugin/terra.yaml"
    fields:
      - name: my_exclusive_volume
        description: "The exclusive volume to use for this plugin"
        required: true
        type: exclusive-volume
    ```
   
2. In your `values.yaml`, you can set a default value or leave it empty:

    ```yaml linenums="1" title="my-plugin/values.yaml"
    my_exclusive_volume:
      name: ""
    ```
   
    !!! note "Default Value and IDE Autocompletion"
        This is actually not needed for Terra to function, but it is good practice to have a 
        default value or an empty string to avoid errors. It also allows many IDEs to auto 
        complete for the values in the templates directory.

3. In your chart's template, you can access this value using Helm's templating. For example by mounting a pod:

    ```yaml linenums="1" title="my-plugin/templates/pod.yaml"
    apiVersion: v1
    kind: Pod
    metadata:
      name: my-pod
    spec:
      containers:
        - name: my-container
          image: my-image
          volumeMounts:
            - name: exclusive-volume
              mountPath: /data  # or any other path you need
      volumes:
        - name: exclusive-volume
          persistentVolumeClaim:
            claimName: {{ .Values.my_exclusive_volume.name | quote }}
    ```
