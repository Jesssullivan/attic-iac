# Attic Stack - Backend Configuration
#
# Uses GitLab Managed Terraform State for state storage and locking.
# This enables collaboration and state versioning through GitLab.
#
# The HTTP backend configuration uses environment variables set by CI:
#   TF_HTTP_ADDRESS        - State read/write URL
#   TF_HTTP_LOCK_ADDRESS   - Lock URL
#   TF_HTTP_UNLOCK_ADDRESS - Unlock URL
#   TF_HTTP_USERNAME       - gitlab-ci-token
#   TF_HTTP_PASSWORD       - CI_JOB_TOKEN
#
# For CI/CD deployments, the HTTP backend is configured via environment
# variables in the .gitlab-ci.yml job templates.
#
# For local development, use the local backend below.

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
