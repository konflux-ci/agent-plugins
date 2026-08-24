---
name: generating-e2e-tests
description: Use when writing E2E tests based on JIRA ticket recommendations, acceptance criteria, or test scenarios. Auto-detects repo framework (Ginkgo, Chainsaw, Godog, CLI binary) and generates tests matching existing patterns.
---

# Writing E2E Tests from JIRA

Generic orchestrator for writing E2E tests from a JIRA ticket. The workflow is the same for
every repo; only the *framework adapter* and *repo profile* change. Load ONE framework file
and ONE repo profile at runtime — never all of them.

**Read the *entire* pasted ticket, not just the "Acceptance Criteria" section.** When present,
the detailed **"What to Test (Exact)" / step-by-step** table is the authoritative
implementation spec (Step 1) — don't stop at the AC, which is only a thin done-checklist (e.g.
"T1 merged and passing"). When that table is absent, derive the plan from the AC, scenarios,
and the repository itself (Step 1).

**When activated:** if the JIRA content is not already available, tell the user "Using
**generating-e2e-tests**. Please paste the JIRA ticket content." and show the checklist. If the
ticket was already pasted, acknowledge with "Using **generating-e2e-tests**." and proceed
directly to Step 1.

## What this skill is (and is not)

**The skill is a code/config generator with static + compile-level QA — not a coverage
verifier, an E2E runner, or a CI executor.**

It writes the E2E tests, diagnostics, coverage instrumentation, and CI/Codecov configuration
required for coverage to be reported *after the developer reviews, commits, and pushes the
changes*. It prepares review-ready changes that it has statically reviewed and compile/syntax
validated where possible; it does not run the E2E scenarios and does not prove coverage went up.

**The boundary is *test execution*, not *validation*: compiling a test ≠ running a test.**

- ✅ **Inspect** repo files with read-only file/search operations — `go.mod`, existing tests,
  `.github/` / `.gitlab-ci.yml`, Makefile, Codecov config, existing scripts.
- ✅ **Write** build/test/coverage/CI commands into Makefiles, scripts, CI workflows, and the
  developer handoff — e.g. `go tool covdata textfmt -i="$GOCOVERDIR" -o coverage.out`.
- ✅ **Validate (no E2E execution)** the generated changes locally — compile-only of Go test
  packages (`go test -c` / `go vet`; `go build` skips `_test.go`), `shellcheck`, YAML
  syntax/schema checks, and Gherkin↔step-definition consistency (see Step 7).
- ❌ **Execute the E2E behavior or delivery pipeline** — running E2E scenarios (`go test`,
  `make test-e2e`, `chainsaw test`, `make … test`), creating KinD/clusters, touching
  AWS/Kerberos/SSO, running CI, `git` commit/push, or calculating/inspecting coverage / Codecov.

**Never** commit, push, trigger CI, run E2E, upload to Codecov, calculate/print/inspect coverage
percentages, or claim a coverage target has been reached. At completion, hand off to the
developer (Step 8).

## Source-of-truth hierarchy

When information conflicts, trust in this order (higher wins):

1. **Existing tests in the current repo** — authoritative
2. **Current repo config / CI** (Makefile, `.github/`, `.gitlab-ci.yml`)
3. **Repo profile** (`repos/<name>.md`) — hints + known constraints only
4. **Framework adapter** (`frameworks/<fw>.md`) — how to write that framework well
5. **This skill's generic defaults**

Profiles and adapters are hints, NOT authoritative templates. Always inspect the current
repo's tests and CI before generating code — Makefile targets, helpers, namespaces, labels,
artifact paths, and env vars may have changed since a profile was written.

## Workflow

