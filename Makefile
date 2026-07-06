.PHONY: plugins docs verify venv new-plugin package check-size watch

SHELL := /bin/bash
MAKEFLAGS += --no-print-directory

ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

# workflow
venv:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt

test-plugin:
	@echo " >> Deploying $(ARGS) << "
	@./hack/deploy-test.sh $(ARGS)
	@echo

test-catalog:
	@echo " >> Deploying Catalog << "
	@./hack/deploy-test-all.sh
	@echo

deploy:
	@echo "Deploying changes"
	@./hack/deploy-changes.sh
	@echo

# Creates a new plugin with interactive type selection.
# Usage: make new-plugin
new-plugin:
	@echo ""
	@echo "========================================"
	@echo "  Terra Plugin Scaffolding"
	@echo "========================================"
	@echo ""
	@read -p "Plugin name (lowercase, hyphens only): " plugin_name; \
	if [ -z "$$plugin_name" ]; then echo "Error: plugin name required." && exit 1; fi; \
	if [ -d "./plugins/$$plugin_name" ]; then echo "Error: plugins/$$plugin_name already exists." && exit 1; fi; \
	echo ""; \
	echo "Plugin type:"; \
	echo "  1) namespaced    - deploys a workload into a user namespace (e.g. Ollama)"; \
	echo "  2) cluster       - cluster-wide operator via ArgoCD Application (e.g. nvidia-gpu-operator)"; \
	echo "  3) workload      - workload template consumed by Genesis/Kuiper (e.g. Helios)"; \
	echo ""; \
	read -p "Select type [1/2/3]: " plugin_type; \
	case "$$plugin_type" in \
	  1) \
	    echo ""; \
	    echo " >> Building namespaced plugin: $$plugin_name <<"; \
	    mkdir -p ./plugins/$$plugin_name; \
	    cp -r ./template/namespaced/. ./plugins/$$plugin_name/; \
	    find ./plugins/$$plugin_name -type f | xargs sed -i "s/PLUGIN/$$plugin_name/g"; \
	    ;; \
	  2) \
	    echo ""; \
	    echo " >> Building cluster-level plugin: $$plugin_name <<"; \
	    mkdir -p ./plugins/$$plugin_name; \
	    cp -r ./template/cluster/. ./plugins/$$plugin_name/; \
	    find ./plugins/$$plugin_name -type f | xargs sed -i "s/PLUGIN/$$plugin_name/g"; \
	    ;; \
	  3) \
	    echo ""; \
	    echo "Workload UI category:"; \
	    echo "  1) Application   - general GUI application"; \
	    echo "  2) Terminal      - terminal/shell workload"; \
	    echo "  3) Workspace     - full desktop or IDE environment"; \
	    echo "  4) Server        - headless server workload"; \
	    echo "  5) Virtual Machine - KubeVirt VM"; \
	    echo ""; \
	    read -p "Select category [1-5]: " wl_type; \
	    case "$$wl_type" in \
	      1) wl_label="Application" ;; \
	      2) wl_label="Terminal" ;; \
	      3) wl_label="Workspace" ;; \
	      4) wl_label="Server" ;; \
	      5) wl_label="Virtual Machine" ;; \
	      *) echo "Invalid category." && exit 1 ;; \
	    esac; \
	    echo ""; \
	    echo " >> Building workload template plugin: $$plugin_name ($$wl_label) <<"; \
	    mkdir -p ./plugins/$$plugin_name; \
	    cp -r ./template/workload/. ./plugins/$$plugin_name/; \
	    find ./plugins/$$plugin_name -type f | xargs sed -i "s/PLUGIN/$$plugin_name/g"; \
	    find ./plugins/$$plugin_name -type f | xargs sed -i "s/WORKLOAD_TYPE/$$wl_label/g"; \
	    ;; \
	  *) echo "Invalid type." && exit 1 ;; \
	esac; \
	$(MAKE) --no-print-directory package $$plugin_name; \
	git add ./plugins/$$plugin_name; \
	echo ""; \
	echo " >> Plugin created at: $(shell pwd)/plugins/$$plugin_name <<"; \
	echo " >> Added to git staging <<"; \
	echo " >> Ready to go <<"

