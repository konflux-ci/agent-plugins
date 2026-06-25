---
name: red-hat-konflux-teams
description: Use when needing to know which Red Hat team owns a Konflux-related repository (konflux-ci, hermetoproject, conforma orgs), which JIRA project or component to file issues against, or how the Red Hat Konflux engineering organization maps to the codebase.
---

# Red Hat Konflux Teams

Maps repositories across Konflux-related GitHub orgs (`konflux-ci`, `hermetoproject`, `conforma`) to the Red Hat engineering teams that own them and their JIRA metadata.

## How to Answer Questions

**"Which team owns repo X?"** or **"Where do I file a bug for X?"**
Read `references/teams-by-repo.md` and find the repo. The table shows the owning team(s), their JIRA project key(s), and a clarification of each team's stake.

**"What repos does team Y own?"** or **"What does team Y work on?"**
Read `references/repos-by-team.md` and find the team section. It lists the team's JIRA project, JIRA components, description, and all owned repos.

**"What repos have no owner?"**
Read `references/unassociated-repos.md` for repos not yet mapped to any team.

## JIRA Context

Teams use two kinds of JIRA locations:
- **JIRA Project**: The project key where the team's epics and stories live (e.g., STONEBLD, KFLUXINFRA, RELEASE).
- **JIRA Components**: Component names within the KONFLUX JIRA project used for routing support and triage. Not all teams have KONFLUX components — some work entirely within their own JIRA project.

## Keywords

konflux-ci repo owner, repository ownership, JIRA project, JIRA component, file a bug, which team, who owns, team mapping, Red Hat Konflux teams, STONEBLD, KFLUXINFRA, STONEINTG, RELEASE, SRVKP, KONFLUX, KFLUXUI, KFLUXVNGD, KFLUXSE, KFLUXDP, CWFHEALTH, EC, ISV, KAR, PVO11Y, CLOUDDST, SPRE, KFLUXSPRT, ROK, RHELBLD, RELDEV
