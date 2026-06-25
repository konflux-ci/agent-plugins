# Repositories by Team

*Generated file — do not edit. Run `scripts/sync-repos.sh` to regenerate.*

## Build

**JIRA Project:** STONEBLD

**JIRA Components (KONFLUX):** Build

Build pipelines, .tekton/ yaml files, SBOMs (partially), pipeline-migration-tool, prefetching and hermetic builds using Hermeto. Component nudging. Review PRs in build-definitions, build-service, image-controller.

| Repository | Clarification |
|---|---|
| hermetoproject/hermeto | Hermetic build tool (Hermeto) |
| hermetoproject/pybuild-deps | Python build dependency resolution for Hermeto |
| konflux-ci/build-definitions | Build pipeline definitions and task bundles |
| konflux-ci/build-pipeline-tasks | Individual build pipeline tasks |
| konflux-ci/build-service | Build service controller |
| konflux-ci/build-tasks-dockerfiles | Dockerfiles for build task images |
| konflux-ci/build-trusted-artifacts | Trusted artifacts for build pipelines |
| konflux-ci/buildah-container | Buildah container image for builds |
| konflux-ci/image-controller | Image repository management controller |
| konflux-ci/konflux-build-cli | Konflux build CLI tool |
| konflux-ci/pipeline-migration-tool | Tool for migrating pipeline configurations |
| konflux-ci/task-repo-shared-ci | Shared CI configuration for task repos |
| konflux-ci/task-runner | Tekton task runner |

## Builds for OpenShift

**JIRA Project:** BUILD

OCP Builds.

*No repositories currently mapped to this team.*

## CentOS Stream

**JIRA Project:** CS

**JIRA Components (KONFLUX):** CentOS Stream

Adoption of Konflux in CentOS Stream workflows.

*No repositories currently mapped to this team.*

## Collective

**JIRA Project:** ISV

**JIRA Components (KONFLUX):** Pyxis, Radas, Sbom

Pyxis, container, and product metadata visible at catalog.redhat.com. Container signature storage. Signing-related issues (Radas). SBOM generation, processing, and quality.

| Repository | Clarification |
|---|---|
| konflux-ci/capo | Cluster API Provider OpenStack |
| konflux-ci/mobster | Mobster team collaboration tool |

## Conforma

**JIRA Project:** EC

**JIRA Components (KONFLUX):** Conforma

Anything related to Conforma/EC, policies.

| Repository | Clarification |
|---|---|
| conforma/.fullsend | Fullsend configuration for Conforma |
| conforma/.github | GitHub org-level configuration |
| conforma/action-validate-image | GitHub Action for image validation |
| conforma/claude-skills | Claude Code skills for Conforma |
| conforma/cli | Conforma CLI tool |
| conforma/conforma | Enterprise Contract / Conforma policy engine |
| conforma/conforma.github.io | Conforma website |
| conforma/crds | Custom Resource Definitions |
| conforma/demos | Demo configurations and examples |
| conforma/e2e-tests | End-to-end test suite |
| conforma/go-containerregistry | Go container registry library fork |
| conforma/go-gather | Go gather utility library |
| conforma/golden-container | Golden container image for testing |
| conforma/golden-rpm | Golden RPM package for testing |
| conforma/hacks | Development hacks and utilities |
| conforma/infra-deployments-ci | Infrastructure deployment CI configuration |
| conforma/knative-service | Knative service configuration |
| conforma/policy | Conforma policy definitions |
| conforma/pr-size-label-action | GitHub Action for PR size labeling |
| conforma/review-rot | Code review rotation tool |
| conforma/rhtap-ec-policy | RHTAP Enterprise Contract policy |
| conforma/step-actions | Tekton step actions |
| conforma/tekton-catalog | Tekton task and pipeline catalog |
| conforma/user-guide | Conforma user guide documentation |

## Container Health

**JIRA Project:** CWFHEALTH

**JIRA Components (KONFLUX):** Mintmaker, Diffused

MintMaker and Renovate: issues and functionality with Renovate PRs opened against repositories. Automatic detection of CVEs fixed by release (Diffused).

| Repository | Clarification |
|---|---|
| konflux-ci/diffused | Automatic CVE detection for releases |
| konflux-ci/mintmaker | MintMaker dependency update service |
| konflux-ci/mintmaker-osv-database | OSV vulnerability database for MintMaker |
| konflux-ci/mintmaker-presets | Default configuration presets for MintMaker |
| konflux-ci/mintmaker-renovate-image | Renovate container image for MintMaker |
| konflux-ci/mintmaker-schedule-calculator | Scheduling logic for MintMaker updates |

