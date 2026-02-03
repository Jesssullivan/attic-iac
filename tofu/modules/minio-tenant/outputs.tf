# MinIO Tenant Module - Outputs
#
# Outputs for connecting to the MinIO tenant.

output "tenant_name" {
  description = "Name of the MinIO tenant"
  value       = var.tenant_name
}

output "namespace" {
  description = "Namespace where the MinIO tenant is deployed"
  value       = var.namespace
}

output "s3_endpoint" {
  description = "S3 endpoint URL for internal cluster access"
  value       = local.s3_endpoint
}

output "headless_service" {
  description = "Headless service name for MinIO"
  value       = local.headless_service
}

output "bucket_name" {
  description = "Primary bucket name (first bucket in list)"
  value       = length(var.buckets) > 0 ? var.buckets[0].name : ""
}

output "buckets" {
  description = "List of all bucket names"
  value       = [for b in var.buckets : b.name]
}

output "distributed_mode" {
  description = "Whether distributed mode is enabled"
  value       = var.distributed_mode
}

output "storage_total" {
  description = "Total storage capacity (approximate)"
  value       = var.distributed_mode ? "${4 * 4 * tonumber(replace(var.volume_size, "Gi", ""))}Gi" : var.volume_size
}

output "credentials_secret" {
  description = "Name of the credentials secret"
  value       = var.credentials_secret
}
