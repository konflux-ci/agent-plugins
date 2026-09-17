# multi-platform-controller (MPC)

> Profiles are hints and known constraints, NOT authoritative templates.
> Always inspect the current repo's tests and CI before generating code.

- **Framework:** [ginkgo](../frameworks/ginkgo.md) — reference implementation for all repos
- **What:** K8s controller allocating multi-arch build hosts (arm64, s390x, ppc64le, Windows, macOS) for Konflux CI
- **Controller:** `ReconcileTaskRun` — watches Tekton TaskRuns, allocates hosts, creates SSH Secrets

## Test locations
```
test/e2e/
├── common/common.go    # CollectDebugInfo, GetK8sClientOrDie
├── deployment/         # Suite 1: controller pod running
├── taskrun/            # Suite 2: platform allocation (AWS)
└── otelcol/            # Suite 3: S3 log collection (AWS)
```

## Execution
- `make test-e2e` (3 suites sequentially)
- Cluster: KinD + Podman. Credentials: **AWS OIDC** for taskrun/otelcol suites

## Failure diagnostics (resources to dump)
TaskRuns, Pods, Pod logs, Events, controller pod logs. `CollectDebugInfo` → `E2E_DEBUG_LOG_DIR`, uploaded via `upload-artifact`.

## Key config
- ConfigMap `host-config` holds all platform configs; tests patch it to configure strategies
- 4 allocation strategies: Local, HostPool, DynamicResolver, DynamicHostPool
- 3 cloud providers: AWS EC2, IBM Power, IBM Z
- OTP server: separate binary exchanging SSH keys for one-time passwords

## Dependencies
Tekton Pipelines, cert-manager v1.19.2, AWS OIDC.
