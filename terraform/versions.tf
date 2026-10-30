terraform {
  required_version = ">= 1.7"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

# Token comes from GITHUB_TOKEN.
provider "github" {
  owner = "Stefan-org-1"
}