# Verify all plugins have up-to-date packaged scripts.
# Fails hard if any plugin's scripts/ directory is newer than its packaged-scripts.yaml.
# Run automatically in CI via .github/workflows/verify-packages.yaml.
verify:
	@echo "Verifying packaged scripts are up to date..."
	@failed=0; \
	for plugin_dir in ./plugins/*/; do \
	  plugin=$$(basename "$$plugin_dir"); \
	  scripts_dir="$$plugin_dir/scripts"; \
	  packaged="$$plugin_dir/templates/packaged-scripts.yaml"; \
	  if [ ! -d "$$scripts_dir" ]; then continue; fi; \
	  if [ ! -f "$$packaged" ]; then \
	    echo "  [SKIP] $$plugin: no templates/packaged-scripts.yaml"; \
	    continue; \
	  fi; \
	  newest_script=$$(find "$$scripts_dir" -type f -newer "$$packaged" 2>/dev/null | head -1); \
	  if [ -n "$$newest_script" ]; then \
	    echo "  [FAIL] $$plugin: scripts/ has changes not yet packaged — run: make package $$plugin"; \
	    failed=1; \
	  else \
	    echo "  [OK]   $$plugin"; \
	  fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
	  echo ""; \
	  echo "One or more plugins have stale packages. Run 'make package <plugin>' for each failure above."; \
	  exit 1; \
	fi; \
	echo "All packaged scripts are up to date."

lint-scripts:
	shellcheck plugins/wetty/scripts/chart/files/system.sh
lint:
	bash hack/lint.sh

# wrappers

# Package a plugin's scripts/ directory into a base64-encoded ConfigMap.
# MUST be run after any change to scripts/ or scripts/chart/.
# Usage: make package <plugin-name>
package:
	@cd ./plugins/$(ARGS) \
		&& tar --owner=0 --group=0 --mtime='1970-01-01' --sort=name -czf scripts.tar scripts \
		&& base64 -w 0 scripts.tar > scripts.base64 \
		&& rm -rf scripts.tar \
		&& cp ../../template/packaged-scripts-template.yaml ./templates/packaged-scripts.yaml \
		&& cp ../../template/packaged-scripts-template-cleanup.yaml ./templates/packaged-scripts-cleanup.yaml \
		&& sed -i '1s/^/  packaged_scripts.base64: "/' scripts.base64 \
		&& sed -i '1s/$$/"/' scripts.base64 \
		&& cat scripts.base64 >> ./templates/packaged-scripts.yaml \
		&& cat scripts.base64 >> ./templates/packaged-scripts-cleanup.yaml \
		&& rm -rf scripts.base64
	@$(MAKE) --no-print-directory check-size $(ARGS)

# Check the size of a plugin's packaged scripts ConfigMap.
# Warns if approaching the 1MiB Kubernetes ConfigMap limit.
# Called automatically by 'make package'. Can also be run standalone.
# Usage: make check-size <plugin-name>
check-size:
	@packaged="./plugins/$(ARGS)/templates/packaged-scripts.yaml"; \
	if [ ! -f "$$packaged" ]; then exit 0; fi; \
	size=$$(grep 'packaged_scripts.base64' "$$packaged" | wc -c); \
	limit=1048576; \
	warn=921600; \
	echo "  [size] $(ARGS): packaged scripts $$size bytes (limit: $$limit)"; \
	if [ "$$size" -ge "$$limit" ]; then \
	  echo "  [ERROR] $(ARGS): packaged scripts EXCEED the 1MiB Kubernetes ConfigMap limit!"; \
	  echo "         Reduce the size of scripts/ before deploying — ArgoCD will reject this."; \
	  exit 1; \
	elif [ "$$size" -ge "$$warn" ]; then \
	  echo "  [WARN]  $(ARGS): packaged scripts are within 10%% of the 1MiB limit. Consider trimming scripts/."; \
	fi

# Watch a plugin's scripts/ directory and auto-repackage on changes.
# Useful during active workload template development.
# Requires inotify-tools (available in devbox shell).
# Usage: make watch <plugin-name>
watch:
	@./hack/watch.sh $(ARGS)


# documentation
docs:
	.venv/bin/mkdocs serve

deploy-docs: .venv/bin/activate
	. .venv/bin/activate; mkdocs gh-deploy --force

lint-docs: .venv/bin/activate
	@echo " >> skipping lint << "

#	@(grep -q -r '<a href' docs && (echo Please use markdown links instead of href. && exit 1)) || true
#	([[ -d site ]] && rm -rf site/) || true
#	.venv/bin/mkdocs build --strict
#	cp -r site /tmp/site-terra-official-docs
#	@ # This is due to some CI environments providing root as default.
#	@ # linkchecker will drop to the `nobody` user. Depending on the workdir, it might not be able to reach it and will fail.
#	([[ "$$EUID" -eq 0 ]] && chmod -R 655 /tmp/site-terra-official-docs) || true
#	source .venv/bin/activate; linkchecker /tmp/site-terra-official-docs/index.html

# when using devbox, this will already exist and not trigger
# It's used by the CI, where devbox hook behavior is different
.venv/bin/activate:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt
# env
cluster:
	@which kind || (echo "kind is not in PATH - did you install devbox and run 'devbox shell'?" && exit 1)
	@kind create cluster --name terra-plugins --config .kind.yaml || echo "Cluster already exists..."

dependencies: cluster
	@kubectl create namespace argocd || echo "Argo namespace already exists..."
	@echo " >> Installing ArgoCD << "
	@kubectl create -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD to be ready..."
	@sleep 15
	@kubectl wait --namespace argocd \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/name=argocd-server \
		--timeout=90s
	@echo " >> ArgoCD Ready << "
	@echo " >> Setting Example Volumes << "
	@kubectl apply -n argocd -f k8s/
	@echo " >> Cluster Ready << "

down:
	@kind delete cluster --name terra-plugins

test: cluster dependencies
	@echo " >> Deploying $(ARGS) << "
	@helm upgrade -i terra-plugin ./tests/Application \
		--set branch=$(shell git rev-parse --abbrev-ref HEAD) \
		--set remote=$(shell hack/get-remote.sh),plugin=$(ARGS) \
		--set name=terra-test \
		--wait \
		--timeout 5m
	@echo
	@echo " >> ArgoCD UI Listening << "
	@echo "http://localhost:8080"
	@echo
	@echo " >> ArgoCD Admin Credentials << "
	@echo "admin"
	@kubectl -n argocd get secret argocd-initial-admin-secret \
               -o jsonpath="{.data.password}" | base64 -d; echo
	@kubectl -n argocd port-forward service/argocd-server 8080:80 > /dev/null 2>&1


# --- Test harness ---
.PHONY: deploy-test full-test test-harness-list test-harness-render-all test-harness-render test-harness-all test-harness-plugin test-cluster-up test-cluster-down

# Safe — no cluster needed, just validates Helm rendering
# Interactive deploy-test: deploys to existing cluster (run make test-cluster-up first)
# Usage: make deploy-test helios
deploy-test:
	python3 test/run_test.py --deploy $(ARGS) --retries 5 --retry-delay 5

test-harness-list:
	python3 test/run_test.py --list

test-harness-render-all:
	python3 test/run_test.py --all --dry-run

test-harness-render:
	python3 test/run_test.py --plugin $(ARGS) --dry-run

# Requires Kind cluster (guard built into script)
test-harness-all: test-cluster-up
	@python3 test/run_test.py --all; status=$$?; \
	$(MAKE) test-cluster-down; \
	exit $$status

test-harness-plugin:
	python3 test/run_test.py --plugin $(ARGS)

# Full pipeline: render validation (no cluster) → cluster up → deploy tests → cluster down
full-test:
	@echo "=== Stage 1/3: Render validation (no cluster needed) ==="; \
	python3 test/run_test.py --all --dry-run; \
	if [ $$? -ne 0 ]; then \
		echo "RENDER VALIDATION FAILED — aborting"; \
		exit 1; \
	fi; \
	echo "=== Stage 2/3: Starting Kind cluster ==="; \
	$(MAKE) test-cluster-up; \
	if [ $$? -ne 0 ]; then \
		echo "CLUSTER SETUP FAILED — aborting"; \
		$(MAKE) test-cluster-down 2>/dev/null; \
		exit 1; \
	fi; \
	echo "=== Stage 3/3: Full deploy + auth tests ==="; \
	python3 test/run_test.py --all; \
	status=$$?; \
	$(MAKE) test-cluster-down; \
	exit $$status

CLUSTER_NAME := terra-plugins

test-cluster-up:
	# Remove stale cluster entry from previous failed runs (cleans kubeconfig too)
	kind delete cluster --name $(CLUSTER_NAME) 2>/dev/null || true
	# Clear any lingering kubectl proxy/port-forward processes from earlier runs
	-pkill -f "kubectl port-forward" 2>/dev/null || true
	bash test/patch-kind-config.sh test/kind-config.yaml
	kind create cluster --name $(CLUSTER_NAME) --config test/kind-config.yaml.patched
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	# Install CRDs needed by certain plugins
	kubectl apply -f test/crds/ 2>/dev/null || true
	# Create common namespaces
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace kube-system --dry-run=client -o yaml | kubectl apply -f -
	# Remove ingress-nginx validating webhook (blocks Ingress creation in Kind)
	kubectl delete validatingwebhookconfiguration ingress-nginx-admission 2>/dev/null || true
	# Wait for controller pod to exist before waiting for ready
	@for i in $$(seq 1 30); do \
		if kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --no-headers 2>/dev/null | grep -q .; then break; fi; \
		sleep 2; \
	done; \
	echo "Controller pod found, waiting for ready..."; \
	kubectl wait --namespace ingress-nginx --for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller --timeout=120s; \
	echo "Node labels configured in kind config"

test-cluster-down:
	kind delete cluster --name $(CLUSTER_NAME) 2>/dev/null || true
	rm -f test/kind-config.yaml.patched

# LEGACY
test-%:
	@echo "Legacy: Use 'make test $(subst test-,,$@)' instead."
	@$(MAKE) --no-print-directory test $(subst test-,,$@)

package-%:
	@echo "Legacy: Use 'make package $(subst package-,,$@)' instead."
	@$(MAKE) --no-print-directory package $(subst package-,,$@)
