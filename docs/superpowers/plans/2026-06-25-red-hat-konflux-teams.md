# red-hat-konflux-teams Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a skill that maps repos across Konflux-related GitHub orgs (`konflux-ci`, `hermetoproject`, `conforma`) to Red Hat teams and their JIRA metadata, with maintenance scripts to detect new repos.

**Architecture:** YAML source files (per-team + repo-owners mapping) feed a Python generator that produces markdown reference docs. A bash wrapper calls `gh` to fetch the live repo list from all tracked orgs, then invokes the generator. Repos are keyed as `org/repo` throughout.

**Tech Stack:** Python 3 (PyYAML), Bash, `gh` CLI

---

### Task 1: Create team YAML data files

**Files:**
- Create: `skills/red-hat-konflux-teams/data/teams/build.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/java-builds.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/builds-for-openshift.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/collective.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/conforma.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/container-health.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/cue.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/developer-productivity.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/fullsend.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/infrastructure.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/integration.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/kubearchive.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/marketplace.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/cpaas-and-traditional.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/observability.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/operator-foundry.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/performance.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/pipelines.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/release.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/release-engineering.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/rhel-on-konflux.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/service-enhancement.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/spre.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/support-ops.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/ui.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/uxd.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/vanguard.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/centos-stream.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/rhel-product-engineering-workflows.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/rok-migration.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/rpm-storage-mechanism.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/rpm-build-process.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/rpm-delivery-experience.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/rpm-package-integration.yaml`
- Create: `skills/red-hat-konflux-teams/data/teams/rpm-release-workflow.yaml`

Each file follows this format:

```yaml
name: <Display Name from spreadsheet>
jira_project: <JIRA project key>
jira_components:
  - <component name>  # or empty list if N/A
description: >
  <Brief scope description from spreadsheet>
```

- [ ] **Step 1: Create all team YAML files**

Source data from the spreadsheet (already fetched). Here is every team file:

**`data/teams/build.yaml`**:
```yaml
name: Build
jira_project: STONEBLD
jira_components:
  - Build
description: >
  Build pipelines, .tekton/ yaml files, SBOMs (partially),
  pipeline-migration-tool, prefetching and hermetic builds using Hermeto.
  Component nudging. Review PRs in build-definitions, build-service,
  image-controller.
```

**`data/teams/java-builds.yaml`**:
```yaml
name: Java Builds
jira_project: STONEBLD
jira_components: []
description: >
  Java builds on Konflux.
```

**`data/teams/builds-for-openshift.yaml`**:
```yaml
name: Builds for OpenShift
jira_project: BUILD
jira_components: []
description: >
  OCP Builds.
```

**`data/teams/collective.yaml`**:
```yaml
name: Collective
jira_project: ISV
jira_components:
  - Pyxis
  - Radas
  - Sbom
description: >
  Pyxis, container, and product metadata visible at catalog.redhat.com.
  Container signature storage. Signing-related issues (Radas).
  SBOM generation, processing, and quality.
```

**`data/teams/conforma.yaml`**:
```yaml
name: Conforma
jira_project: EC
jira_components:
  - Conforma
description: >
  Anything related to Conforma/EC, policies.
```

**`data/teams/container-health.yaml`**:
```yaml
name: Container Health
jira_project: CWFHEALTH
jira_components:
  - Mintmaker
  - Diffused
description: >
  MintMaker and Renovate: issues and functionality with Renovate PRs
  opened against repositories. Automatic detection of CVEs fixed by release
  (Diffused).
```

**`data/teams/cue.yaml`**:
```yaml
name: CUE
jira_project: KFLUXUI
jira_components: []
description: >
  Konflux UI + UX integration.
```

**`data/teams/developer-productivity.yaml`**:
```yaml
name: Developer Productivity
jira_project: KFLUXDP
jira_components:
  - DevProd
description: >
  Devlake, Devlake MCP, engineering metrics, team weekly updates,
  Tekton-integration-catalog, konflux component CI. FinOps:
  cost-saving initiatives, right-sizing resources, cloud accounts.
```

**`data/teams/fullsend.yaml`**:
```yaml
name: Fullsend
jira_project: ""
jira_components: []
description: >
  Fullsend platform.
```

