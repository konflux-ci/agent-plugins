# How to Subscribe to Konflux Skills

## Quick Start

Add this repository as a Claude Code plugin to get access to all Konflux skills.

## Installation

1. Open Claude Code settings
2. Navigate to the Plugins section
3. Add a new plugin source:
   ```
   https://github.com/<your-org>/skills
   ```
4. Claude Code will load skills from `.claude-plugin/marketplace.json`

## Available Skills

Once subscribed, skills will be automatically available when working on Konflux-related tasks:

- **understanding-konflux-resources** - Quick reference for Konflux CI/CD Custom Resources (RP, RPA, ITS) - helps users understand Applications, Components, Snapshots, IntegrationTestScenarios, ReleasePlans, namespace placement, common abbreviations, and confusions
- **debugging-pipeline-failures** - Use when investigating Konflux Tekton pipeline failures, PipelineRun/TaskRun issues, build failures, or CI/CD workflow problems
- **navigating-github-to-konflux-pipelines** - Use when GitHub PR or branch has failing checks and you need to find Konflux pipeline information (cluster, namespace, PipelineRun name)
- **working-with-provenance** - Use when tracing Konflux builds from image references, finding build logs from artifacts, or verifying source commits for container images
- **component-build-status** - Use to trigger component builds, releases or get a component or application status

## Updating Skills

Skills are automatically updated when this repository is updated. Claude Code periodically refreshes plugin sources.

## More Information

- See CLAUDE.md for skill development guidelines
- Visit https://konflux-ci.dev/docs/ for Konflux platform documentation
- File issues in this repository for skill improvements or bugs
