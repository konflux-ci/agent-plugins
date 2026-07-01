#!/bin/bash

# Analyze timing of a PipelineRun via KubeArchive.
# Usage: check-plr-timings.sh <tenant-namespace> <pipelinerun-name>
#
# Fetches PLR and TaskRuns via KubeArchive, shows timing breakdown.

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

if ! [[ -r "$PLR_FILE" ]]; then
    echo "Fetching PipelineRun ${PLR_NAME}..."
    oc ka get -n "$TENANT" --limit 1 pipelinerun "$PLR_NAME" -o yaml > "$PLR_FILE"
else
    echo "Using cached PipelineRun ${PLR_FILE}"
fi

yellow=$(tput setaf 3 2>/dev/null || true)
blue=$(tput setaf 4 2>/dev/null || true)
reset=$(tput sgr0 2>/dev/null || true)

stat_waiting_time=0

pr_name=$(yq '.items[0].metadata.name' "$PLR_FILE")
pr_pipeline=$(yq '.items[0].metadata.labels["tekton.dev/pipeline"]' "$PLR_FILE")
pr_created=$(yq '.items[0].metadata.creationTimestamp' "$PLR_FILE")
pr_started=$(yq '.items[0].status.startTime' "$PLR_FILE")
pr_finally=$(yq '.items[0].status.finallyStartTime // "n/a"' "$PLR_FILE")
pr_completed=$(yq '.items[0].status.completionTime // "n/a"' "$PLR_FILE")

echo "${yellow}PipelineRun '${pr_name}' (${pr_pipeline}) duration:${reset}"

# Build header row
printf "  %-22s %-22s %-22s %-22s" "creationTimestamp" "startTime" "finallyStartTime" "completionTime"
if [[ "$pr_started" != "null" && "$pr_created" != "null" ]]; then
    pending=$(( $(date -d "$pr_started" +%s) - $(date -d "$pr_created" +%s) ))
    printf " pending=%ds" "$pending"
else
    printf " pending=n/a"
fi
if [[ "$pr_completed" != "null" && "$pr_completed" != "n/a" && "$pr_created" != "null" ]]; then
    total=$(( $(date -d "$pr_completed" +%s) - $(date -d "$pr_created" +%s) ))
    printf " total=%ds" "$total"
fi
if [[ "$pr_completed" != "null" && "$pr_completed" != "n/a" && "$pr_started" != "null" ]]; then
    running=$(( $(date -d "$pr_completed" +%s) - $(date -d "$pr_started" +%s) ))
    printf " running=%ds" "$running"
fi
echo
printf "  %-22s %-22s %-22s %-22s\n" "$pr_created" "$pr_started" "$pr_finally" "$pr_completed"
echo

# Track earliest TaskRun creation to compute PLR wait time
trs_earliest_start=""
trs_processed=false

for tr_name in $(yq '.items[0].status.childReferences[] | select(.kind == "TaskRun") | .name' "$PLR_FILE"); do
    tr_file="${CACHE_DIR}/collected-taskrun-${tr_name}.yaml"

    if ! [[ -r "$tr_file" ]]; then
        echo " Fetching TaskRun ${tr_name}..."
        oc ka get -n "$TENANT" --limit 1 taskrun "$tr_name" -o yaml > "$tr_file"
    fi

    tr_task=$(yq '.items[0].metadata.labels["tekton.dev/pipelineTask"]' "$tr_file")
    tr_created=$(yq '.items[0].metadata.creationTimestamp' "$tr_file")
    tr_started=$(yq '.items[0].status.startTime // "n/a"' "$tr_file")
    tr_completed=$(yq '.items[0].status.completionTime // "n/a"' "$tr_file")

    # Track earliest TR
    if [[ "$tr_created" != "null" ]]; then
        trs_processed=true
        tr_created_epoch=$(date -d "$tr_created" +%s)
        if [[ -z "$trs_earliest_start" ]] || [[ $tr_created_epoch -lt $trs_earliest_start ]]; then
            trs_earliest_start=$tr_created_epoch
        fi
    fi

    # Compute durations
    tr_pending="n/a"
    tr_running="n/a"
    tr_total="n/a"
    if [[ "$tr_started" != "null" && "$tr_started" != "n/a" && "$tr_created" != "null" ]]; then
        tr_pending=$(( $(date -d "$tr_started" +%s) - $(date -d "$tr_created" +%s) ))
    fi
    if [[ "$tr_completed" != "null" && "$tr_completed" != "n/a" && "$tr_started" != "null" && "$tr_started" != "n/a" ]]; then
        tr_running=$(( $(date -d "$tr_completed" +%s) - $(date -d "$tr_started" +%s) ))
    fi
    if [[ "$tr_completed" != "null" && "$tr_completed" != "n/a" && "$tr_created" != "null" ]]; then
        tr_total=$(( $(date -d "$tr_completed" +%s) - $(date -d "$tr_created" +%s) ))
    fi

    echo " ⤷ ${yellow}TaskRun '${tr_task}' (${tr_name}):${reset}"
    printf "     %-22s %-22s %-22s pending=%-5s running=%-5s total=%-5s\n" \
        "$tr_created" "$tr_started" "$tr_completed" \
        "${tr_pending}s" "${tr_running}s" "${tr_total}s"

    # Show steps
    step_count=$(yq '.items[0].status.steps | length' "$tr_file" 2>/dev/null || echo "0")
    if [[ "$step_count" -gt 0 ]]; then
        echo "     ${yellow}Steps:${reset}"
        for i in $(seq 0 $(( step_count - 1 ))); do
            step_name=$(yq ".items[0].status.steps[${i}].name" "$tr_file")
            step_started=$(yq ".items[0].status.steps[${i}].terminated.startedAt // \"n/a\"" "$tr_file")
            step_finished=$(yq ".items[0].status.steps[${i}].terminated.finishedAt // \"n/a\"" "$tr_file")
            step_reason=$(yq ".items[0].status.steps[${i}].terminated.reason // \"n/a\"" "$tr_file")

            step_duration="n/a"
            if [[ "$step_started" != "n/a" && "$step_finished" != "n/a" ]]; then
                step_duration=$(( $(date -d "$step_finished" +%s) - $(date -d "$step_started" +%s) ))
            fi

            printf "       %-35s %5ss  %s\n" "$step_name" "$step_duration" "$step_reason"
        done
    fi

    # Compute TaskRun wait time (TR creation to first step start)
    if [[ "$step_count" -gt 0 && "$tr_created" != "null" ]]; then
        first_step_start=$(yq '.items[0].status.steps[].terminated.startedAt | select(. != null)' "$tr_file" | sort | head -n 1)
        if [[ -n "$first_step_start" && "$first_step_start" != "null" ]]; then
            tr_wait=$(( $(date -d "$first_step_start" +%s) - $(date -d "$tr_created" +%s) ))
            (( stat_waiting_time += tr_wait ))
            echo "     ${yellow}TaskRun wait time (creation to first step): ${tr_wait}s${reset}"
        fi
    fi
    echo
done

# PLR-level wait time
if [[ "$pr_created" != "null" ]] && $trs_processed; then
    pr_created_epoch=$(date -d "$pr_created" +%s)
    plr_wait=$(( trs_earliest_start - pr_created_epoch ))
    (( stat_waiting_time += plr_wait ))
    echo " ⤷ ${yellow}PipelineRun wait time (creation to first TaskRun): ${plr_wait}s${reset}"
fi

echo
echo "${blue}Total waiting time: ${stat_waiting_time}s${reset}"
