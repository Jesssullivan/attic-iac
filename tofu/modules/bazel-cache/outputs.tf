# bazel-cache Module - Outputs

output "service_name" {
  description = "Kubernetes Service name"
  value       = kubernetes_service_v1.main.metadata[0].name
}

output "grpc_endpoint" {
  description = "gRPC endpoint for Bazel remote cache (cluster-internal)"
  value       = "grpc://${kubernetes_service_v1.main.metadata[0].name}.${var.namespace}.svc.cluster.local:${local.grpc_port}"
}

output "http_endpoint" {
  description = "HTTP endpoint for status and metrics"
  value       = "http://${kubernetes_service_v1.main.metadata[0].name}.${var.namespace}.svc.cluster.local:${local.http_port}"
}

output "bazelrc_config" {
  description = "Configuration lines for .bazelrc"
  value       = <<-EOT
    # Bazel remote cache configuration (cluster-internal)
    build:ci-internal --remote_cache=grpc://${kubernetes_service_v1.main.metadata[0].name}.${var.namespace}.svc.cluster.local:${local.grpc_port}
    build:ci-internal --remote_upload_local_results=true
    build:ci-internal --remote_download_minimal
  EOT
}

output "external_grpc_endpoint" {
  description = "External gRPC endpoint (if ingress enabled)"
  value       = var.enable_ingress ? "grpcs://${var.ingress_host}:443" : null
}

output "external_bazelrc_config" {
  description = "Configuration lines for .bazelrc (external access)"
  value = var.enable_ingress ? join("\n", [
    "# Bazel remote cache configuration (external)",
    "build:remote --remote_cache=grpcs://${var.ingress_host}:443",
    "build:remote --remote_upload_local_results=true",
    "build:remote --remote_download_minimal"
  ]) : null
}

output "grpc_port" {
  description = "gRPC port number"
  value       = local.grpc_port
}

output "http_port" {
  description = "HTTP port number"
  value       = local.http_port
}

output "labels" {
  description = "Labels applied to all resources"
  value       = local.labels
}
