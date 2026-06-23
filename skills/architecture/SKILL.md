---
name: architecture
description: Use when needing to understand Konflux architecture, design decisions, service responsibilities, APIs, build/test/release workflows, or how Konflux components fit together. Provides navigation to the two canonical architecture sources and strategies for progressive discovery.
---

# Konflux Architecture Reference

## Overview

Two GitHub repositories are the canonical source of truth for Konflux architecture. Use them together - they serve complementary purposes.

## The Two Sources

| Repository | What It Contains | When to Use |
|---|---|---|
| [konflux-ci/architecture](https://github.com/konflux-ci/architecture) | ADRs, service specs, design diagrams, architectural constraints | Understanding **why** things work the way they do, service boundaries, design rationale |
| [konflux-ci/docs](https://github.com/konflux-ci/docs) | User-facing guides (AsciiDoc/Antora), API references, troubleshooting, workflows | Understanding **how** to use Konflux, configuration, operational procedures |

Use **architecture** for design-level questions. Use **docs** for usage-level questions. Most feature work requires both.

## Progressive Discovery Strategy

Don't try to read everything. Navigate from broad to specific:

**Step 1 - Orient** with the architecture repo's main overview:
- `architecture/index.md` - Principles, constraints, and service inventory
- Core services live in `architecture/core/` (build, integration, release, pipeline, enterprise-contract, hybrid-application-service, konflux-ui)
- Add-on services live in `architecture/add-ons/` (image-controller, mintmaker, multi-platform-controller, and others)

**Step 2 - Find the relevant service** by reading the specific service doc:
- `architecture/core/<service-name>.md` - e.g., `build-service.md`, `integration-service.md`, `release-service.md`
- Each service doc covers responsibilities, CRDs owned, and interactions with other services

**Step 3 - Check ADRs** for design rationale on the topic:
- `ADR/` contains 60+ numbered decision records: `ADR/NNNN-description.md`
- ADRs explain **why** a design choice was made, not just what it is
- Search ADR filenames and content for your topic before proposing changes that might contradict existing decisions

**Step 4 - Get operational details** from the docs repo:
- Docs are organized by workflow stage: `modules/building/`, `modules/testing/`, `modules/releasing/`, `modules/installing/`
- Each module has `pages/` (main content) and `nav.adoc` (table of contents)
- Also check: `modules/troubleshooting/`, `modules/patterns/`, `modules/reference/`

## When Refining or Critiquing Feature Definitions

Before evaluating a proposed feature:
1. Identify which service(s) the feature touches
2. Read those service architecture docs to understand current boundaries and responsibilities
3. Search ADRs for prior decisions on the same topic - a proposal may conflict with or duplicate an existing ADR
4. Check the docs repo for how the current workflow is documented to users - this reveals the user-facing contract that changes would affect

## Key Directories Quick Reference

**konflux-ci/architecture:**
```
architecture/core/       - Service specs (build, integration, release, pipeline, etc.)
architecture/add-ons/    - Optional service specs (mintmaker, image-controller, etc.)
ADR/                     - Architecture Decision Records (0001-00XX)
diagrams/                - Service and ADR diagrams (draw.io SVG/PNG)
```

**konflux-ci/docs:**
```
modules/building/        - Build configuration, secrets, optimization
modules/testing/         - Integration tests, build-time tests
modules/releasing/       - Release pipelines and management
modules/installing/      - Setup and installation
modules/troubleshooting/ - Debugging guides by service area
modules/patterns/        - Best practices, monorepos, GitOps
modules/reference/       - API references, Kubernetes CRDs
modules/glossary/        - Terminology definitions
```

## Common Mistakes

| Mistake | Better Approach |
|---|---|
| Proposing a feature without checking ADRs | Search `ADR/` for prior decisions on the topic first |
| Reading only one repo | Architecture repo explains design; docs repo explains usage. Both matter. |
| Reading entire service docs upfront | Start with the overview, then read only the relevant service doc |
| Ignoring diagrams | `diagrams/` directory has visual service interaction flows that clarify text docs |
| Assuming docs repo is just tutorials | It contains API references, CRD specs, and troubleshooting that inform architecture |