```
- [ ] Step 1: Parse the full JIRA ticket (whole ticket, not just acceptance criteria)
- [ ] Step 2: Detect repo structure, framework, existing conventions (load ONE profile + ONE adapter)
- [ ] Step 3: Design test plan
- [ ] Step 4: Ensure failure diagnostics / log collection (before any test code)
- [ ] Step 5: Implement tests
- [ ] Step 6: Prepare CI wiring — diagnostics artifacts (always) + coverage (when in scope) (generator only — never run)
- [ ] Step 7: Validate generated changes (static self-review + compile/lint/syntax — never run E2E)
- [ ] Step 8: Developer handoff (summary + review/push/CI/Codecov instructions)
```

### Step 1: Parse the Full JIRA Ticket

Read everything the user pasted. **When a "What to Test (Exact)" / step-by-step section
exists, treat it as the primary implementation specification** — extract from it: exact
functions, file paths, line numbers, per-test environment/credential needs, and the "Files
Covered". Also extract expected behavior, edge cases, affected components, and any
implementation order (e.g. "P1/P2 before tests"). Treat the **Acceptance Criteria as the
completion checklist**, not the implementation detail. **If that section does not exist, derive
the test plan from the acceptance criteria, scenarios, and the current repository
implementation.** Ask for clarification only when a material ambiguity cannot be resolved from
the repo.

**Classify each item by recommendation type** — the workflow differs:

- **new-test** — author a new test from the criteria (the common case).
- **bug-fix** — the recommendation is to *fix an existing broken/misleading test* (e.g. a
  copy-paste that asserts the wrong resource). Don't write a new test: locate the named
  file/lines, correct them, and confirm by inspection that the test now exercises what it
  claims. A guard/static test may already exist to verify the fix — identify it, compile-validate
  it (Step 7), and include its run command in the developer handoff, but do not run it.
- **infrastructure/process** — CI or tooling change (e.g. artifact upload), not test code.

**Apply only the workflow steps relevant to each classified item.** An infrastructure/process-only
item (e.g. "fix the Codecov upload") must not cause new test code or diagnostics to be created
unless that item requires them. If the ticket recommends no new tests, do not author tests; if it
asks for no coverage work, do not add coverage/Codecov wiring beyond what the item names. Failure
diagnostics (Step 4) are mandatory whenever you author or extend test code — not for a pure
infra/process change that touches no tests.

### Step 2: Detect Repo Structure, Framework, Conventions

```bash
MODULE=$(head -1 go.mod 2>/dev/null | awk '{print $2}')
```

**Monorepo?** Some repos hold multiple `go.mod` files and several test dirs (e.g.
`may/test/e2e/`, `drivers/*/test/e2e/`) with no single `make test-e2e`. Don't assume one
module: `find . -name go.mod` and pick the module + test dir that owns the files the JIRA
names. Detect the framework and run command *per that test dir*, from its existing tests/CI.

Match `MODULE` to a file in [repos/](repos/) and **read only that one**. It names the
framework — then read only that one file in [frameworks/](frameworks/):

| Module suffix | Repo profile | Framework adapter |
|---|---|---|
| `multi-platform-controller` | `repos/multi-platform-controller.md` | `frameworks/ginkgo.md` |
| `etcd-shield` | `repos/etcd-shield.md` | `frameworks/chainsaw.md` |
| `may` | `repos/may.md` | `frameworks/ginkgo.md` |
| `tekton-kueue` | `repos/tekton-kueue.md` | `frameworks/ginkgo.md` |
| `namespace-lister` | `repos/namespace-lister.md` | `frameworks/godog.md` |
| `hermes` | `repos/hermes.md` | `frameworks/cli-shell.md` |
| `sa-cleanup` | `repos/sa-cleanup.md` | `frameworks/cli-shell.md` |
| `external-secrets*` | `repos/external-secrets-operator.md` | `frameworks/ginkgo.md` |

**Unknown repo?** Detect the framework directly and load only its adapter:

