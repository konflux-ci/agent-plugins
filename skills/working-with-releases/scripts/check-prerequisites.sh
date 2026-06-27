#!/usr/bin/env bash
# check-prerequisites.sh - Verify CLI tools and cluster connectivity for working with releases
#
# Usage:
#   check-prerequisites.sh
#
# Checks for kubectl, tkn, jq, oc, curl and active cluster connection.
# Exits 0 if all checks pass, 1 otherwise.

set -euo pipefail

FAILED=0

for tool in kubectl tkn jq oc curl; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "OK: $tool"
    else
        echo "MISSING: $tool"
        FAILED=1
    fi
done

if [[ $FAILED -eq 1 ]]; then
    echo ""
    echo "Install missing tools before proceeding."
    exit 1
fi

echo ""
cluster_output=$(kubectl cluster-info --request-timeout=5s 2>&1 || true)
if echo "$cluster_output" | grep -q "running"; then
    echo "$cluster_output" | head -1
else
    echo "NOT CONNECTED: kubectl cannot reach a cluster"
    echo "Use the selecting-konflux-cluster or connecting-to-konflux-cluster skill to connect."
    exit 1
fi
