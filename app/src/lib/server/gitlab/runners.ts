import { gitlab, type GitLabClient } from "./client";

export interface GitLabRunner {
  id: number;
  description: string;
  active: boolean;
  paused: boolean;
  is_shared: boolean;
  runner_type: string;
  tag_list: string[];
  version: string;
  ip_address: string;
  status: string;
  contacted_at: string;
  online: boolean;
}

interface GitLabJob {
  id: number;
  status: string;
  pipeline: { id: number };
  project: { name: string; path_with_namespace: string };
  ref: string;
  stage: string;
  name: string;
  started_at: string;
  finished_at: string;
  duration: number;
}

export async function listGroupRunners(
  groupId: string,
  client: GitLabClient = gitlab,
): Promise<GitLabRunner[]> {
  return client.request<GitLabRunner[]>(`/groups/${groupId}/runners`, {
    params: { per_page: "100", type: "group_type" },
  });
}

export async function getRunner(
  runnerId: number,
  client: GitLabClient = gitlab,
): Promise<GitLabRunner> {
  return client.request<GitLabRunner>(`/runners/${runnerId}`);
}

export async function pauseRunner(
  runnerId: number,
  client: GitLabClient = gitlab,
): Promise<void> {
  await client.request(`/runners/${runnerId}`, {
    method: "PUT",
    body: { paused: true },
  });
}

export async function resumeRunner(
  runnerId: number,
  client: GitLabClient = gitlab,
): Promise<void> {
  await client.request(`/runners/${runnerId}`, {
    method: "PUT",
    body: { paused: false },
  });
}

export async function getRunnerJobs(
  runnerId: number,
  status?: string,
  client: GitLabClient = gitlab,
): Promise<GitLabJob[]> {
  const params: Record<string, string> = { per_page: "20" };
  if (status) params.status = status;

  return client.request<GitLabJob[]>(`/runners/${runnerId}/jobs`, { params });
}
