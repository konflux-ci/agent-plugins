# tekton-kueue

> Profiles are hints and known constraints, NOT authoritative templates.
> Always inspect the current repo's tests and CI before generating code.

- **Framework:** [ginkgo](../frameworks/ginkgo.md)
- **What:** Mutating webhook + controller bridging Tekton PipelineRuns with Kueue. Built-in CEL engine for dynamic mutations
- **2 controllers + webhook:** `KueuePipelineRunController` (wraps PipelineRun as Kueue GenericJob), `ConfigMapReconciler` (watches ConfigMap `tekton-kueue-config`), Mutating webhook (intercepts PipelineRun CREATE, runs CEL)

## Test locations
```
test/e2e/
├── e2e_suite_test.go    # BeforeSuite installs deps
└── e2e_test.go          # All tests (single large file)
```

## Execution
- `make test-e2e`
- Cluster: KinD + Podman. Credentials: none

## Failure diagnostics (resources to dump)
PipelineRuns, Workloads, ConfigMap `tekton-kueue-config`, pod logs, events.
Current: partial (AfterEach → stdout). Missing: ConfigMap dumps + upload-artifact.

## Key config
- CEL functions: `annotation()`, `label()`, `resource()` (summing), `multiKueue()` (2 overloads), `managedBy()`, `priority()`, `priorityClass()`
- CEL context vars: `pacEventType`, `pacTestEventType`, `plrNamespace`, `pipelineRun`

## Dependencies
Kueue (from go.mod), Tekton v0.70.0, cert-manager v1.19.2, Prometheus Operator v0.77.1.

## Known gaps
- coverport-cli misses webhook pod coverage. Fix: add `--label-selector=app.kubernetes.io/name=tekton-kueue-webhook`
