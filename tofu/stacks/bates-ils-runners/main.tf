# Bates ILS GitLab Runners Stack
#
# Unified auto-scaling GitLab Runner infrastructure for the bates-ils group.
# Supports: docker, dind, rocky8, rocky9, nix workloads.
# Registered at GROUP level for all bates-ils projects.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.k8s_config_path != "" ? var.k8s_config_path : null
  config_context = var.cluster_context
}

provider "helm" {
  kubernetes {
    config_path    = var.k8s_config_path != "" ? var.k8s_config_path : null
    config_context = var.cluster_context
  }
}

provider "gitlab" {
  token = var.gitlab_token
}

# =============================================================================
# Automated Runner Token Registration
# =============================================================================
# When gitlab_group_id is set, tokens are managed automatically via
# gitlab_user_runner. Otherwise, fall back to manually-provided tokens.

locals {
  use_auto_tokens = var.gitlab_group_id != 0

  docker_token = local.use_auto_tokens ? module.docker_token[0].token : var.docker_runner_token
  dind_token   = local.use_auto_tokens ? module.dind_token[0].token : var.dind_runner_token
  rocky8_token = local.use_auto_tokens ? module.rocky8_token[0].token : var.rocky8_runner_token
  rocky9_token = local.use_auto_tokens ? module.rocky9_token[0].token : var.rocky9_runner_token
  nix_token    = local.use_auto_tokens ? module.nix_token[0].token : var.nix_runner_token
}

module "docker_token" {
  source = "../../modules/gitlab-user-runner"
  count  = local.use_auto_tokens && var.deploy_docker_runner ? 1 : 0

  group_id    = var.gitlab_group_id
  tag_list    = ["docker", "linux", "amd64"]
  description = "bates-docker: Standard Alpine-based builds"
}

module "dind_token" {
  source = "../../modules/gitlab-user-runner"
  count  = local.use_auto_tokens && var.deploy_dind_runner ? 1 : 0

  group_id    = var.gitlab_group_id
  tag_list    = ["docker", "dind", "privileged"]
  description = "bates-dind: Docker-in-Docker container builds"
}

module "rocky8_token" {
  source = "../../modules/gitlab-user-runner"
  count  = local.use_auto_tokens && var.deploy_rocky8_runner ? 1 : 0

  group_id    = var.gitlab_group_id
  tag_list    = ["rocky8", "rhel8", "linux"]
  description = "bates-rocky8: RHEL 8 compatibility builds"
}

module "rocky9_token" {
  source = "../../modules/gitlab-user-runner"
  count  = local.use_auto_tokens && var.deploy_rocky9_runner ? 1 : 0

  group_id    = var.gitlab_group_id
  tag_list    = ["rocky9", "rhel9", "linux"]
  description = "bates-rocky9: RHEL 9 compatibility builds"
}

module "nix_token" {
  source = "../../modules/gitlab-user-runner"
  count  = local.use_auto_tokens && var.deploy_nix_runner ? 1 : 0

  group_id    = var.gitlab_group_id
  tag_list    = ["nix", "flakes"]
  description = "bates-nix: Nix flake builds with Attic cache"
}

# =============================================================================
# Namespace (shared by all runners)
# =============================================================================

resource "kubernetes_namespace_v1" "runners" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "bates-ils-runners"
      "app.kubernetes.io/managed-by" = "opentofu"
      "app.kubernetes.io/component"  = "ci-cd"
    }
  }
}

# =============================================================================
# Docker Runner - Standard builds
# =============================================================================

module "docker_runner" {
  source = "../../modules/gitlab-runner"
  count  = var.deploy_docker_runner ? 1 : 0

  runner_name      = "bates-docker"
  runner_type      = "docker"
  namespace        = var.namespace
  create_namespace = false

  depends_on = [kubernetes_namespace_v1.runners]

  gitlab_url   = var.gitlab_url
  runner_token = local.docker_token

  runner_tags     = var.docker_runner_tags
  concurrent_jobs = var.docker_concurrent_jobs
  run_untagged    = false
  protected       = false

  # Manager pod resources
  cpu_request    = var.docker_cpu_request
  memory_request = var.docker_memory_request
  cpu_limit      = var.docker_cpu_limit
  memory_limit   = var.docker_memory_limit

  # Job pod resources
  job_cpu_request    = var.docker_job_cpu_request
  job_memory_request = var.docker_job_memory_request
  job_cpu_limit      = var.docker_job_cpu_limit
  job_memory_limit   = var.docker_job_memory_limit

