# MinIO Tenant - Lifecycle Policies (ILM)
#
# Implements bucket lifecycle policies for automatic cleanup of:
# - NAR files (Nix archive files)
# - Chunks (content-addressed storage chunks)
#
# Uses `mc ilm rule add` commands directly instead of JSON import
# for compatibility across mc client versions.

# =============================================================================
# Job to Apply Lifecycle Policies
# =============================================================================

resource "kubernetes_job" "apply_lifecycle" {
  count = var.enable_lifecycle_policies ? 1 : 0

  metadata {
    name      = "${var.tenant_name}-apply-lifecycle"
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "minio"
      "app.kubernetes.io/instance"   = var.tenant_name
      "app.kubernetes.io/component"  = "lifecycle-init"
      "app.kubernetes.io/managed-by" = "opentofu"
    }
  }

  spec {
    ttl_seconds_after_finished = 300
    backoff_limit              = 5

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "minio"
          "app.kubernetes.io/instance"  = var.tenant_name
          "app.kubernetes.io/component" = "lifecycle-init"
        }
      }

      spec {
        restart_policy = "OnFailure"

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          run_as_group    = 1000
          fs_group        = 1000
        }

        container {
          name  = "mc"
          image = "quay.io/minio/mc:RELEASE.2025-01-17T23-25-50Z"

          # mc needs a writable config directory
          env {
            name  = "MC_CONFIG_DIR"
            value = "/tmp/.mc"
          }

          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
              set -e
              echo "Waiting for MinIO to be ready..."
              sleep 30

              mkdir -p /tmp/.mc

              echo "Loading credentials..."
              source /credentials/config.env

              echo "Configuring MinIO client..."
              mc alias set myminio http://${var.tenant_name}-hl:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

              echo "Waiting for bucket to exist..."
              for i in $(seq 1 30); do
                if mc ls myminio/${var.buckets[0].name} >/dev/null 2>&1; then
                  echo "Bucket exists"
                  break
                fi
                echo "Attempt $i: Waiting for bucket..."
                sleep 5
              done

              echo "Applying lifecycle rules..."

              # Expire NAR files after retention period
              mc ilm rule add --expiry-days ${var.nar_retention_days} --prefix "nar/" myminio/${var.buckets[0].name} \
                && echo "  Added: expire nar/ after ${var.nar_retention_days} days" \
                || echo "  Note: nar/ rule may already exist"

              # Expire chunk files after retention period
              mc ilm rule add --expiry-days ${var.chunk_retention_days} --prefix "chunks/" myminio/${var.buckets[0].name} \
                && echo "  Added: expire chunks/ after ${var.chunk_retention_days} days" \
                || echo "  Note: chunks/ rule may already exist"

              echo "Verifying lifecycle rules..."
              mc ilm rule ls myminio/${var.buckets[0].name}

              echo "Lifecycle rules applied successfully"
            EOT
          ]

          volume_mount {
            name       = "credentials"
            mount_path = "/credentials"
            read_only  = true
          }

          # Writable directory for mc config (read_only_root_filesystem blocks /root/.mc)
          volume_mount {
            name       = "mc-config"
            mount_path = "/tmp/.mc"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        volume {
          name = "credentials"
          secret {
            secret_name = var.credentials_secret
          }
        }

        # Writable volume for mc config (needed with read_only_root_filesystem)
        volume {
          name = "mc-config"
          empty_dir {}
        }
      }
    }
  }

  wait_for_completion = false

  depends_on = [
    kubectl_manifest.minio_tenant,
    null_resource.wait_for_tenant
  ]
}

# =============================================================================
# ServiceMonitor for Prometheus (optional)
# =============================================================================

resource "kubernetes_manifest" "minio_servicemonitor" {
  count = var.enable_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.tenant_name}-metrics"
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/name"       = "minio"
        "app.kubernetes.io/instance"   = var.tenant_name
        "app.kubernetes.io/component"  = "monitoring"
        "app.kubernetes.io/managed-by" = "opentofu"
        "release"                      = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "v1.min.io/tenant" = var.tenant_name
        }
      }
      namespaceSelector = {
        matchNames = [var.namespace]
      }
      endpoints = [
        {
          port     = "http-minio"
          path     = "/minio/v2/metrics/cluster"
          interval = "30s"
          scheme   = "http"
        }
      ]
    }
  }

  depends_on = [kubectl_manifest.minio_tenant]
}
