# etcd-shield

> Profiles are hints and known constraints, NOT authoritative templates.
> Always inspect the current repo's tests and CI before generating code.

- **Framework:** [chainsaw](../frameworks/chainsaw.md) (YAML, NOT Ginkgo)
- **What:** Validating admission webhook blocking PipelineRun creation when etcd storage exceeds threshold. JK flip-flop hysteresis: 95% SET, 80% RESET
- **No controllers:** Runnable (`Querier` polls Prometheus every 15s) + webhook (`Handler` reads ConfigMap, returns allow/deny)

## Test locations
```
acceptance/
├── .chainsaw-test/
│   ├── chainsaw-test.yaml       # existing: 2 tests (allow + deny)
│   └── resources/               # PrometheusRule + PipelineRun fixtures
└── config/                      # Kustomize overlays for test env
```

## Execution
- `chainsaw test --no-color=false acceptance/` (no Makefile target)
- Setup: `hack/e2e_tests.sh` (creates KinD cluster `etcd-shield-test`, deploys deps)
- Cluster: KinD. Credentials: none

## Failure diagnostics (resources to dump)
**Currently NONE — critical gap.** Add `catch:` blocks dumping: ConfigMap `etcd-shield-state` (allow field), pod logs (`app=etcd-shield`), events in `etcd-shield` namespace.

## Key config
- Tests toggle alert via PrometheusRule expr `sum(up) > 0` (firing→deny) / `sum(up) < 0` (never→allow)
- State ConfigMap: `etcd-shield-state`, key `allow` ("1"=allow, "0"=deny)
- Prometheus needs a rollout restart to pick up rule changes quickly
- Two ways to drive alert state: the **synthetic PrometheusRule trick** (above) — cheap/deterministic, for
  the existing allow/deny wiring tests; vs. the **etcd-pressure-simulator** (below) — real storage pressure,
  required for the 95%/80% hysteresis tests (T4/T5) where crossing real thresholds is the point.

## etcd-pressure-simulator (hysteresis tests: T4/T5)
Lives **in the etcd-shield repo** at `hack/tools/etcd-pressure-simulator/`
(https://github.com/konflux-ci/etcd-shield/tree/main/hack/tools/etcd-pressure-simulator). It is **not** in
the developer's working tree by default — the developer must fetch it from the repo (pull/checkout the branch
that carries it) before running. It creates **real** etcd storage pressure in a dedicated KinD cluster.
Runtime ~35-45 min per full run → CI-only / long-running. The skill wires it into a dedicated CI workflow and
flags it as a CI-only prerequisite in the developer handoff (SKILL Step 8); it never runs the tool itself.

- **Setup (once):** `./setup.sh` — creates KinD cluster `etcd-shield-test` (256MB etcd quota) + installs
  kube-prometheus-stack scraping etcd. Does NOT deploy etcd-shield or run tests.
- **Commands:** `etcd-pressure.sh status | fill <pct> | drain <pct> | cleanup`
- **Hysteresis flow — add etcd-shield assertions *between* the commands:**
  - `fill 95`  → >95% → SET   → expect **deny**              (~10-12 min)
  - `drain 85` → 80-95% hold zone → still **deny** (hysteresis holds) (~15-18 min)
  - `drain 79` → <80% → RESET → expect **allow**             (~7-9 min)
  - `cleanup`, then `kind delete cluster -n etcd-shield-test`
- **Env vars:** `CLUSTER_NAME` (etcd-shield-test), `HOLD_SAFETY_FLOOR` (81.0), `QUOTA_BYTES` (256MB),
  `PROMETHEUS_LOCAL_PORT` (19091)
- **Scope — the tool ONLY creates pressure states.** It does NOT deploy etcd-shield/PrometheusRule, create
  PipelineRuns, or verify admission/alerts. The E2E test must deploy etcd-shield and add its own assertions.
- **Do NOT run `hack/e2e_tests.sh` between pressure commands** — it manages its own KinD cluster and would
  delete the pressure environment. Write a dedicated E2E test/CI workflow for the pressure flow (P3), and
  do NOT have it create its own cluster (`setup.sh` already owns the cluster lifecycle).

## Dependencies
Prometheus (Helm kube-prometheus-stack), cert-manager v1.18.0, Tekton PipelineRun CRD only (not full Tekton), Chainsaw v0.2.15.

## Known gaps
- No log collection, no artifact upload in `chainsaw-test.yaml`
- Hysteresis (95% SET / 80% RESET) tests need the etcd-pressure-simulator + a dedicated CI workflow (T4/T5,
  P3). The tool lives in the etcd-shield repo (must be fetched from there) — see "etcd-pressure-simulator"
  above for its location, interface, and constraints.
