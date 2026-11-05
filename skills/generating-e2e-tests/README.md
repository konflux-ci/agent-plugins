# generating-e2e-tests

A Claude Code skill that turns a JIRA ticket into **review-ready E2E test changes** for a
Konflux repository — tests, failure diagnostics, and the coverage/CI wiring needed to report
them — without ever running the pipeline itself.

## The problem it solves

Each Konflux repo uses a different E2E framework (Ginkgo, Chainsaw, Godog, or a CLI/shell
harness) with its own conventions, diagnostics, and coverage plumbing. Writing E2E from a JIRA
ticket means re-learning all of that every time. This skill encodes the shared workflow once
and swaps in a per-repo profile + per-framework adapter at runtime.

## How to use it

1. In a repo (or with the repo in context), invoke the skill and paste the JIRA ticket.
2. The skill parses the ticket, auto-detects the repo's framework and conventions, and presents
   a test plan.
3. On approval it writes the tests, failure diagnostics, and coverage/CI configuration.
4. It stops with a **developer handoff** summarizing what changed and what you should run.

**You** review, run the E2E scenarios and any additional validation you want, commit, push, and
check coverage. The skill compiles/statically validates what it wrote (see below) but never runs
the E2E scenarios or the pipeline.

## What it does — and does not

The skill is a **code/config generator with static + compile-level QA — not an E2E runner, a
coverage verifier, or a CI executor**. It **inspects** the repo (read-only), **writes** the E2E
tests, failure diagnostics, coverage instrumentation, and CI/coverage-upload configuration, and
**validates** what it wrote where possible *without running it* — compile-only (`go build`/`go
vet`/`go test -c`), `shellcheck`, YAML/schema, and Gherkin↔step checks. It never **runs the E2E
scenarios or the delivery pipeline** — no E2E run, cluster/cloud/credentials, CI, Git, or
coverage/Codecov calculation. Running E2E, push, CI, and coverage verification are the developer's.
The boundary is *test execution*, not *validation*: compiling a test ≠ running a test.

## Supported repos & frameworks

| Framework | Adapter | Repos |
|---|---|---|
| Ginkgo v2 + Gomega (Go) | `frameworks/ginkgo.md` | multi-platform-controller, may, tekton-kueue, external-secrets-operator |
| Kyverno Chainsaw (YAML) | `frameworks/chainsaw.md` | etcd-shield |
| Godog / Cucumber BDD | `frameworks/godog.md` | namespace-lister |
| Go CLI (shell-driven) | `frameworks/cli-shell.md` | hermes, sa-cleanup |

An unknown repo is detected by signal (a `_suite_test.go`, `chainsaw-test.yaml`, a `.feature`
file, or a CLI binary) and mapped to the matching adapter.

## Structure

```
SKILL.md              # the orchestrator: 8-step workflow + source-of-truth hierarchy
frameworks/           # how to write each framework well (load ONE)
├── ginkgo.md
├── chainsaw.md
├── godog.md
└── cli-shell.md
repos/                # per-repo hints + known constraints (load ONE)
└── <repo>.md
```

At runtime the skill loads `SKILL.md` + exactly ONE framework adapter + ONE repo profile.
Profiles and adapters are **hints, not authoritative templates** — the skill always inspects the
repo's actual tests and CI before generating code.

## Testing

No automated pressure-test suite (`tests/scenarios.yaml`) has been added yet — a TDD suite in the
repository's standard RED-GREEN-REFACTOR format is a planned follow-up.