**`data/teams/infrastructure.yaml`**:
```yaml
name: Infrastructure
jira_project: KFLUXINFRA
jira_components:
  - Infrastructure
description: >
  Infrastructure compute, network, storage, authentication, authorization,
  ArgoCD for Konflux deployment, multi-arch builds (MPC), Kyverno,
  namespace-lister, kueue, etcd-shield.
```

**`data/teams/integration.yaml`**:
```yaml
name: Integration
jira_project: STONEINTG
jira_components:
  - Integration
description: >
  Integration tests against Snapshot, security tests from build-pipelines
  (e.g. clair-scan, clamav-scan, deprecated-image-check), Snapshot
  Garbage Collection.
```

**`data/teams/kubearchive.yaml`**:
```yaml
name: Kubearchive
jira_project: KAR
jira_components:
  - Kubearchive
description: >
  Store Snapshots, Releases, PipelineRuns, TaskRuns and Pods in an
  external DB. Has a REST API compatible with Kubernetes clients.
```

**`data/teams/marketplace.yaml`**:
```yaml
name: Marketplace
jira_project: ""
jira_components: []
description: >
  Stratosphere.
```

**`data/teams/cpaas-and-traditional.yaml`**:
```yaml
name: CPaaS and Traditional
jira_project: ""
jira_components: []
description: >
  Continuous Productization as a Service + Traditional combined.
```

**`data/teams/observability.yaml`**:
```yaml
name: Observability
jira_project: PVO11Y
jira_components:
  - O11Y
description: >
  Design and implement observability solutions for Konflux both on the
  global and tenant level, maintaining and expanding the observability
  toolset. Includes cost management to support business processes.
```

**`data/teams/operator-foundry.yaml`**:
```yaml
name: Operator Foundry
jira_project: CLOUDDST
jira_components:
  - Operators
description: >
  OLM Operators (RH, Certified, Community), File Based Configs (FBC),
  Operator Indexes/Catalogs, FIPS compliance testing, Traditional
  Container/Operator Test Pipelines.
```

**`data/teams/performance.yaml`**:
```yaml
name: Performance
jira_project: KONFLUX
jira_components:
  - Performance
description: >
  Konflux perf and scale issues, Load Test Probe run issues.
```

**`data/teams/pipelines.yaml`**:
```yaml
name: Pipelines
jira_project: SRVKP
jira_components:
  - Pipelines
description: >
  Install and upgrade pipeline components across Konflux environments,
  Pipelines-as-Code component queries, troubleshoot customer PipelineRun
  failures using splunk and results logs, respond to Pipeline component
  alerts.
```

**`data/teams/release.yaml`**:
```yaml
name: Release
jira_project: RELEASE
jira_components:
  - Release
description: >
  Release admission, release pipelines, FBC, Signing, release monitoring,
  release advisories, operators, collectors. Review PRs in
  release-service-catalog.
```

**`data/teams/release-engineering.yaml`**:
```yaml
name: Release Engineering
jira_project: RELDEV
jira_components:
  - ContainerReleng
description: >
  ReleasePlanAdmission (RPA) configuration, konflux-release-data MRs
  (excluding tenants-config), quay.io/redhat-services-prod, eng-id
  assistance, policy exceptions, macos or windows binary signing,
  secret management for managed cluster.
```

**`data/teams/rhel-on-konflux.yaml`**:
```yaml
name: RHEL on Konflux
jira_project: ROK
jira_components:
  - RoK
description: >
  Everything RHEL on Konflux. Umbrella team for ROK sub-teams.
```

**`data/teams/service-enhancement.yaml`**:
```yaml
name: Service Enhancement
jira_project: KFLUXSE
jira_components: []
description: >
  Cross-service Konflux feature development, user-feedback-driven
  enhancements, platform-wide repo health and adoption.
```

**`data/teams/spre.yaml`**:
```yaml
name: Spre
jira_project: SPRE
jira_components:
  - Spre
description: >
  Konflux incident/outage response.
```

**`data/teams/support-ops.yaml`**:
```yaml
name: Support Ops
jira_project: KFLUXSPRT
jira_components:
  - SupportOps
description: >
  Ideas on how to improve user support for Konflux.
```

**`data/teams/ui.yaml`**:
```yaml
name: UI
jira_project: KFLUXUI
jira_components:
  - UI
description: >
  UI elements, error messages, site reloads, loading times.
```

**`data/teams/uxd.yaml`**:
```yaml
name: UXD
jira_project: DTUX
jira_components:
  - UXD
description: >
  UX Design and Research.
```

