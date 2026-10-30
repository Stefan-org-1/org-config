locals {
  team_files = [for f in fileset("${path.module}/../repos", "*.yaml") : yamldecode(file("${path.module}/../repos/${f}"))]
  groups     = yamldecode(file("${path.module}/../groups.yaml")).groups

  repos = { for r in flatten([for t in local.team_files : [for r in t.repos : merge(r, { team = t.team })]]) : r.name => r }

  # Later maps win on the same key, so platform's maintain overrides push on its own repos.
  access = merge(
    { for name, r in local.repos : "${name}:${r.team}" => { repo = name, team = r.team, permission = "push" } },
    { for name, r in local.repos : "${name}:group-sentinels" => { repo = name, team = "group-sentinels", permission = "push" } },
    { for name, r in local.repos : "${name}:team-platform" => { repo = name, team = "team-platform", permission = "maintain" } },
  )
}

resource "github_team" "team" {
  for_each = { for t in local.team_files : t.team => t }

  name    = each.key
  privacy = "closed"
}

resource "github_team" "group" {
  for_each = { for g in local.groups : g.name => g }

  name        = each.key
  description = each.value.description
  privacy     = "closed"
}

resource "github_repository" "repo" {
  for_each = local.repos

  name               = each.key
  description        = each.value.description
  visibility         = "public"
  has_issues         = true
  has_projects       = false
  has_wiki           = false
  archived           = each.value.status == "archived"
  archive_on_destroy = true
}

resource "github_team_repository" "access" {
  for_each = local.access

  team_id    = merge(github_team.team, github_team.group)[each.value.team].id
  repository = github_repository.repo[each.value.repo].name
  permission = each.value.permission
}
