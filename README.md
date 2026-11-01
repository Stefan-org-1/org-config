# org-config

The list of approved repos in Stefan-org-1. A repo not listed here is not supported and cannot deploy.

Each team has one file in `repos/`. To add or change a repo, open a PR against your team's file. Your team or a sentinel approves it, as set in `.github/CODEOWNERS`. A new team file needs platform or a sentinel. Only platform can change `CODEOWNERS`.

Sentinels are senior engineers trusted to approve across teams, so routine changes don't wait on a manager.

## Fields

| Field | Values |
|---|---|
| `tier` | `critical`, `internal` |
| `shape` | `service`, `frontend`, `vendor`, `library`, `config`, `docs` |
| `status` | `active`, `archived` |

## Rule sets

The deploy gate checks PRs and deploys against rule sets in `rulesets/`. Each file is a named group of rules with parameters.

- `baseline.yaml` lists the sets every repo gets, for merge and for deploy.
- A repo's manifest entry adds its own under `rulesets.merge` and `rulesets.deploy.<environment>`.
- All selected sets must pass.
- Sets with `break_glass: true` are soft. An emergency change in `change-requests`, approved by the people `baseline.yaml` lists under `break_glass`, overrides them.

```yaml
# repos/payments.yaml
rulesets:
  merge: [workflow-sentinel, scanned]
  deploy:
    prod: [from-main, change-team, scanned]
```

### Available sets

| Set | Kind | Passes when |
|---|---|---|
| `platform-integrity` | hard | The repo is active in this manifest |
| `central-deploy` | hard | The deploy uses `ci-templates` `deploy.yml` |
| `scanned` | hard | `ci-templates` `scan.yml` signed a passing scan for the commit |
| `workflow-sentinel` | hard | A PR that changes `.github/workflows/` is approved by any sentinel |
| `change-team` | hard | A change request covers the deploy, approved by anyone on the owning team |
| `change-two-person` | hard | Same, approved by a sentinel and a different manager of the owning team |
| `from-main` | soft | The commit is on `main` and passed the merge gate |
| `green-pipeline` | soft | Every other workflow run on the commit passed |
| `deploy-window` | soft | Not Friday after 16:00 or the weekend, Toronto time |

`{team}` in a set means the repo's owning team, so one set serves every team.

### Add or change a set

A new set reuses existing rule types: `approvals`, `approvals_if_changed`, `change_approved`, `attested`, `central_template`, `from_branch`, `check_passed`, `pipeline_green`, `deploy_window`, `manifest_active`. A new rule type is code in [platform-gate](https://github.com/Stefan-org-1/platform-gate/blob/main/gate/policy.py).
