# GitLab User Runner Module - Provider Requirements

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
}
