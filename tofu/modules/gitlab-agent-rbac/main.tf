# GitLab Agent RBAC Module
#
# Configures Kubernetes RBAC for GitLab Agent ci_job impersonation.
# When ci_access is configured on the agent, CI jobs authenticate as
# the "gitlab:ci_job" group. This module grants read-only access to
# runner resources in the target namespace.

resource "kubernetes_role_v1" "ci_job_access" {
  metadata {
    name      = "ci-job-runner-access"
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "gitlab-agent-rbac"
      "app.kubernetes.io/managed-by" = "opentofu"
      "app.kubernetes.io/component"  = "rbac"
    }
  }

  rule {
    api_groups = ["", "apps", "autoscaling", "batch"]
    resources  = ["pods", "pods/log", "deployments", "horizontalpodautoscalers", "jobs", "events"]
    verbs      = var.allowed_verbs
  }
}

resource "kubernetes_role_binding_v1" "ci_job_access" {
  metadata {
    name      = "bates-ils-ci-job-access"
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "gitlab-agent-rbac"
      "app.kubernetes.io/managed-by" = "opentofu"
      "app.kubernetes.io/component"  = "rbac"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.ci_job_access.metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "gitlab:ci_job"
  }
}
