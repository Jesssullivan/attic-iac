import type { GitLabRunner } from "./runners";
import type { RunnerInfo, RunnerType, RunnerStatus, RunnerConfig } from "$lib/types/runner";
import {
  RUNNER_TYPES,
  RUNNER_TYPE_DEFAULT_TAGS,
  RUNNER_TYPE_DEFAULT_IMAGES,
} from "$lib/types/runner";

/** Detect RunnerType from GitLab tag_list. Falls back to "docker". */
function detectRunnerType(tagList: string[]): RunnerType {
  const tags = tagList.map((t) => t.toLowerCase());
  if (tags.includes("dind")) return "dind";
  if (tags.includes("rocky8") || tags.includes("rhel8")) return "rocky8";
  if (tags.includes("rocky9") || tags.includes("rhel9")) return "rocky9";
  if (tags.includes("nix") || tags.includes("flakes")) return "nix";
  if (tags.includes("docker")) return "docker";
  // Check description-based fallback isn't needed since we check tags first
  return "docker";
}

/** Map GitLab runner status fields to our RunnerStatus. */
function mapStatus(runner: GitLabRunner): RunnerStatus {
  if (runner.paused) return "paused";
  if (runner.online) return "online";
  if (runner.status === "online") return "online";
  return "offline";
}

/** Default resource spec for manager pods by runner type. */
function defaultManagerResources() {
  return {
    cpu_request: "100m",
    memory_request: "128Mi",
    cpu_limit: "500m",
    memory_limit: "512Mi",
  };
}

/** Default resource spec for job pods by runner type. */
function defaultJobResources(type: RunnerType) {
  if (type === "dind") {
    return {
      cpu_request: "100m",
      memory_request: "512Mi",
      cpu_limit: "2",
      memory_limit: "4Gi",
    };
  }
  if (type === "nix") {
    return {
      cpu_request: "100m",
      memory_request: "512Mi",
      cpu_limit: "2",
      memory_limit: "4Gi",
    };
  }
  return {
    cpu_request: "100m",
    memory_request: "256Mi",
    cpu_limit: "2",
    memory_limit: "2Gi",
  };
}

/** Synthesize a RunnerConfig from type defaults. */
function buildDefaultConfig(name: string, type: RunnerType, tags: string[]): RunnerConfig {
  return {
    name,
    type,
    tags,
    concurrent_jobs: type === "docker" ? 8 : 4,
    run_untagged: false,
    protected: false,
    default_image: RUNNER_TYPE_DEFAULT_IMAGES[type],
    privileged: type === "dind",
    manager_resources: defaultManagerResources(),
    job_resources: defaultJobResources(type),
    hpa: {
      enabled: false,
      min_replicas: 1,
      max_replicas: 5,
      cpu_target: 70,
      memory_target: 80,
      scale_up_window: 15,
      scale_down_window: 300,
    },
    pdb_enabled: false,
    pdb_min_available: 1,
    metrics_enabled: true,
    service_monitor_enabled: false,
  };
}

/** Transform a GitLab API runner to our RunnerInfo shape. */
export function gitlabRunnerToRunnerInfo(runner: GitLabRunner): RunnerInfo {
  const type = detectRunnerType(runner.tag_list);
  const name = runner.description;
  const tags = runner.tag_list;

  return {
    id: runner.id,
    name,
    type,
    status: mapStatus(runner),
    tags,
    config: buildDefaultConfig(name, type, tags),
    version: runner.version || undefined,
    ip_address: runner.ip_address || undefined,
    contacted_at: runner.contacted_at || undefined,
  };
}

/** Transform a list of GitLab runners to RunnerInfo[]. */
export function gitlabRunnersToRunnerInfoList(runners: GitLabRunner[]): RunnerInfo[] {
  return runners.map(gitlabRunnerToRunnerInfo);
}
