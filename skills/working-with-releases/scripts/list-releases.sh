#!/usr/bin/env bash
# list-releases.sh - List Konflux Releases sorted by creation time
#
# Usage:
#   list-releases.sh [--namespace <ns>] [--limit <n>]
#
# Outputs JSON to stdout. Pipe through jq to filter.
#
# Examples:
#   list-releases.sh | jq '.[].name'
#   list-releases.sh --limit 5 | jq '.[] | {name, status, age}'
#   list-releases.sh | jq '.[] | select(.status == "Failed")'

set -euo pipefail

NAMESPACE_FLAG=""
LIMIT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --namespace|-n)
            NAMESPACE_FLAG="--namespace $2"
            shift 2
            ;;
        --limit|-l)
            LIMIT="$2"
            shift 2
            ;;
        *)
            echo "Usage: list-releases.sh [--namespace <ns>] [--limit <n>]" >&2
            exit 1
            ;;
    esac
done

# shellcheck disable=SC2086
kubectl get releases $NAMESPACE_FLAG --sort-by=.metadata.creationTimestamp -o json | jq --arg limit "${LIMIT:-0}" '
[.items[] | {
    name: .metadata.name,
    namespace: .metadata.namespace,
    created: .metadata.creationTimestamp,
    age: (
        (now - (.metadata.creationTimestamp | fromdateiso8601)) |
        if . < 3600 then "\(. / 60 | floor)m"
        elif . < 86400 then "\(. / 3600 | floor)h"
        else "\(. / 86400 | floor)d"
        end
    ),
    status: (
        .status.conditions[]? |
        select(.type == "Released") |
        .reason
    ),
    statusMessage: (
        .status.conditions[]? |
        select(.type == "Released") |
        .message // ""
    ),
    snapshot: .spec.snapshot,
    releasePlan: .spec.releasePlan,
    author: .status.attribution.author,
    target: .status.target,
    tenantPipelineRun: .status.tenantProcessing.pipelineRun,
    managedPipelineRun: .status.managedProcessing.pipelineRun,
    finalPipelineRun: .status.finalProcessing.pipelineRun,
    tenantPipelineStatus: (
        .status.conditions[]? |
        select(.type == "TenantPipelineProcessed") |
        .reason
    ),
    managedPipelineStatus: (
        .status.conditions[]? |
        select(.type == "ManagedPipelineProcessed") |
        .reason
    ),
    finalPipelineStatus: (
        .status.conditions[]? |
        select(.type == "FinalPipelineProcessed") |
        .reason
    )
}] |
if ($limit | tonumber) > 0 then .[-($limit | tonumber):]
else .
end
'
