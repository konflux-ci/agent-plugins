# Godog Adapter

How to write Godog / Cucumber BDD (Gherkin + Go steps) E2E tests. Load this when the
detected repo uses Godog. Repos: namespace-lister.

## Style Rules

- Behavior lives in `.feature` files (Gherkin); glue lives in Go step definitions
- Scenarios isolate via per-scenario context (run id / scoped ServiceAccount), NOT namespaces
- Godog has NO built-in `AfterEach` — use `ctx.After(...)` hooks for cleanup AND diagnostics
- Acceptance tests usually live in a SEPARATE Go module (`acceptance/go.mod`)
- Keep step regexes stable — they are the public contract of the suite

## Gherkin Feature File

```gherkin
# features/namespace-access.feature
Feature: Namespace access listing
  As a user with limited RBAC permissions
  I want to see only namespaces I have access to

  Scenario: User with single namespace access
    Given a cluster with namespaces "default,test-ns-1,test-ns-2"
    And user "test-user" has role binding in "test-ns-1"
    When user "test-user" requests namespace list
    Then the response should contain "test-ns-1"
    And the response should not contain "test-ns-2"
```

## Go Step Definitions + Hooks

```go
func InitializeScenario(ctx *godog.ScenarioContext) {
    s := &suite.Suite{}

    ctx.Before(func(ctx context.Context, sc *godog.Scenario) (context.Context, error) {
        return s.Setup(ctx)
    })

    // Godog's equivalent of AfterEach — put cleanup AND failure diagnostics here.
    ctx.After(func(ctx context.Context, sc *godog.Scenario, err error) (context.Context, error) {
        if err != nil {
            s.CollectDiagnostics(ctx, sc) // dump pod logs, events, RBAC resources
        }
        return s.Teardown(ctx)
    })

    ctx.Step(`^a cluster with namespaces "([^"]*)"$`, s.ClusterWithNamespaces)
    ctx.Step(`^user "([^"]*)" has role binding in "([^"]*)"$`, s.UserHasRoleBinding)
    ctx.Step(`^user "([^"]*)" requests namespace list$`, s.UserRequestsNamespaces)
    ctx.Step(`^the response should contain "([^"]*)"$`, s.ResponseContains)
    ctx.Step(`^the response should not contain "([^"]*)"$`, s.ResponseNotContains)
}
```

## Failure Diagnostics

Because there is no framework-level failure hook, add collection explicitly in `ctx.After`
when `err != nil`. Dump the resources named in the repo profile (for namespace-lister:
Namespaces, RoleBindings, ClusterRoleBindings) plus pod logs and events.

## Separate Go Module Structure

```
acceptance/
├── go.mod              # Independent module — run tests from here
├── test/
│   ├── dumb-proxy/     # make -C acceptance/test/dumb-proxy
│   └── smart-proxy/    # make -C acceptance/test/smart-proxy
└── pkg/
    └── suite/          # Shared step definitions + hooks
```

## Commands: what the skill validates vs. what only the developer/CI runs

Per SKILL Step 7 the skill **may validate** the generated code without running the scenarios:
verify every Gherkin step maps to a step definition (and vice-versa) and compile the Go glue
from the acceptance module — e.g. `go vet ./...` / `go test -c ./...` (compiles, runs nothing).

The following **run the scenarios** — developer / CI only, the skill never executes them:

```bash
make -C acceptance/test/dumb-proxy prepare
make -C acceptance/test/dumb-proxy test
make -C acceptance/test/smart-proxy test
```
