# hermes

> Profiles are hints and known constraints, NOT authoritative templates.
> Always inspect the current repo's tests and CI before generating code.

- **Framework:** [cli-shell](../frameworks/cli-shell.md)
- **What:** Go CLI bridging Kerberos → AWS via SAML SSO. NOT Kubernetes
- **Commands:** `list-roles`, `assume-role`, `interactive`

## Test locations
Shell-based E2E: drive the built binary against real Red Hat SSO + AWS STS, asserting on
stdout/stderr/exit codes (PTY for `interactive`). A `test/` dir with an existing mock-based
**unit** suite already exists on GitLab — add E2E separately; do not duplicate the unit tests.
Real code lives on GitLab; the local scaffold under `hack/tools/` is test tooling only.

## Execution
- `go build -cover` + `GOCOVERDIR` for binary-level coverage
- Cluster: **none** (no KinD). Credentials: Kerberos keytab
- Platform: **GitLab CI** (not GitHub)
- Coverage: **GitLab-native** (`coverage:` regex + `coverage.out`/`coverage.html` artifacts), NOT Codecov

## Failure diagnostics
Binary stdout/stderr + exit codes. Use `trap ... EXIT` in the test script.

## Dependencies
Kerberos keytab (`SA_KONFLUX_INFRA_TERRAFORM_KEYTAB`), krb5-user, PTY tool (for `interactive` mode).

## Notes
- Tests run the binary against Red Hat SSO + AWS STS
- `interactive` command needs a PTY, not piped stdin
