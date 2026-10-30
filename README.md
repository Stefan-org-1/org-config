# org-config

The list of approved repos in Stefan-org-1. A repo not listed here is not supported and cannot deploy.

Each team has one file in `repos/`. To add or change a repo, open a PR against your team's file. Your team or a sentinel approves it, as set in `.github/CODEOWNERS`. A new team file needs platform or a sentinel. Only platform can change `CODEOWNERS`.

Sentinels are senior engineers trusted to approve across teams, so routine changes don't wait on a manager.

## Fields

| Field | Values |
|---|---|
| `tier` | `critical`, `internal` |
| `shape` | `service`, `frontend`, `vendor`, `library`, `config` |
| `status` | `active`, `archived` |
