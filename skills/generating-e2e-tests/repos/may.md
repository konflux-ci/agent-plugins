# may

> Profiles are hints and known constraints, NOT authoritative templates.
> Always inspect the current repo's tests and CI before generating code.

- **Framework:** [ginkgo](../frameworks/ginkgo.md) (monorepo, `//go:build e2e` tag)
- **What:** K8s controller monorepo for multi-arch build runners. Successor to MPC with CRDs, autoscaling, Kueue integration
- **5 CRDs:** Runner, Claim, StaticHost, DynamicHost, DynamicHostAutoscaler
- **17 controllers** across 4 modules; Pod Mutating webhook injects scheduling gate `may.konflux-ci.dev/scheduling`

## Test locations (4 separate test dirs)
```
may/test/e2e/                    # Core: 17 test files
drivers/incluster/test/e2e/      # Incluster driver
drivers/aws/test/e2e/            # AWS driver (stubs)
drivers/ibm/test/e2e/            # IBM driver (stubs)
```

## Execution
- CI workflow matrix (no single `make test-e2e`)
- Build tag: `//go:build e2e`
- Cluster: KinD. Credentials: none (drivers are stubs)

## Failure diagnostics (resources to dump)
Runners, Claims, StaticHosts, DynamicHosts, controller logs, events, pods.
Current: partial (AfterEach → GinkgoWriter only). Missing: CRD dumps + upload-artifact.

## Dependencies
cert-manager v1.18.2, OTP server (from MPC), Prometheus. Kueue NOT installed in E2E (gap).

## Known gaps
- DynamicHost incluster E2E tests broken (copy-paste: lines 463, 470, 581 of `drivers/incluster/test/e2e/e2e_test.go` reference StaticHost instead of DynamicHost)
- Kueue not installed in E2E env
