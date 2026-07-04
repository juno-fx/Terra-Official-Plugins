#!/usr/bin/env python3
"""Plugin test harness — Tier 2: deploy to Kind + mock auth + HTTP validation.

Usage:
    python3 test/run_test.py --all          # test all auth plugins
    python3 test/run_test.py --plugin NAME  # test single plugin
    python3 test/run_test.py --list         # list auth plugins
"""

import argparse
import os
import subprocess
import sys
import time
import yaml
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NAMESPACE_PREFIX = "t-"
LOCAL_PORT = 9999


DRY_RUN = False


def log(msg):
    print(f"  [..] {msg}")


def ok(msg):
    print(f"  [OK] {msg}")


def fail(msg):
    print(f"  [FAIL] {msg}")
    return False


def check_safe_cluster():
    """Refuse to run deploy if not targeting a Kind cluster."""
    res = run("kubectl config current-context 2>/dev/null")
    if res.returncode != 0:
        print("  [SAFETY] No kubectl context set.")
        print("  [SAFETY] Run 'make test-cluster-up' first.")
        sys.exit(1)
    ctx = res.stdout.strip()
    if "kind" not in ctx.lower():
        print(f"  [SAFETY] Current context is '{ctx}' — not a Kind cluster.")
        print(f"  [SAFETY] Run 'make test-cluster-up' first.")
        sys.exit(1)
    # Verify cluster API is reachable — use kubectl get ns as a reliable check
    res2 = run("kubectl get ns --request-timeout=3s 2>/dev/null")
    if res2.returncode != 0:
        print(f"  [SAFETY] Cluster context '{ctx}' exists but API server is not reachable.")
        print(f"  [SAFETY] Stale kubeconfig entry. Run 'kind delete cluster --name terra-plugins-test' then 'make test-cluster-up'")
        sys.exit(1)


def find_auth_plugins():
    """Return workload template plugins (method: template) with auth."""
    plugins = []
    for d in sorted((ROOT / "plugins").iterdir()):
        config_path = d / "test" / "config.yaml"
        if not config_path.exists():
            continue
        with open(config_path) as f:
            cfg = yaml.safe_load(f)
        if not cfg:
            continue
        if cfg.get("auth", {}).get("type") in (None, "none"):
            continue
        if cfg.get("deploy", {}).get("method") != "template":
            continue  # skip install-method (cluster-level) plugins
        plugins.append(d.name)
    return plugins


def run(cmd, **kwargs):
    """Run shell command, return CompletedProcess."""
    return subprocess.run(cmd, shell=True, capture_output=True, text=True, **kwargs)


def render_plugin(plugin_dir, cfg):
    """Helm template only — validate rendering succeeds. Returns (namespace, err)."""
    deploy_path = cfg["deploy"]["path"]
    plugin_name = plugin_dir.name
    namespace = f"{NAMESPACE_PREFIX}{plugin_name}"
    values = plugin_dir / "test" / "template.yaml"
    chart = plugin_dir / deploy_path
    log(f"helm template {chart} -f {values} --namespace {namespace}")
    res = run(f"helm template test-release {chart} -f {values} --namespace {namespace}")
    if res.returncode != 0:
        return None, f"helm template failed:\n{res.stderr}"
    resource_count = res.stdout.count("---\n# Source:")
    log(f"Rendered {resource_count} resources")
    return namespace, None


def deploy_plugin(plugin_dir, cfg):
    """Deploy plugin resources to the test namespace."""
    if DRY_RUN:
        return render_plugin(plugin_dir, cfg)

    deploy_path = cfg["deploy"]["path"]
    plugin_name = plugin_dir.name
    namespace = f"{NAMESPACE_PREFIX}{plugin_name}"
    values = plugin_dir / "test" / "template.yaml"
    chart = plugin_dir / deploy_path

    log(f"helm template {chart} -f {values} --namespace {namespace}")
    res = run(f"helm template test-release {chart} -f {values} --namespace {namespace}")
    if res.returncode != 0:
        return None, f"helm template failed:\n{res.stderr}"

    # Create namespace and apply rendered manifests
    run(f"kubectl create namespace {namespace} --dry-run=client -o yaml | kubectl apply -f -")
    log("kubectl apply")
    res2 = run(f"kubectl apply --validate=false -f - --namespace {namespace}", input=res.stdout)
    if res2.returncode != 0:
        return None, f"kubectl apply failed:\n{res2.stderr}"

    return namespace, None


