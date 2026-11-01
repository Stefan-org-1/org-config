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
