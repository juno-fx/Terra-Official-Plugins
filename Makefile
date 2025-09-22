.PHONY: plugins docs verify venv

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

lint:
	bash hack/lint.sh

# wrappers
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


# documentation
docs:
	.venv/bin/mkdocs serve

lint-docs: .venv/bin/activate
	@(grep -q -r '<a href' docs && (echo Please use markdown links instead of href. && exit 1)) || true
	([[ -d site ]] && rm -rf site/) || true
	.venv/bin/mkdocs build --strict
	cp -r site /tmp/site-terra-official-docs
	@ # This is due to some CI environments providing root as default.
	@ # linkchecker will drop to the `nobody` user. Depending on the workdir, it might not be able to reach it and will fail.
	([[ "$$EUID" -eq 0 ]] && chmod -R 655 /tmp/site-terra-official-docs) || true
	source .venv/bin/activate; linkchecker /tmp/site-terra-official-docs/index.html

# when using devbox, this will already exist and not trigger
# It's used by the CI, where devbox hook behavior is different
.venv/bin/activate: venv

# LEGACY
test-%:
	@echo "Legacy: Use 'make test $(subst test-,,$@)' instead."
	@$(MAKE) --no-print-directory test $(subst test-,,$@)

package-%:
	@echo "Legacy: Use 'make package $(subst package-,,$@)' instead."
	@$(MAKE) --no-print-directory package $(subst package-,,$@)
