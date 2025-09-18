# Workflow (TDK)

Juno ships the Terra Development Kit which aims to make developing on our platform easy and enjoyable.

## Pre-Requisite

Juno provides the Terra Development Kit as part of the Terra Official Plugins repository.
Here are the requirements before getting started:

1. Existing Kubernetes cluster with Orion installed.
2. Git repo that follows the plugin layout for Terra. (this can be a fork of the Official Plugins Repo).

## Setup

You have 2 ways to develop using the TDK.

1. In-Cluster
2. Remote

### In-Cluster

The in-cluster TDK ships with a VSCode environment you can launch and run inside a project in Orion.

| Pros                                                                                                   | Cons                                                                          |
|--------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| The environment is already optimized with the proper libraries including kubectl, helm, k9s and python | Need to install the TDK plugin for the IDE to be setup                        |
| Service account roles are attached and provide access to argo with no additional setup                 | Additional service accounts need to be created to attach to the running IDE's |

#### Setup

1. Login to Genesis and either create or decide what project you will be deploying the TDK into. We will call ours "tdk".
2. Go to the Terra App Store.
3. Go to the Sources tab and add the Official Plugins Repository if it isn't already.
4. Go back to the Store tab and search for "terra".
5. Install the "terra-cluster-admin" into the "tdk" project and call the install "admin".
6. Install the "terra-development-kit" and call it "tdk".
7. Go to the Workstations/Workloads panel and open the "Workloads" tab.
8. Select "tdk" from the Version drop down and fill out the following values.
    - label: tdk
    - terra_role: "admin-tdk" (if you are using a different project name, it should be "admin-<project name>")
    - groups: "tdk" (if you are using a different project name, set the projects name here)
9. Go back to the project page and connect to your project.
10. Open the workstations/workload page and launch the "tdk" workload.
11. Once up and running, you can start the workflow.

### Remote

You can also use the remote setup which will bind to an existing cluster which can be a local kind cluster, 
cloud hosted, or on a juno cluster on the same network.

| Pros                                       | Cons                                                                                                                |
|--------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| Use your own IDE                           | You local machine must be accessible from the cluster                                                               |
| Uses your own kubeconfig for access        | Kubectl must be configured properly to point to the correct cluster                                                 |
| No additional plugins need to be installed | If using `kind` you must provision the cluster locally yourself and verify it has Orion and Argo installed properly |

#### Setup

