# Design: red-hat-konflux-teams skill

## Problem

The Red Hat Konflux engineering organization spans ~30 teams and ~140 repositories in the `konflux-ci` GitHub org. Developers working in or around Konflux need to know which team owns a given repo, what JIRA project to file issues against, and which JIRA components are relevant. This information lives in a Google Spreadsheet that isn't easily queryable by tooling.

## Goal

Create a skill that maps konflux-ci repositories to Red Hat teams and their JIRA metadata (project keys, components). The skill should be programmatically maintainable so that new repos are detected and flagged for ownership assignment.

## Non-goals

- People data (leads, managers, architects) — future consideration
- Slack channels — future consideration
- JIRA validation (checking that project keys/components still exist)
- Automated team assignment (humans decide ownership)

## Directory structure

```
skills/red-hat-konflux-teams/
├── SKILL.md
├── README.md
├── data/
│   ├── teams/
│   │   ├── build.yaml
│   │   ├── collective.yaml
│   │   ├── conforma.yaml
│   │   ├── container-health.yaml
│   │   ├── cue.yaml
│   │   ├── developer-productivity.yaml
│   │   ├── infrastructure.yaml
│   │   ├── integration.yaml
│   │   ├── kubearchive.yaml
│   │   ├── observability.yaml
│   │   ├── operator-foundry.yaml
│   │   ├── performance.yaml
│   │   ├── pipelines.yaml
│   │   ├── release.yaml
│   │   ├── release-engineering.yaml
│   │   ├── rhel-on-konflux.yaml
│   │   ├── service-enhancement.yaml
│   │   ├── spre.yaml
│   │   ├── support-ops.yaml
│   │   ├── ui.yaml
│   │   ├── uxd.yaml
│   │   ├── vanguard.yaml
│   │   ├── builds-for-openshift.yaml
│   │   ├── centos-stream.yaml
│   │   ├── rhel-product-engineering-workflows.yaml
│   │   ├── rok-migration.yaml
│   │   ├── rpm-storage-mechanism.yaml
│   │   ├── rpm-build-process.yaml
│   │   ├── rpm-delivery-experience.yaml
│   │   ├── rpm-package-integration.yaml
│   │   └── rpm-release-workflow.yaml
│   └── repo-owners.yaml
├── references/
│   ├── repos-by-team.md              # Generated
│   ├── teams-by-repo.md              # Generated
│   └── unassociated-repos.md         # Generated
└── scripts/
    ├── sync-repos.sh
    └── generate-references.py
```

## Data model

### Team file (`data/teams/<team-name>.yaml`)

```yaml
name: Build
jira_project: STONEBLD
jira_components:
  - Build
description: >
  Build pipelines, .tekton/ yaml files, SBOMs, pipeline-migration-tool,
  prefetching and hermetic builds using Hermeto.
```

- `name`: Display name (title case, as used by the team)
- `jira_project`: JIRA project key (e.g., STONEBLD, KFLUXINFRA). Required.
- `jira_components`: List of component names in the KONFLUX JIRA project. Empty list if the team has no KONFLUX components (teams whose work lives entirely in their own JIRA project).
- `description`: Brief description of the team's scope.

Teams with no JIRA component (CUE, Fullsend, Builds for OpenShift, etc.) leave `jira_components` empty.

Teams like Collective that own multiple JIRA components (Pyxis, Radas, Sbom) list all of them.

### Repo ownership (`data/repo-owners.yaml`)

Flat map keyed by repo name. Each value is a list of ownership entries:

```yaml
build-definitions:
  - team: build
    clarification: Primary owners of build pipeline definitions
  - team: java-builds
    clarification: Java-specific build pipeline definitions
integration-service:
  - team: integration
    clarification: Primary owners
```

- `team`: Matches the filename (without `.yaml`) in `data/teams/`
- `clarification`: Required free-text explaining the nature of ownership or stake

Repos absent from this file are considered unassociated.

## Scripts

### `scripts/sync-repos.sh`

Bash wrapper that:
1. Runs `gh repo list konflux-ci --limit 500 --json name,isArchived --jq '.[] | select(.isArchived == false) | .name'`
2. Passes the repo list to `generate-references.py` via stdin

### `scripts/generate-references.py`

Python script that:
1. Reads repo list from stdin (one repo per line)
2. Reads all `data/teams/*.yaml` files
3. Reads `data/repo-owners.yaml`
4. Generates three files:

**`references/repos-by-team.md`**: One section per team, sorted alphabetically. Each section includes the team's JIRA project, JIRA components, description, and a table of owned repos with clarification text.

**`references/teams-by-repo.md`**: Single alphabetical table. Columns: Repo, Team(s), JIRA Project(s), Clarification.

**`references/unassociated-repos.md`**: Simple list of repo names found on GitHub but absent from `repo-owners.yaml`.

## SKILL.md

```yaml
---
name: red-hat-konflux-teams
description: >
  Use when needing to know which Red Hat team owns a konflux-ci repository,
  which JIRA project or component to file issues against, or how the Red Hat
  Konflux engineering organization maps to the codebase.
---
```

Body directs Claude to read the appropriate reference file:
- "Which team owns repo X?" → `references/teams-by-repo.md`
- "What repos does team Y own?" → `references/repos-by-team.md`
- "What repos have no owner?" → `references/unassociated-repos.md`

## Initial data population

Team YAML files will be populated from the "Konflux Team Structure" sheet (gid 698174757) of the source spreadsheet. The repo-owners.yaml will be seeded with known mappings based on repo names that clearly correspond to teams (e.g., `build-service` → build, `integration-service` → integration, `release-service` → release). Remaining repos start as unassociated.

## README notes

- Source of truth for team data: the Red Hat spreadsheet (linked)
- This skill exists as a convenience to help the community understand which Red Hat teams work on which parts of Konflux
- Future considerations: adding people data (leads, architects), Slack channels
