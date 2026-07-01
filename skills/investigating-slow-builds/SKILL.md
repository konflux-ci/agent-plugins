---
name: investigating-slow-builds
description: >
  Investigate why Konflux builds/pipeline runs are slow.
  Use when user asks "why are my builds slow?", "pipeline runs taking long",
  "slow PLR", or invokes /investigating-slow-builds.
---

# Investigate Slow Konflux Builds

Help user answer: "Why are my Konflux builds/pipeline runs so slow?"

Work through these steps interactively — ask user for input when needed, skip steps where info already provided.

## Step 1: Identify the Cluster

Determine which Konflux cluster we're investigating.

Check currently logged-in cluster:
```
oc whoami --show-server
```

If you have a skill for listing available Konflux clusters, use it. Otherwise, ask the user which cluster to connect to.

If login is needed, suggest:
```
oc login --web <api_server>
```

## Step 2: Identify the Tenant Namespace

Determine which namespace/tenant user cares about. Format: `<something>-tenant`.

Ask user if not provided. Verify access:
```
oc get namespace/<tenant>
```

## Step 3: Find PipelineRuns to Investigate

Use KubeArchive `oc` plugin to inspect past PipelineRuns. If not installed, user needs: https://kubearchive.github.io/kubearchive/main/cli/installation.html

**IMPORTANT**: KubeArchive wraps results in `.items[]` — always use `yq '.items[0]...'` (unlike regular `oc get -o yaml` which gives direct access).

Choose approach based on what user provided:

**Specific PipelineRun name given:**
```
oc ka get -n <tenant> --limit 10 pipelinerun <pipelinerun>
```

**Specific component given:**
```
oc ka get -n <tenant> --limit 10 pipelinerun --selector appstudio.openshift.io/component=<component>
```

**No specifics — list recent ones:**
```
oc ka get -n <tenant> --limit 10 pipelinerun
```

If user mentions a time frame, use `--before` (and/or `--after`) parameter:
```
oc ka get -n <tenant> --limit 10 pipelinerun --before 2026-01-01T00:00:00Z
```

Save PLR YAML to temp file to avoid repeated downloads:
```
oc ka get -n <tenant> --limit 10 pipelinerun <pipelinerun> -o yaml > /tmp/pr.yaml
```

## Step 4: Analyze PipelineRun Timeline

### 4a: Sanity check — is it complete?

```
cat /tmp/pr.yaml | yq '.items[0].status.conditions'
```

Look for `type: Succeeded` with `status: "True"` and `reason: Completed`. If not successfully completed, this PLR might need error investigation instead — consider running `/investigating-failed-plrs`.

### 4b: Check timestamps

Extract all timing fields:
```
cat /tmp/pr.yaml | yq '.items[0].metadata.creationTimestamp'
cat /tmp/pr.yaml | yq '.items[0].status.startTime'
cat /tmp/pr.yaml | yq '.items[0].status.finallyStartTime'
cat /tmp/pr.yaml | yq '.items[0].status.completionTime'
cat /tmp/pr.yaml | yq '.items[0].metadata.deletionTimestamp'
```

Analyze the gaps:
- **creationTimestamp -> startTime**: Time PLR waited before starting (kueue queue time — PLR created as pending waiting for resources, kueue limits concurrent PLRs on cluster). Large gap = cluster congestion / kueue throttling.
- **startTime -> finallyStartTime**: Time executing main tasks (the `finally` block runs after all regular tasks). This is the actual build work time.
- **finallyStartTime -> completionTime**: Time in `finally` tasks (cleanup, reporting).
- **completionTime -> deletionTimestamp**: Post-completion retention before garbage collection.

### 4c: Check individual task durations

List all TaskRuns from the PipelineRun:
```
cat /tmp/pr.yaml | yq '.items[0].status.childReferences[] | select(.kind == "TaskRun") | .name' | sort
```

For each TaskRun, fetch via KubeArchive and extract timing:
```
for tr_name in $(cat /tmp/pr.yaml | yq '.items[0].status.childReferences[] | select(.kind == "TaskRun") | .name'); do
  oc ka get -n <tenant> --limit 1 taskrun "$tr_name" -o yaml > "/tmp/tr-${tr_name}.yaml"
  task_label=$(cat "/tmp/tr-${tr_name}.yaml" | yq '.items[0].metadata.labels["tekton.dev/pipelineTask"]')
  created=$(cat "/tmp/tr-${tr_name}.yaml" | yq '.items[0].metadata.creationTimestamp')
  started=$(cat "/tmp/tr-${tr_name}.yaml" | yq '.items[0].status.startTime')
  completed=$(cat "/tmp/tr-${tr_name}.yaml" | yq '.items[0].status.completionTime')
  pending=$(( $(date -d "$started" +%s) - $(date -d "$created" +%s) ))
  running=$(( $(date -d "$completed" +%s) - $(date -d "$started" +%s) ))
  total=$(( $(date -d "$completed" +%s) - $(date -d "$created" +%s) ))
  printf "%-40s pending=%4ds  running=%4ds  total=%4ds\n" "$task_label" "$pending" "$running" "$total"
done | sort -t= -k4 -n -r
```

