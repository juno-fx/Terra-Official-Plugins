### Before requesting review, I have done the following:

- [ ] Code Formatting
- [ ] Made sure `make test <plugin name>` passes
- [ ] I packaged the latest scripts with `make package`
- [ ] Linting job passes (see: `make lint`)
- [ ] Updated Documentation (if any)
- [ ] Resolved any Merge Conflicts


### Reviewer's checklist

- [ ] I deployed the installation live and could get it working.
- [ ] I checked that on installation, no directories outside the plugin's management can be clobbered.
- [ ] I checked that on uninstall, no directories/files outside the installation itself are removed.
- [ ] I checked that on install, no k8s resources that the plugin doesn't deploy are tracked in argo. If there's a need to manage them, they are edited in a non-invasive way.
- [ ] I checked that on uninstall, no K8s resources that were created outside the plugin are removed.
- [ ] I checked there are appropriate NetworkPolicies for any services with unauthenticated API endpoints.
- [ ] I considered the security impact of defined RBACs / serviceaccounts . The plugin keeps to least-necessary, reasonable privileges on any long-running services it deploys.
- [ ] I unpacked the base64-encoded scripts and validated they are the same as what was submitted.