## CPaaS and Traditional

**JIRA Project:** N/A

Continuous Productization as a Service + Traditional combined.

*No repositories currently mapped to this team.*

## CUE

**JIRA Project:** KFLUXUI

Konflux UI + UX integration.

| Repository | Clarification |
|---|---|
| konflux-ci/konflux-ui | UX integration aspects |

## Developer Productivity

**JIRA Project:** KFLUXDP

**JIRA Components (KONFLUX):** DevProd

Devlake, Devlake MCP, engineering metrics, team weekly updates, Tekton-integration-catalog, konflux component CI. FinOps: cost-saving initiatives, right-sizing resources, cloud accounts.

| Repository | Clarification |
|---|---|
| konflux-ci/agent-plugins | Claude Code plugins and skills for Konflux |
| konflux-ci/agentready-scores | Agent readiness scoring |
| konflux-ci/coverage-dashboard | Code coverage dashboard |
| konflux-ci/coverport | Code coverage reporting |
| konflux-ci/devlake | DevLake deployment for engineering metrics |
| konflux-ci/kargo | Kargo deployment pipeline promotion |
| konflux-ci/konflux-devlake-dashboards | Grafana dashboards for DevLake metrics |
| konflux-ci/konflux-devlake-mcp | MCP server for DevLake data |
| konflux-ci/konflux-lightspeed | AI assistant integration for Konflux |
| konflux-ci/multi-arch-konflux-sample | Multi-arch Konflux sample application |
| konflux-ci/qe-tools | QE testing tools |
| konflux-ci/quality-dashboard | Quality metrics dashboard |
| konflux-ci/sample-component-golang | Sample Go component for testing |
| konflux-ci/sample-component-golang-updater | Updater for sample Go component |
| konflux-ci/tekton-integration-catalog | Tekton task and pipeline catalog for CI |
| konflux-ci/testrepo | Test repository for CI verification |
| konflux-ci/testrepo-updater | Updater for test repository |

## Fullsend

**JIRA Project:** N/A

Fullsend platform.

| Repository | Clarification |
|---|---|
| konflux-ci/.fullsend | Fullsend platform configuration |
| konflux-ci/refinement | Backlog refinement tooling |

## Infrastructure

**JIRA Project:** KFLUXINFRA

**JIRA Components (KONFLUX):** Infrastructure

Infrastructure compute, network, storage, authentication, authorization, ArgoCD for Konflux deployment, multi-arch builds (MPC), Kyverno, namespace-lister, kueue, etcd-shield.

| Repository | Clarification |
|---|---|
| konflux-ci/ci-terraform-runner | Terraform runner for CI infrastructure |
| konflux-ci/deptriage | Dependency triage tool |
| konflux-ci/etcd-shield | etcd protection tooling |
| konflux-ci/kueue-external-admission | Kueue external admission webhook |
| konflux-ci/kyverno | Kyverno policy engine deployment |
| konflux-ci/multi-arch | Multi-architecture build support |
| konflux-ci/multi-platform-controller | Multi-architecture build controller |
| konflux-ci/namespace-lister | Namespace listing utility |

## Integration

**JIRA Project:** STONEINTG

**JIRA Components (KONFLUX):** Integration

Integration tests against Snapshot, security tests from build-pipelines (e.g. clair-scan, clamav-scan, deprecated-image-check), Snapshot Garbage Collection.

| Repository | Clarification |
|---|---|
| konflux-ci/clair-in-ci-db | Clair vulnerability database for CI scanning |
| konflux-ci/e2e-tests | End-to-end test suite |
| konflux-ci/integration-examples | Example integration test configurations |
| konflux-ci/integration-service | Integration service controller |
| konflux-ci/integration-service-utils | Shared utilities for integration service |
| konflux-ci/konflux-clamav | ClamAV antivirus scanning |
| konflux-ci/konflux-sast-tasks | SAST scanning pipeline tasks |
| konflux-ci/konflux-test | Konflux test framework |
| konflux-ci/konflux-test-tasks | Konflux test pipeline tasks |
| konflux-ci/test-data-sast | Test data for SAST scanning |

## Java Builds

**JIRA Project:** STONEBLD

Java builds on Konflux.

| Repository | Clarification |
|---|---|
| konflux-ci/java-pipelines | Java-specific pipeline definitions |
| konflux-ci/maven-lockfile | Maven dependency lockfile tooling |

## Kubearchive

**JIRA Project:** KAR

