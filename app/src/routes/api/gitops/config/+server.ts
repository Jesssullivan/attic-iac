import { json } from "@sveltejs/kit";
import type { RequestHandler } from "./$types";
import { parseTfVars } from "$lib/server/gitops/tfvars-parser";
import { getTfvarsPath, getDefaultEnvironment } from "$lib/server/gitops/config";
import { readFileSync } from "fs";
import { resolve } from "path";

export const GET: RequestHandler = async ({ url }) => {
  // In development, read from local file; in production, read from GitLab API
  try {
    // Get environment from query parameter, or use default
    const environment = url.searchParams.get("env") ?? getDefaultEnvironment();
    const relativePath = getTfvarsPath(environment);
    const tfvarsPath = resolve("..", relativePath);

    const content = readFileSync(tfvarsPath, "utf-8");
    const doc = parseTfVars(content);
    return json({ source: "local", environment, values: doc.values });
  } catch (error) {
    return json({ source: "unavailable", error: String(error), values: {} });
  }
};
