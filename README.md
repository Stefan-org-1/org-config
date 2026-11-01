# org-manifest

The approved repos, teams and members in Stefan-org-1. A repo not listed here is not supported and cannot deploy. [org-terraform](https://github.com/Stefan-org-1/org-terraform) applies these files to GitHub.

Each team has one file in `repos/`. To add or change a repo or a member, open a PR against your team's file. Your team's sentinels or managers approve it, as set in `.github/CODEOWNERS`. Platform approves everything else, including new team files and `CODEOWNERS` itself.

Sentinels are senior engineers trusted to approve across teams, so routine changes don't wait on a manager.

## Fields

| Field | Values |
|---|---|
| `tier` | `critical`, `internal` |
| `shape` | `service`, `frontend`, `vendor`, `library`, `config`, `docs` |
| `status` | `active`, `archived` |
| `rulesets` | Rule sets for merges and per environment. Each key under `rulesets.deploy` is an environment, created in the repo. The sets are defined in [org-policy](https://github.com/Stefan-org-1/org-policy#rule-sets) |
| `shared` | `true` gives every team write access, for platform repos teams contribute to |
| `code_owner_review` | `true` makes GitHub require a code owner's approval on PRs to the default branch |
| `required_checks` | GitHub Actions checks that must pass before merging, such as `validate` |

## Validation

`validate.py` runs on every PR and must pass. It rejects:

- A file defining a team other than its own name.
- Sentinels or managers who are not members.
- Unknown fields, so a typo is not silently ignored.
- Values outside the allowed ones, and environment names that are not lowercase.
- Rule sets that do not exist in org-policy.
- A repo listed by two teams.
- `shared`, `code_owner_review` or `required_checks` outside platform repos, since they widen access or change enforcement.
- People who are not GitHub users.

Moving a repo between teams changes both team files, so both teams' code owners must approve.

```
python validate.py . ../org-policy
```
