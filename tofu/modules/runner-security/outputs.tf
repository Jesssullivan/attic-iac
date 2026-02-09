# Runner Security Module - Outputs

output "manager_priority_class_name" {
  description = "PriorityClass name for runner manager pods"
  value       = var.priority_classes_enabled ? kubernetes_priority_class_v1.manager[0].metadata[0].name : ""
}

output "job_priority_class_name" {
  description = "PriorityClass name for CI job pods"
  value       = var.priority_classes_enabled ? kubernetes_priority_class_v1.job[0].metadata[0].name : ""
}
