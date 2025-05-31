# Development Workflow

Terra uses ArgoCD as its backend for plugin deployment and management, allowing for a streamlined GitOps workflow. 
In order to fully understand the development process, we need to first understand ArgoCD.

## ArgoCD Overview

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It allows you to manage your Kubernetes 
applications using Git repositories as the source of truth. With ArgoCD, you can define your application state in 
Git and have ArgoCD automatically sync your Kubernetes cluster to match that state.

Terra deploys its plugins on the backend as ArgoCD Application resources that are populated with the values from 
the `terra.yaml` file in each plugin. This allows Terra to manage the high level lifecycle of the Plugin, while
ArgoCD handles the actual deployment, management and clean up of the Kubernetes resources.

## Workflow Overview

The development workflow is designed to focus on the raw Helm Chart development and then simulate the deployment
via a local Kubernetes cluster installed with ArgoCD. This allows developers to iterate quickly on their plugins
locally without needing to deploy to a production environment until they are ready. The workflow is as follows:

1. Create the plugin locally and push it to a remote branch.
2. Launch a local Kind Cluster pre-installed with ArgoCD.
3. Install the ArgoCD Application Resource that points to your plugin on your remote branch.
4. Log in to the ArgoCD UI and see your plugin listed as an Application.
5. Make changes to your plugin locally and push them to the remote branch.
6. ArgoCD will automatically detect the changes and update the application in the local cluster.

## Workflow Steps

1. **Create a Plugin**: Use the `make new-plugin <plugin name>` command to create a new plugin scaffolding.

    <!-- termynal -->

    ```shell
    $ make new-plugin my-plugin
    ```

2. **Push to Remote Branch**: Commit your changes and push them to a remote branch.
3. **Launch Local Cluster**: Use `make test <plugin name>` to start a local Kind cluster with ArgoCD pre-installed.

    <!-- termynal -->

    ```shell
    $ make test my-plugin
    ...
    >> ArgoCD UI Listening <<
    http://localhost:8080
   
    >> ArgoCD Admin Credentials <<
    admin
    336LYpUVgfDeFUKb
    ```

    !!! danger "ArgoCD Sync Failure"
        If you encounter a sync failure that states something about "failed to dial", this is likely due to 
        a race condition where the ArgoCD server is not fully up and running before the sync is attempted. Open the 
        cluster and restart the ArgoCD server.

    !!! danger "ArgoCD Sync Failure"
        If your plugin says "path not found", you need to push your changes to the remote branch before running the
        `make test` command. ArgoCD needs to see the latest changes in the remote branch to sync correctly.

4. **Access ArgoCD UI**: Open the ArgoCD UI in your browser at `http://localhost:8080` and log in with the provided credentials.


