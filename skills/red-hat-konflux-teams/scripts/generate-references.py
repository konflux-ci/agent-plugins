#!/usr/bin/env python3
"""Generate markdown reference files from team YAML and repo-owners data.

Reads org/repo names from stdin (one per line), team definitions from
data/teams/*.yaml, and ownership from data/repo-owners.yaml.
Writes three files to references/:
  - repos-by-team.md
  - teams-by-repo.md
  - unassociated-repos.md
"""

import sys
from pathlib import Path

import yaml

SKILL_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = SKILL_DIR / "data"
REFS_DIR = SKILL_DIR / "references"


def load_teams():
    teams = {}
    for f in sorted((DATA_DIR / "teams").glob("*.yaml")):
        with open(f) as fh:
            data = yaml.safe_load(fh)
        teams[f.stem] = data
    return teams


def load_repo_owners():
    path = DATA_DIR / "repo-owners.yaml"
    with open(path) as fh:
        return yaml.safe_load(fh) or {}


def read_repo_list():
    return sorted(line.strip() for line in sys.stdin if line.strip())


def write_repos_by_team(teams, repo_owners):
    # Invert: team -> [(repo, clarification)]
    team_repos = {key: [] for key in teams}
    for repo, owners in sorted(repo_owners.items()):
        for entry in owners:
            team_key = entry["team"]
            if team_key in team_repos:
                team_repos[team_key].append((repo, entry["clarification"]))

    REFS_DIR.mkdir(parents=True, exist_ok=True)
    with open(REFS_DIR / "repos-by-team.md", "w") as fh:
        fh.write("# Repositories by Team\n\n")
        fh.write("*Generated file — do not edit. Run `scripts/sync-repos.sh` to regenerate.*\n\n")
        for team_key in sorted(team_repos):
            team = teams[team_key]
            fh.write(f"## {team['name']}\n\n")
            fh.write(f"**JIRA Project:** {team['jira_project'] or 'N/A'}\n\n")
            components = team.get("jira_components") or []
            if components:
                fh.write(f"**JIRA Components (KONFLUX):** {', '.join(components)}\n\n")
            fh.write(f"{team['description'].strip()}\n\n")
            repos = team_repos[team_key]
            if repos:
                fh.write("| Repository | Clarification |\n")
                fh.write("|---|---|\n")
                for repo, clarification in sorted(repos):
                    fh.write(f"| {repo} | {clarification} |\n")
            else:
                fh.write("*No repositories currently mapped to this team.*\n")
            fh.write("\n")


def write_teams_by_repo(teams, repo_owners):
    REFS_DIR.mkdir(parents=True, exist_ok=True)
    with open(REFS_DIR / "teams-by-repo.md", "w") as fh:
        fh.write("# Teams by Repository\n\n")
        fh.write("*Generated file — do not edit. Run `scripts/sync-repos.sh` to regenerate.*\n\n")
        fh.write("| Repository | Team(s) | JIRA Project(s) | Clarification |\n")
        fh.write("|---|---|---|---|\n")
        for repo in sorted(repo_owners):
            owners = repo_owners[repo]
            team_names = []
            jira_projects = []
            clarifications = []
            for entry in owners:
                team_key = entry["team"]
                team = teams.get(team_key, {})
                team_names.append(team.get("name", team_key))
                jp = team.get("jira_project", "")
                if jp and jp not in jira_projects:
                    jira_projects.append(jp)
                clarifications.append(entry["clarification"])
            fh.write(
                f"| {repo} "
                f"| {', '.join(team_names)} "
                f"| {', '.join(jira_projects) or 'N/A'} "
                f"| {'; '.join(clarifications)} |\n"
            )


def write_unassociated(all_repos, repo_owners):
    unassociated = sorted(set(all_repos) - set(repo_owners))
    REFS_DIR.mkdir(parents=True, exist_ok=True)
    with open(REFS_DIR / "unassociated-repos.md", "w") as fh:
        fh.write("# Unassociated Repositories\n\n")
        fh.write("*Generated file — do not edit. Run `scripts/sync-repos.sh` to regenerate.*\n\n")
        fh.write(
            "These repositories in the tracked GitHub orgs are not yet mapped to any team.\n"
            "To associate a repo, add it to `data/repo-owners.yaml` and re-run `scripts/sync-repos.sh`.\n\n"
        )
        if unassociated:
            for repo in unassociated:
                fh.write(f"- {repo}\n")
        else:
            fh.write("*All repositories are associated with a team.*\n")


def main():
    all_repos = read_repo_list()
    teams = load_teams()
    repo_owners = load_repo_owners()

    # Validate team references
    unknown = []
    for repo, owners in repo_owners.items():
        for entry in owners:
            if entry["team"] not in teams:
                unknown.append(f"  repo '{repo}' references unknown team '{entry['team']}'")
    if unknown:
        print("Error: unknown team references in repo-owners.yaml:", file=sys.stderr)
        for msg in unknown:
            print(msg, file=sys.stderr)
        sys.exit(1)

    write_repos_by_team(teams, repo_owners)
    write_teams_by_repo(teams, repo_owners)
    write_unassociated(all_repos, repo_owners)

    owned = len(repo_owners)
    unassociated = len(set(all_repos) - set(repo_owners))
    print(f"Generated references: {owned} owned repos, {unassociated} unassociated repos")


if __name__ == "__main__":
    main()
