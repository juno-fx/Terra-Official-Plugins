.PHONY: plugins docs verify

SHELL := /bin/bash
MAKEFLAGS += --no-print-directory

ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

# workflow
test: cluster dependencies
	@echo " >> Deploying $(ARGS) << "
	@helm upgrade -i terra-plugin ./tests/Application \
		--set branch=$(shell git rev-parse --abbrev-ref HEAD),plugin=$(ARGS) \
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

package:
	docker run --rm -v $(shell pwd):/workspace -w /workspace \
		alpine /bin/ash -c "apk add bash make tar && make _package ARGS=$(ARGS)"

new-plugin:
	@echo " >> Building New Plugin: $(ARGS) << "
	@mkdir -p ./plugins/$(ARGS)
	@cp -r ./template/chart/* ./plugins/$(ARGS)/
	@echo " >> Setting up Plugin: $(ARGS) << "
	@sed -i 's/PLUGIN/$(ARGS)/g' ./plugins/$(ARGS)/Chart.yaml
	@sed -i 's/PLUGIN/$(ARGS)/g' ./plugins/$(ARGS)/terra.yaml
	@$(MAKE) --no-print-directory package $(ARGS)
	@echo " >> New Plugin Setup << "
	@git add ./plugins/$(ARGS)
	@echo " >> Added to git << "
	@echo " >> Plugin Location: $(shell pwd)/plugins/$(ARGS) << "
	@echo " >> Ready to go << "

verify:
	@echo "Verify is disabled"
#	docker run --rm -v $(shell pwd):/workspace -w /workspace \
#		alpine /bin/ash -c "apk add bash make tar && bash hack/verify.sh"

lint:
	bash hack/lint.sh

# wrappers
_package:
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


# documentation
docs:
	.venv/bin/mkdocs serve


# realpath due to: https://github.com/linkchecker/linkchecker/issues/873
lint: .venv/bin/activate
	@(grep -q -r '<a href' docs && (echo Please use markdown links instead of href. && exit 1)) || true
	([[ -d site ]] && rm -rf site/) || true
	.venv/bin/mkdocs build --strict
	.venv/bin/linkchecker '$(realpath .)/site/index.html'

# when using devbox, this will already exist and not trigger
# It's used by the CI, where devbox hook behavior is different
.venv/bin/activate:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt
# env
cluster:
	@kind create cluster --name terra-plugins --config .kind.yaml || echo "Cluster already exists..."

dependencies: cluster
	@kubectl create namespace argocd || echo "Argo namespace already exists..."
	@echo " >> Installing ArgoCD << "
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
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


# LEGACY
test-%: cluster dependencies
	@echo "Legacy: Use 'make test $(subst test-,,$@)' instead."
	@$(MAKE) --no-print-directory test $(subst test-,,$@)

package-%:
	@echo "Legacy: Use 'make package $(subst package-,,$@)' instead."
	@$(MAKE) --no-print-directory package $(subst package-,,$@)
