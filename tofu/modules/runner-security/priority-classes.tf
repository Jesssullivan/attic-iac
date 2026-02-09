# Runner Security Module - PriorityClasses
#
# Ensures runner manager pods survive node-pressure eviction while
# CI job pods remain preemptible.

resource "kubernetes_priority_class_v1" "manager" {
  count = var.priority_classes_enabled ? 1 : 0

  metadata {
    name   = "${var.namespace}-manager"
    labels = local.common_labels
  }

  value          = 1000
  global_default = false
  description    = "Priority for GitLab Runner manager pods"
}

resource "kubernetes_priority_class_v1" "job" {
  count = var.priority_classes_enabled ? 1 : 0

  metadata {
    name   = "${var.namespace}-job"
    labels = local.common_labels
  }

  value          = 100
  global_default = false
  description    = "Priority for CI job pods (preemptible)"
}
