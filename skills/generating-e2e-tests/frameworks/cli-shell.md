# CLI / Shell Adapter

How to write E2E tests for Go CLI binaries (no controller, coverage via instrumented
binary). Load this when the detected repo is a CLI tool. Repos: hermes, sa-cleanup.

## Style Rules

- Build the binary with `-cover`, run it as a subprocess, assert on stdout/stderr/exit code
- If the CLI writes output files (state/rotation JSON, CSVs, reports), assert on their
  **contents** too — not just stdout — and archive them as failure artifacts (see `teardown`)
- Collect coverage via `GOCOVERDIR`
- Isolation is per-test resource naming (namespace/SA prefix) or temp dirs, not K8s namespaces
- Use `trap ... EXIT` for cleanup AND diagnostics — this is the failure-collection hook;
  capture `rc=$?` first and `exit "$rc"` last so cleanup/coverage-export failures never mask the
  test's exit code
- Some CLIs need a cluster (KinD), some don't — check the repo profile

## Build with Coverage

```bash
go build -cover -o ./bin/tool-name ./cmd/tool-name
export GOCOVERDIR=$(mktemp -d)
```

## Shell Test Script with Diagnostics on Failure

```bash
#!/bin/bash
set -euo pipefail

BINARY="./bin/tool-name"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

setup_test_resources() {
    kubectl create namespace prd-e2e-test || true
    kubectl create serviceaccount test-sa -n prd-e2e-test
}

teardown() {
    rc=$?    # preserve the test's exit code before anything below can change it
    set +e   # cleanup/diagnostics/coverage failures must not override rc
    # diagnostics first (only meaningful on failure, cheap to always run)
    kubectl get events -n prd-e2e-test --sort-by=.lastTimestamp > e2e-debug-logs/events.txt || true
    kubectl get sa,secrets,rolebindings -n prd-e2e-test -o yaml > e2e-debug-logs/rbac.yaml || true
    # cleanup
    kubectl delete namespace prd-e2e-test --ignore-not-found || true
    if [ -n "${GOCOVERDIR:-}" ]; then
        # produce coverage.out for the repo's coverage upload — do NOT print or inspect a percentage
        go tool covdata textfmt -i="$GOCOVERDIR" -o coverage.out || true
    fi
    exit "$rc"   # exit with the original test result, not cleanup's
}
trap teardown EXIT

mkdir -p e2e-debug-logs
setup_test_resources

echo "=== Test: audit command ==="
output=$($BINARY audit --kubeconfig "$KUBECONFIG" --phase prd-e2e)
echo "$output" | grep -q "expected string" || { echo "FAIL: audit"; exit 1; }

echo "=== All tests passed ==="
```

## Testing Interactive / PTY Commands

For commands with an interactive mode (e.g. hermes `interactive`), drive them through a PTY
tool rather than piping stdin, so the binary sees a real terminal.

## Non-Cluster CLIs

Some CLIs (or subcommands) never touch a cluster — they read state files or call external
APIs. For those, no KinD; assert purely on binary I/O and exit codes. Check the repo profile
for which subcommands need a cluster vs credentials (e.g. Kerberos keytab).

## Coverage Upload Target — CLI repos are GitLab, not Codecov

Both current CLI repos are **GitLab CI and do not use Codecov** — never inject a
`codecov/codecov-action` step. But their coverage state differs:

- **hermes** — a GitLab-native coverage flow already exists (`coverage:` regex over
  `go tool cover -func`, plus `coverage.out` / `coverage.html` artifacts). Inspect
  `.gitlab-ci.yml` and **reuse** it.
- **sa-cleanup** — **no CI pipeline exists yet.** When coverage work is in scope, **create** the
  missing GitLab CI/coverage flow (native `coverage:` regex + artifacts); do not assume a
  pipeline is there to reuse.

## Commands: what the skill validates vs. what only the developer/CI runs

Per SKILL Step 7 the skill **may validate** the generated code/scripts without running the
E2E flow:

```bash
go vet ./...
go test -c ./...                   # compile any generated _test.go packages, run nothing
go build ./...                     # production/helper code only — skips _test.go
shellcheck ./test/e2e/*.sh         # lint the generated/modified scripts
```

The following **run the E2E flow / produce coverage** — developer / CI only, the skill never
executes them (it writes them into scripts / CI config):

```bash
go build -cover -o ./bin/ ./...
bash ./test/e2e/run.sh
go tool covdata textfmt -i="$GOCOVERDIR" -o coverage.out   # input for the repo's coverage upload, not for local inspection
```
