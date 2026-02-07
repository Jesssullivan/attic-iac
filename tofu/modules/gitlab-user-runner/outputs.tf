# GitLab User Runner Module - Outputs

output "token" {
  description = "Runner authentication token"
  value       = gitlab_user_runner.this.token
  sensitive   = true
}

output "runner_id" {
  description = "GitLab runner ID"
  value       = gitlab_user_runner.this.id
}
