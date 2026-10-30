locals {
  gate_app_id = 5543165

  active_repos = { for name, r in local.repos : name => r if r.status == "active" }

  environments = {
    for e in flatten([
      for name, r in local.active_repos : [
        for env in keys(lookup(lookup(r, "rulesets", {}), "deploy", {})) : { repo = name, env = env }
      ]
    ]) : "${e.repo}:${e.env}" => e
  }
}

resource "github_repository_ruleset" "baseline" {
  for_each = local.active_repos

  name        = "platform-baseline"
  repository  = github_repository.repo[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # Org admins can bypass: the merge-side break-glass for this lab.
  bypass_actors {
    actor_id    = 1
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    deletion         = true
    non_fast_forward = true

    required_status_checks {
      # Only a check from the gate App counts.
      required_check {
        context        = "policy"
        integration_id = local.gate_app_id
      }
    }
  }
}

resource "github_repository_environment" "env" {
  for_each = local.environments

  repository  = github_repository.repo[each.value.repo].name
  environment = each.value.env
}
