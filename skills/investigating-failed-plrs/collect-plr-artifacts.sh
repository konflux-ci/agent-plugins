#!/bin/bash

# Collect all artifacts for a PipelineRun: PLR, TaskRuns, Pods, container logs.
# Usage: collect-plr-artifacts.sh <tenant-namespace> <pipelinerun-name>
#
# Downloads everything into the shared cache directory for offline investigation.
# All data is fetched via KubeArchive (oc ka).
# Note: oc ka logs returns an error for containers with empty logs (treats them
# as non-existent), so missing log files don't necessarily indicate a problem.

set -eu -o pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <tenant-namespace> <pipelinerun-name>"
    echo "Example: $0 myapp-tenant my-component-on-push-abc123"
    exit 1
fi

TENANT="$1"
PLR_NAME="$2"
CACHE_DIR="${PLR_CACHE_DIR:-./collected-data}"
mkdir -p "$CACHE_DIR"
PLR_FILE="${CACHE_DIR}/collected-pipelinerun-${PLR_NAME}.yaml"

yellow=$(tput setaf 3)
green=$(tput setaf 2)
blue=$(tput setaf 4)
red=$(tput setaf 1)
reset=$(tput sgr0)

fetch_or_cached() {
    local file="$1"
    local label="$2"
    shift 2

    if [[ -r "$file" ]]; then
        echo "   ${green}Cached: ${file}${reset}"
        return 0
    fi

    echo "   Fetching ${label}..."
    if "$@" > "$file" 2>/dev/null; then
        echo "   ${green}Saved: ${file}${reset}"
        return 0
    else
        echo "   ${red}Failed to fetch ${label}${reset}"
        rm -f "$file"
        return 1
    fi
}

# --- PipelineRun ---
echo "${yellow}=== PipelineRun ===${reset}"
fetch_or_cached "$PLR_FILE" "PipelineRun ${PLR_NAME}" \
    oc ka get -n "$TENANT" --limit 1 pipelinerun "$PLR_NAME" -o yaml

# --- TaskRuns, Pods, container logs ---
echo
echo "${yellow}=== TaskRuns ===${reset}"

for tr_name in $(yq '.items[0].status.childReferences[] | select(.kind == "TaskRun") | .name' "$PLR_FILE"); do
    tr_file="${CACHE_DIR}/collected-taskrun-${tr_name}.yaml"
    tr_task="${tr_name#"${PLR_NAME}-"}"
    echo " ${yellow}TaskRun: ${tr_task} (${tr_name})${reset}"

    fetch_or_cached "$tr_file" "TaskRun ${tr_name}" \
        oc ka get -n "$TENANT" --limit 1 taskrun "$tr_name" -o yaml || continue

    # --- Pod manifest ---
    pod_name=$(yq '.items[0].status.podName // ""' "$tr_file")
    if [[ -z "$pod_name" || "$pod_name" == "null" ]]; then
        echo "   ${blue}No pod associated with this TaskRun${reset}"
        continue
    fi

    pod_file="${CACHE_DIR}/collected-pod-${pod_name}.yaml"
    fetch_or_cached "$pod_file" "Pod ${pod_name}" \
        oc ka get -n "$TENANT" --limit 1 pod "$pod_name" -o yaml

    # --- Container logs (from step containers) ---
    step_count=$(yq '.items[0].status.steps | length' "$tr_file" 2>/dev/null || echo "0")
    for i in $(seq 0 $(( step_count - 1 ))); do
        container_name=$(yq ".items[0].status.steps[${i}].container" "$tr_file")
        log_file="${CACHE_DIR}/pod-${pod_name}-${container_name}.log"

        fetch_or_cached "$log_file" "log ${pod_name}/${container_name}" \
            oc ka logs -n "$TENANT" "$pod_name" -c "$container_name" || true
    done

    # --- Container logs (from sidecar containers) ---
    sidecar_count=$(yq '.items[0].status.sidecars | length' "$tr_file" 2>/dev/null || echo "0")
    for i in $(seq 0 $(( sidecar_count - 1 ))); do
        container_name=$(yq ".items[0].status.sidecars[${i}].container" "$tr_file")
        log_file="${CACHE_DIR}/pod-${pod_name}-${container_name}.log"

        fetch_or_cached "$log_file" "sidecar log ${pod_name}/${container_name}" \
            oc ka logs -n "$TENANT" "$pod_name" -c "$container_name" || true
    done
done

# --- Summary ---
echo
echo "${yellow}=== Collection complete ===${reset}"
echo "Cache directory: ${CACHE_DIR}"
echo
ls -1 "${CACHE_DIR}/"
count=$(find "${CACHE_DIR}/" -maxdepth 1 -type f -printf '.' | wc -c)
echo
echo "${blue}Total cached artifacts: ${count}${reset}"