**JIRA Components (KONFLUX):** Kubearchive

Store Snapshots, Releases, PipelineRuns, TaskRuns and Pods in an external DB. Has a REST API compatible with Kubernetes clients.

*No repositories currently mapped to this team.*

## Marketplace

**JIRA Project:** N/A

Stratosphere.

*No repositories currently mapped to this team.*

## Observability

**JIRA Project:** PVO11Y

**JIRA Components (KONFLUX):** O11Y

Design and implement observability solutions for Konflux both on the global and tenant level, maintaining and expanding the observability toolset. Includes cost management to support business processes.

*No repositories currently mapped to this team.*

## Operator Foundry

**JIRA Project:** CLOUDDST

**JIRA Components (KONFLUX):** Operators

OLM Operators (RH, Certified, Community), File Based Configs (FBC), Operator Indexes/Catalogs, FIPS compliance testing, Traditional Container/Operator Test Pipelines.

| Repository | Clarification |
|---|---|
| konflux-ci/community-operators-prod | OLM operators production catalog |
| konflux-ci/konflux-operator-tasks | Tekton tasks for operator pipelines |
| konflux-ci/konflux-operator-trusted-sources | Trusted source configuration for operators |
| konflux-ci/olm-operator-konflux-sample | Sample OLM operator for Konflux |
| konflux-ci/operator-foundry | Operator build and test infrastructure |
| konflux-ci/operator-toolkit | Toolkit for operator development workflows |

## Performance

**JIRA Project:** KONFLUX

**JIRA Components (KONFLUX):** Performance

Konflux perf and scale issues, Load Test Probe run issues.

| Repository | Clarification |
|---|---|
| konflux-ci/loadtest | Load testing framework |
| konflux-ci/perfscale | Performance and scale testing tools |

## Pipelines

**JIRA Project:** SRVKP

**JIRA Components (KONFLUX):** Pipelines

Install and upgrade pipeline components across Konflux environments, Pipelines-as-Code component queries, troubleshoot customer PipelineRun failures using splunk and results logs, respond to Pipeline component alerts.

| Repository | Clarification |
|---|---|
| konflux-ci/pipeline-samples | Sample pipeline configurations |
| konflux-ci/sprayproxy | Spray proxy for Pipelines-as-Code |
| konflux-ci/tekton-kueue | Kueue integration for Tekton pipelines |

## Release

**JIRA Project:** RELEASE

**JIRA Components (KONFLUX):** Release

Release admission, release pipelines, FBC, Signing, release monitoring, release advisories, operators, collectors. Review PRs in release-service-catalog.

| Repository | Clarification |
|---|---|
| konflux-ci/community-catalog | Community pipeline catalog |
| konflux-ci/internal-services | Internal services for release workflows |
| konflux-ci/release-service | Release service controller |
| konflux-ci/release-service-automations | Release automation scripts |
| konflux-ci/release-service-catalog | Release pipeline catalog |
| konflux-ci/release-service-catalog-e2e-base | Base images for release catalog e2e tests |
| konflux-ci/release-service-collectors | Data collectors for release monitoring |
| konflux-ci/release-service-docs | Release service documentation |
| konflux-ci/release-service-monitor | Release monitoring dashboards and alerts |
| konflux-ci/release-service-utils | Shared utilities for release service |

## Release Engineering

**JIRA Project:** RELDEV

**JIRA Components (KONFLUX):** ContainerReleng

ReleasePlanAdmission (RPA) configuration, konflux-release-data MRs (excluding tenants-config), quay.io/redhat-services-prod, eng-id assistance, policy exceptions, macos or windows binary signing, secret management for managed cluster.

| Repository | Clarification |
|---|---|
| conforma/rhtap-ec-policy | Release engineering policy integration |

## RHEL on Konflux

**JIRA Project:** ROK

**JIRA Components (KONFLUX):** RoK

Everything RHEL on Konflux. Umbrella team for ROK sub-teams.

*No repositories currently mapped to this team.*

## RHEL Product Engineering Workflows

**JIRA Project:** ROK

**JIRA Components (KONFLUX):** RHEL Process

Integration of Konflux with RHEL Engineering development process, RHEL on Gitlab, RHEL package testing workflows.

*No repositories currently mapped to this team.*

## RoK Migration

**JIRA Project:** KFLUXMIG

**JIRA Components (KONFLUX):** RoK Migration

Driving the onboarding of RHEL engineering to Konflux RPM pipeline.

*No repositories currently mapped to this team.*

## RPM Build Process

**JIRA Project:** RHELBLD

