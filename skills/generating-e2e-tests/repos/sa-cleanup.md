# sa-cleanup

> Profiles are hints and known constraints, NOT authoritative templates.
> Always inspect the current repo's tests and CI before generating code.

- **Framework:** [cli-shell](../frameworks/cli-shell.md)
- **What:** Go CLI for managing ServiceAccounts at scale
- **6 commands:** audit, delete, create, rotate, remove-admin, notify

## Test locations
Shell scripts running the built binary against a KinD cluster. Not cloned locally.

## Execution
- `go build -cover` + `GOCOVERDIR`
- Cluster: KinD for cluster ops (T1-T5). `notify` (T6) reads state files only — no cluster
- **KinD cluster name must be `prd-e2e`** (phase filtering checks prefix "prd")
- Platform: **GitLab CI** (no CI pipeline exists yet)
- Coverage: when creating CI, follow the org's GitLab pattern (native `coverage:` regex + artifacts); add Codecov only if the org standard requires it — NOT by default

## Failure diagnostics (resources to dump)
ServiceAccounts, Secrets, RoleBindings, Pods, Events. Use `trap ... EXIT` in the test script.

## Known gaps
- No CI pipeline exists yet — needs to be created
- Not cloned locally; inspect remote before generating