1. Verify you have the following tools installed locally
    - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
    - [helm](https://helm.sh/docs/intro/install/)
    - [make](https://www.gnu.org/software/make/)

    !!! info "Devbox"

        For local development, we do provide a devbox setup which will install all of this for you in most cases. Sometimes Helm can have issues, so just verify before
        begining development.

2. Make sure you have `kubectl` pointing to the cluster you want to interact with.
3. Verify you have access to the Application and Namespace objects in kubernetes.
    - Namespaces

        <!-- termynal -->

        ```shell
        $ kubectl get namespaces
        ```

    - Applications

        <!-- termynal -->
        
        ```shell
        $ kubectl get Applications -n argocd
        ```

!!! warning "Local Firewall"

    One thing to keep in mind, the TDK leverages `git daemon` to launch a git server on your system and then serve it to the cluster. 
    So make sure your firewall doesn't block external communication on port 9418 which will block ArgoCD from getting your local git
    repository.

!!! warning "Networking Considerations"

    Because the cluster needs access to the local machine to pull the git repo, you need to make sure that the cluster can get to your
    local machine without issue. We normally recommend you are on the same network as the cluster so you don't run in to issues. In 
    more security concious environments, the in-cluster workflow makes more sense.

## Plugin Workflow

From this point on, the workflow is the same for both remote and in-cluster.


1. **Create a Plugin**: Use the `make new-plugin <plugin name>` command to create a new plugin scaffolding.

    <!-- termynal -->

    ```shell
    $ make new-plugin my-plugin
    ```

2. **Launch Development Environment**: Use `make test-plugin <plugin name>` this will communicate with ArgoCD and create an Application deployment that points to your local system.

    <!-- termynal -->

    ```shell
    $ make test-plugin helios
    >> Deploying helios << 
    Plugin: helios
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

3. **Test Changes**: Now that you are in the development shell, you can make changes to the plugin and then run `make deploy`. The following will happen:
    - The TDK will first run a `make package` which will compile all of your changes in the scripts directory and apply them to the plugin.
    - Then, it will commit, **not push**, your changes which will register the local `git daemon` server with changes.
    - Then TDK will trigger a sync from ArgoCD which will pick up those changes live for you.
    - Finally you can try out your plugin. In most cased, this will live update the plugin and it's deployment unless it is a workload/workstation which 
        will need to be upgraded

4. **Repeat**: Continue making changes and running `make deploy`. ArgoCD will keep the cluster in sync with the latest changes.

9. **Clean Up**: When you are done, all you need to do is press CTRL+D and it will automatically clean up after itself.

    <!-- termynal -->

    ```shell
    $ CTRL+D
    exit

    >>> Caught termination signal. Cleaning up...
    >>> Uninstalling Helm release: ginger
    release "ginger" uninstalled
    error: git-daemon died of signal 15
    >>> Cleanup complete.
    ```


## Catalog Workflow

This targets deploying the entire repository to Terra as a source. This is useful when wanting to test that your entire repo and all the UI elements are working.


1. **Launch Development Environment**: Use `make test-catalog` this will communicate with Terra and add a new source that points to your local system.

    <!-- termynal -->

    ```shell
    $ make test-catalog
     >> Deploying Catalog << 
    TDK Name: ginger
    Git Branch: 354-build-terra-plugin-development-kit
    URL: git://ginger.svc.cluster.local:9418/Terra-Official-Plugins
    /config/workspace/Terra-Official-Plugins
    [86108] Ready to rumble
    >> Terra Payload << 
    {
    "name": "ginger",
    "ref": "354-build-terra-plugin-development-kit",
    "url": "git://ginger.svc.cluster.local:9418/Terra-Official-Plugins"
    }

    [{"name":"tdk","url":"https://github.com/juno-fx/terra-official-plugins","ref":"354-build-terra-plugin-development-kit"},{"name":"official","url":"https://github.com/juno-fx/terra-official-plugins","ref":"main"},{"name":"ginger","url":"git://ginger.svc.cluster.local:9418/Terra-Official-Plugins","ref":"354-build-terra-plugin-development-kit"}]
    ```

3. **Test Changes**: To test the changes you will need to open a second shell manually commit and package each plugin as you make changes. You **do not** need to push anything, but you must commit. To see your changes, simply login to Genesis and refresh the Terra App Store page.

4. **Repeat**: Continue making changes and refrehing the Terra App Store page.

9. **Clean Up**: When you are done, all you need to do is press CTRL+D and it will automatically clean up after itself.

    <!-- termynal -->

    ```shell
    $ CTRL+D
    >>> Caught termination signal. Cleaning up...
    >>> Uninstalling Source: ginger
    [{"name":"tdk","url":"https://github.com/juno-fx/terra-official-plugins","ref":"354-build-terra-plugin-development-kit"},{"name":"official","url":"https://github.com/juno-fx/terra-official-plugins","ref":"main"}]>>> Cleanup complete.

    >>> Caught termination signal. Cleaning up...
    >>> Uninstalling Source: ginger
    error: waitpid for git-daemon failed: No child processes
    [{"name":"tdk","url":"https://github.com/juno-fx/terra-official-plugins","ref":"354-build-terra-plugin-development-kit"},{"name":"official","url":"https://github.com/juno-fx/terra-official-plugins","ref":"main"}]git-daemon: no process found
    >>> Cleanup complete.
    make: *** [Makefile:21: test-catalog] Error 130
    ```

    !!! info "Error codes"

        You will see the clean up process run twice and usually throw an error code at the end. This is normal and expected. This is to make sure it doesn't leave anything behind.