Output is sorted by total duration descending — top entries are the bottlenecks.

Large **pending** time on a TaskRun means it waited for pod scheduling (node resources, PVC provisioning). Large **running** time means the task itself is slow (build-container, clamav-scan, etc.).

### 4d: Check platforms build was happening on

Check which platforms this was building for (directly translates to what VMs MPC had to provision):
```
cat /tmp/pr.yaml | yq '.items[0].spec.params[] | select(.name == "build-platforms") | .value'
```

## Step 5: Check Tenant ResourceQuota

Check what quota exists (there should be only one called "konflux"):
```
oc -n <tenant> get ResourceQuota -o name
```

Check quota status (hard limits vs current usage):
```
oc -n <tenant> get ResourceQuota/konflux -o yaml | yq .status
```

Compare `.status.used` vs `.status.hard` for key resources:
- `count/pipelineruns.tekton.dev` — PLR count limit
- `requests.cpu` — CPU requests limit
- `requests.memory` — memory requests limit
- `count/persistentvolumeclaims` — PVC limit
- `requests.storage` — storage limit

**Note**: `.status.used` shows CURRENT usage only, not historical. Useful to check if any resource is currently at or near its hard limit (potential bottleneck), but won't show past saturation.

## Step 6: Prometheus Metrics (Optional — Requires Cluster Access)

Query Prometheus for historical data around the time the PLR ran. This helps distinguish tenant-level problems (quota) from cluster-level problems (kueue, overload).

**IMPORTANT**: We will use the `prometheus-cli` tool. Check if it is installed locally first:
```
command -v prometheus-cli
```

If available, use it directly: `prometheus-cli ...`

If not installed locally, fall back to:
```
uvx --from git+https://github.com/Appservices-perfscale/prometheus-cli.git prometheus-cli
```

Key parameters of `query` subcommand:
- `--interval <duration>` — relative time range from now (e.g. `1h`, `24h`, `7d`)
- `--start <ISO8601>` / `--end <ISO8601>` — absolute time range
- `--step <duration>` — query resolution, "auto" by default (e.g. `15s`, `1m`, `5m`)
- `--downsample <duration>` — downsample output for readability
- `--csv <file>` — dump full data to the file
- `--graph <file>` — generate PNG graph (you can show it to the user with `xdg-open <file>`)

Use `--start` / `--end` matching the PLR's creationTimestamp through completionTime (with some margin).

### 6a: Find Thanos Querier URL

Get it from the cluster:
```
oc -n openshift-monitoring get route/thanos-querier -o jsonpath='{.spec.host}'
```

If you have a skill for discovering Grafana dashboards, use it. Otherwise, ask the user for the Grafana URL (search for "Performance: Tenant resources usage" dashboard).

### 6b: Tenant-Scoped Metrics (any user with Thanos access)

**Quick quota saturation check** — was ANY quota resource near its limit?
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'max(sum(kube_resourcequota{namespace="<tenant>", type="used"}) by (resource) / sum(kube_resourcequota{namespace="<tenant>", type="hard"} > 0) by (resource))' \
  --start <plr-start> --end <plr-end>
```

Values close to 1.0 = near quota limit = potential cause of slowness.

**Detailed quota breakdown** (if saturation detected, shows resources above 30% usage):
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'sort_desc(sum(kube_resourcequota{namespace="<tenant>", type="used"}) by (resource) / sum(kube_resourcequota{namespace="<tenant>", type="hard"} > 0) by (resource)) > 0.3' \
  --start <plr-start> --end <plr-end>
```

**Image pull delays** — average time from pod creation to first container start (includes image pull + kubelet scheduling):
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'avg by (namespace) (taskrun_pod_duration_kubelet_to_container_start_milliseconds_sum{namespace="<tenant>"} / taskrun_pod_duration_kubelet_to_container_start_milliseconds_count{namespace="<tenant>"}) / 1000' \
  --start <plr-start> --end <plr-end>
