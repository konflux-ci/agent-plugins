---
name: architecture
description: Use when needing to understand Konflux architecture, design decisions, service responsibilities, APIs, build/test/release workflows, or how Konflux components fit together.
allowed-tools: Bash(git clone:*), Bash(git pull:*), Bash(find:*), Bash(ls:*), Bash(grep:*), Bash(cat:*), Read, Glob, Grep
---

# Konflux Architecture Reference

## Overview

Two GitHub repositories are the canonical source of truth for Konflux architecture. **Clone them and read the actual content** - do not answer architecture questions from memory or training data alone.

## The Two Sources

| Repository | Clone To | Contains |
|---|---|---|
| [konflux-ci/architecture](https://github.com/konflux-ci/architecture) | `/tmp/konflux-architecture` | ADRs, service specs, design diagrams, architectural constraints |
| [konflux-ci/docs](https://github.com/konflux-ci/docs) | `/tmp/konflux-docs` | User-facing guides (AsciiDoc/Antora), API references, troubleshooting |

## How to Gather Information

**Always clone and read.** Do not describe directory layouts from memory - fetch the actual content.

```bash
# Clone or pull to ensure fresh content
if [ -d /tmp/konflux-architecture ]; then git -C /tmp/konflux-architecture pull --ff-only; else git clone https://github.com/konflux-ci/architecture /tmp/konflux-architecture; fi
if [ -d /tmp/konflux-docs ]; then git -C /tmp/konflux-docs pull --ff-only; else git clone https://github.com/konflux-ci/docs /tmp/konflux-docs; fi
```

Then navigate from broad to specific:

**Step 1 - Orient.** Read the overview to identify which services are relevant:
- Read `/tmp/konflux-architecture/architecture/index.md`
- Core services: `architecture/core/` (build-service, integration-service, release-service, pipeline-service, enterprise-contract, hybrid-application-service, konflux-ui)
- Add-ons: `architecture/add-ons/` (image-controller, mintmaker, multi-platform-controller, etc.)

**Step 2 - Read the relevant service doc:**
- Read `/tmp/konflux-architecture/architecture/core/<service-name>.md`
- Extract: responsibilities, CRDs owned, interactions with other services

**Step 3 - Search ADRs** for design rationale:
```bash
# Find ADRs related to your topic
grep -ril "your-topic" /tmp/konflux-architecture/ADR/
# Then read the matching ADRs
```
- 60+ numbered decision records in `ADR/NNNN-description.md`
- ADRs explain **why** a design choice was made

**Step 4 - Get user-facing details** from the docs repo:
```bash
# Find relevant docs pages
grep -ril "your-topic" /tmp/konflux-docs/modules/
```
- Organized by workflow: `modules/building/`, `modules/testing/`, `modules/releasing/`
- Also: `modules/troubleshooting/`, `modules/patterns/`, `modules/reference/`

## When Refining or Critiquing Feature Definitions

Before evaluating a proposed feature, **actually read** these sources:
1. Clone both repos (if not already cloned)
2. Read the service doc(s) the feature touches to understand current boundaries
3. Search ADRs for prior decisions - a proposal may conflict with an existing ADR
4. Read the docs repo to understand the user-facing contract changes would affect
5. Cite specific documents and content in your analysis

## Common Mistakes

| Mistake | Better Approach |
|---|---|
| Describing repos without reading them | Clone and read the actual files |
| Answering from training data | Fetch current content - repos evolve |
| Proposing features without checking ADRs | `grep -ril "topic" /tmp/konflux-architecture/ADR/` first |
| Reading only one repo | Design repo + docs repo together give the full picture |
| Reading everything upfront | Start with overview, then drill into relevant service docs only |
