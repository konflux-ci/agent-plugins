# Working with Releases

A Claude Code skill for investigating Konflux Release status and pipeline logs.

## What it does

Provides two wrapper scripts that produce structured, filterable output for working with Konflux Releases:

- **`list-releases.sh`** — Lists releases sorted by creation time as JSON. Pipe through `jq` to filter.
- **`release-logs.sh`** — Shows logs for all three pipeline stages (tenant, managed, final) of a release.

The skill discourages raw `kubectl`/`tkn` usage in favor of these scripts, which handle namespace resolution and produce consistent output.

## Prerequisites

- `kubectl` — Kubernetes CLI
- `tkn` — Tekton CLI (for pipeline logs)
- `jq` — JSON processor (for filtering output)
- Active connection to a Konflux cluster

## Installation

This skill is installed as part of the `konflux-skills` plugin. See the top-level README for installation instructions.