```

Result is in seconds. High values (>30s) suggest registry throttling or large image pulls.

### 6c: Cluster-Wide Metrics (requires cluster-admin access)

Ask user: "Do you have cluster-admin access? These queries check if the cluster itself was overloaded."

If user doesn't have access, skip to Step 7 — tenant-level data from 6b is still valuable.

**Kueue queue depth** — how many workloads were waiting to be admitted?
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'sum by (status) (kueue_pending_workloads{cluster_queue="cluster-pipeline-queue"})' \
  --start <plr-start> --end <plr-end>
```

Non-zero `status="active"` = workloads queued waiting for resources. Non-zero `status="inadmissible"` = workloads stuck until cluster conditions change (worse).

**Kueue resource bottleneck** — which resource is most reserved relative to its nominal quota?
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'sort_desc(max by (resource) (kueue_cluster_queue_resource_reservation{cluster_queue="cluster-pipeline-queue"} / kueue_cluster_queue_nominal_quota{cluster_queue="cluster-pipeline-queue"} * 100))' \
  --start <plr-start> --end <plr-end>
```

Values near 100% = that resource is the scheduling bottleneck. Common culprits: CPU, memory, PVCs.

**MPC VM provisioning delays** — how long did Multi Platform Controller take to provision build VMs?
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'multi_platform_controller_wait_time' \
  --start <plr-start> --end <plr-end>
```

High wait times = MPC pool exhausted, builds waiting for VMs. Also check allocation time (cloud provider instance start latency):
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'multi_platform_controller_host_allocation_time' \
  --start <plr-start> --end <plr-end>
```

And check for provisioning failures:
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'increase(multi_platform_controller_provisioning_failures[1h])' \
  --start <plr-start> --end <plr-end>
```

### 6d: Per-Namespace Container Issues (tenant-scoped, but may need cluster access)

**Containers stuck in waiting state** — pods that can't start:
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'sum by (reason, pod, container) (kube_pod_container_status_waiting_reason{namespace="<tenant>"})' \
  --start <plr-start> --end <plr-end>
```

Common waiting reasons: `ContainerCreating` (pulling images), `CrashLoopBackOff`, `ImagePullBackOff`.

**Abnormally terminated containers** — containers that exited for reasons other than normal completion:
```
prometheus-cli --url "https://<thanos-querier-host>" query \
  --query 'count by (reason, pod, container) (increase(kube_pod_container_status_terminated_reason{reason!="Completed", namespace="<tenant>"}[1h]))' \
  --start <plr-start> --end <plr-end>
```

Non-zero = containers OOMKilled, Errored, or Evicted — indicates resource pressure or bugs.

## Step 7: Summary and Recommendations

After gathering data, summarize findings:

1. **Queue wait time** (creationTimestamp -> startTime): Was PLR waiting in kueue queue?
2. **Build duration** (startTime -> finallyStartTime): Was actual build work slow?
3. **Duration per task**: Which TaskRuns are the bottlenecks?
4. **Tenant quota pressure**: Any resources near limits?
5. **Kueue state** (if cluster-admin data available): Were workloads queued? Which resource was the bottleneck?
6. **Image pull delays**: Were containers slow to start?
7. **MPC provisioning**: Were multi-platform VMs slow to provision or failing?
8. **Container issues**: Were containers stuck waiting or being OOMKilled?

Classify the root cause:

**Tenant-level issues** (user/team can act on):
- **Quota saturation**: Tenant hitting resource limits -> pods can't schedule. Action: request quota increase or reduce concurrent builds.
- **Large build context**: Specific tasks (build-container, clamav-scan) dominating duration. Action: optimize Dockerfile, reduce image size, review build pipeline config.
- **Multi-platform builds**: Building for many platforms -> MPC must provision VMs for each. Action: reduce platform list if not all needed.

**Cluster-level issues** (need platform team):
- **Kueue throttling**: `kueue_pending_workloads > 0` during the PLR's lifetime -> builds queued. Action: escalate to platform team.
- **Kueue resource bottleneck**: Reservation/nominal near 100% for specific resource -> cluster can't admit more workloads. Action: escalate to platform team with the specific resource identified.
- **MPC provisioning delays**: High wait/allocation times or provisioning failures -> multi-platform builds delayed. Action: escalate to platform team.
- **Registry throttling**: High image pull delays (>30s average). Action: check if registry mirrors are configured, escalate if cluster-wide.
- **Container OOMKills/Evictions**: Pods terminated abnormally -> resource requests too low or node pressure. Action: increase resource requests or escalate.
