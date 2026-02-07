# GitLab Agent RBAC Module - Outputs

output "role_name" {
  description = "Name of the created Role"
  value       = kubernetes_role_v1.ci_job_access.metadata[0].name
}

output "role_binding_name" {
  description = "Name of the created RoleBinding"
  value       = kubernetes_role_binding_v1.ci_job_access.metadata[0].name
}
