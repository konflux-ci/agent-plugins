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
# If a PipelineRun has been garbage collected, falls back to kubearchive
# to retrieve archived logs.
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

# Discover kubearchive API URL (cached for the duration of the script)
KA_HOST=""
discover_kubearchive() {
    if [[ -n "$KA_HOST" ]]; then
        return
    fi
    KA_HOST=$(kubectl get configmap kubearchive-api-url -n product-kubearchive -o jsonpath='{.data.URL}' 2>/dev/null || true)
}

# Fetch archived logs from kubearchive for a PipelineRun
get_archived_logs() {
    local pr_namespace="$1"
    local pr_name="$2"

    discover_kubearchive
    if [[ -z "$KA_HOST" ]]; then
        echo "(kubearchive not available — cannot retrieve archived logs)" >&2
        return 1
    fi

    local token
    token=$(oc whoami -t 2>/dev/null || true)
    if [[ -z "$token" ]]; then
        echo "(no auth token — cannot query kubearchive)" >&2
        return 1
    fi

    local auth_header="Authorization: Bearer $token"

    # Get the PipelineRun from kubearchive to find child TaskRuns
    local pr_json
    pr_json=$(curl -sf -H "$auth_header" \
        "${KA_HOST}/apis/tekton.dev/v1/namespaces/${pr_namespace}/pipelineruns/${pr_name}" 2>/dev/null) || {
        echo "(PipelineRun not found in kubearchive either)" >&2
        return 1
    }

    echo "[kubearchive] Retrieved archived PipelineRun"
    echo ""

    # Get child TaskRun names and iterate
    local task_refs
    task_refs=$(echo "$pr_json" | jq -r '.status.childReferences[]? | "\(.name)\t\(.pipelineTaskName)"')

    if [[ -z "$task_refs" ]]; then
        echo "(no TaskRuns found in archived PipelineRun)" >&2
        return 1
    fi

    while IFS=$'\t' read -r tr_name task_name; do
        echo "  [task: $task_name]"

        # Get TaskRun to find pod name and step names
        local tr_json
        tr_json=$(curl -sf -H "$auth_header" \
            "${KA_HOST}/apis/tekton.dev/v1/namespaces/${pr_namespace}/taskruns/${tr_name}" 2>/dev/null) || {
            echo "    (could not fetch TaskRun from kubearchive)"
            continue
        }

        local pod_name
        pod_name=$(echo "$tr_json" | jq -r '.status.podName // empty')
        if [[ -z "$pod_name" ]]; then
            echo "    (no pod name in archived TaskRun)"
            continue
        fi

        # Get step names and their statuses
        local steps
        steps=$(echo "$tr_json" | jq -r '.status.steps[]? | "\(.name)\t\(.terminated.exitCode // "?")\t\(.terminated.reason // "?")"')

        while IFS=$'\t' read -r step_name exit_code reason; do
            local prefix="    "
            if [[ "$exit_code" != "0" ]]; then
                prefix="  ! "
            fi
            echo "${prefix}[step: ${step_name}] exit=${exit_code} (${reason})"

            # Fetch the actual log for this step
            local log
            log=$(curl -sf -H "$auth_header" \
                "${KA_HOST}/api/v1/namespaces/${pr_namespace}/pods/${pod_name}/log?container=step-${step_name}" 2>/dev/null) || {
                echo "      (logs not available)"
                continue
            }

            if [[ -n "$log" ]]; then
                echo "$log" | sed 's/^/      /'
            fi
        done <<< "$steps"
        echo ""
    done <<< "$task_refs"
}

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

    # Try live logs first, fall back to kubearchive if GC'd
    # shellcheck disable=SC2086
    tkn pipelinerun logs --namespace "$pr_namespace" $FOLLOW "$pr_name" 2>/dev/null || {
        echo "(PipelineRun not found on cluster — trying kubearchive...)" >&2
        get_archived_logs "$pr_namespace" "$pr_name" || {
            echo "Error: could not retrieve logs for $pr_name from cluster or kubearchive" >&2
        }
    }
    echo ""
}

get_logs "Tenant Pipeline" "$TENANT_PR" "TenantPipelineProcessed"
get_logs "Managed Pipeline" "$MANAGED_PR" "ManagedPipelineProcessed"
get_logs "Final Pipeline" "$FINAL_PR" "FinalPipelineProcessed"
