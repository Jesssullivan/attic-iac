import { json } from "@sveltejs/kit";
import { env } from "$env/dynamic/private";
import { listGroupRunners } from "$lib/server/gitlab/runners";
import { gitlabRunnersToRunnerInfoList } from "$lib/server/gitlab/transform";
import { MOCK_RUNNERS } from "$lib/mocks";
import type { RequestHandler } from "./$types";

export const GET: RequestHandler = async () => {
  if (!env.GITLAB_TOKEN || !env.GITLAB_GROUP_ID) {
    return json(MOCK_RUNNERS);
  }

  try {
    const rawRunners = await listGroupRunners(env.GITLAB_GROUP_ID);
    const runners = gitlabRunnersToRunnerInfoList(rawRunners);
    return json(runners);
  } catch {
    return json(MOCK_RUNNERS);
  }
};
