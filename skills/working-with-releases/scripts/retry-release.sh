#!/usr/bin/env bash
# retry-release.sh - Retry a failed Release by creating a new one with the same spec
#
# Usage:
#   retry-release.sh <release-name> --namespace <ns> [--dry-run]
#
# Creates a new Release with the same snapshot and releasePlan as the original,
# using a "-retry-NNN" suffix. Strips Kubernetes-managed metadata, controller
# finalizers, and the random generateName suffix. Existing -retry-NNN suffixes
# are scrubbed so retries don't stack (e.g. foo-retry-001, not foo-retry-001-retry-002).
#
# Examples:
#   retry-release.sh my-release-abc123 --namespace my-tenant
#   retry-release.sh my-release-abc123 --namespace my-tenant --dry-run

set -euo pipefail

RELEASE_NAME=""
NAMESPACE=""
DRY_RUN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --namespace|-n)
            [[ $# -lt 2 ]] && { echo "Error: --namespace requires an argument" >&2; exit 1; }
            NAMESPACE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="1"
            shift
            ;;
        -*)
            echo "Usage: retry-release.sh <release-name> --namespace <ns> [--dry-run]" >&2
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
    echo "Usage: retry-release.sh <release-name> --namespace <ns> [--dry-run]" >&2
    exit 1
fi

if [[ -z "$NAMESPACE" ]]; then
    echo "Error: --namespace is required" >&2
    echo "Usage: retry-release.sh <release-name> --namespace <ns> [--dry-run]" >&2
    exit 1
fi

# Fetch the original release
RELEASE_JSON=$(kubectl get release "$RELEASE_NAME" --namespace "$NAMESPACE" -o json)

# Verify it actually failed
RELEASE_STATUS=$(echo "$RELEASE_JSON" | jq -r '[.status.conditions[]? | select(.type == "Released") | .reason] | first // "Unknown"')
if [[ "$RELEASE_STATUS" != "Failed" ]]; then
    echo "Warning: release '$RELEASE_NAME' has status '$RELEASE_STATUS', not 'Failed'"
    echo "Are you sure you want to retry? (The new Release will be created regardless.)"
    echo ""
fi

# Extract the base name: strip the random generateName suffix and any existing -retry-NNN
GENERATE_NAME=$(echo "$RELEASE_JSON" | jq -r '.metadata.generateName // empty')
if [[ -n "$GENERATE_NAME" ]]; then
    # generateName is the prefix, the rest is random suffix — use generateName as base
    BASE_NAME="$GENERATE_NAME"
else
    # No generateName, use the full name as base
    BASE_NAME="$RELEASE_NAME"
fi

# Strip any existing -retry-NNN suffix from the base
shopt -s extglob
BASE_NAME="${BASE_NAME%-retry-+([0-9])}"
shopt -u extglob

# Find existing retries to determine the next number
EXISTING_RETRIES=$(kubectl get releases --namespace "$NAMESPACE" -o json 2>/dev/null | \
    jq -r --arg base "$BASE_NAME" '
        [.items[].metadata.name | select(startswith($base + "-retry-"))] |
        map(capture("-retry-(?<n>[0-9]+)$") | .n | tonumber) |
        sort | last // 0
    ')

NEXT_RETRY=$((EXISTING_RETRIES + 1))
RETRY_NAME=$(printf '%s-retry-%03d' "$BASE_NAME" "$NEXT_RETRY")

# Build the new Release resource
NEW_RELEASE=$(echo "$RELEASE_JSON" | jq --arg name "$RETRY_NAME" --arg ns "$NAMESPACE" '
{
    apiVersion: .apiVersion,
    kind: .kind,
    metadata: {
        name: $name,
        namespace: $ns,
        labels: (.metadata.labels // {}),
        annotations: ((.metadata.annotations // {}) | with_entries(
            select(.key | startswith("kubectl.kubernetes.io/") | not)
        ))
    },
    spec: .spec
}
')

echo "Original:  $RELEASE_NAME (status: $RELEASE_STATUS)"
echo "Retry as:  $RETRY_NAME"
echo "Namespace: $NAMESPACE"
echo "Snapshot:  $(echo "$RELEASE_JSON" | jq -r '.spec.snapshot')"
echo "Plan:      $(echo "$RELEASE_JSON" | jq -r '.spec.releasePlan')"
echo ""

if [[ -n "$DRY_RUN" ]]; then
    echo "--- Dry run: would create the following Release ---"
    echo "$NEW_RELEASE" | jq .
    exit 0
fi

echo "$NEW_RELEASE" | kubectl create --namespace "$NAMESPACE" -f -
echo ""
echo "Release '$RETRY_NAME' created. Use release-logs.sh to monitor progress:"
echo "  release-logs.sh $RETRY_NAME --namespace $NAMESPACE --follow"
