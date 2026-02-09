import { json, error } from "@sveltejs/kit";
import { env } from "$env/dynamic/private";
import { listGroupRunners } from "$lib/server/gitlab/runners";
import { gitlabRunnersToRunnerInfoList } from "$lib/server/gitlab/transform";
import { MOCK_RUNNER_MAP } from "$lib/mocks";
import type { RequestHandler } from "./$types";

export const GET: RequestHandler = async ({ params }) => {
  if (env.GITLAB_TOKEN && env.GITLAB_GROUP_ID) {
    try {
      const rawRunners = await listGroupRunners(env.GITLAB_GROUP_ID);
      const runners = gitlabRunnersToRunnerInfoList(rawRunners);
      const runner = runners.find((r) => r.name === params.name);
      if (runner) {
        return json(runner);
      }
    } catch {
      // Fall through to mock lookup
    }
  }

  const runner = MOCK_RUNNER_MAP[params.name];
  if (!runner) {
    error(404, `Runner "${params.name}" not found`);
  }
  return json(runner);
};
