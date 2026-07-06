#!/usr/bin/env python3
"""Generate test/template.yaml from a workload template's templates/metadata.yaml.

Usage:
    python3 test/generate-template-fixture.py plugins/<name>

Output: plugins/<name>/test/template.yaml + test/config.yaml (created/overwritten)
"""

import os
import re
import sys
import yaml
from pathlib import Path


FIELD_TYPES = {
    "string": "",
    "int": 0,
    "boolean": False,
    "select": "",
    "multi": [],
    "k8sStorageClass": "",
    "k8sServiceAccount": "",
    "k8sPriority": "",
    "k8sIngressClass": "",
    "env": [],
    "list": [],
    "multi-line": "",
}


def strip_helm_templates(text):
    """Replace Helm template directives {{ ... }} with safe placeholders."""
    # Replace {{ }} blocks with safe values
    text = re.sub(r"\{\{\s*\.Values\.(\w+)\s*\}\}", r"__VAL_\1__", text)
    text = re.sub(r"\{\{\s*\.Release\.(\w+)\s*\}\}", r"__REL_\1__", text)
    text = re.sub(r"\{\{.*?\}\}", '"placeholder"', text)
    return text


def extract_fields(metadata_path):
    """Parse metadata.yaml and return list of field dicts."""
    with open(metadata_path) as f:
        raw_text = f.read()

    # Strip Helm directives before YAML parsing
    clean = strip_helm_templates(raw_text)
    data = yaml.safe_load(clean)

    raw = data.get("data", {}).get("fields", "")
    if isinstance(raw, str):
        fields = yaml.safe_load(raw)
    else:
        fields = raw
    return fields or []


def infer_default(field):
    """Return a sensible test default for a metadata field."""
    # Explicit default takes precedence
    if "default" in field:
        raw = field["default"]
        typ = field.get("type", "string")
        # Coerce types
        if typ == "int":
            return int(raw)
        if typ == "boolean":
            if isinstance(raw, bool):
                return raw
            return raw.lower() in ("true", "1", "yes")
        if typ == "select":
            return str(raw)
        return raw

    # No default — pick based on type
    typ = field.get("type", "string")
    if typ == "select" and field.get("options"):
        return field["options"][0]
    return FIELD_TYPES.get(typ, "")


def generate(plugin_dir):
    plugin_dir = Path(plugin_dir)
    plugin_name = plugin_dir.name
    metadata_path = plugin_dir / "templates" / "metadata.yaml"

    if not metadata_path.exists():
        print(f"  [SKIP] {plugin_name}: no templates/metadata.yaml")
        return

    fields = extract_fields(metadata_path)

    # Build values dict
    values = {
        # Standard Kuiper-injected keys
        "name": "test-workload",
        "user": "testuser",
        "host": "test.example.com",
        "cpu": "1",
        "memory": "1Gi",
        "puid": 1000,
        "guid": 1000,
        "pullSecret": "",
        "session": "test-session",
        "volumeMounts": [],
        "volumes": [],
        "env": [],
        "selector": [],
        "plugins": [],
        "idx": 0,
        # Common optional keys many plugins use
        "timezone": "America/New_York",
        "storage_class": "",
        "storage_size": "1Gi",
        # Nginx + ingress defaults
        "nginx_registry": "docker.io",
        "nginx_repo": "nginx",
        "nginx_tag": "alpine",
        "ingressClassName": "nginx",
        # Kuiper gateway API flag
        "_juno_gateway_api": False,
    }

    # Add plugin-specific fields (don't overwrite hardcoded defaults)
    for f in fields:
        name = f.get("name")
        if not name:
            continue
        # Skip icon (not a real template value)
        if name == "icon":
            continue
        # Skip fields we already set with test-specific defaults
        if name in values:
            continue
        values[name] = infer_default(f)

    # Ensure test directory exists
    test_dir = plugin_dir / "test"
    test_dir.mkdir(parents=True, exist_ok=True)

    # Write template.yaml
    template_path = test_dir / "template.yaml"
    with open(template_path, "w") as f:
        yaml.dump(values, f, default_flow_style=False, sort_keys=False)
    print(f"  [OK]   {plugin_name}: wrote test/template.yaml")

    # Build and write config.yaml
    # Determine ingress path prefix from common conventions
    # Default to /plugin/name/ for workload templates
    ingress_paths = [
        {"path": "/plugin/__NAME__/"}
    ]

    config = {
        "deploy": {
            "method": "template",
            "path": "scripts/chart/",
        },
        "auth": {
            "type": "hubble",
            "port": 8080,
            "paths": ingress_paths,
        },
    }

    config_path = test_dir / "config.yaml"
    with open(config_path, "w") as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)
    print(f"  [OK]   {plugin_name}: wrote test/config.yaml")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 test/generate-template-fixture.py plugins/<name>")
        sys.exit(1)

    target = sys.argv[1]
    generate(target)


if __name__ == "__main__":
    main()
