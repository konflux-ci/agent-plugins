#!/usr/bin/env bash
# list-releases.sh - List Konflux Releases sorted by creation time
#
# Usage:
#   list-releases.sh [--namespace <ns>] [--limit <n>]
#
# Outputs JSON to stdout. Pipe through jq to filter.
# --limit returns the N most recent releases.
#
# Examples:
#   list-releases.sh | jq '.[].name'
#   list-releases.sh --limit 5 | jq '.[] | {name, status, age}'
#   list-releases.sh | jq '.[] | select(.status == "Failed")'

set -euo pipefail

NAMESPACE_ARGS=()
LIMIT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --namespace|-n)
            [[ $# -lt 2 ]] && { echo "Error: --namespace requires an argument" >&2; exit 1; }
            NAMESPACE_ARGS=(--namespace "$2")
            shift 2
            ;;
        --limit|-l)
            [[ $# -lt 2 ]] && { echo "Error: --limit requires an argument" >&2; exit 1; }
            LIMIT="$2"
            shift 2
            ;;
        *)
            echo "Usage: list-releases.sh [--namespace <ns>] [--limit <n>]" >&2
            exit 1
            ;;
    esac
done

CLUSTER_DOMAIN=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | sed 's|https://api\.||; s|:.*||')

kubectl get releases "${NAMESPACE_ARGS[@]}" --sort-by=.metadata.creationTimestamp -o json | jq --arg limit "${LIMIT:-0}" --arg cluster "$CLUSTER_DOMAIN" '
[.items[] | {
    clusterDomain: $cluster,
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
    status: ([.status.conditions[]? | select(.type == "Released") | .reason] | first // null),
    statusMessage: ([.status.conditions[]? | select(.type == "Released") | .message // ""] | first // null),
    application: (.metadata.labels["appstudio.openshift.io/application"] // null),
    snapshot: .spec.snapshot,
    releasePlan: .spec.releasePlan,
    author: .status.attribution.author,
    target: .status.target,
    tenantPipelineRun: .status.tenantProcessing.pipelineRun,
    managedPipelineRun: .status.managedProcessing.pipelineRun,
    finalPipelineRun: .status.finalProcessing.pipelineRun,
    tenantPipelineStatus: ([.status.conditions[]? | select(.type == "TenantPipelineProcessed") | .reason] | first // null),
    managedPipelineStatus: ([.status.conditions[]? | select(.type == "ManagedPipelineProcessed") | .reason] | first // null),
    finalPipelineStatus: ([.status.conditions[]? | select(.type == "FinalPipelineProcessed") | .reason] | first // null)
}] |
if ($limit | tonumber) > 0 then .[-($limit | tonumber):]
else .
end
'
