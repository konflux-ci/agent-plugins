#!/bin/bash

# Analyze a failed PipelineRun via KubeArchive.
# Usage: check-plr-errors.sh <tenant-namespace> <pipelinerun-name>
#
# Fetches PLR and TaskRuns via KubeArchive, inspects failure reasons.

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

bold_in=$(tput smso 2>/dev/null || true)
bold_out=$(tput rmso 2>/dev/null || true)
red=$(tput setaf 1 2>/dev/null || true)
green=$(tput setaf 2 2>/dev/null || true)
yellow=$(tput setaf 3 2>/dev/null || true)
blue=$(tput setaf 4 2>/dev/null || true)
reset=$(tput sgr0 2>/dev/null || true)

pr_name=$(yq '.items[0].metadata.name' "$PLR_FILE")
pr_status=$(yq '.items[0].status.conditions[0].status' "$PLR_FILE")
pr_reason=$(yq '.items[0].status.conditions[0].reason' "$PLR_FILE")
pr_msg=$(yq '.items[0].status.conditions[0].message' "$PLR_FILE" | tr "\n" " " | sed "s/ \+$//")

echo "${yellow}PipelineRun: ${bold_in}${pr_name}${bold_out}${reset}"
echo "${yellow}Status: ${pr_status} | Reason: ${pr_reason}${reset}"
echo "${yellow}Message: ${pr_msg}${reset}"
echo

if [[ "$pr_status" == "True" ]]; then
    echo "${green}PipelineRun succeeded — nothing to investigate.${reset}"
    exit 0
fi

if [[ "$pr_reason" == "Cancelled" ]]; then
    echo "${blue}PipelineRun was cancelled.${reset}"
    echo "Check if user/automation cancelled it or if another PLR superseded it."
    exit 0
fi

if [[ "$pr_reason" == "PipelineRunPending" ]]; then
    echo "${blue}PipelineRun was left pending (never started).${reset}"
    echo "Likely kueue/scheduling issue. Consider running /investigating-slow-builds."
    exit 0
fi

if [[ "$pr_reason" == "CouldntGetTask" ]]; then
    echo "${blue}PipelineRun could not resolve a Task reference.${reset}"
    echo "Check if the referenced Task/ClusterTask exists and is accessible."
    exit 0
fi

if [[ "$pr_reason" == "PipelineRunTimeout" ]]; then
    echo "${blue}PipelineRun timed out.${reset}"
    echo "Check timing analysis to see which task was still running."
    exit 0
fi

echo "${red}PipelineRun failed (${pr_reason}). Checking TaskRuns...${reset}"
echo

found_failed_tr=false

for tr_name in $(yq '.items[0].status.childReferences[] | select(.kind == "TaskRun") | .name' "$PLR_FILE"); do
    tr_file="${CACHE_DIR}/collected-taskrun-${tr_name}.yaml"

    if ! [[ -r "$tr_file" ]]; then
        echo " Fetching TaskRun ${tr_name}..."
        oc ka get -n "$TENANT" --limit 1 taskrun "$tr_name" -o yaml > "$tr_file"
    fi

    tr_task_name=$(yq '.items[0].metadata.labels["tekton.dev/pipelineTask"]' "$tr_file")
    tr_status=$(yq '.items[0].status.conditions[0].status' "$tr_file")
    tr_reason=$(yq '.items[0].status.conditions[0].reason' "$tr_file")
    tr_msg=$(yq '.items[0].status.conditions[0].message' "$tr_file" | tr "\n" " " | sed "s/ \+$//")

    if [[ "$tr_status" == "True" ]]; then
        continue
    fi

    found_failed_tr=true

    if [[ "$tr_reason" == "TaskRunImagePullFailed" ]]; then
        echo " ⤷ ${blue}TaskRun image pull failed: ${tr_task_name} (${tr_name})${reset}"
        echo "   ${tr_msg}"
        continue
    fi

    if [[ "$tr_reason" == "PodCreationFailed" ]]; then
        echo " ⤷ ${blue}TaskRun pod creation failed: ${tr_task_name} (${tr_name})${reset}"
        echo "   ${tr_msg}"
        continue
    fi

    if [[ "$tr_msg" == "OOMKilled" || "$tr_msg" == *"exited with code 137: OOMKilled"* ]]; then
        echo " ⤷ ${blue}TaskRun OOMKilled: ${tr_task_name} (${tr_name})${reset}"
        echo "   ${tr_msg}"
        continue
    fi

    if [[ "$tr_reason" == "TaskRunCancelled" ]]; then
        echo " ⤷ ${blue}TaskRun cancelled: ${tr_task_name} (${tr_name})${reset}"
        echo "   ${tr_msg}"
        continue
    fi

    echo " ⤷ ${red}TaskRun failed: ${tr_task_name} (${tr_name})${reset}"
    echo "   Reason: ${tr_reason}"
    echo "   Message: ${tr_msg}"

    # Check steps for failed containers
    step_count=$(yq '.items[0].status.steps | length' "$tr_file" 2>/dev/null || echo "0")
    if [[ "$step_count" -gt 0 ]]; then
        echo "   ${yellow}Steps:${reset}"
        for i in $(seq 0 $(( step_count - 1 ))); do
            step_name=$(yq ".items[0].status.steps[${i}].name" "$tr_file")
            step_rc=$(yq ".items[0].status.steps[${i}].terminated.exitCode // -1" "$tr_file")
            step_reason=$(yq ".items[0].status.steps[${i}].terminated.reason // \"unknown\"" "$tr_file")
            step_msg=$(yq ".items[0].status.steps[${i}].terminated.message // \"\"" "$tr_file" | tr "\n" " " | sed "s/ \+$//")

            if [[ "$step_rc" == "0" ]]; then
                continue
            fi

            # Check if step was skipped due to prior failure
            if [[ "$step_msg" == *"Skipping step because a previous step failed"* ]]; then
                echo "      ⤷ ${blue}Step skipped: ${step_name} (prior step failed)${reset}"
                continue
            fi

            # Check for EC assert failure
            if [[ "$step_name" == "step-assert" && "$step_rc" == "1" && "$step_msg" =~ .*key.*TEST_OUTPUT.*result.*FAILURE ]]; then
                echo "      ⤷ ${blue}Enterprise Contract assert failed: ${step_name}${reset}"
                echo "        ${step_msg}" | head -c 500
                echo
                continue
            fi

            echo "      ⤷ ${red}Step failed: ${step_name} (exit code: ${step_rc}, reason: ${step_reason})${reset}"
            if [[ -n "$step_msg" && "$step_msg" != "null" ]]; then
                echo "        Message: ${step_msg}" | head -c 1000
                echo
            fi
        done
    fi
done

if ! $found_failed_tr; then
    pr_skipped_stopping=$(yq '[.items[0].status.skippedTasks[]? | select(.reason == "PipelineRun was stopping")] | length' "$PLR_FILE")
    if [[ "$pr_skipped_stopping" -gt 0 ]]; then
        echo " ⤷ ${blue}PipelineRun was stopped mid-run (all TaskRuns succeeded, ${pr_skipped_stopping} tasks skipped with 'PipelineRun was stopping')${reset}"
    else
        echo " ⤷ ${yellow}No failed TaskRun found among childReferences despite PipelineRun reporting failure${reset}"
    fi
fi
