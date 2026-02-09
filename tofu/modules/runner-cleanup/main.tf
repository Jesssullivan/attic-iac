# Runner Cleanup Module
#
# CronJob that reaps orphaned/stuck pods in the runner namespace.
# Handles: Terminating pods, Completed pods, Failed pods.

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

locals {
  common_labels = {
    "app.kubernetes.io/name"       = "runner-cleanup"
    "app.kubernetes.io/managed-by" = "opentofu"
    "app.kubernetes.io/component"  = "cleanup"
  }

  cleanup_script = <<-BASH
    set -euo pipefail

    NS="${var.namespace}"
    echo "=== Runner Cleanup Job ==="
    echo "Namespace: $NS"
    echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""

    # Force-delete pods stuck in Terminating
    echo "Force-deleting pods stuck in Terminating > ${var.terminating_threshold_seconds}s..."
    TERMINATING=$(kubectl get pods -n "$NS" --field-selector=metadata.deletionTimestamp!='' \
      -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.deletionTimestamp}{"\n"}{end}' 2>/dev/null || echo "")
    TERM_COUNT=0
    if [ -n "$TERMINATING" ]; then
      while IFS=' ' read -r POD TS; do
        [ -z "$POD" ] && continue
        CREATED_EPOCH=$(date -d "$TS" +%s 2>/dev/null || echo 0)
        NOW_EPOCH=$(date +%s)
        AGE=$(( NOW_EPOCH - CREATED_EPOCH ))
        if [ "$AGE" -gt ${var.terminating_threshold_seconds} ]; then
          echo "  Force-deleting: $POD (stuck $${AGE}s)"
          kubectl delete pod "$POD" -n "$NS" --grace-period=0 --force --ignore-not-found || true
          TERM_COUNT=$((TERM_COUNT + 1))
        fi
      done <<< "$TERMINATING"
    fi
    echo "  Force-deleted $TERM_COUNT pods"
    echo ""

    # Delete Completed pods
    echo "Deleting Completed pods older than ${var.completed_threshold_seconds}s..."
    COMPLETED=$(kubectl get pods -n "$NS" --field-selector=status.phase==Succeeded \
      -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.creationTimestamp}{"\n"}{end}' 2>/dev/null || echo "")
    COMP_COUNT=0
    if [ -n "$COMPLETED" ]; then
      while IFS=' ' read -r POD TS; do
        [ -z "$POD" ] && continue
        CREATED_EPOCH=$(date -d "$TS" +%s 2>/dev/null || echo 0)
        NOW_EPOCH=$(date +%s)
        AGE=$(( NOW_EPOCH - CREATED_EPOCH ))
        if [ "$AGE" -gt ${var.completed_threshold_seconds} ]; then
          echo "  Deleting completed: $POD (age: $${AGE}s)"
          kubectl delete pod "$POD" -n "$NS" --ignore-not-found || true
          COMP_COUNT=$((COMP_COUNT + 1))
        fi
      done <<< "$COMPLETED"
    fi
    echo "  Deleted $COMP_COUNT completed pods"
    echo ""

    # Delete Failed pods
    echo "Deleting Failed pods older than ${var.failed_threshold_seconds}s..."
    FAILED=$(kubectl get pods -n "$NS" --field-selector=status.phase==Failed \
      -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.creationTimestamp}{"\n"}{end}' 2>/dev/null || echo "")
    FAIL_COUNT=0
    if [ -n "$FAILED" ]; then
      while IFS=' ' read -r POD TS; do
        [ -z "$POD" ] && continue
        CREATED_EPOCH=$(date -d "$TS" +%s 2>/dev/null || echo 0)
        NOW_EPOCH=$(date +%s)
        AGE=$(( NOW_EPOCH - CREATED_EPOCH ))
        if [ "$AGE" -gt ${var.failed_threshold_seconds} ]; then
          echo "  Deleting failed: $POD (age: $${AGE}s)"
          kubectl delete pod "$POD" -n "$NS" --ignore-not-found || true
          FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      done <<< "$FAILED"
    fi
    echo "  Deleted $FAIL_COUNT failed pods"
    echo ""
    echo "=== Cleanup complete ==="
  BASH
}

# =============================================================================
# RBAC
# =============================================================================

resource "kubernetes_service_account_v1" "cleanup" {
  metadata {
    name      = "runner-cleanup"
    namespace = var.namespace
    labels    = local.common_labels
  }
}

resource "kubernetes_role_v1" "cleanup" {
  metadata {
    name      = "runner-cleanup"
    namespace = var.namespace
    labels    = local.common_labels
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "delete"]
  }
}

resource "kubernetes_role_binding_v1" "cleanup" {
  metadata {
    name      = "runner-cleanup"
    namespace = var.namespace
    labels    = local.common_labels
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cleanup.metadata[0].name
    namespace = var.namespace
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role_v1.cleanup.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# =============================================================================
# CronJob
# =============================================================================

resource "kubernetes_cron_job_v1" "cleanup" {
  metadata {
    name      = "runner-cleanup"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    schedule                      = var.schedule
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {
        labels = local.common_labels
      }

      spec {
        ttl_seconds_after_finished = 3600

        template {
          metadata {
            labels = local.common_labels
          }

          spec {
            service_account_name = kubernetes_service_account_v1.cleanup.metadata[0].name
            restart_policy       = "OnFailure"

            container {
              name    = "cleanup"
              image   = var.kubectl_image
              command = ["/bin/bash", "-c", local.cleanup_script]

              resources {
                requests = {
                  cpu    = "50m"
                  memory = "64Mi"
                }
                limits = {
                  cpu    = "100m"
                  memory = "128Mi"
                }
              }
            }
          }
        }
      }
    }
  }
}