  # HPA configuration
  hpa_enabled           = var.hpa_enabled
  hpa_min_replicas      = var.docker_hpa_min_replicas
  hpa_max_replicas      = var.docker_hpa_max_replicas
  hpa_cpu_target        = var.hpa_cpu_target
  hpa_memory_target     = var.hpa_memory_target
  hpa_scale_up_window   = var.hpa_scale_up_window
  hpa_scale_down_window = var.hpa_scale_down_window

  # PDB
  pdb_enabled       = var.pdb_enabled
  pdb_min_available = 1

  # Monitoring
  metrics_enabled         = var.metrics_enabled
  service_monitor_enabled = var.service_monitor_enabled
  service_monitor_labels  = var.service_monitor_labels
}

# =============================================================================
# DinD Runner - Container builds with Docker-in-Docker
# =============================================================================

module "dind_runner" {
  source = "../../modules/gitlab-runner"
  count  = var.deploy_dind_runner ? 1 : 0

  runner_name      = "bates-dind"
  runner_type      = "dind"
  namespace        = var.namespace
  create_namespace = false

  depends_on = [kubernetes_namespace_v1.runners]

  gitlab_url   = var.gitlab_url
  runner_token = local.dind_token

  runner_tags     = var.dind_runner_tags
  concurrent_jobs = var.dind_concurrent_jobs
  run_untagged    = false
  protected       = false

  # DinD configuration
  docker_version = var.docker_version

  # Manager pod resources (higher for DinD)
  cpu_request    = var.dind_cpu_request
  memory_request = var.dind_memory_request
  cpu_limit      = var.dind_cpu_limit
  memory_limit   = var.dind_memory_limit

  # Job pod resources (higher for container builds)
  job_cpu_request    = var.dind_job_cpu_request
  job_memory_request = var.dind_job_memory_request
  job_cpu_limit      = var.dind_job_cpu_limit
  job_memory_limit   = var.dind_job_memory_limit

  # HPA configuration
  hpa_enabled           = var.hpa_enabled
  hpa_min_replicas      = var.dind_hpa_min_replicas
  hpa_max_replicas      = var.dind_hpa_max_replicas
  hpa_cpu_target        = var.hpa_cpu_target
  hpa_memory_target     = var.hpa_memory_target
  hpa_scale_up_window   = var.hpa_scale_up_window
  hpa_scale_down_window = var.hpa_scale_down_window

  # PDB
  pdb_enabled       = var.pdb_enabled
  pdb_min_available = 1

  # Monitoring
  metrics_enabled         = var.metrics_enabled
  service_monitor_enabled = var.service_monitor_enabled
  service_monitor_labels  = var.service_monitor_labels

  # Node selector for privileged workloads (optional)
  node_selector = var.dind_node_selector
  tolerations   = var.dind_tolerations
}

# =============================================================================
# Rocky 8 Runner - RHEL 8 compatibility
# =============================================================================

module "rocky8_runner" {
  source = "../../modules/gitlab-runner"
  count  = var.deploy_rocky8_runner ? 1 : 0

  runner_name      = "bates-rocky8"
  runner_type      = "rocky8"
  namespace        = var.namespace
  create_namespace = false

  depends_on = [kubernetes_namespace_v1.runners]

  gitlab_url   = var.gitlab_url
  runner_token = local.rocky8_token

  runner_tags     = var.rocky8_runner_tags
  concurrent_jobs = var.rocky8_concurrent_jobs
  run_untagged    = false
  protected       = false

  # Manager pod resources
  cpu_request    = var.rocky_cpu_request
  memory_request = var.rocky_memory_request
  cpu_limit      = var.rocky_cpu_limit
  memory_limit   = var.rocky_memory_limit

  # Job pod resources
  job_cpu_request    = var.rocky_job_cpu_request
  job_memory_request = var.rocky_job_memory_request
  job_cpu_limit      = var.rocky_job_cpu_limit
  job_memory_limit   = var.rocky_job_memory_limit

  # HPA configuration
  hpa_enabled           = var.hpa_enabled
  hpa_min_replicas      = var.rocky_hpa_min_replicas
  hpa_max_replicas      = var.rocky_hpa_max_replicas
  hpa_cpu_target        = var.hpa_cpu_target
  hpa_memory_target     = var.hpa_memory_target
  hpa_scale_up_window   = var.hpa_scale_up_window
  hpa_scale_down_window = var.hpa_scale_down_window