def deploy_mock_auth(namespace):
    """Deploy mock auth Deployment + hubble/genesis Services."""
    mock_path = ROOT / "test" / "mock-auth.yaml"
    res = run(f"kubectl apply -f {mock_path} --namespace {namespace}")
    if res.returncode != 0:
        return f"mock auth deploy failed:\n{res.stderr}"
    return None


def wait_for_pods(namespace, label, timeout=120):
    """Wait for pods matching label to be ready."""
    log(f"Waiting for {label} in namespace {namespace}...")
    for i in range(timeout):
        res = run(f"kubectl wait --for=condition=ready pod -l {label} --namespace {namespace} --timeout=5s 2>/dev/null")
        if res.returncode == 0:
            ok(f"Pods {label} ready")
            return True
        time.sleep(1)
    return False


def load_values_name(plugin_dir):
    """Extract the workload name from template.yaml."""
    path = plugin_dir / "test" / "template.yaml"
    if path.exists():
        with open(path) as f:
            vals = yaml.safe_load(f)
        if vals and "name" in vals:
            return vals["name"]
    return "test-workload"


def get_app_pod_name(namespace):
    """Get first non-auth-mock pod name in namespace."""
    res = run(f"kubectl get pods --namespace {namespace} -o jsonpath='{{range .items[*]}}{{.metadata.name}} {{end}}'")
    if res.returncode != 0:
        return None
    pod_names = res.stdout.strip().strip("'").split()
    for p in pod_names:
        if "auth-mock" not in p:
            return p
    return None


def wait_for_app_pods(namespace, timeout=120):
    """Wait for all non-auth-mock pods to be ready. Fails fast on CrashLoopBackOff."""
    log(f"Waiting for app pods in namespace {namespace}...")
    for i in range(timeout):
        res = run(f"kubectl get pods --namespace {namespace} -o jsonpath='{{range .items[*]}}{{.metadata.name}}{{\"\\n\"}}{{end}}'")
        if res.returncode != 0:
            time.sleep(2)
            continue
        pods = [p.strip() for p in res.stdout.strip().split("\n") if p.strip() and "auth-mock" not in p]
        if not pods:
            time.sleep(2)
            continue
        # Check all app pods ready (uses Ready condition = all containers passed probes)
        all_ready = True
        for pod in pods:
            r = run(f"kubectl get pod {pod} --namespace {namespace} -o jsonpath='{{.status.conditions[?(@.type==\"Ready\")].status}}'")
            if r.stdout.strip() != "True":
                all_ready = False
                # Check for CrashLoopBackOff — fail fast
                status = run(f"kubectl get pod {pod} --namespace {namespace} -o jsonpath='{{range .status.containerStatuses[*]}}{{.state.waiting.reason}}{{end}}'")
                if "CrashLoopBackOff" in status.stdout or "ImagePullBackOff" in status.stdout:
                    return fail(f"Pod {pod} in {status.stdout.strip()}")
                break
        if all_ready:
            ok(f"{len(pods)} app pod(s) ready")
            return True
        time.sleep(2)
    return False


def set_auth_mode(namespace, mode):
    """Set auth mock to 'pass' or 'block'."""
    if mode == "block":
        run(f"kubectl exec deploy/auth-mock --namespace {namespace} -- touch /tmp/block 2>/dev/null || true")
    else:
        run(f"kubectl exec deploy/auth-mock --namespace {namespace} -- rm -f /tmp/block 2>/dev/null || true")