| Signal | Adapter |
|---|---|
| `_suite_test.go` + `Describe`/`It` | `frameworks/ginkgo.md` |
| `chainsaw-test.yaml` | `frameworks/chainsaw.md` |
| `.feature` + `godog` import | `frameworks/godog.md` |
| CLI binary, no K8s CRDs | `frameworks/cli-shell.md` |

Then read the repo's existing tests to lock in its actual conventions.

### Step 3: Design Test Plan

Map each acceptance criterion to a concrete test. Respect any order the JIRA specifies.
**Present the plan before implementing.** Two cross-repo principles to apply here:

- **Environment/credential tiering.** Group tests by the credentials they need
  (no-creds/KinD-only → cloud/external: AWS, IBM, Kerberos, real secret stores). Implement in
  tier order, cheapest first. When the repo already has a mechanism for separating
  credential/infrastructure tiers, reuse it. Introduce new labels, Chainsaw file splits, or Go
  build tags only when the JIRA requires it or CI execution needs it. Higher tiers that need
  CI-only infra must be marked clearly as CI-only; include the appropriate run command in
  the developer handoff (Step 8), do not execute it.
- **Deterministic testing of external behavior.** When a behavior depends on something
  unreachable/nondeterministic in a hermetic cluster (external hosts, cloud APIs, live
  metrics), look for the repo's deterministic hook and prefer it — e.g. reserved TEST-NET
  addresses (`192.0.2.x`) for unreachable hosts, or a synthetic PrometheusRule expression for
  metrics. Check existing tests/profile before inventing one. **But if no hook exists** — e.g.
  a CLI whose whole value is real integration with external services (SSO, STS) — that's
  legitimate: don't force determinism or mocks, just document the required credentials and
  flaky-risk instead.

### Step 4: Ensure Failure Diagnostics / Log Collection (before any test code)

When you author or extend test code, failure diagnostics are **non-negotiable and come before
any test code**, even if the JIRA only "recommends" them or omits them entirely — this is the
first thing you implement. (An infrastructure/process-only item that adds no test code skips
this step — see the Step 1 scoping note.)

First decide **reuse vs. create** (this decision recurs for every repo):

- **Reuse** — if a suite already wires diagnostics (e.g. an `AfterEach` calling the repo's
  collector), add the new tests *into that suite* and inherit it. Prefer this.
- **Create** — if the target area has no existing diagnostics harness, scaffold the
  framework-appropriate test/suite structure defined by the loaded adapter, and wire
  diagnostics *before* adding the new test cases.

Then add/confirm collection per the adapter: Ginkgo `CollectDebugInfo` AfterEach, Chainsaw
`catch:` blocks, Godog `ctx.After` on error, or CLI `trap EXIT`. Dump the resources named in
the repo profile. The CI wiring that uploads these diagnostics as artifacts is written in
Step 6, and is **mandatory whenever you add diagnostics — independent of whether coverage work
is in scope.**

### Step 5: Implement Tests

Follow the loaded adapter's patterns and the repo's existing conventions. Every test MUST have
appropriate isolation, MUST be **covered by** failure diagnostics (from Step 4) — either
directly or through its suite/harness, not duplicated in every case — and, **only when the
behavior under test is asynchronous**, explicit timeouts/polling. Do not add async polling to
inherently synchronous tests (e.g. a CLI that returns output + an exit code).

### Step 6: Prepare CI Wiring — Diagnostics Artifacts & Coverage

This step has two **independent** concerns. You prepare CI config, you never run it.

**Diagnostics artifact upload — whenever Step 4 added diagnostics (mandatory, even when coverage
is out of scope).** Wire the Step 4 diagnostics output into CI as an uploaded artifact
(`upload-artifact` for GitHub, `artifacts:` for GitLab) so failure logs survive the run. Do this
even if no coverage work is requested. **Never duplicate** an existing artifact-upload step.