**`data/teams/vanguard.yaml`**:
```yaml
name: Vanguard
jira_project: KFLUXVNGD
jira_components:
  - Vanguard
description: >
  Konflux-CI Upstream, Caching, Project Controller (multi-version),
  Environment as a Service (EaaS), PipelineRun Results Notifier,
  Internal Cluster Tooling.
```

**`data/teams/centos-stream.yaml`**:
```yaml
name: CentOS Stream
jira_project: CS
jira_components:
  - CentOS Stream
description: >
  Adoption of Konflux in CentOS Stream workflows.
```

**`data/teams/rhel-product-engineering-workflows.yaml`**:
```yaml
name: RHEL Product Engineering Workflows
jira_project: ROK
jira_components:
  - RHEL Process
description: >
  Integration of Konflux with RHEL Engineering development process,
  RHEL on Gitlab, RHEL package testing workflows.
```

**`data/teams/rok-migration.yaml`**:
```yaml
name: RoK Migration
jira_project: KFLUXMIG
jira_components:
  - RoK Migration
description: >
  Driving the onboarding of RHEL engineering to Konflux RPM pipeline.
```

**`data/teams/rpm-storage-mechanism.yaml`**:
```yaml
name: RPM Storage Mechanism
jira_project: ROK
jira_components:
  - RPM Storage
description: >
  Implementation of RPM Artifact Storage, embargoed content
  classification.
```

**`data/teams/rpm-build-process.yaml`**:
```yaml
name: RPM Build Process
jira_project: RHELBLD
jira_components:
  - RPM Build
description: >
  RPM Build pipeline, issues with SBOM, Mock.
```

**`data/teams/rpm-delivery-experience.yaml`**:
```yaml
name: RPM Delivery Experience
jira_project: ROK
jira_components:
  - RPM Delivery
description: >
  RPM delivery pipeline development, pushing to CDN.
```

**`data/teams/rpm-package-integration.yaml`**:
```yaml
name: RPM Package Integration
jira_project: ROK
jira_components:
  - RPM Package Integration
description: >
  Integration of RPM packages to composite artifacts.
```

**`data/teams/rpm-release-workflow.yaml`**:
```yaml
name: RPM Release Workflow
jira_project: ROK
jira_components:
  - RPM Release
description: >
  RHEL release configuration setup, Release Plans,
  Package Collections, Conforma.
```

- [ ] **Step 2: Verify all YAML files parse correctly**

Run: `python3 -c "import yaml, glob; [yaml.safe_load(open(f)) for f in glob.glob('skills/red-hat-konflux-teams/data/teams/*.yaml')]; print('All YAML files valid')"` from the repo root.

Expected: `All YAML files valid`

- [ ] **Step 3: Commit**

```bash
git add skills/red-hat-konflux-teams/data/teams/
git commit -s -S -m "feat(red-hat-konflux-teams): Add team YAML data files

Populated from Red Hat Konflux Team Structure spreadsheet.
35 teams with JIRA project keys and component mappings.

Assisted-by: Claude Opus 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Create repo-owners.yaml with initial known mappings

**Files:**
- Create: `skills/red-hat-konflux-teams/data/repo-owners.yaml`

Seed with mappings where the repo name clearly maps to a team. Leave the rest for the unassociated list.

- [ ] **Step 1: Create repo-owners.yaml with obvious mappings**

```yaml
# Repo ownership mapping for Konflux-related GitHub orgs.
# Keys use org/repo format. Each maps to a list of {team, clarification} entries.
# The team value must match a filename (without .yaml) in data/teams/.
# Repos not listed here will appear in references/unassociated-repos.md.

# --- konflux-ci org ---

konflux-ci/application-api:
  - team: vanguard
    clarification: Application and Component API definitions

konflux-ci/build-definitions:
  - team: build
    clarification: Build pipeline definitions and task bundles

konflux-ci/build-service:
  - team: build
    clarification: Build service controller

konflux-ci/build-trusted-artifacts:
  - team: build
    clarification: Trusted artifacts for build pipelines

konflux-ci/build-pipeline-tasks:
  - team: build
    clarification: Individual build pipeline tasks

konflux-ci/build-tasks-dockerfiles:
  - team: build
    clarification: Dockerfiles for build task images

konflux-ci/buildah-container:
  - team: build
    clarification: Buildah container image for builds

