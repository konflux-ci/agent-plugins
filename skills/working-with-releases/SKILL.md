---
name: working-with-releases
description: Use when investigating Konflux Release status, listing recent releases, viewing release pipeline logs, or debugging release failures. Covers tenant, managed, and final PipelineRuns associated with a Release resource.
allowed-tools: Bash(~/.claude/skills/working-with-releases/scripts/*), Bash(jq:*)
---

# Working with Releases

## Overview

**Core Principle**: Use the provided scripts to interact with Konflux Releases. Do NOT run raw `kubectl` or `tkn` commands directly — always prefer the wrapper scripts, which produce structured output suitable for filtering.

**Key fields in a Release resource**:
- `.status.tenantProcessing.pipelineRun` — tenant pipeline (runs in tenant namespace)
- `.status.managedProcessing.pipelineRun` — managed pipeline (runs in managed/target namespace)
- `.status.finalProcessing.pipelineRun` — final/post pipeline (runs in managed namespace)
- All pipelineRun references use `namespace/name` format

## When to Use

- "What releases have happened recently?"
- "Why did this release fail?"
- "Show me the logs for this release"
- "What's the status of the release pipeline?"
- User mentions a Release name or asks about release progress

## Prerequisites — Check These First

Before running any commands, run the prerequisites check:

```bash
~/.claude/skills/working-with-releases/scripts/check-prerequisites.sh
```

This verifies that `kubectl`, `tkn`, and `jq` are installed and that you have an active cluster connection.

If tools are **missing**, install them:
- **kubectl**: `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/`
- **tkn**: `TKN_VERSION=$(curl -s https://api.github.com/repos/tektoncd/cli/releases/latest | jq -r .tag_name) && curl -LO "https://github.com/tektoncd/cli/releases/download/${TKN_VERSION}/tkn_${TKN_VERSION#v}_Linux_x86_64.tar.gz" && tar xzf tkn_*.tar.gz tkn && sudo mv tkn /usr/local/bin/ && rm tkn_*.tar.gz`
- **jq**: `sudo dnf install -y jq`

If **not connected** to a cluster, use the **selecting-konflux-cluster** or **connecting-to-konflux-cluster** skill.

## Listing Releases

Use the `list-releases.sh` script. It outputs structured JSON — always pipe through `jq` to minimize token usage.

```bash
SCRIPT=~/.claude/skills/working-with-releases/scripts/list-releases.sh
```

### Compact summary (names and status only):
```bash
$SCRIPT --limit 10 | jq '.[] | {name, status, age}'
```

### Just names:
```bash
$SCRIPT | jq '.[].name'
```

### Failed releases only:
```bash
$SCRIPT --limit 20 | jq '[.[] | select(.status == "Failed")] | .[] | {name, status, statusMessage, age}'
```

### Releases for a specific application:
```bash
$SCRIPT | jq '[.[] | select(.name | startswith("my-app"))] | .[] | {name, status, age}'
```

### Full detail for a specific release:
```bash
$SCRIPT | jq '.[] | select(.name == "my-release-abc123")'
```

### With explicit namespace:
```bash
$SCRIPT --namespace my-tenant --limit 5 | jq '.[] | {name, status, age}'
```

**Token efficiency**: Always filter with jq. The full JSON output includes snapshot, releasePlan, author, target, and all three pipelineRun references. Only request what you need.

## Viewing Release Logs

Use the `release-logs.sh` script. It fetches logs for all three pipeline stages (tenant, managed, final) in sequence.

```bash
SCRIPT=~/.claude/skills/working-with-releases/scripts/release-logs.sh
```

### View logs for a completed release:
```bash
$SCRIPT my-release-abc123
```

### Follow logs for an in-progress release:
```bash
$SCRIPT my-release-abc123 --follow
```

### With explicit namespace:
```bash
$SCRIPT my-release-abc123 --namespace my-tenant
```

The script outputs:
1. Overall Release status
2. Tenant Pipeline logs (or "Skipped" if not applicable)
3. Managed Pipeline logs (runs in the target/managed namespace)
4. Final Pipeline logs (or "Skipped" if not applicable)

## Release Pipeline Stages

A release progresses through up to three pipeline stages:

| Stage | Condition Type | Namespace | Purpose |
|-------|---------------|-----------|---------|
| Tenant | TenantPipelineProcessed | Tenant namespace | Pre-processing in user's namespace |
| Managed | ManagedPipelineProcessed | Managed namespace (`.status.target`) | Main release work (publish, sign, etc.) |
| Final | FinalPipelineProcessed | Managed namespace | Post-release cleanup and notifications |

Any stage may be **Skipped** if the ReleasePlan doesn't define a pipeline for it.

## Common Failure Patterns

<!-- TODO: Add conforma (Enterprise Contract) failures — likely warrants its own skill -->
<!-- TODO: Add quay.io service flakes (push failures, timeouts) -->
<!-- TODO: Add signing process failures -->
<!-- TODO: Add other patterns as we encounter them in practice -->

## Do NOT Use Raw kubectl

- Do NOT run `kubectl get releases ...` directly. Use `list-releases.sh`.
- Do NOT run `tkn pr logs ...` directly. Use `release-logs.sh`.
- The scripts produce structured, filterable output and handle the namespace/name splitting for pipelineRun references automatically.

## Keywords for Search

Konflux release, release status, release pipeline, release logs, managed pipeline, tenant pipeline, final pipeline, post-actions, release failed, ReleasePlan, PipelineRun logs, tkn logs, release debugging
