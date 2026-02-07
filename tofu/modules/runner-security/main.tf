# Runner Security Module
#
# Applies security policies to the runner namespace:
# - NetworkPolicy: default-deny ingress, full egress allowed
# - ResourceQuota: cluster-appropriate limits
# - LimitRange: sane defaults for job pods without explicit limits

locals {
  common_labels = {
    "app.kubernetes.io/name"       = "runner-security"
    "app.kubernetes.io/managed-by" = "opentofu"
    "app.kubernetes.io/component"  = "security"
  }
}

# =============================================================================
# NetworkPolicy: deny ingress by default, allow full egress
# =============================================================================

resource "kubernetes_network_policy_v1" "default_deny_ingress" {
  metadata {
    name      = "default-deny-ingress"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}