  # PDB
  pdb_enabled       = var.pdb_enabled
  pdb_min_available = 1

  # Monitoring
  metrics_enabled         = var.metrics_enabled
  service_monitor_enabled = var.service_monitor_enabled
  service_monitor_labels  = var.service_monitor_labels
}

# =============================================================================
# Rocky 9 Runner - RHEL 9 compatibility
# =============================================================================

module "rocky9_runner" {
  source = "../../modules/gitlab-runner"
  count  = var.deploy_rocky9_runner ? 1 : 0

  runner_name      = "bates-rocky9"
  runner_type      = "rocky9"
  namespace        = var.namespace
  create_namespace = false

  depends_on = [kubernetes_namespace_v1.runners]

  gitlab_url   = var.gitlab_url
  runner_token = local.rocky9_token

  runner_tags     = var.rocky9_runner_tags
  concurrent_jobs = var.rocky9_concurrent_jobs
  run_untagged    = false
  protected       = false

  # Manager pod resources
  cpu_request    = var.rocky_cpu_request
  memory_request = var.rocky_memory_request
  cpu_limit      = var.rocky_cpu_limit
  memory_limit   = var.rocky_memory_limit

  # Job pod resources
  job_cpu_request    = var.rocky_job_cpu_request
  job_memory_request = var.rocky_job_memory_request
  job_cpu_limit      = var.rocky_job_cpu_limit
  job_memory_limit   = var.rocky_job_memory_limit

  # HPA configuration
  hpa_enabled           = var.hpa_enabled
  hpa_min_replicas      = var.rocky_hpa_min_replicas
  hpa_max_replicas      = var.rocky_hpa_max_replicas
  hpa_cpu_target        = var.hpa_cpu_target
  hpa_memory_target     = var.hpa_memory_target
  hpa_scale_up_window   = var.hpa_scale_up_window
  hpa_scale_down_window = var.hpa_scale_down_window

  # PDB
  pdb_enabled       = var.pdb_enabled
  pdb_min_available = 1

  # Monitoring
  metrics_enabled         = var.metrics_enabled
  service_monitor_enabled = var.service_monitor_enabled
  service_monitor_labels  = var.service_monitor_labels
}

# =============================================================================
# Nix Runner - Nix builds with Attic cache integration
# =============================================================================

module "nix_runner" {
  source = "../../modules/gitlab-runner"
  count  = var.deploy_nix_runner ? 1 : 0

  runner_name      = "bates-nix"
  runner_type      = "nix"
  namespace        = var.namespace
  create_namespace = false

  depends_on = [kubernetes_namespace_v1.runners]

  gitlab_url   = var.gitlab_url
  runner_token = local.nix_token

  runner_tags     = var.nix_runner_tags
  concurrent_jobs = var.nix_concurrent_jobs
  run_untagged    = false
  protected       = false

  # Attic cache integration
  attic_server = var.attic_server
  attic_cache  = var.attic_cache
  attic_token  = var.attic_token

  # Nix store configuration
  nix_store_size = var.nix_store_size

  # Manager pod resources
  cpu_request    = var.nix_cpu_request
  memory_request = var.nix_memory_request
  cpu_limit      = var.nix_cpu_limit
  memory_limit   = var.nix_memory_limit

  # Job pod resources (higher for Nix builds)
  job_cpu_request    = var.nix_job_cpu_request
  job_memory_request = var.nix_job_memory_request
  job_cpu_limit      = var.nix_job_cpu_limit
  job_memory_limit   = var.nix_job_memory_limit

  # HPA configuration
  hpa_enabled           = var.hpa_enabled
  hpa_min_replicas      = var.nix_hpa_min_replicas
  hpa_max_replicas      = var.nix_hpa_max_replicas
  hpa_cpu_target        = var.hpa_cpu_target
  hpa_memory_target     = var.hpa_memory_target
  hpa_scale_up_window   = var.hpa_scale_up_window
  hpa_scale_down_window = var.hpa_scale_down_window

  # PDB
  pdb_enabled       = var.pdb_enabled
  pdb_min_available = 1

  # Monitoring
  metrics_enabled         = var.metrics_enabled
  service_monitor_enabled = var.service_monitor_enabled
  service_monitor_labels  = var.service_monitor_labels
}
