#!/usr/bin/env bash
# release-logs.sh - Show logs for all PipelineRuns associated with a Release
#
# Usage:
#   release-logs.sh <release-name> [--namespace <ns>] [--follow]
#
# Fetches the Release resource, extracts pipelinerun references from
# tenantProcessing, managedProcessing, and finalProcessing, then runs
# "tkn pr logs" on each in sequence.
#
# Examples:
#   release-logs.sh my-release-abc123
#   release-logs.sh my-release-abc123 --namespace my-tenant --follow

set -euo pipefail

RELEASE_NAME=""
NAMESPACE_FLAG=""
FOLLOW=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --namespace|-n)
            NAMESPACE_FLAG="--namespace $2"
            shift 2
            ;;
        --follow|-f)
            FOLLOW="-f"
            shift
            ;;
        -*)
            echo "Usage: release-logs.sh <release-name> [--namespace <ns>] [--follow]" >&2
            exit 1
            ;;
        *)
            if [[ -z "$RELEASE_NAME" ]]; then
                RELEASE_NAME="$1"
            else
                echo "Error: unexpected argument '$1'" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$RELEASE_NAME" ]]; then
    echo "Error: release name is required" >&2
    echo "Usage: release-logs.sh <release-name> [--namespace <ns>] [--follow]" >&2
    exit 1
fi

# Fetch the release JSON once
# shellcheck disable=SC2086
RELEASE_JSON=$(kubectl get release "$RELEASE_NAME" $NAMESPACE_FLAG -o json)

echo "=== Release: $RELEASE_NAME ==="
echo "$RELEASE_JSON" | jq -r '"Status: \(.status.conditions[]? | select(.type == "Released") | "\(.reason) - \(.message // "")")"'
echo ""

# Extract pipelinerun references (format: "namespace/name")
TENANT_PR=$(echo "$RELEASE_JSON" | jq -r '.status.tenantProcessing.pipelineRun // empty')
MANAGED_PR=$(echo "$RELEASE_JSON" | jq -r '.status.managedProcessing.pipelineRun // empty')
FINAL_PR=$(echo "$RELEASE_JSON" | jq -r '.status.finalProcessing.pipelineRun // empty')

# Helper to extract namespace and name from "namespace/name" format
get_logs() {
    local label="$1"
    local ref="$2"
    local condition_type="$3"

    if [[ -z "$ref" ]]; then
        local reason
        reason=$(echo "$RELEASE_JSON" | jq -r --arg t "$condition_type" '
            .status.conditions[]? | select(.type == $t) | .reason // "Unknown"
        ')
        echo "--- $label: $reason (no PipelineRun) ---"
        echo ""
        return
    fi

    local pr_namespace pr_name
    pr_namespace="${ref%%/*}"
    pr_name="${ref##*/}"

    echo "--- $label: $pr_namespace/$pr_name ---"

    local status
    status=$(echo "$RELEASE_JSON" | jq -r --arg t "$condition_type" '
        .status.conditions[]? | select(.type == $t) | "\(.reason) - \(.message // "")"
    ')
    echo "Condition: $status"
    echo ""

    # shellcheck disable=SC2086
    tkn pipelinerun logs --namespace "$pr_namespace" $FOLLOW "$pr_name" || {
        echo "Error: failed to get logs for $pr_name in namespace $pr_namespace" >&2
        echo "The PipelineRun may have been garbage collected or the namespace may be inaccessible." >&2
    }
    echo ""
}

get_logs "Tenant Pipeline" "$TENANT_PR" "TenantPipelineProcessed"
get_logs "Managed Pipeline" "$MANAGED_PR" "ManagedPipelineProcessed"
get_logs "Final Pipeline" "$FINAL_PR" "FinalPipelineProcessed"
