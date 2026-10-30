# One-off adoption of resources created by hand before Terraform. Delete after the first apply.

import {
  for_each = toset(["team-platform", "team-payments"])
  to       = github_team.team[each.key]
  id       = each.key
}

import {
  for_each = toset(["group-sentinels", "group-managers"])
  to       = github_team.group[each.key]
  id       = each.key
}

import {
  for_each = toset(["ci-templates", "payments-web"])
  to       = github_repository.repo[each.key]
  id       = each.key
}