def test_paths(namespace, cfg, plugin_dir):
    """Test all auth paths with pass and block modes."""
    port = cfg["auth"]["port"]
    paths = cfg["auth"]["paths"]
    workload_name = load_values_name(plugin_dir)

    # Find the app pod
    app_pod = get_app_pod_name(namespace)
    if not app_pod:
        return fail("App pod not found")

    # Start port-forward
    pf = subprocess.Popen(
        ["kubectl", "port-forward", app_pod, f"{LOCAL_PORT}:{port}",
         f"--namespace={namespace}"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    time.sleep(3)

    all_ok = True
    try:
        for entry in paths:
            # Substitute __NAME__ with actual workload name
            path = entry["path"].replace("__NAME__", workload_name)
            expect = entry.get("expect_contains")

            # Test pass mode
            set_auth_mode(namespace, "pass")
            time.sleep(0.5)
            res = run(f"curl -s -o /tmp/test_resp -w '%{{http_code}}' http://localhost:{LOCAL_PORT}{path}")
            status = res.stdout.strip()
            if status != "200":
                all_ok = fail(f"  {path}: expected 200, got {status}")
                continue
            ok(f"  {path}: 200 (pass)")

            # Check response body
            if expect:
                with open("/tmp/test_resp") as f:
                    body = f.read()
                if expect.lower() in body.lower():
                    ok(f"  {path}: body contains '{expect}'")
                else:
                    all_ok = fail(f"  {path}: body missing '{expect}'")

            # Test block mode
            set_auth_mode(namespace, "block")
            time.sleep(0.5)
            res = run(f"curl -s -o /dev/null -w '%{{http_code}}' http://localhost:{LOCAL_PORT}{path}")
            status = res.stdout.strip()
            if status not in ("401", "403"):
                all_ok = fail(f"  {path}: expected 401/403, got {status}")
            else:
                ok(f"  {path}: {status} (blocked)")
    finally:
        pf.terminate()
        pf.wait()

    return all_ok


def cleanup(namespace):
    """Delete test namespace in background. Caller should wait_for_namespace_gone() before next deploy."""
    log(f"Cleaning up namespace {namespace}...")
    # Remove PVC finalizers that prevent namespace from terminating
    run(f"kubectl get pvc -n {namespace} -o name 2>/dev/null | xargs -r kubectl patch -n {namespace} -p '{{\"metadata\":{{\"finalizers\":[]}}}}' --type=merge 2>/dev/null || true")
    # Fire deletion in background — no blocking wait
    subprocess.Popen(
        ["kubectl", "delete", "namespace", namespace, "--ignore-not-found"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    log("Cleanup initiated in background")


def wait_for_namespace_gone(namespace, timeout=60):
    """Poll until namespace is fully deleted. Returns True if gone, False if timeout."""
    for _ in range(timeout):
        res = run(f"kubectl get ns {namespace} 2>/dev/null")
        if res.returncode != 0:
            return True
        time.sleep(1)
    return False


def test_plugin(plugin_name):
    """Run full test for one plugin."""
    plugin_dir = ROOT / "plugins" / plugin_name
    config_path = plugin_dir / "test" / "config.yaml"

    if not config_path.exists():
        return fail(f"No test/config.yaml for {plugin_name}")

    with open(config_path) as f:
        cfg = yaml.safe_load(f)

    auth_type = cfg.get("auth", {}).get("type", "none")
    if auth_type == "none":
        ok(f"{plugin_name}: auth=none, skipping")
        return True

    print(f"\n{'='*60}")
    print(f"  Testing: {plugin_name} (auth: {auth_type})")
    print(f"{'='*60}")

    # Deploy / render plugin
    namespace, err = deploy_plugin(plugin_dir, cfg)
    if err:
        return fail(f"{plugin_name}: {err}")

    if DRY_RUN:
        ok(f"{plugin_name}: RENDERING OK")
        return True

    # Deploy mock auth
    err = deploy_mock_auth(namespace)
    if err:
        cleanup(namespace)
        return fail(f"{plugin_name}: {err}")

    # Wait for mock auth
    wait_for_pods(namespace, "app=auth-mock")

    # Wait for app pods to be ready
    if not wait_for_app_pods(namespace):
        log("App pods did not become ready within timeout")

    # Test paths
    result = test_paths(namespace, cfg, plugin_dir)

    # Cleanup
    cleanup(namespace)

    if result:
        ok(f"{plugin_name}: ALL CHECKS PASSED")
    else:
        fail(f"{plugin_name}: SOME CHECKS FAILED")

    return result


def prompt_yes_no(label):
    """Prompt user for y/n input. Returns True for y, False for n."""
    while True:
        try:
            ans = input(f"  [{label}] Is auth working correctly? [y/n] ").strip().lower()
            if ans in ("y", "yes"):
                return True
            if ans in ("n", "no"):
                return False
        except (EOFError, KeyboardInterrupt):
            return None


def deploy_test_interactive(plugin_name, retries, retry_delay):
    """Interactive deploy-test: deploy, test, prompt user, return True/False."""
    plugin_dir = ROOT / "plugins" / plugin_name
    config_path = plugin_dir / "test" / "config.yaml"

    if not config_path.exists():
        return fail(f"No test/config.yaml for {plugin_name}")

    with open(config_path) as f:
        cfg = yaml.safe_load(f)

    auth_type = cfg.get("auth", {}).get("type", "none")
    if auth_type == "none":
        return fail(f"{plugin_name}: auth=none, not supported for deploy-test")

    port = cfg["auth"]["port"]
    paths = cfg["auth"]["paths"]
    workload_name = load_values_name(plugin_dir)

    print(f"\n{'='*60}")
    print(f"  Interactive test: {plugin_name}")
    print(f"{'='*60}")

    # Retry loop
    for attempt in range(1, retries + 1):
        print(f"\n  --- Attempt {attempt}/{retries} ---")

        namespace = f"{NAMESPACE_PREFIX}{plugin_name}"

        # Wait for any previous namespace with the same name to fully terminate
        if not wait_for_namespace_gone(namespace, timeout=45):
            log("Previous namespace still terminating — continuing anyway (will likely fail)")

        # Deploy
        namespace, err = deploy_plugin(plugin_dir, cfg)
        if err:
            log(f"Deploy failed: {err}")
            continue

        # Deploy mock auth
        err = deploy_mock_auth(namespace)
        if err:
            cleanup(namespace)
            continue

        # Wait for mock auth
        wait_for_pods(namespace, "app=auth-mock")

        # Wait for app pods - fast timeout for retry loop
        if not wait_for_app_pods(namespace, timeout=300):
            # Check if CrashLoopBackOff detected (fail returns False, but also prints fail)
            cleanup(namespace)
            if attempt < retries:
                log(f"Retrying in {retry_delay}s...")
                time.sleep(retry_delay)
            continue

        # Get app pod
        app_pod = get_app_pod_name(namespace)
        if not app_pod:
            cleanup(namespace)
            if attempt < retries:
                log(f"Retrying in {retry_delay}s...")
                time.sleep(retry_delay)
            continue

        # Start port-forward
        pf = subprocess.Popen(
            ["kubectl", "port-forward", app_pod, f"{LOCAL_PORT}:{port}",
             f"--namespace={namespace}"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        time.sleep(3)

        pf_alive = True

        try:
            # --- Auth-pass test ---
            set_auth_mode(namespace, "pass")
            time.sleep(0.5)

            for entry in paths:
                path = entry["path"].replace("__NAME__", workload_name)
                res = run(f"curl -s -o /dev/null -w '%{{http_code}}' http://localhost:{LOCAL_PORT}{path}")
                status = res.stdout.strip()

                if status != "200":
                    log(f"{path}: expected 200, got {status}")
                    all_failed = True
                    break
                ok(f"{path}: 200 (pass)")

                # Check response body if expected
                expect = entry.get("expect_contains")
                if expect:
                    res2 = run(f"curl -s http://localhost:{LOCAL_PORT}{path}")
                    if expect.lower() not in res2.stdout.lower():
                        log(f"{path}: body missing '{expect}'")

            print(f"\n  === AUTH-PASS TEST ===")
            print(f"  http://localhost:{LOCAL_PORT}{paths[0]['path'].replace('__NAME__', workload_name)}")
            print(f"  Open in browser and verify the app loads correctly.")
            result = prompt_yes_no("PASS")
            if result is None:
                print("\n  Interrupted. Cleaning up...")
                pf.terminate()
                pf.wait()
                cleanup(namespace)
                return fail(f"{plugin_name}: INTERRUPTED")
            if not result:
                print("  User reported auth-pass test FAILED.")
                pf.terminate()
                pf.wait()
                cleanup(namespace)
                return fail(f"{plugin_name}: AUTH-PASS FAILED (user)")

            # --- Auth-block test ---
            set_auth_mode(namespace, "block")
            time.sleep(0.5)

            for entry in paths:
                path = entry["path"].replace("__NAME__", workload_name)
                res = run(f"curl -s -o /dev/null -w '%{{http_code}}' http://localhost:{LOCAL_PORT}{path}")
                status = res.stdout.strip()
                if status not in ("401", "403"):
                    log(f"{path}: expected 401/403, got {status}")
                else:
                    ok(f"{path}: {status} (blocked)")

            print(f"\n  === AUTH-BLOCK TEST ===")
            print(f"  http://localhost:{LOCAL_PORT}{paths[0]['path'].replace('__NAME__', workload_name)}")
            print(f"  The page should show an error / blank state (auth blocked).")
            result = prompt_yes_no("BLOCK")
            if result is None:
                print("\n  Interrupted. Cleaning up...")
                pf.terminate()
                pf.wait()
                cleanup(namespace)
                return fail(f"{plugin_name}: INTERRUPTED")
            if not result:
                print("  User reported auth-block test FAILED.")
                pf.terminate()
                pf.wait()
                cleanup(namespace)
                return fail(f"{plugin_name}: AUTH-BLOCK FAILED (user)")

            # Both passed
            pf.terminate()
            pf.wait()
            cleanup(namespace)
            ok(f"{plugin_name}: TEST PASSED")
            return True

        except KeyboardInterrupt:
            print("\n  Caught Ctrl+C — cleaning up...")
            if pf_alive:
                pf.terminate()
                pf.wait()
            cleanup(namespace)
            return fail(f"{plugin_name}: INTERRUPTED")
        finally:
            if pf_alive:
                try:
                    pf.terminate()
                    pf.wait()
                except:
                    pass

        # If we got here, this attempt failed — clean up and retry
        cleanup(namespace)
        if attempt < retries:
            log(f"Retrying in {retry_delay}s...")
            time.sleep(retry_delay)

    return fail(f"{plugin_name}: All {retries} attempts exhausted")


def main():
    parser = argparse.ArgumentParser(description="Plugin test harness")
    parser.add_argument("--all", action="store_true", help="Test all auth plugins")
    parser.add_argument("--plugin", type=str, help="Test a single plugin")
    parser.add_argument("--list", action="store_true", help="List auth plugins")
    parser.add_argument("--dry-run", action="store_true", help="Helm template only, no deploy")
    parser.add_argument("--deploy", type=str, help="Interactive deploy-test for a single plugin")
    parser.add_argument("--retries", type=int, default=5, help="Retry count for deploy-test")
    parser.add_argument("--retry-delay", type=int, default=5, help="Seconds between retries")
    args = parser.parse_args()

    global DRY_RUN
    DRY_RUN = args.dry_run

    if args.list:
        for p in find_auth_plugins():
            print(p)
        return

    if args.deploy:
        check_safe_cluster()
        result = deploy_test_interactive(args.deploy, args.retries, args.retry_delay)
        sys.exit(0 if result else 1)
        return

    if not args.plugin and not args.all:
        parser.print_help()
        return

    plugins = [args.plugin] if args.plugin else find_auth_plugins()

    # Safety guard: only allow deploy to Kind clusters
    if not DRY_RUN and not args.list:
        check_safe_cluster()

    passed = 0
    failed = 0
    for p in plugins:
        if test_plugin(p):
            passed += 1
        else:
            failed += 1

    print(f"\n{'='*60}")
    print(f"  Results: {passed} passed, {failed} failed out of {passed+failed}")
    print(f"{'='*60}")

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