konflux-ci/caching:
  - team: vanguard
    clarification: Caching infrastructure

konflux-ci/clair-in-ci-db:
  - team: integration
    clarification: Clair vulnerability database for CI scanning

konflux-ci/diffused:
  - team: container-health
    clarification: Automatic CVE detection for releases

konflux-ci/e2e-tests:
  - team: integration
    clarification: End-to-end test suite

konflux-ci/etcd-shield:
  - team: infrastructure
    clarification: etcd protection tooling

konflux-ci/image-controller:
  - team: build
    clarification: Image repository management controller

konflux-ci/integration-service:
  - team: integration
    clarification: Integration service controller

konflux-ci/integration-service-utils:
  - team: integration
    clarification: Shared utilities for integration service

konflux-ci/integration-examples:
  - team: integration
    clarification: Example integration test configurations

konflux-ci/konflux-ui:
  - team: ui
    clarification: Konflux web UI frontend
  - team: cue
    clarification: UX integration aspects

konflux-ci/konflux-ci:
  - team: vanguard
    clarification: Upstream Konflux CI deployment

konflux-ci/mintmaker:
  - team: container-health
    clarification: MintMaker dependency update service

konflux-ci/mintmaker-renovate-image:
  - team: container-health
    clarification: Renovate container image for MintMaker

konflux-ci/mintmaker-osv-database:
  - team: container-health
    clarification: OSV vulnerability database for MintMaker

konflux-ci/mintmaker-presets:
  - team: container-health
    clarification: Default configuration presets for MintMaker

konflux-ci/mintmaker-schedule-calculator:
  - team: container-health
    clarification: Scheduling logic for MintMaker updates

konflux-ci/multi-platform-controller:
  - team: infrastructure
    clarification: Multi-architecture build controller

konflux-ci/multi-arch:
  - team: infrastructure
    clarification: Multi-architecture build support

konflux-ci/namespace-lister:
  - team: infrastructure
    clarification: Namespace listing utility

konflux-ci/kyverno:
  - team: infrastructure
    clarification: Kyverno policy engine deployment

konflux-ci/kueue-external-admission:
  - team: infrastructure
    clarification: Kueue external admission webhook

konflux-ci/release-service:
  - team: release
    clarification: Release service controller

konflux-ci/release-service-catalog:
  - team: release
    clarification: Release pipeline catalog

konflux-ci/release-service-utils:
  - team: release
    clarification: Shared utilities for release service

konflux-ci/release-service-automations:
  - team: release
    clarification: Release automation scripts

konflux-ci/release-service-collectors:
  - team: release
    clarification: Data collectors for release monitoring

konflux-ci/release-service-docs:
  - team: release
    clarification: Release service documentation

konflux-ci/release-service-monitor:
  - team: release
    clarification: Release monitoring dashboards and alerts

konflux-ci/release-service-catalog-e2e-base:
  - team: release
    clarification: Base images for release catalog e2e tests

konflux-ci/notification-service:
  - team: vanguard
    clarification: PipelineRun results notifier

konflux-ci/project-controller:
  - team: vanguard
    clarification: Multi-version project controller

konflux-ci/pipeline-migration-tool:
  - team: build
    clarification: Tool for migrating pipeline configurations

konflux-ci/tekton-integration-catalog:
  - team: developer-productivity
    clarification: Tekton task and pipeline catalog for CI

konflux-ci/devlake:
  - team: developer-productivity
    clarification: DevLake deployment for engineering metrics

konflux-ci/konflux-devlake-dashboards:
  - team: developer-productivity
    clarification: Grafana dashboards for DevLake metrics

konflux-ci/konflux-devlake-mcp:
  - team: developer-productivity
    clarification: MCP server for DevLake data

konflux-ci/coverage-dashboard:
  - team: developer-productivity
    clarification: Code coverage dashboard

konflux-ci/segment-bridge:
  - team: service-enhancement
    clarification: Segment analytics bridge

konflux-ci/operator-toolkit:
  - team: operator-foundry
    clarification: Toolkit for operator development workflows

konflux-ci/operator-foundry:
  - team: operator-foundry
    clarification: Operator build and test infrastructure

konflux-ci/konflux-operator-tasks:
  - team: operator-foundry
    clarification: Tekton tasks for operator pipelines

konflux-ci/konflux-operator-trusted-sources:
  - team: operator-foundry
    clarification: Trusted source configuration for operators

