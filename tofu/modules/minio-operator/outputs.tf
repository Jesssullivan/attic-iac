# MinIO Operator Module - Outputs
#
# Outputs for downstream module dependencies.

output "namespace" {
  description = "Namespace where the MinIO operator is installed"
  value       = var.namespace
}

output "operator_installed" {
  description = "Whether the MinIO operator was installed"
  value       = var.install_operator
}

output "operator_version" {
  description = "Version of the MinIO operator installed"
  value       = var.operator_version
}

output "release_name" {
  description = "Helm release name"
  value       = var.install_operator ? helm_release.minio_operator[0].name : ""
}

output "chart_version" {
  description = "Helm chart version"
  value       = var.install_operator ? helm_release.minio_operator[0].version : ""
}
