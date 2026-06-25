# red-hat-konflux-teams

Maps repositories across Konflux-related GitHub orgs
([konflux-ci](https://github.com/konflux-ci),
[hermetoproject](https://github.com/hermetoproject),
[conforma](https://github.com/conforma)) to the Red Hat engineering teams
that own them and their JIRA metadata (project keys, components).

## Source of truth

The authoritative source for Red Hat Konflux team structure is the
[Konflux Team Structure spreadsheet](https://docs.google.com/spreadsheets/d/1meAQQVmBRUmBYw97JV4eszv4_ugJxbER0WPSdj4y-Ew/edit?gid=698174757#gid=698174757).
This skill exists as a convenience to help the community understand which
Red Hat teams work on which parts of Konflux.

## Maintenance

To update the generated reference docs after repos are added or removed
from the tracked GitHub orgs:

    ./scripts/sync-repos.sh

To assign an unassociated repo to a team, add an entry to
`data/repo-owners.yaml` and re-run the sync script.

To update team JIRA metadata, edit the relevant file in `data/teams/`.

### Prerequisites

- `gh` CLI, authenticated
- Python 3 with PyYAML (`pip install pyyaml`)

## Future considerations

- People data (team leads, managers, architects)
- Slack channels per team
- JIRA validation (checking that project keys and components still exist)
