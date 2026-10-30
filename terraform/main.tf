locals {
  team_files = [for f in fileset("${path.module}/../repos", "*.yaml") : yamldecode(file("${path.module}/../repos/${f}"))]
  groups     = yamldecode(file("${path.module}/../groups.yaml")).groups

  repos = { for r in flatten([for t in local.team_files : [for r in t.repos : merge(r, { team = t.team })]]) : r.name => r }

  # Later maps win on the same key, so platform's maintain overrides push on its own repos.
  access = merge(
    { for name, r in local.repos : "${name}:${r.team}" => { repo = name, team = r.team, permission = "push" } },
    # Not on platform repos: write access there could read the gate App's key or move template tags.
    {
      for name, r in local.repos : "${name}:group-sentinels" => { repo = name, team = "group-sentinels", permission = "push" }
      if r.team != "team-platform" || name == "org-config"
    },
    # CODEOWNERS only counts teams with write access, and each team owns its file here.
    { for t in local.team_files : "org-config:${t.team}" => { repo = "org-config", team = t.team, permission = "push" } },
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

locals {
  # sentinels-<area> and managers-<area>, nested under the matching group.
  roles = {
    for r in flatten([
      for t in local.team_files : [
        for role in ["sentinels", "managers"] : {
          name    = "${role}-${trimprefix(t.team, "team-")}"
          group   = "group-${role}"
          members = lookup(t, role, [])
        }
      ]
    ]) : r.name => r
  }

  role_members = {
    for m in flatten([for name, r in local.roles : [for u in r.members : { team = name, user = u }]]) :
    "${m.team}:${m.user}" => m
  }
}

resource "github_team" "role" {
  for_each = local.roles

  name           = each.key
  parent_team_id = github_team.group[each.value.group].id
  privacy        = "closed"
}

resource "github_team_membership" "role" {
  for_each = local.role_members

  team_id  = github_team.role[each.value.team].id
  username = each.value.user
  role     = "member"

  # GitHub makes org owners maintainers of every team they join.
  lifecycle {
    ignore_changes = [role]
  }
}
