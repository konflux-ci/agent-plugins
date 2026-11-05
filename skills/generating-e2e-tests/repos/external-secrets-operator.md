# external-secrets-operator (ESO)

> Profiles are hints and known constraints, NOT authoritative templates.
> Always inspect the current repo's tests and CI before generating code.

- **Framework:** [ginkgo](../frameworks/ginkgo.md) (upstream); wrapper repo has no tests
- **What:** Wrapper repo (git submodule tracking upstream external-secrets v2.0.1)
- **9 controllers, 23 CRDs, 3 webhooks** — all from upstream

## Test locations
No tests in the wrapper. Not cloned locally. Upstream carries the E2E suite.

## Execution
- Cluster: KinD. Credentials: **Fake provider** (no real cloud secret store needed)

## Recommended tests
Use the Fake provider for KinD-based tests: ExternalSecret sync, webhook validation, template transformation.

## Failure diagnostics (resources to dump)
ExternalSecrets, SecretStores, generated Secrets, controller logs, events.

## Notes
- Wrapper only — most work happens upstream; confirm what belongs in the wrapper vs upstream before generating
