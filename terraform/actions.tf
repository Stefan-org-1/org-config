resource "github_actions_organization_permissions" "org" {
  enabled_repositories = "all"
  allowed_actions      = "selected"
  sha_pinning_required = true

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = false
    patterns_allowed     = yamldecode(file("${path.module}/../actions-allowlist.yaml")).patterns
  }
}