konflux-ci/olm-operator-konflux-sample:
  - team: operator-foundry
    clarification: Sample OLM operator for Konflux

konflux-ci/loadtest:
  - team: performance
    clarification: Load testing framework

konflux-ci/perfscale:
  - team: performance
    clarification: Performance and scale testing tools

konflux-ci/rpmbuild-pipeline:
  - team: rpm-build-process
    clarification: RPM build pipeline definitions

konflux-ci/rpmbuild-pipeline-environment-container:
  - team: rpm-build-process
    clarification: Container image for RPM build environment

konflux-ci/rpmbuild-pipeline-monorepo-mock-config-test:
  - team: rpm-build-process
    clarification: Test configuration for RPM monorepo mock builds

konflux-ci/rpmbuild-pipeline-test-sources:
  - team: rpm-build-process
    clarification: Test source packages for RPM pipeline

konflux-ci/rpm-lockfile-prototype:
  - team: rpm-build-process
    clarification: RPM lockfile prototype tooling

konflux-ci/refresh-rpm-lockfiles:
  - team: rpm-build-process
    clarification: Tool to refresh RPM lockfile data

konflux-ci/java-pipelines:
  - team: java-builds
    clarification: Java-specific pipeline definitions

konflux-ci/maven-lockfile:
  - team: java-builds
    clarification: Maven dependency lockfile tooling

konflux-ci/architecture:
  - team: vanguard
    clarification: Architecture decision records and design docs

konflux-ci/docs:
  - team: vanguard
    clarification: User-facing Konflux documentation

konflux-ci/internal-services:
  - team: release
    clarification: Internal services for release workflows

konflux-ci/sprayproxy:
  - team: pipelines
    clarification: Spray proxy for Pipelines-as-Code

konflux-ci/tekton-kueue:
  - team: pipelines
    clarification: Kueue integration for Tekton pipelines

konflux-ci/pipeline-samples:
  - team: pipelines
    clarification: Sample pipeline configurations

konflux-ci/agent-plugins:
  - team: developer-productivity
    clarification: Claude Code plugins and skills for Konflux

konflux-ci/konflux-lightspeed:
  - team: developer-productivity
    clarification: AI assistant integration for Konflux

konflux-ci/.fullsend:
  - team: fullsend
    clarification: Fullsend platform configuration

# --- hermetoproject org ---

hermetoproject/hermeto:
  - team: build
    clarification: Hermetic build tool (Hermeto)

# --- conforma org ---

conforma/conforma:
  - team: conforma
    clarification: Enterprise Contract / Conforma policy engine
```

- [ ] **Step 2: Verify YAML parses correctly**

Run: `python3 -c "import yaml; yaml.safe_load(open('skills/red-hat-konflux-teams/data/repo-owners.yaml')); print('Valid')"` from repo root.

Expected: `Valid`

- [ ] **Step 3: Commit**

```bash
git add skills/red-hat-konflux-teams/data/repo-owners.yaml
git commit -s -S -m "feat(red-hat-konflux-teams): Add initial repo-owners.yaml

Seed with obvious repo-to-team mappings across konflux-ci,
hermetoproject, and conforma orgs. Keys use org/repo format.
Remaining repos will appear as unassociated in generated references.

Assisted-by: Claude Opus 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Write generate-references.py

**Files:**
- Create: `skills/red-hat-konflux-teams/scripts/generate-references.py`

- [ ] **Step 1: Write the generator script**

