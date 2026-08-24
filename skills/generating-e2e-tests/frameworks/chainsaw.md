# Chainsaw Adapter

How to write Kyverno Chainsaw (declarative YAML) E2E tests. Load this when the detected
repo uses Chainsaw. Repos: etcd-shield.

## Style Rules

- Tests are YAML `kind: Test` (chainsaw.kyverno.io/v1alpha1), NOT Go
- One `spec.namespace` per test → isolation is built in
- `try:` holds the steps; `catch:` holds failure diagnostics (this is where log collection lives)
- Use `assert:` for expected state, `error:` for expected rejection
- `script:` steps run raw shell (kubectl) when declarative ops aren't enough
- Keep fixtures under `resources/`, referenced by relative path

## Declarative Test with Failure Diagnostics

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/kyverno/chainsaw/main/.schemas/json/test-chainsaw-v1alpha1.json
apiVersion: chainsaw.kyverno.io/v1alpha1
kind: Test
metadata:
  name: test-feature
spec:
  description: |
    What this test verifies
  concurrent: false
  namespace: 'test-feature'
  steps:
  - name: when-precondition
    try:
    - apply:
        file: ./resources/precondition.yaml
    - assert:
        resource:
          apiVersion: v1
          kind: ConfigMap
          metadata:
            name: etcd-shield-state
          data:
            allow: "1"
    catch:            # runs only if the step fails — this IS the diagnostics
    - describe:
        apiVersion: v1
        kind: Pod
        namespace: etcd-shield
    - podLogs:
        namespace: etcd-shield
        selector: app=etcd-shield
    - events:
        namespace: etcd-shield
  - name: then-expected-outcome
    try:
    - error:                       # expect this resource to be REJECTED
        timeout: 60s
        file: ./resources/pipelinerun.yaml
```

## Expect Allowed vs Denied

```yaml
# expect the resource to be admitted:
- apply:
    file: ./resources/pipelinerun.yaml

# expect the resource to be rejected by the webhook:
- error:
    file: ./resources/pipelinerun.yaml
```

## PrometheusRule Trick (etcd-shield)

Tests toggle alert state synthetically instead of generating real etcd pressure:

```yaml
expr: sum(up) > 0   # always firing  → deny
expr: sum(up) < 0   # never firing   → allow
```

Prometheus may need a restart to pick up rule changes quickly:

```yaml
- script:
    timeout: 60s
    content: |
      kubectl get statefulsets -n prometheus -o name --no-headers | \
        xargs -I{} -P8 kubectl rollout restart -n prometheus {}
- script:
    timeout: 300s
    content: kubectl rollout status -n prometheus statefulsets
```

## Commands: what the skill validates vs. what only the developer/CI runs

Per SKILL Step 7 the skill **may validate** the generated YAML without running the suite —
check it against the Chainsaw schema (the `# yaml-language-server: $schema=…` header above)
and confirm every referenced `resources/` file exists.

Running the suite is **developer / CI only** — the skill never executes it:

```bash
chainsaw test --no-color=false acceptance/
```

No Makefile target by default — CI invokes `chainsaw test` directly.
