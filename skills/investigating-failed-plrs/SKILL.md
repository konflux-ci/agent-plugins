---
name: investigating-failed-plrs
description: >
  Investigate why a specific Konflux PipelineRun failed. Drills through PLR
  conditions, failed TaskRuns, pod status, container exit codes, and timing.
  Use when user asks "why did my build fail?", "PLR failed", "pipeline error",
  or invokes /investigating-failed-plrs.
---

# Investigate Failed Konflux PipelineRun

Help user answer: "Why did my PipelineRun fail?"

Work through these steps interactively — ask user for input when needed, skip steps where info already provided.

## Prerequisites

- `oc` CLI with KubeArchive plugin installed (https://kubearchive.github.io/kubearchive/main/cli/installation.html)
- `yq` and `jq` available
- Logged into the target Konflux cluster (`oc whoami --show-server`)

## Step 1: Identify Cluster and Tenant

Check currently logged-in cluster:
```
oc whoami --show-server
```

Ask user for the tenant namespace (`<something>-tenant`). Verify access:
```
oc get namespace/<tenant>
```

If you have a skill for listing available Konflux clusters, use it. Otherwise, ask the user which cluster to connect to.

If login is needed, suggest:
```
oc login --web <api_server>
```


## Step 2: Find the Failed PipelineRun

**IMPORTANT**: KubeArchive wraps results in `.items[]` — always use `yq '.items[0]...'`.

If user already provided a specific PipelineRun name, skip to Step 3.

**Find recent failed ones:**
```
oc ka get -n <tenant> --limit 20 pipelinerun -o yaml | yq '.items[] | select(.status.conditions[0].status != "True") | [.metadata.name, .status.conditions[0].reason, .metadata.creationTimestamp] | @tsv'
```

If no failures found with the above, list all recent PLRs and let user pick:
```
oc ka get -n <tenant> --limit 10 pipelinerun
```

Note the PipelineRun name for use in the next steps.

## Step 3: Run Error Analysis

Run the bundled error analysis script (it fetches the PLR via KubeArchive):
```
<skill_dir>/check-plr-errors.sh <tenant> <pipelinerun-name>
```

This script:
- Fetches the PipelineRun and checks PLR-level conditions (Cancelled, Pending, Timeout, CouldntGetTask, Stopped)
- For failed PLRs, fetches each TaskRun via KubeArchive
- Identifies TaskRun failure reasons (ImagePullFailed, PodCreationFailed, OOMKilled, Cancelled)
- For unknown TaskRun failures, checks step exit codes and messages
- Detects Enterprise Contract assertion failures and skipped steps

Review the output. The script classifies failures into known categories (blue) vs unknown (red). Focus on red items — those need investigation.

## Step 4: Run Timing Analysis

Run the bundled timing analysis script (it fetches the PLR via KubeArchive):
```
<skill_dir>/check-plr-timings.sh <tenant> <pipelinerun-name>
```

This script:
- Shows PLR-level timing (creation → start → completion, pending vs run duration)
- Fetches each TaskRun and shows per-task timing breakdown
- Shows per-step timing within each TaskRun
- Computes total waiting time across all levels

Even for failed PLRs, timing is valuable — it shows whether the failure happened early or late, whether the PLR was stuck pending, and which task was running when it failed.

## Cached Artifacts

All scripts share a local cache directory (`./collected-data/`, overridable via `PLR_CACHE_DIR`). Artifacts are only downloaded once — subsequent runs reuse cached files. Use these cached files for followup investigation instead of re-fetching from KubeArchive.

**To collect all artifacts** (PLR, TaskRuns, Pod manifests, and container logs) for deeper offline investigation:
```
<skill_dir>/collect-plr-artifacts.sh <tenant> <pipelinerun-name>
```

This downloads everything via KubeArchive into the shared cache. Run it when the error/timing scripts don't provide enough detail and you need to read full container logs or inspect pod state.

**Note:** `oc ka logs` returns an error for containers with empty logs (treats them as non-existent), so a "Failed to fetch" message for a log does not necessarily mean something went wrong — the container may simply have produced no output.

**Naming conventions:**
- PipelineRun manifests: `collected-pipelinerun-<plr-name>.yaml`
- TaskRun manifests: `collected-taskrun-<taskrun-name>.yaml`
- Pod manifests: `collected-pod-<pod-name>.yaml`
- Container logs: `pod-<pod-name>-<container-name>.log`

**Reusing cached data in followup investigation:**
- To inspect a cached TaskRun: `yq '.items[0]...' collected-data/collected-taskrun-<name>.yaml`
- To inspect the cached PLR: `yq '.items[0]...' collected-data/collected-pipelinerun-<name>.yaml`
- To inspect a cached Pod: `yq '.items[0]...' collected-data/collected-pod-<name>.yaml`
- To read a container log: `cat collected-data/pod-<pod-name>-<container-name>.log`
- List all cached artifacts: `ls collected-data/`

## Step 5: Deeper Investigation

TODO: This section needs human touch to make it practical and easy to follow

Based on scripts output, investigate further:

**If PLR was Cancelled or Stopped:**
- Check if user/automation cancelled it
- Check if another PLR superseded it (common with rapid git pushes)

**If TaskRun had ImagePullFailed:**
- Check image reference in the TaskRun spec
- Check registry availability (quay.io, registry.redhat.io)
- Verify image name and tag spelling — typos are common
- Verify ServiceAccount has correct imagePullSecrets
- Check network policies that might block registry access

**If TaskRun was OOMKilled:**
- Check container resource requests vs actual usage
- Compare with successful runs of same pipeline
- Suggest implementing <https://konflux.pages.redhat.com/docs/users/building/overriding-compute-resources.html>

**If container failed with non-zero exit code:**
- Read the full container log (the script shows the tail)
- Exit code 127 = command not found — wrong container image or missing tool
- Exit code 137 = OOMKilled — increase memory limits
- Check script syntax errors in the step definition
- Verify working directory is correct (`workingDir` in Task)
- Verify required environment variables and parameters are set

**If PLR was stuck pending (large creation→start gap):**
- This is a scheduling/kueue issue — consider running `/investigating-slow-builds` instead

**If TaskRun had PodCreationFailed:**
- Check namespace ResourceQuota — quota may be exhausted
- Check if referenced ServiceAccount exists
- Check RBAC: `oc auth can-i create pods --as=system:serviceaccount:<namespace>:<sa-name>`

**If workspace or volume mount errors occurred:**
- Check PVC exists and is Bound: `oc get pvc -n <tenant>`
- Verify workspace name matches between Pipeline and PipelineRun definitions
- Check PVC AccessMode (RWO vs RWX) — RWO can't be shared across nodes
- Verify storage class exists and provisioner is available

**If permission or RBAC errors ("Forbidden", "unauthorized"):**
- Check ServiceAccount exists: `oc get sa <sa-name> -n <tenant>`
- Check RoleBindings: `oc get rolebindings -n <tenant>`
- Test specific permissions: `oc auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<sa-name>`
- For cross-namespace access, ClusterRole/ClusterRoleBinding may be needed

**If PLR timed out:**
- Check timing analysis (Step 4) to identify which task was still running
- Look for processes hanging without progress in container logs
- Check for slow network operations (dependency downloads, registry pulls)
- Consider adding progress logging to long-running steps to detect hangs
- Increase timeout only after understanding the root cause

## Step 6: Summary

Summarize:
1. **What failed**: Which TaskRun/step/container
2. **Why it failed**: Exit code, error message, condition
3. **Category**: Known issue (ImagePull, OOM, Eviction, EC failure) or unknown
4. **Action**: What the user should do next