```python
#!/usr/bin/env python3
"""Generate markdown reference files from team YAML and repo-owners data.

Reads org/repo names from stdin (one per line), team definitions from
data/teams/*.yaml, and ownership from data/repo-owners.yaml.
Writes three files to references/:
  - repos-by-team.md
  - teams-by-repo.md
  - unassociated-repos.md
"""

import sys
from pathlib import Path

import yaml

SKILL_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = SKILL_DIR / "data"
REFS_DIR = SKILL_DIR / "references"


def load_teams():
    teams = {}
    for f in sorted((DATA_DIR / "teams").glob("*.yaml")):
        with open(f) as fh:
            data = yaml.safe_load(fh)
        teams[f.stem] = data
    return teams


def load_repo_owners():
    path = DATA_DIR / "repo-owners.yaml"
    with open(path) as fh:
        return yaml.safe_load(fh) or {}


def read_repo_list():
    return sorted(line.strip() for line in sys.stdin if line.strip())


def write_repos_by_team(teams, repo_owners):
    # Invert: team -> [(repo, clarification)]
    team_repos = {key: [] for key in teams}
    for repo, owners in sorted(repo_owners.items()):
        for entry in owners:
            team_key = entry["team"]
            if team_key in team_repos:
                team_repos[team_key].append((repo, entry["clarification"]))

    REFS_DIR.mkdir(parents=True, exist_ok=True)
    with open(REFS_DIR / "repos-by-team.md", "w") as fh:
        fh.write("# Repositories by Team\n\n")
        fh.write("*Generated file — do not edit. Run `scripts/sync-repos.sh` to regenerate.*\n\n")
        for team_key in sorted(team_repos):
            team = teams[team_key]
            fh.write(f"## {team['name']}\n\n")
            fh.write(f"**JIRA Project:** {team['jira_project'] or 'N/A'}\n\n")
            components = team.get("jira_components") or []
            if components:
                fh.write(f"**JIRA Components (KONFLUX):** {', '.join(components)}\n\n")
            fh.write(f"{team['description'].strip()}\n\n")
            repos = team_repos[team_key]
            if repos:
                fh.write("| Repository | Clarification |\n")
                fh.write("|---|---|\n")
                for repo, clarification in sorted(repos):
                    fh.write(f"| {repo} | {clarification} |\n")
            else:
                fh.write("*No repositories currently mapped to this team.*\n")
            fh.write("\n")


def write_teams_by_repo(teams, repo_owners):
    REFS_DIR.mkdir(parents=True, exist_ok=True)
    with open(REFS_DIR / "teams-by-repo.md", "w") as fh:
        fh.write("# Teams by Repository\n\n")
        fh.write("*Generated file — do not edit. Run `scripts/sync-repos.sh` to regenerate.*\n\n")
        fh.write("| Repository | Team(s) | JIRA Project(s) | Clarification |\n")
        fh.write("|---|---|---|---|\n")
        for repo in sorted(repo_owners):
            owners = repo_owners[repo]
            team_names = []
            jira_projects = []
            clarifications = []
            for entry in owners:
                team_key = entry["team"]
                team = teams.get(team_key, {})
                team_names.append(team.get("name", team_key))
                jp = team.get("jira_project", "")
                if jp and jp not in jira_projects:
                    jira_projects.append(jp)
                clarifications.append(entry["clarification"])
            fh.write(
                f"| {repo} "
                f"| {', '.join(team_names)} "
                f"| {', '.join(jira_projects) or 'N/A'} "
                f"| {'; '.join(clarifications)} |\n"
            )


def write_unassociated(all_repos, repo_owners):
    unassociated = sorted(set(all_repos) - set(repo_owners))
    REFS_DIR.mkdir(parents=True, exist_ok=True)
    with open(REFS_DIR / "unassociated-repos.md", "w") as fh:
        fh.write("# Unassociated Repositories\n\n")
        fh.write("*Generated file — do not edit. Run `scripts/sync-repos.sh` to regenerate.*\n\n")
        fh.write(
            "These repositories in the tracked GitHub orgs are not yet mapped to any team.\n"
            "To associate a repo, add it to `data/repo-owners.yaml` and re-run `scripts/sync-repos.sh`.\n\n"
        )
        if unassociated:
            for repo in unassociated:
                fh.write(f"- {repo}\n")
        else:
            fh.write("*All repositories are associated with a team.*\n")


def main():
    all_repos = read_repo_list()
    teams = load_teams()
    repo_owners = load_repo_owners()

    # Validate team references
    for repo, owners in repo_owners.items():
        for entry in owners:
            if entry["team"] not in teams:
                print(
                    f"Warning: repo '{repo}' references unknown team '{entry['team']}'",
                    file=sys.stderr,
                )

    write_repos_by_team(teams, repo_owners)
    write_teams_by_repo(teams, repo_owners)
    write_unassociated(all_repos, repo_owners)

    owned = len(repo_owners)
    unassociated = len(set(all_repos) - set(repo_owners))
    print(f"Generated references: {owned} owned repos, {unassociated} unassociated repos")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Test the script with piped repo list**

Run from repo root:
```bash
{ for org in konflux-ci hermetoproject conforma; do gh repo list "$org" --limit 500 --json name,isArchived --jq ".[] | select(.isArchived == false) | \"${org}/\" + .name"; done; } | python3 skills/red-hat-konflux-teams/scripts/generate-references.py
```

Expected: Output like `Generated references: 72 owned repos, 80 unassociated repos` (numbers will vary). Check that `skills/red-hat-konflux-teams/references/` contains three `.md` files.

- [ ] **Step 3: Spot-check generated files**

Run: `head -30 skills/red-hat-konflux-teams/references/repos-by-team.md`
Run: `head -20 skills/red-hat-konflux-teams/references/teams-by-repo.md`
Run: `head -20 skills/red-hat-konflux-teams/references/unassociated-repos.md`

Verify tables are well-formed and data looks correct.

- [ ] **Step 4: Commit**

```bash
git add skills/red-hat-konflux-teams/scripts/generate-references.py
git commit -s -S -m "feat(red-hat-konflux-teams): Add reference generator script