**Coverage reporting — only when coverage/reporting work is in scope** (see the Step 1 scoping
note). Ensure the new E2E tests are wired into the repository's **existing** coverage-reporting
mechanism — use Codecov only where the repo already uses Codecov, and GitLab-native (or whatever
the repo has) elsewhere. Inspect the existing coverage path first; reuse it if it already reports
the new tests, and add or modify configuration only where something is missing. **If no coverage
work was requested and nothing needs changing, skip this part.**

- **Collect:** ensure the files/scripts that gather E2E coverage exist (e.g. `go build -cover` +
  `GOCOVERDIR`, `go tool covdata textfmt -i="$GOCOVERDIR" -o coverage.out`) — as code CI will
  run, not for you to execute.
- **Publish:** ensure CI uploads that coverage to the repository's configured coverage mechanism
  per its existing conventions. **Never duplicate** an existing coverage upload step, flag, or
  coverage artifact.
- If the pipeline already reports the new E2E coverage correctly, leave it unchanged.
- **Do NOT** commit, push, run CI, upload coverage, or calculate/print/inspect/validate
  coverage percentages (see the handoff instruction at the top of this file).

### Step 7: Validate Generated Changes

Before handing changes to the developer, validate the generated files **without executing the
E2E scenarios themselves**. Compiling a test is not running it. Perform two levels:

**1. Static self-review**
- verify imports, package names, identifiers, function signatures and types against the current
  repository
- verify referenced helpers, fixtures, resource files and paths exist
- verify build tags and repository conventions match existing tests
- verify no placeholders, TODOs, invented APIs, or unresolved references remain
- verify framework-specific consistency (see the loaded adapter)

**2. Compile / syntax / lint validation, where locally possible**
- **Go:** compile the generated **test** packages with `go test -c <owning-package>` (compiles
  the test binary, runs nothing) — `go build` skips `_test.go` files, so it does **not** prove a
  test compiles; use `go build` only for production/helper code. `go vet <owning-package>`
  additionally type-checks test files. Never use `go test` / `go test -run=…` — they execute the
  binary and any suite setup. Run all Go validation **from the owning Go module identified in
  Step 2**; for nested/multi-module repos, do not assume validation from the repository root
  includes them.
- **Shell:** `shellcheck` the generated/modified scripts.
- **YAML:** validate syntax/schema where tooling exists (e.g. the Chainsaw schema).
- **Godog:** verify every Gherkin step maps to a step definition and compile the Go glue.

If validation fails, **fix the generated changes and validate again** before handoff.

**Do NOT** (these remain the developer's / CI's): execute E2E scenarios; create test
infrastructure or clusters; access cloud/external credentials (AWS, Kerberos, SSO); run a
Chainsaw suite, run CI, or commit/push; generate, inspect, or validate coverage / Codecov.

### Step 8: Developer Handoff

By this point the changes are statically reviewed and compile/syntax validated (Step 7). The
skill's job ends here — **do not run the E2E scenarios, CI, coverage, or any Git command.**

Summarize what was produced:

- files created / modified
- E2E tests added
- failure diagnostics added
- coverage instrumentation added
- CI/Codecov wiring added
- validation performed (static review + compile/`vet`/`shellcheck`/schema — **E2E not executed**)
- commands the developer / CI should run after review
- any CI-only prerequisites or credentials (e.g. AWS OIDC, Kerberos, PTY, or a repo-provided
  tool the developer must fetch and run — like etcd-shield's etcd-pressure simulator,
  ~35-45 min on a dedicated KinD cluster)

Then instruct the developer to:

1. review the generated changes
2. run the E2E scenarios and any further validation (compile/lint already done in Step 7)
3. commit and push
4. wait for CI
5. if coverage work is in scope, inspect the result in the repo's configured coverage system
   (Codecov, GitLab-native, etc.)
6. if the JIRA defines a numeric/objective coverage target, report whether it was reached

A useful closing line for the handoff: *"Generated changes were statically reviewed and
compile/syntax validated where locally possible. E2E scenarios were not executed."*
