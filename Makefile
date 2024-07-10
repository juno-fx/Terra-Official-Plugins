.PHONY: dev terra

SHELL := /bin/bash

# vars
VENV="venv/bin"
PIP="$(VENV)/pip"
UV="$(VENV)/uv"

# env
cluster:
	kind create cluster --name terra-plugins --config .kind.yaml

down:
	kind delete cluster --name terra-plugins

dev: local-test

# development
venv:
	python3.12 -m venv venv
	$(PIP) install --upgrade uv

install-prod:
	@source $(VENV)/activate \
		&& $(VENV)/uv pip install -r requirements.txt

install-dev:
	@source $(VENV)/activate \
    	&& $(VENV)/uv pip install -r dev-requirements.txt

install: venv install-dev install-prod

lint: install
	@$(VENV)/ruff check terra
	@$(VENV)/ruff check plugins

format: install
	@$(VENV)/ruff format terra
	@$(VENV)/ruff format plugins

qc-format: install
	@$(VENV)/ruff format --check terra
	@$(VENV)/ruff format --check plugins

# testing
dependencies:
	@echo "Installing dependencies..."

_run_tests:
	# Create the cluster if it doesn't exist
	@$(MAKE) --no-print-directory cluster || echo "Cluster already exists..."

	# Install the required dependencies
	@$(MAKE) --no-print-directory dependencies

	# Build the required artifacts and export them to the
	# build file for use in the next steps
	@skaffold build --file-output build.json

	# Force load images into the cluster
	@skaffold deploy -a build.json --load-images=true
	# Mongo flushed...

	# Launch the integration tests
	@skaffold verify -a build.json

local-test:
	@echo "Running Local tests... Cluster will persist after"
	@$(MAKE) --no-print-directory _run_tests || (echo "Tests failed!" \
		&& rm -rf build.json \
		&& unzip -o htmlcov.zip > /dev/null \
		&& rm -rf htmlcov.zip \
		&& exit 1) && (rm -rf build.json \
		&& unzip -o htmlcov.zip > /dev/null \
		&& rm -rf htmlcov.zip \
		&& exit 0)

test:
	@echo "Running CI tests... Cluster will be taken down after"
	@$(MAKE) --no-print-directory _run_tests || (echo "Tests failed!" \
		&& rm -rf build.json \
		&& $(MAKE) --no-print-directory down \
		&& exit 1) && (echo "Tests passed!" \
		&& rm -rf build.json \
		&& $(MAKE) --no-print-directory down \
		&& exit 0)

open-coverage:
	@xdg-open htmlcov/index.html