Python script reads team YAML + repo-owners.yaml + stdin repo list,
produces repos-by-team.md, teams-by-repo.md, and unassociated-repos.md.

Assisted-by: Claude Opus 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Write sync-repos.sh wrapper

**Files:**
- Create: `skills/red-hat-konflux-teams/scripts/sync-repos.sh`

- [ ] **Step 1: Write the sync script**

```bash
#!/usr/bin/env bash
# Fetch repos from all tracked GitHub orgs and regenerate reference docs.
#
# Usage: ./scripts/sync-repos.sh
#
# Requires: gh CLI (authenticated), python3, PyYAML

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ORGS=(konflux-ci hermetoproject conforma)

{
  for org in "${ORGS[@]}"; do
    gh repo list "$org" --limit 500 --json name,isArchived \
      --jq ".[] | select(.isArchived == false) | \"${org}/\" + .name"
  done
} | python3 "$SCRIPT_DIR/generate-references.py"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x skills/red-hat-konflux-teams/scripts/sync-repos.sh`

- [ ] **Step 3: Run it end-to-end**

Run: `skills/red-hat-konflux-teams/scripts/sync-repos.sh`

Expected: Same output as Task 3 Step 2. References regenerated.

- [ ] **Step 4: Commit the script and the generated references**

```bash
git add skills/red-hat-konflux-teams/scripts/sync-repos.sh skills/red-hat-konflux-teams/references/
git commit -s -S -m "feat(red-hat-konflux-teams): Add sync script and initial generated references

Bash wrapper fetches live repo list from konflux-ci, hermetoproject,
and conforma GitHub orgs, pipes to generator. Includes initial
generated reference docs.

Assisted-by: Claude Opus 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 5: Write SKILL.md

**Files:**
- Create: `skills/red-hat-konflux-teams/SKILL.md`

- [ ] **Step 1: Write the skill file**

```markdown
---
name: red-hat-konflux-teams
description: Use when needing to know which Red Hat team owns a Konflux-related repository (konflux-ci, hermetoproject, conforma orgs), which JIRA project or component to file issues against, or how the Red Hat Konflux engineering organization maps to the codebase.
---

# Red Hat Konflux Teams

Maps repositories across Konflux-related GitHub orgs (`konflux-ci`, `hermetoproject`, `conforma`) to the Red Hat engineering teams that own them and their JIRA metadata.

## How to Answer Questions

**"Which team owns repo X?"** or **"Where do I file a bug for X?"**
Read `references/teams-by-repo.md` and find the repo. The table shows the owning team(s), their JIRA project key(s), and a clarification of each team's stake.

**"What repos does team Y own?"** or **"What does team Y work on?"**
Read `references/repos-by-team.md` and find the team section. It lists the team's JIRA project, JIRA components, description, and all owned repos.

**"What repos have no owner?"**
Read `references/unassociated-repos.md` for repos not yet mapped to any team.

## JIRA Context

Teams use two kinds of JIRA locations:
- **JIRA Project**: The project key where the team's epics and stories live (e.g., STONEBLD, KFLUXINFRA, RELEASE).
- **JIRA Components**: Component names within the KONFLUX JIRA project used for routing support and triage. Not all teams have KONFLUX components — some work entirely within their own JIRA project.

## Keywords