**JIRA Components (KONFLUX):** RPM Build

RPM Build pipeline, issues with SBOM, Mock.

| Repository | Clarification |
|---|---|
| konflux-ci/refresh-rpm-lockfiles | Tool to refresh RPM lockfile data |
| konflux-ci/rpm-lockfile-prototype | RPM lockfile prototype tooling |
| konflux-ci/rpmbuild-pipeline | RPM build pipeline definitions |
| konflux-ci/rpmbuild-pipeline-environment-container | Container image for RPM build environment |
| konflux-ci/rpmbuild-pipeline-monorepo-mock-config-test | Test configuration for RPM monorepo mock builds |
| konflux-ci/rpmbuild-pipeline-test-sources | Test source packages for RPM pipeline |

## RPM Delivery Experience

**JIRA Project:** ROK

**JIRA Components (KONFLUX):** RPM Delivery

RPM delivery pipeline development, pushing to CDN.

*No repositories currently mapped to this team.*

## RPM Package Integration

**JIRA Project:** ROK

**JIRA Components (KONFLUX):** RPM Package Integration

Integration of RPM packages to composite artifacts.

*No repositories currently mapped to this team.*

## RPM Release Workflow

**JIRA Project:** ROK

**JIRA Components (KONFLUX):** RPM Release

RHEL release configuration setup, Release Plans, Package Collections, Conforma.

*No repositories currently mapped to this team.*

## RPM Storage Mechanism

**JIRA Project:** ROK

**JIRA Components (KONFLUX):** RPM Storage

Implementation of RPM Artifact Storage, embargoed content classification.

*No repositories currently mapped to this team.*

## Service Enhancement

**JIRA Project:** KFLUXSE

Cross-service Konflux feature development, user-feedback-driven enhancements, platform-wide repo health and adoption.

| Repository | Clarification |
|---|---|
| konflux-ci/segment-bridge | Segment analytics bridge |

## Spre

**JIRA Project:** SPRE

**JIRA Components (KONFLUX):** Spre

Konflux incident/outage response.

*No repositories currently mapped to this team.*

## Support Ops

**JIRA Project:** KFLUXSPRT

**JIRA Components (KONFLUX):** SupportOps

Ideas on how to improve user support for Konflux.

| Repository | Clarification |
|---|---|
| konflux-ci/support | User support repository |

## UI

**JIRA Project:** KFLUXUI

**JIRA Components (KONFLUX):** UI

UI elements, error messages, site reloads, loading times.

| Repository | Clarification |
|---|---|
| konflux-ci/konflux-ui | Konflux web UI frontend |

## UXD

**JIRA Project:** DTUX

**JIRA Components (KONFLUX):** UXD

UX Design and Research.

*No repositories currently mapped to this team.*

## Vanguard

**JIRA Project:** KFLUXVNGD

**JIRA Components (KONFLUX):** Vanguard

Konflux-CI Upstream, Caching, Project Controller (multi-version), Environment as a Service (EaaS), PipelineRun Results Notifier, Internal Cluster Tooling.

| Repository | Clarification |
|---|---|
| konflux-ci/application-api | Application and Component API definitions |
| konflux-ci/architecture | Architecture decision records and design docs |
| konflux-ci/caching | Caching infrastructure |
| konflux-ci/cluster-template-charts | Cluster template Helm charts |
| konflux-ci/community | Community governance and guidelines |
| konflux-ci/crossplane-components | Crossplane managed resource components |
| konflux-ci/crossplane-control-plane | Crossplane control plane configuration |
| konflux-ci/dex | Dex identity provider deployment |
| konflux-ci/docs | User-facing Konflux documentation |
| konflux-ci/external-secrets-operator | External Secrets Operator deployment |
| konflux-ci/image-rbac-proxy | RBAC proxy for image access |
| konflux-ci/konflux-ci | Upstream Konflux CI deployment |
| konflux-ci/konflux-ci.github.io | Konflux CI website |
| konflux-ci/notification-service | PipelineRun results notifier |
| konflux-ci/oauth2-proxy | OAuth2 proxy deployment |
| konflux-ci/pr-review-webhook | PR review webhook service |
| konflux-ci/project-controller | Multi-version project controller |
| konflux-ci/reverse-proxy | Reverse proxy deployment |
| konflux-ci/smee-sidecar | Smee webhook relay sidecar |
| konflux-ci/tekton-tools | Tekton utility tools |
| konflux-ci/tools | General-purpose platform tools |
| konflux-ci/zot | Zot container registry deployment |

