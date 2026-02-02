# Feature Sets

## Introduction to Plugin Feature Sets

Kuiper uses Kubernetes annotations to control how resources are managed, displayed, and configured. 
All annotations use the prefix `kuiper.juno-innovations.com/`. You are expected to leverage these 
annotations within your Kuiper-managed workloads to customize behavior as needed. For example, to 
hide certain resources from the UI, specify connection details, or manage storage paths. You can 
also make use of these annotations to protect resources from deletion or to define what actions 
are activated. 

### Core Instance Management

#### `kuiper.juno-innovations.com/kuiper-instance`
- **Resource Types**: All resources
- **Value**: String (instance name)
- **Purpose**: Core identifier that links resources to a specific Kuiper instance/workload
- **Example**: `kuiper.juno-innovations.com/kuiper-instance: "my-workstation"`

**Usage**: This annotation is automatically added to all resources created by Kuiper and is essential for resource discovery, management, and deletion operations.

### User Interface & Display Control

#### `kuiper.juno-innovations.com/hidden`
- **Resource Types**: ConfigMaps, other resources
- **Value**: `"true"` or `"false"`
- **Purpose**: Marks resources as hidden from the UI and API responses
- **Example**: `kuiper.juno-innovations.com/hidden: "true"`

**Usage**: Used primarily for internal ConfigMaps that shouldn't be exposed to users in the frontend interface.

#### `kuiper.juno-innovations.com/connection`
- **Resource Types**: Services, Ingresses
- **Value**: Comma-separated key=value pairs
- **Purpose**: Provides connection details for services, displayed as extra information in the frontend
- **Example**: `kuiper.juno-innovations.com/connection: "username=admin,password=secret"`

**Usage**: Add to Service/Ingress resources when they require authentication or special connection parameters that users need to know.

### Ingress Configuration

#### `kuiper.juno-innovations.com/ingress-hide`
- **Resource Types**: Ingress
- **Value**: Comma-separated list of paths
- **Purpose**: Hides specific ingress endpoints from being displayed in the frontend
- **Example**: `kuiper.juno-innovations.com/ingress-hide: "/internal/api,/admin/panel"`

**Usage**: Useful for hiding backend endpoints, admin interfaces, or internal API routes that shouldn't be accessible to end users.

#### `kuiper.juno-innovations.com/ingress-extras`
- **Resource Types**: Ingress
- **Value**: Comma-separated list of extra paths
- **Purpose**: Adds extra paths to existing ingress endpoints, mapped to the closest existing path
- **Example**: `kuiper.juno-innovations.com/ingress-extras: "/docs/index.html?version=1,/help/faq.html"`

**Usage**: Perfect for directing users to specific documentation files, help pages, or query-string enhanced versions of existing routes.

### Storage & Volume Management

#### `kuiper.juno-innovations.com/user-created-datavolume`
- **Resource Types**: DataVolumes
- **Value**: `"true"` or `"false"`
- **Purpose**: Marks DataVolumes as being created by users (via clone operations) rather than part of the original workload
- **Example**: `kuiper.juno-innovations.com/user-created-datavolume: "true"`

**Usage**: Automatically added by Kuiper when users clone DataVolumes. Helps distinguish between template volumes and user-created copies.

### Protection & Lifecycle Management

#### `kuiper.juno-innovations.com/delete-protection`
- **Resource Types**: All resources (especially DataVolumes)
- **Value**: `"true"` or `"false"`
- **Purpose**: Prevents automatic deletion of resources during instance shutdown
- **Example**: `kuiper.juno-innovations.com/delete-protection: "true"`

**Usage**: Apply to resources you want to preserve even when the workload instance is deleted. Resources are untagged from the instance rather than deleted.

### Generic Resource Configuration

#### `kuiper.juno-innovations.com/actions`
- **Resource Types**: All resources
- **Value**: Comma-separated list of actions
- **Purpose**: Defines custom actions that can be performed on the resource
- **Example**: `kuiper.juno-innovations.com/actions: "restart,scale,backup"`

**Usage**: Actions must correspond to methods on the resource handler class. Allows extending Kuiper's functionality with custom resource operations.

#### `kuiper.juno-innovations.com/<setting>`
- **Resource Types**: All resources
- **Value**: Any string
- **Purpose**: Generic pattern for passing arbitrary settings to resources
- **Example**: `kuiper.juno-innovations.com/timeout: "30s"`

**Usage**: Use for any custom configuration that your specific workload needs. **Note**: These settings are displayed in plain text on the frontend, so don't use them for sensitive information.

### Legacy Support

For backward compatibility, Kuiper also supports legacy annotations:

- `juno-innovations.com/kuiper-instance` (legacy version of core instance label)
- `juno-innovations.com/<setting>` (legacy version of generic settings)

These are automatically converted to the new `kuiper.juno-innovations.com/` format but maintained for compatibility with existing deployments.

### Quick Reference Examples

```yaml
# Service with connection details
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    kuiper.juno-innovations.com/connection: "username=admin,password=secret123"

# Ingress with hidden paths and extras
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    kuiper.juno-innovations.com/ingress-hide: "/admin,/internal"
    kuiper.juno-innovations.com/ingress-extras: "/docs/index.html?latest"

# DataVolume with delete protection
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: my-datavolume
  annotations:
    kuiper.juno-innovations.com/delete-protection: "true"
    kuiper.juno-innovations.com/user-created-datavolume: "true"
```

These annotations provide a comprehensive system for managing how Kuiper handles, displays, and configures Kubernetes resources in your workloads.