konflux-ci repo owner, repository ownership, JIRA project, JIRA component, file a bug, which team, who owns, team mapping, Red Hat Konflux teams, STONEBLD, KFLUXINFRA, STONEINTG, RELEASE, SRVKP, KONFLUX, KFLUXUI, KFLUXVNGD, KFLUXSE, KFLUXDP, CWFHEALTH, EC, ISV, KAR, PVO11Y, CLOUDDST, SPRE, KFLUXSPRT, ROK, RHELBLD, RELDEV
```

- [ ] **Step 2: Validate frontmatter**

Run: `python3 -c "import yaml; content=open('skills/red-hat-konflux-teams/SKILL.md').read(); fm=content.split('---')[1]; data=yaml.safe_load(fm); print(f'name: {data[\"name\"]}'); print(f'description length: {len(data[\"description\"])}'); assert len(content.split('---')[1]) < 1024, 'Frontmatter too long'"` from repo root.

Expected: Prints name and description length, no assertion error.

- [ ] **Step 3: Commit**

```bash
git add skills/red-hat-konflux-teams/SKILL.md
git commit -s -S -m "feat(red-hat-konflux-teams): Add SKILL.md

Skill directs Claude to the appropriate reference file based on
the question direction (repo→team or team→repo).

Assisted-by: Claude Opus 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 6: Write README.md

**Files:**
- Create: `skills/red-hat-konflux-teams/README.md`

- [ ] **Step 1: Write the README**

```markdown
# red-hat-konflux-teams

Maps repositories across Konflux-related GitHub orgs
([konflux-ci](https://github.com/konflux-ci),
[hermetoproject](https://github.com/hermetoproject),
[conforma](https://github.com/conforma)) to the Red Hat engineering teams
that own them and their JIRA metadata (project keys, components).

## Source of truth

The authoritative source for Red Hat Konflux team structure is the
[Konflux Team Structure spreadsheet](https://docs.google.com/spreadsheets/d/1meAQQVmBRUmBYw97JV4eszv4_ugJxbER0WPSdj4y-Ew/edit?gid=698174757#gid=698174757).
This skill exists as a convenience to help the community understand which
Red Hat teams work on which parts of Konflux.

## Maintenance

To update the generated reference docs after repos are added or removed
from the tracked GitHub orgs:

    ./scripts/sync-repos.sh

To assign an unassociated repo to a team, add an entry to
`data/repo-owners.yaml` and re-run the sync script.

To update team JIRA metadata, edit the relevant file in `data/teams/`.

### Prerequisites

- `gh` CLI, authenticated
- Python 3 with PyYAML (`pip install pyyaml`)

## Future considerations

- People data (team leads, managers, architects)
- Slack channels per team
- JIRA validation (checking that project keys and components still exist)
```

- [ ] **Step 2: Commit**

```bash
git add skills/red-hat-konflux-teams/README.md
git commit -s -S -m "docs(red-hat-konflux-teams): Add README

Links to source spreadsheet, documents maintenance workflow,
notes future considerations.

Assisted-by: Claude Opus 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 7: Add to marketplace.json

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Read current marketplace.json**

Read `.claude-plugin/marketplace.json` to get the current content.

- [ ] **Step 2: Add the new skill entry**

Add the following entry to the `plugins` array:

```json
{
  "name": "red-hat-konflux-teams",
  "source": "./skills/red-hat-konflux-teams",
  "description": "Use when needing to know which Red Hat team owns a Konflux-related repository (konflux-ci, hermetoproject, conforma orgs), which JIRA project or component to file issues against, or how the Red Hat Konflux engineering organization maps to the codebase.",
  "version": "1.0.0",
  "author": {
    "name": "Konflux CI Team"
  }
}
```

- [ ] **Step 3: Validate JSON**

Run: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); print('Valid JSON')"` from repo root.

Expected: `Valid JSON`

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -s -S -m "feat(red-hat-konflux-teams): Add to marketplace.json

Assisted-by: Claude Opus 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 8: Run linter and validate

**Files:** None (validation only)

- [ ] **Step 1: Run claudelint**

Run: `make validate` from repo root.

Expected: `Validation passed!`

- [ ] **Step 2: Fix any lint errors**

If validation fails, read the error output and fix the SKILL.md frontmatter or marketplace.json accordingly. Re-run `make validate` until it passes.

- [ ] **Step 3: Commit any fixes**

If fixes were needed:
```bash
git add -u
git commit -s -S -m "fix(red-hat-konflux-teams): Fix lint errors

Assisted-by: Claude Opus 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```
